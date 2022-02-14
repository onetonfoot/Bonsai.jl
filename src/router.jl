export Router, register!

struct Router 
	paths::Dict{HttpMethod, Vector{Pair{HttpPath, Any}}}
	middleware::Dict{HttpMethod, Vector{Pair{HttpPath, Any}}}
	error_handler::Function
end

function default_error_handler(stream::HTTP.Stream, error::Exception)
	@error error
	# https://github.com/wookay/Bukdu.jl/issues/105
    HTTP.setstatus(stream, 500)
end

function Router()
	d = Dict(
		GET => [],
		POST => [],
		PUT => [],
		DELETE => [],
		CONNECT => [],
		OPTIONS => [],
		TRACE => [],
		PATCH => [],
	)
	Router(d, deepcopy(d), default_error_handler)
end

function match_handler(router::Router, method::HttpMethod, target::String)
	paths = router.paths[method]
	for (path, handler) in paths
		matches = match_path(path , target)
		if !isnothing(matches)
			return handler
		end
	end
	return nothing
end

function match_handler(router::Router, stream::Stream)
	method = convert(HttpMethod, stream.message.method)
	target = stream.message.target
	match_handler(router, method, target)
end


function match_middleware(router::Router, method::HttpMethod, target::String)
	paths = router.middleware[method]
	handlers = []
	for (path, handler) in paths
		matches = match_path(path , target)
		if !isnothing(matches)
			push!(handlers, handler)
		end
	end
	return handlers
end

function match_middleware(router::Router, stream::Stream)
	method = convert(HttpMethod, stream.message.method)
	target = stream.message.target
	match_middleware(router, method, target)
end

function register!(
	router::Router, 
	path::String, 
	method::HttpMethod, 
	static::Static,
)
	path = HttpPath(path)
	handler = stream -> static(stream, stream.message.target)

	register!(
		router, 
		path, 
		method, 
		handler
	)
end

function register!(
	router::Router, 
	path::AbstractString, 
	method::HttpMethod, 
	handler
)
	path = HttpPath(path)
	register!(
		router, 
		path, 
		method, 
		handler
	)
end


function register!(
	router::Router, 
	path::HttpPath, 
	method::HttpMethod, 
	handler
)
	paths = router.paths[method] 
	_register!(paths, path, handler)
end

#  POST | GET is and example of when this would be called with a tuple
function register!(
	router::Router, 
	path::HttpPath, 
	methods::Tuple{HttpMethod}, 
	handler
)
	for method in methods
		register!(router, path, method, handler)
	end
end

function _register!(
	paths::Array, 
	path::HttpPath, 
	handler
)
	if !isempty(methods(handler, (Stream,)))
		precompile(handler, (Stream,))
	end

	push!(paths, path => handler)
	# make greddy handlers match last
	sort!( paths, by = x -> isgreedy(x[1]))
	return nothing

end
