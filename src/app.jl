using Bonsai: CancelToken
using AbstractTrees
using Sockets: InetAddr, TCPServer
using HTTP.Handlers: Leaf, Node, segment
using OrderedCollections

export App

Base.@kwdef mutable struct App
    # Why is this here again?
    id::Int = rand(Int)

    cancel_token::CancelToken = CancelToken()
    inet_addr::Union{InetAddr,Nothing} = nothing
    server::Union{TCPServer,Nothing} = nothing

    # LittleDict is ordered dict that is fast to iterate over for less than 50 elements
    _middleware::LittleDict{Tuple{HttpMethod, String}, Array{Middleware}} = LittleDict() # 

    paths::Node = Node("*")
    _paths = Dict{Tuple{HttpMethod, String}, HttpHandler}()
    paths_docs::Dict{Symbol,Dict{String,String}} = Dict(
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

    @info "Request" request.url request.target request.method

    # Unsure why this is empty, I would have thought that HTTP
    # would fill this field but seemingly not atm
    request.url = URI(request.target)

    if !hasheader(stream, "Sec-WebSocket-Version", "13")
        request.body = Base.read(stream)
        closeread(stream)
    end

    try
        handler, middleware = gethandlers(app, request)

        @info "match" handler middleware

        if ismissing(handler) || isnothing(handler)
            push!(middleware, Middleware((stream, next) -> throw(NoHandler(stream))))
        else
            push!(middleware, Middleware((stream, next) -> handler(stream)))
        end

        combine_middleware(middleware)(stream)

    catch e
        if e isa NoHandler
            @warn e
        else
            @error "Unhandled Error" e = e
        end
    finally
        request.response.request = request
        startwrite(stream)
        Base.write(stream, request.response.body)
    end
end

struct CreateHandler
    app::App
    method::HttpMethod
end


(create::CreateHandler)(fn, path) = create(HttpHandler(fn), path)
(create::CreateHandler)(fn::Array, path) = create(Middleware.(fn), path)

function (create::CreateHandler)(handler::HttpHandler, path)
    create.app._paths[(create.method, path)] = handler
    segments = map(segment, split(path, '/'; keepempty=false))
    insert!(create.app.paths, Leaf(string(create.method), Tuple{Int, String}[], path, handler), segments, 1)
    # We need to return this handler for the open api doc functionality
    return handler
end


#= 
app.get["/"] = function(stream)
end
app.get["**"] = [authentication, someother, middleware]
app.get["/files/*"] = [gzip]
=# 
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
