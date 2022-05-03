using Bonsai: CancelToken, register!
using AbstractTrees
using Sockets: InetAddr

export App

function path_params(stream)
    stream.context[:params]
end

mutable struct App
    id::Int
    hot_reload::Bool
    redocs::Union{String,Nothing}
    cancel_token::CancelToken
    inet_addr::Union{InetAddr,Nothing}
    paths::Node
    middleware::Node

    function App()
        id = rand(Int)
        app = new(
            id,
            false,
            nothing,
            CancelToken(),
            nothing,
            Node("*"),
            Node("*"),
        )
        finalizer(stop, app)
        return app
    end
end

struct NoHandler <: Exception
    stream::Stream
end

function Base.show(io::IO, e::NoHandler)
    print(
        io,
        "Target - $(e.stream.message.target)\n",
        "Method - $(e.stream.message.method)"
    )
end

function (app::App)(stream)
    request::Request = stream.message
    request.body = Base.read(stream)
    closeread(stream)



    try
        # request.response::Response = handler(request)
        handler, middleware::Array{Any} = match(app, stream)

        if isnothing(middleware) || ismissing(middleware)
            middleware = []
        end

        if app.hot_reload
            middleware = map(middleware) do fn
                (stream, next) -> Base.invokelatest(fn, stream, next)
            end
        end

        # Base.invoke_in_world
        if isnothing(handler) || ismissing(handler) || isempty(middleware)
            push!(middleware, (stream, next) -> throw(NoHandler(stream)))
        else
            if app.hot_reload
                push!(middleware, (stream, next) -> Base.invokelatest(handler, stream))
            else
                push!(middleware, (stream, next) -> handler(stream))
            end
        end
        combine_middleware(middleware)(stream)

    catch e
        @error e
    finally
        request.response.request = request
        @info request.response
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
    # return eval(:(function(fn, path)  
    # 	handler = wrap_handler(fn)
    # 	node = handler isa Middleware ? $(app).middleware : $(app).paths
    # 	register!(
    # 		node,
    # 		$method,
    # 		path,
    # 		handler
    # 	)
    # end))
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
