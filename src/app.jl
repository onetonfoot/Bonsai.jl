using Bonsai: CancelToken, register!
using AbstractTrees
using Sockets: InetAddr
using HTTP.Handlers: Leaf

export App
# There must be a better way to handle multple app's

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
