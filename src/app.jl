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
    paths_docs::Dict{Symbol, Dict{String, String}} = Dict(
        :get => Dict(),
        :post => Dict(),
        :put => Dict(),
        :trace => Dict(),
        :delete => Dict(),
        :options => Dict(),
        :patch => Dict(),
        :summary => Dict(),
    )
    middleware::Node = Node("*")
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
        # We need to return this hanlder for the open api doc functionality
        # to work
        handler
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
    elseif s == :summary
        return (x) -> nothing
    elseif s == :all
        return create_handler(app, ALL)
    else
        return Base.getfield(app, s)
    end
end
