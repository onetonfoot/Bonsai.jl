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

# Required that the key is a symbol for StructTypes.constructfrom to work
const ParamsDict = Dict{Symbol, Any}

function gethandlers(app::App, req::Request)
    handler, _, params = gethandler(app, req)
    if !isnothing(params)
        req.context[:params] = params
    else 
        req.context[:params] = ParamsDict()
    end
    middleware = getmiddleware(app, req)
    return handler, middleware
end

function spliturl(s::AbstractString)
    s == "/" ? ["/"] :  map(segment, split(s, "/", keepempty=false))
end

# duplicated from here and redefinded first argument Router
# https://github.com/JuliaWeb/HTTP.jl/blob/63a268e68933438e099726bc07b152d48b5385d7/src/Handlers.jl
function gethandler(app::App, req::Request)
    url = URI(req.target)
    segments = spliturl(url.path)
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
    segments = spliturl(url.path)

    middleware = AbstractHandler[]

    for ((method, path), fn) in app._middleware
        node = Node("*")
        leaf = Leaf(string(method), Tuple{Int, String}[], path, fn)
        insert!(node, leaf, spliturl(path) , 1)
        m = match(node, req.method, segments, 1)

        if isnothing(m)  || ismissing(m)
            continue
        end

        push!(middleware, m.handler...)

    end

    return middleware
end

