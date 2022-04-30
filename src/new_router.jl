module R

# Copied and modified from
# https://github.com/JuliaWeb/HTTP.jl/blob/master/src/Handlers.jl

using HTTP.Handlers: Node, Leaf, find, segment, insert!, match

export register!


using URIs

function matchall(node::Node, params, method, segments, i)
	matches = []
    # @info "Node"
	# @show node.segment, i, segments
	if i > length(segments)
		if isempty(node.methods)
			return nothing
		end
		j = find(method, node.methods; by=x->x.method, eq=(x, y) -> x == "*" || x == y)
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
	j = find(segment, node.exact; by=x->x.segment)
    # @info "Exact"
	if j !== nothing
		# found an exact match, recurse
		m = matchall(node.exact[j], params, method, segments, i + 1)
		anymissing = m === missing
		m = coalesce(m, nothing)
		@show :exact, m
		if m !== nothing
			push!(matches, m...)
			# return m
		end
	end
    # @info "Conditional" node=node.conditional
	# check for conditional matches
	for node in node.conditional
		@show node.segment.pattern, segment
		if match(node.segment.pattern, segment) !== nothing
			# matched a conditional node, recurse
			m = matchall(node, params, method, segments, i + 1)
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
		m = matchall(node.wildcard, params, method, segments, i + 1)
		anymissing = m === missing
		m = coalesce(m, nothing)
        @show :wildcard, m
		if m !== nothing
			push!(matches, m...)
			# return m
		end
	end
    # @info "Double Star"
	if node.doublestar !== nothing
		m = matchall(node.doublestar, params, method, segments, length(segments) + 1)
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
    HTTP.register!(r::Router, [method,] path, handler)

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
    segments = map(segment, split(path, '/'; keepempty=false))
    insert!(n, Leaf(method, Tuple{Int, String}[], path, handler), segments, 1)
    return
end

# register!(r::Router, path, handler) = register!(r, "*", path, handler)

const Params = Dict{String, String}

# function (r::Router)(req)
#     url = URI(req.target)
#     segments = split(url.path, '/'; keepempty=false)
#     params = Params()
#     handler = match(r.routes, params, req.method, segments, 1)
#     if handler === nothing
#         # didn't match a registered route
#         return r._404(req)
#     elseif handler === missing
#         # matched the path, but method not supported
#         return r._405(req)
#     else
#         if !isempty(params)
#             req.context[:params] = params
#         end
#         return handler(req)
#     end
# end

end # module