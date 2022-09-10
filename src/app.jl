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

    # LittleDict is ordered dict that is fast to iterate over less than 50 elements
    middleware = LittleDict{Tuple{HttpMethod, String}, Array{Middleware}}() # 

    paths::Node = Node("*")
    path_ = Dict{Tuple{HttpMethod, String}, HttpHandler}()
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

    # Unsure why this is empty, I would have thought that HTTP
    # would fill this field but seemingly not atm
    request.url = URI(request.target)

    if !hasheader(stream, "Sec-WebSocket-Version", "13")
        request.body = Base.read(stream)
        closeread(stream)
    end

    try
        handler, middleware = match(app, stream)
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

struct CreateHandler
    app::App
    method::HttpMethod
end


(create::CreateHandler)(fn, path) = create(HttpHandler(fn), path)
(create::CreateHandler)(fn::Array, path) = create(Middleware.(fn), path)

function (create::CreateHandler)(handler::HttpHandler, path)
    create.app.path_[(create.method, path)] = handler
    segments = map(segment, split(path, '/'; keepempty=false))
    insert!(create.app.paths, Leaf(string(create.method), Tuple{Int, String}[], path, handler), segments, 1)
    # We need to return this handler for the open api doc functionality
    return handler
end

(create::CreateHandler)(middleware::Array{Middleware}, path) = create.app.middleware[(create.method, path)] = middleware

#= 
app.get["/"] = function(stream)
end
app.get["**"] = [authentication, someother, middleware]
app.get["/files/*"] = [gzip]
=# 
Base.setindex!(create::CreateHandler, fn, path::String) = create(HttpHandler(fn), path)
Base.setindex!(create::CreateHandler, l::Array, path::String) = create(Middleware.(l), path)

function Base.getindex(create::CreateHandler, s::String)
    (
        get(create.app.path_, (create.method, s), nothing),
        get(create.app.middleware, (create.method, s), nothing)
    )
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
    else
        return Base.getfield(app, s)
    end
end
