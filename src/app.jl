using Bonsai: CancelToken
using AbstractTrees
using Sockets: InetAddr, TCPServer, @ip_str
using HTTP.Handlers: Leaf, Node, segment
using OrderedCollections
using PkgVersion
using Term
using Term: hstack
using Base.Threads

const VERSION = PkgVersion.@Version

export App

Base.@kwdef mutable struct App
    # Why is this here again?
    cancel_token::CancelToken = CancelToken()
    inet_addr::Union{InetAddr,Nothing} = InetAddr(ip"0.0.0.0", 8081)
    server::Union{TCPServer,Nothing} = nothing

    current_connections::Int = 0
    connection_limit::Int = typemax(Int)
    # LittleDict is ordered dict that is fast to iterate over for less than 50 elements
    _middleware::LittleDict{Tuple{HttpMethod,String},Array{Middleware}} = LittleDict() # 

    paths::Node = Node("*")
    _paths = Dict{Tuple{HttpMethod,String},HttpHandler}()
    # should probably change the type sig so _paths and path_docs match
    paths_docs::Dict{Symbol,Dict{String,Union{String,Nothing}}} = Dict(
        :get => Dict(),
        :post => Dict(),
        :put => Dict(),
        :trace => Dict(),
        :delete => Dict(),
        :options => Dict(),
        :patch => Dict(),
        :summary => Dict(),
    )
end

function (app::App)(stream)
    request::Request = stream.message
    # Unsure why this is empty, I would have thought that HTTP
    # would fill this field but seemingly not atm
    request.url = URI(request.target)

    if !hasheader(stream, "Sec-WebSocket-Version", "13")
        request.body = Base.read(stream)
        closeread(stream)
    end
    handler, middleware = gethandlers(app, request)

    if ismissing(handler) || isnothing(handler)
        push!(middleware, Middleware((stream, next) -> throw(NoHandler(stream))))
    else
        push!(middleware, Middleware((stream, next) -> handler(stream)))
    end

    combine_middleware(middleware)(stream)
    startwrite(stream)
    Base.write(stream, request.response.body)
end


struct CreateHandler
    app::App
    method::HttpMethod
end


(create::CreateHandler)(fn, path) = create(HttpHandler(fn), path)
(create::CreateHandler)(fn::Array, path) = create(Middleware.(fn), path)

function (create::CreateHandler)(handler::HttpHandler, path)
    create.app._paths[(create.method, path)] = handler

    # add doc strings
    docs = description(handler.fn)
    if isnothing(docs)
        docs = docstr(handler.fn)
    end
    key = Symbol(lowercase(string(create.method)))
    create.app.paths_docs[key][path] = docs

    segments = map(segment, split(path, '/'; keepempty=false))
    insert!(create.app.paths, Leaf(string(create.method), Tuple{Int,String}[], path, handler), segments, 1)
    # We need to return this handler for the open api doc functionality
    return handler
end

Base.setindex!(create::CreateHandler, fn, path::String) = create(HttpHandler(fn), path)
Base.getindex(create::CreateHandler, s::String) = create.app._paths[(create.method, s)]

struct CreateMiddleware
    app::App
    method::HttpMethod
end

function (create::CreateMiddleware)(middleware::Array{Middleware}, path)
    k = (create.method, path)
    create.app._middleware[k] = middleware
end

Base.setindex!(create::CreateMiddleware, fn, path::String) = create([Middleware(fn)], path)
Base.setindex!(create::CreateMiddleware, l::Array, path::String) = create(Middleware.(l), path)
Base.getindex(create::CreateMiddleware, s::String) = create.app._middleware[(create.method, s)]

function Base.getproperty(create::CreateMiddleware, s::Symbol)
    # avoid recursive call to getproperty and hence a stackoverflow
    app = getfield(create, :app)
    if s == :get
        return CreateMiddleware(app, GET)
    elseif s == :post
        return CreateMiddleware(app, POST)
    elseif s == :put
        return CreateMiddleware(app, POST)
    elseif s == :trace
        return CreateMiddleware(app, TRACE)
    elseif s == :delete
        return CreateMiddleware(app, DELETE)
    elseif s == :options
        return CreateMiddleware(app, OPTIONS)
    elseif s == :connect
        return CreateMiddleware(app, CONNECT)
    elseif s == :patch
        return CreateMiddleware(app, PATCH)
    else
        return Base.getfield(create, s)
    end
end

function Base.getproperty(app::App, s::Symbol)
    if s == :get
        return CreateHandler(app, GET)
    elseif s == :post
        return CreateHandler(app, POST)
    elseif s == :put
        return CreateHandler(app, POST)
    elseif s == :trace
        return CreateHandler(app, TRACE)
    elseif s == :delete
        return CreateHandler(app, DELETE)
    elseif s == :options
        return CreateHandler(app, OPTIONS)
    elseif s == :connect
        return CreateHandler(app, CONNECT)
    elseif s == :patch
        return CreateHandler(app, PATCH)
    elseif s == :all
        return CreateHandler(app, ALL)
    elseif s == :middleware
        return CreateMiddleware(app, ALL)
    else
        return Base.getfield(app, s)
    end
end

function count_methods(app)

    d = Dict(
        "GET" => 0,
        "POST" => 0,
        "PUT" => 0,
        "PATCH" => 0,
        "DELETE" => 0,
        "TRACE" => 0,
        "OPTION" => 0,
        "HEAD" => 0,
        "CONNECT" => 0
    )

    for node in PreOrderDFS(app.paths)
        for leaf in node.methods
            d[leaf.method] = d[leaf.method] + 1
        end
    end
    d
end

function Base.isopen(app::App)
    isnothing(app.server) && return false
    isopen(app.server)
end

function Base.show(io::IO, app::App)

    #TODO: This errors since upgrading to term v2

    n_handlers = app |> count_methods |> values |> sum |> string
    pid = getpid() |> string
    host = app.inet_addr.host |> string
    port = app.inet_addr.port |> string
    w = 15
    h = 1
    key_color = "white"
    g = grid([
        hstack([
            RenderableText("{$key_color}Host", width=w - length(host)),
            RenderableText("{bold}$(host)  "),
        ]),
        hstack([
            RenderableText("{$key_color}Port", width=w - length(port)),
            RenderableText("{bold}$port"),]),
        hstack([
            RenderableText("{$key_color}Handlers", width=w - length(n_handlers)),
            RenderableText("{bold}$n_handlers  "),
        ]),
        hstack([
            RenderableText("{$key_color}PID", width=w - length(pid)),
            RenderableText("{bold}$pid"),])
    ],)

    panel = Panel(
        g,
        title="Bonsai.jl v$VERSION",
        width=38,
        fit=false,
        padding=(2, 1, 1, 1),
    )

    print(io, panel)

end