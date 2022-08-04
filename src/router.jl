# Copied and slightly modified from
# https://github.com/JuliaWeb/HTTP.jl/blob/master/src/Handlers.jl

using HTTP: Stream
# using HTTP.Handlers: Node, Leaf, find, segment, insert!, match
using URIs
using  AbstractTrees

export register!, match_middleware

# tree-based router handler
mutable struct Variable
    # would it be better to use symbol
    # so captured variable can easily be converted to namedtuples
    name::String 
    pattern::Union{Nothing,Regex}
end

Base.show(io::IO, x::Variable) = print(io, "Variable(name=:$(x.name), pattern=$(x.pattern)")

const VARREGEX = r"^{([[:alnum:]]+):?(.*)}$"

function Variable(pattern)
    re = match(VARREGEX, pattern)
    if re === nothing
        error("problem parsing path variable for route: `$pattern`")
    end
    pat = re.captures[2]
    return Variable(re.captures[1], pat == "" ? nothing : Regex(pat))
end

struct Leaf
    method::String # should be a lowercase symbol
    variables::Vector{Tuple{Int,String}} # [(path_segement_idx, value)]
    path::String
    handler::Any
end

Base.show(io::IO, x::Leaf) = print(io, "Leaf($(x.method))")

mutable struct Node
    segment::Union{String,Variable}
    exact::Vector{Node} # sorted alphabetically, all x.segment are String
    conditional::Vector{Node} # unsorted; will be applied in source-order; all x.segment are Regex
    wildcard::Union{Node,Nothing} # unconditional variable or wildcard
    doublestar::Union{Node,Nothing} # /** to match any length of path; must be final segment

    # should this be a dict instead
    methods::Vector{Leaf}
end

function Base.show(io::IO, x::Node) 
    print(io, "Node($(x.segment))")
end

isvariable(x) = startswith(x, "{") && endswith(x, "}")
segment(x) = segment == "*" ? String(segment) : isvariable(x) ? Variable(x) : String(x)

Node(x) = Node(x, Node[], Node[], nothing, nothing, Leaf[])
Node() = Node("*")

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
# AbstractTrees.nodevalue(n::Node) = n.methods

#   nodevalue(tree, node_index)

function AbstractTrees.printnode(io, x)
     print(io, "Node($(x.segment))")
end

function find(y, itr; by=identity, eq=(==))
    for (i, x) in enumerate(itr)
        eq(by(x), y) && return i
    end
    return nothing
end

function Base.insert!(node::Node, leaf, segments, i)
    if i > length(segments)
        # time to insert leaf method match node
        j = find(leaf.method, node.methods; by=x -> x.method, eq=(x, y) -> x == "*" || x == y)
        if j === nothing
            push!(node.methods, leaf)
        else
            # hmmm, we've seen this route before, warn that we're replacing
            @warn "replacing existing registered route; $(node.methods[j].method) => \"$(node.methods[j].path)\" route with new path = \"$(leaf.path)\""
            node.methods[j] = leaf
        end
        return
    end
    segment = segments[i]
    # @show segment, segment isa Variable
    if segment isa Variable
        # if we're inserting a variable segment, add variable name to leaf vars array
        push!(leaf.variables, (i, segment.name))
    end
    # figure out which kind of node this segment is
    if segment == "*" || (segment isa Variable && segment.pattern === nothing)
        # wildcard node
        if node.wildcard === nothing
            node.wildcard = Node(segment)
        end
        return Base.insert!(node.wildcard, leaf, segments, i + 1)
    elseif segment == "**"
        # double-star node
        if node.doublestar === nothing
            node.doublestar = Node(segment)
        end
        if i < length(segments)
            error("/** double wildcard must be last segment in path")
        end
        return Base.insert!(node.doublestar, leaf, segments, i + 1)
    elseif segment isa Variable
        # conditional node
        # check if we've seen this exact conditional segment before
        j = find(segment.pattern, node.conditional; by=x -> x.segment.pattern)
        if j === nothing
            # new pattern
            n = Node(segment)
            push!(node.conditional, n)
        else
            n = node.conditional[j]
        end
        return Base.insert!(n, leaf, segments, i + 1)
    else
        # exact node
        @assert segment isa String
        j = find(segment, node.exact; by=x -> x.segment)
        if j === nothing
            # new exact match segment
            n = Node(segment)
            push!(node.exact, n)
            sort!(node.exact; by=x -> x.segment)
            return Base.insert!(n, leaf, segments, i + 1)
        else
            # existing exact match segment
            return Base.insert!(node.exact[j], leaf, segments, i + 1)
        end
    end
end

function Base.match(node::Node, method::String, s::AbstractString) 
    params = Dict()
    m = Base.match(node, params,  method, split_route(s), 1)
    return m, Dict(Symbol(k) => v for (k,v) in params)
end

function Base.match(node::Node, params, method, segments, i)
    # @show node.segment, i, segments
    if i > length(segments)
        if isempty(node.methods)
            return nothing
        end
        j = find(method, node.methods; by=x -> x.method, eq=(x, y) -> x == "*" || x == y)
        if j === nothing
            # we return missing here so we can return a 405 instead of 404
            # i.e. we matched the route, but there wasn't a matching method
            return missing
        else
            leaf = node.methods[j]
            # @show leaf.variables, segments
            if !isempty(leaf.variables)
                # we have variables to fill in
                for (i, v) in leaf.variables
                    params[v] = segments[i]
                end
            end
            return leaf.handler
        end
    end
    segment = segments[i]
    anymissing = false
    # first check for exact matches
    j = find(segment, node.exact; by=x -> x.segment)
    if j !== nothing
        # found an exact match, recurse
        m = Base.match(node.exact[j], params, method, segments, i + 1)
        anymissing = m === missing
        m = coalesce(m, nothing)
        # @show :exact, m
        if m !== nothing
            return m
        end
    end
    # check for conditional matches
    for node in node.conditional
        # @show node.segment.pattern, segment
        if match(node.segment.pattern, segment) !== nothing
            # matched a conditional node, recurse
            m = Base.match(node, params, method, segments, i + 1)
            anymissing = m === missing
            m = coalesce(m, nothing)
            if m !== nothing
                return m
            end
        end
    end
    if node.wildcard !== nothing
        m = Base.match(node.wildcard, params, method, segments, i + 1)
        anymissing = m === missing
        m = coalesce(m, nothing)
        if m !== nothing
            return m
        end
    end
    if node.doublestar !== nothing
        m = Base.match(node.doublestar, params, method, segments, length(segments) + 1)
        anymissing = m === missing
        m = coalesce(m, nothing)
        if m !== nothing
            return m
        end
    end
    return anymissing ? missing : nothing
end

function match_middleware(node::Node, params, method, segments, i)
    matches = []
    # @info "Node"
    # @show node.segment, i, segments
    if i > length(segments)
        if isempty(node.methods)
            return nothing
        end
        j = find(method, node.methods; by=x -> x.method, eq=(x, y) -> x == "*" || x == y)
        if j === nothing
            # we return missing here so we can return a 405 instead of 404
            # i.e. we matched the route, but there wasn't a matching method
            return missing
        else
            leaf = node.methods[j]
            # @show leaf.variables, segments
            if !isempty(leaf.variables)
                # we have variables to fill in
                for (i, v) in leaf.variables
                    params[v] = segments[i]
                end
            end
            push!(matches, leaf.handler)
            return matches
        end
    end
    segment = segments[i]
    anymissing = false
    # first check for exact matches
    j = find(segment, node.exact; by=x -> x.segment)
    # @info "Exact"
    if j !== nothing
        # found an exact match, recurse
        m = match_middleware(node.exact[j], params, method, segments, i + 1)
        anymissing = m === missing
        m = coalesce(m, nothing)
        # @show :exact, m
        if m !== nothing
            push!(matches, m...)
            # return m
        end
    end
    # @info "Conditional" node=node.conditional
    # check for conditional matches
    for node in node.conditional
        # @show node.segment.pattern, segment
        if match(node.segment.pattern, segment) !== nothing
            # matched a conditional node, recurse
            m = match_middleware(node, params, method, segments, i + 1)
            anymissing = m === missing
            m = coalesce(m, nothing)
            if m !== nothing
                push!(matches, m...)
                # return m
            end
        end
    end
    # @info "Wildcard" wildcard=node.wildcard
    if node.wildcard !== nothing
        m = match_middleware(node.wildcard, params, method, segments, i + 1)
        anymissing = m === missing
        m = coalesce(m, nothing)
        # @show :wildcard, m
        if m !== nothing
            push!(matches, m...)
            # return m
        end
    end
    # @info "Double Star"
    if node.doublestar !== nothing
        m = match_middleware(node.doublestar, params, method, segments, length(segments) + 1)
        anymissing = m === missing
        m = coalesce(m, nothing)
        if m !== nothing
            push!(matches, m...)
            # return m
        end
    end
    return matches
end



"""
    HTTP.register!(r::Node, [method,] path, handler)

Register a handler function that should be called when an incoming request matches `path`
and the optionally provided `method` (if not provided, any method is allowed). Can be used
to dynamically register routes.
The following path types are allowed for matching:
  * `/api/widgets`: exact match of static strings
  * `/api/*/owner`: single `*` to wildcard match any string for a single segment
  * `/api/widget/{id}`: Define a path variable `id` that matches any valued provided for this segment; path variables are available in the request context like `req.context[:params]["id"]`
  * `/api/widget/{id:[0-9]+}`: Define a path variable `id` that only matches integers for this segment
  * `/api/**`: double wildcard matches any number of trailing segments in the request path; must be the last segment in the path
"""
function register! end

function register!(n::Node, method, path, handler)
    method = uppercase(String(method))
    segments = if path == "/"
        ["/"]
    else
        map(segment, split(path, '/'; keepempty=false))
    end
    Base.insert!(n, Leaf(method, Tuple{Int,String}[], path, handler), segments, 1)
    return
end

function safe_which(fn, args)
    try
        which(fn, args)
    catch
        nothing
    end
end


function wrap_handler(handler)
    if !isnothing(safe_which(handler, Tuple{Any}))
        return HttpHandler(handler)
    elseif !isnothing(safe_which(handler, Tuple{Any, Any}))
        return Middleware(handler)
    else
        error("Unable to infer correct handler type")
    end
end

function split_route(s)
    if s == "/"
        ["/"]
    else
        split(s, '/'; keepempty=false)
    end
end

function Base.match(app, req::Request)
    url = req.url
    handler, params = match(app.paths, req.method, url.path)
    segments = split_route(url.path)
    # todo clean up this matching logic so it uses the 3 args version
    middelware = match_middleware(app.middleware, params, req.method, segments, 1)

    # needed for HTTP 0.9 compat
    if hasfield(Request, :context) 
        req.context[:params] = params
    end
    # handler and be nothing or missing
    # nothing - didn't match a registered route
    # missing - matched the path, but method not supported

    if ismissing(middelware) || isnothing(middelware)
        middelware = Middleware[]
    end

    return handler, middelware
end

Base.match(app, stream::Stream) = Base.match(app, stream.message)