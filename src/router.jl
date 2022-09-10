# Copied and slightly modified from
# https://github.com/JuliaWeb/HTTP.jl/blob/master/src/Handlers.jl

using HTTP.Handlers: Leaf, Node, register!, segment, insert!, match
using URIs, AbstractTrees

function AbstractTrees.children(node::Node)
    l = []
    # the order they are return in the list will
    # determin which order they are iterated in
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

AbstractTrees.nodetype(::Type{Node}) = Node

function AbstractTrees.printnode(io, x)
     print(io, "Node($(x.segment))")
end


function split_route(s)
    if s == "/"
        ["/"]
    else
        split(s, '/'; keepempty=false)
    end
end

function match_middleware(app, req)
    (url, method) = req

end

# Required that the key is a symbol for StructTypes.constructfrom to work
const ParamsDict = Dict{Symbol, Any}

function Base.match(app::App, req::Request)
    url = URI(req.target)
    req.url = url
    segments = split(url.path, '/'; keepempty=false)
    # handler, params = match(app.paths, req.method, segments, 1)
    segments = split_route(url.path)
    handler, _, params = gethandler(app, req)
    if !isnothing(params)
        req.context[:params] = params
    else 
        req.context[:params] = ParamsDict()
    end
    middleware = getmiddleware(app, req)
    return handler, middleware
end

function gethandler(app::App, req::Request)
    url = URI(req.target)
    segments = split(url.path, '/'; keepempty=false)
    leaf = match(app.paths, req.method, segments, 1)
    params = ParamsDict()
    if leaf isa Leaf
        # @show leaf.variables, segments
        if !isempty(leaf.variables)
            # we have variables to fill in
            for (i, v) in leaf.variables
                params[Symbol(v)] = segments[i]
            end
        end
        return leaf.handler, leaf.path, params
    end
    return leaf, "", params
end

function getmiddleware(app::App, req::Request)
    url = URI(req.target)
    segments = split(url.path, '/'; keepempty=false)

    middleware = Middleware[]

    # with this implemntation the more specific middleware won't run first
    # we'll need to uses a ordered dict instead or an array
    for ((method, path), fn) in app.middleware
        node = Node("*")
        leaf = Leaf(string(method), Tuple{Int, String}[], path, fn)
        insert!(node, leaf, map(segment, split(path, "/", keepempty=false)), 1)

        m = match(node, req.method, segments, 1)

        if isnothing(m)  || ismissing(m)
            continue
        end

        push!(middleware, m.handler...)

    end

    return middleware
end

