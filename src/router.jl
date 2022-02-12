export Router, register!

struct Router 
	paths::Dict{HttpMethod, Vector{Pair{HttpPath, Any}}}
	middleware::Array{Tuple{HttpMethod, HttpPath, Any}}
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
	Router(d, [], default_error_handler)
end

function match_handler(router::Router, stream::Stream)
	k = convert(HttpMethod, stream.message.method)
	paths = router.paths[k]
	for (path, handler) in paths
		matches = match_path(path , stream.message.target)
		if !isnothing(matches)
			return handler
		end
	end
	return nothing
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
	stream_handlers = methods(handler, (Stream,))
	request_handlers = methods(handler, (Request,))
	handlers = [stream_handlers ; request_handlers]

	if length(handlers) < 1
		error("No method matching $handler(::Request) or $handler(::Stream)")
	end

	precompile(handler, (Stream,))
	push!(paths, path => handler)
	# make greddy handlers match last
	sort!( paths, by = x -> isgreedy(x[1]))
	return nothing
end

function match_middleware(router::Router, stream::Stream)
	middleware = []
	for (method, path, fn) in router.middleware
		x = match_path(path , stream.message.target)
		if !isnothing(x) && stream.message.method == method
			push!(middleware, fn)
		end
	end
	return middleware
end

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