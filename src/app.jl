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
    middleware_ = Dict() # (GET, <path>) => <handler>
    path_ = Dict()
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

struct CreateHandler
    app::App
    method::HttpMethod
end

(create::CreateHandler)(path) = path

function(create::CreateHandler)(fn, path) 

    handler = if !isnothing(safe_which(fn, Tuple{Any}))
        HttpHandler(fn)
    elseif !isnothing(safe_which(fn, Tuple{Any, Any}))
        Middleware(fn)
    else
        error("Unable to infer correct handler type")
    end

    if handler isa Middleware
        create.app.path_[(create.method, path)] = handler
    else
        create.app.path_[(create.method, path)] = handler
    end

    node = handler isa Middleware ? create.app.middleware : create.app.paths
    register!(
        node,
        create.method,
        path,
        handler
    )
    # We need to return this hanlder for the open api doc functionality
    # to work
    handler
end

function Base.getindex(create::CreateHandler, s::String)
    # This should return (handler, middleware)
    @info "$(create.method) $s"
end

#= Allows for an alternative syntax for setting handlers

app.get["/"] = function(stream)

end

=#
Base.setindex!(create::CreateHandler, fn, path::String) = create(fn, path)

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
