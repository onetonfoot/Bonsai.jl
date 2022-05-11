using Bonsai: CancelToken, register!
using AbstractTrees
using Sockets: InetAddr, TCPServer

export App

function path_params(stream)
    stream.context[:params]
end

Base.@kwdef mutable struct App
    id::Int = rand(Int)
    docs::Union{String,Nothing} = nothing
    cancel_token::CancelToken = CancelToken()
    inet_addr::Union{InetAddr,Nothing} = nothing
    server::Union{TCPServer,Nothing} = nothing
    paths::Node = Node("*")
    middleware::Node = Node("*")

    # function App()
    #     id = rand(Int)
    #     app = new(
    #         id,
    #         nothing,
    #         CancelToken(),
    #         nothing,
    #         nothing,
    #         Node("*"),
    #         Node("*"),
    #     )
    #     # finalizer(stop, app)
    #     return app
    # end
end


function Base.show(io::IO, e::NoHandler)
    print(
        io,
        "Target - $(e.stream.message.target)\n",
        "Method - $(e.stream.message.method)"
    )
end

function ws_upgrade(http::HTTP.Stream; binary=false)

    @info "upgrading"
    @info http

    # check_upgrade(http)
    if !hasheader(http, "Sec-WebSocket-Version", "13")
        throw(WebSocketError(0, "Expected \"Sec-WebSocket-Version: 13\"!\n" *
                                "$(http.message)"))
    end

    setstatus(http, 101)
    setheader(http, "Upgrade" => "websocket")
    setheader(http, "Connection" => "Upgrade")
    key = header(http, "Sec-WebSocket-Key")
    setheader(http, "Sec-WebSocket-Accept" => accept_hash(key))

    startwrite(http)

    io = http.stream
    req = http.message
    ws = WebSocket(io; binary=binary, server=true, request=req)
    return ws
end

function is_ws(stream)

end

function (app::App)(stream)
    request::Request = stream.message

    if !hasheader(stream, "Sec-WebSocket-Version", "13")
        request.body = Base.read(stream)
        closeread(stream)
    end

    try
        handler, middleware::Array{Any} = match(app, stream)

        if isnothing(middleware) || ismissing(middleware)
            middleware = []
        end


        if ismissing(handler) || isnothing(handler)
            push!(middleware, (stream, next) -> throw(NoHandler(stream)))
        else
            push!(middleware, (stream, next) -> handler(stream))
        end
        combine_middleware(middleware)(stream)

    catch e
        if e isa NoHandler
            @warn e
        else
            @error "error" type = typeof(e) e = e
        end
    finally
        request.response.request = request
        startwrite(stream)
        Base.write(stream, request.response.body)
    end
end

function AbstractTrees.children(node::Node)
    l = []
    if !isempty(node.exact)
        push!(l, node.exact...)
    end
    if !isempty(node.conditional)
        push!(l, node.conditional...)
    end
    if !isnothing(node.wildcard)
        push!(l, node.wildcard)
    end
    if !isnothing(node.doublestar)
        push!(l, node.wildcard)
    end
    filter!(x -> !isnothing(x), l)
    return l
end

function middleware(app::App)
    leaves = Leaf[]
    for n in PostOrderDFS(app.middleware)
        if !isempty(n.methods)
            push!(leaves, n.methods...)
        end
    end
    return leaves
end

function handlers(app::App)
    leaves = Leaf[]
    for n in PostOrderDFS(app.paths)
        if !isempty(n.methods)
            push!(leaves, n.methods...)
        end
    end
    return leaves
end

function create_handler(app, method)
    return function (fn, path)
        handler = wrap_handler(fn)
        node = handler isa Middleware ? app.middleware : app.paths
        register!(
            node,
            method,
            path,
            handler
        )
    end
end

function Base.getproperty(app::App, s::Symbol)
    if s == :get
        return create_handler(app, GET)
    elseif s == :post
        return create_handler(app, POST)
    elseif s == :put
        return create_handler(app, POST)
    elseif s == :trace
        return create_handler(app, TRACE)
    elseif s == :delete
        return create_handler(app, DELETE)
    elseif s == :options
        return create_handler(app, OPTIONS)
    elseif s == :connect
        return create_handler(app, CONNECT)
    elseif s == :patch
        return create_handler(app, PATCH)
    elseif s == :all
        return create_handler(app, ALL)
    else
        return Base.getfield(app, s)
    end
end
