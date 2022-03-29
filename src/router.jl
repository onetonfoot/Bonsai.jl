using Term
import Base: get!, put!, delete!, all!
import Term: Panel
import Sockets: InetAddr
import PkgVersion

export Router, get!, post!, put!, patch!, options!, trace!, connect!, all!

mutable struct Router 
	paths::Dict{HttpMethod, Vector{Pair{HttpPath, Any}}}
	middleware::Dict{HttpMethod, Vector{Pair{HttpPath, Any}}}
	cancel_token::CancelToken
	inet_addr::Union{InetAddr, Nothing}
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
	Router(d, deepcopy(d), CancelToken(), nothing)
end

function Base.show(io::IO, r::Router)
	running = r.cancel_token.cancelled[]
	version = PkgVersion.Version(parentmodule(Router))
	n_handlers = sum([length(i) for i in values(r.paths) ])
	n_middleware = sum([length(i) for i in values(r.middleware) ])



	width = 25
	addr = isnothing(r.inet_addr) ? nothing : "$(r.inet_addr.host):$(r.inet_addr.port)"
	box = :SQUARE
	pid = getpid()

	panel = Panel( 
			(
				Panel("Addr - [bold]$addr[bold]", width=width, box=box) *
				Panel("Pid - [bold]$pid[bold]", width=width, box=box) 
			) /
			(
			Panel("Handlers - [bold]$n_handlers", width=width, box=box) * 
			Panel("Middleware - [bold]$n_middleware", width=width, box=box) 

			)

		;title=string(RenderableText("[bold]Bonsai $version")),
		width=width*2,
		height=4,
		box=:HEAVY
	)
	print(io, string(panel))
end

function match_handler(router::Router, method::HttpMethod, uri::URI)
	paths = router.paths[method]
	for (path, handler) in paths
		matches = match_path(path , uri.path)
		if !isnothing(matches)
			return handler
		end
	end
	return nothing
end

function match_handler(router::Router, stream::Stream)
	method = convert(HttpMethod, stream.message.method)
	target = URI(stream.message.target)
	match_handler(router, method, target)
end


function match_middleware(router::Router, method::HttpMethod, uri::URI)
	paths = router.middleware[method]
	handlers = []
	for (path, handler) in paths
		matches = match_path(path , uri.path)
		if !isnothing(matches)
			push!(handlers, handler)
		end
	end
	return handlers
end

function match_middleware(router::Router, stream::Stream)
	method = convert(HttpMethod, stream.message.method)
	target = URI(stream.message.target)
	match_middleware(router, method, target)
end

function register!(
	paths::Array, 
	path::HttpPath, 
	handler::AbstractHandler
)
	push!(paths, path => handler)
	# ensure that the greedy handlers match last
	sort!(paths, by = x -> isgreedy(x[1]))
	return nothing
end

function register!(router::Router, path, method::HttpMethod, handler::AbstractHandler)
	paths = if handler isa HttpHandler
		router.paths[method] 
	elseif handler isa Middleware
		router.middleware[method] 
	elseif handler isa Static
		router.paths[method] 
	else
		error("Unsupported handler type $(typeof(handler))")
	end

	register!(paths, HttpPath(path), handler)
end

function register!( router::Router, path, method::HttpMethod, handler)

	ms = methods(handler)
	c = 0

	for m in ms
		if m.nargs in [2, 3] && m.sig.types[2] in [Any, Stream]
			T = m.nargs == 2 ? HttpHandler : Middleware
			register!(
				router, 
				path, 
				method, 
				T(handler)
			)
			c+= 1
		end
	end

	if c == 0 
		error("""Unable to infer correct handler type. Please wrap handler with correct AbstractHandler subtype""")
	end
end

get!(    router::Router, path, handler) = register!(router, path, GET, handler)
put!(    router::Router, path, handler) = register!(router, path, PUT, handler)
post!(    router::Router, path, handler) = register!(router, path, POST, handler)
patch!(  router::Router, path, handler) = register!(router, path, PATCH, handler)
delete!( router::Router, path, handler) = register!(router, path, DELETE, handler)
options!(router::Router, path, handler) = register!(router, path, OPTIONS, handler)
connect!(router::Router, path, handler) = register!(router, path, CONNECT, handler)
trace!(  router::Router, path, handler) = register!(router, path, TRACE, handler)

function all!(router::Router, path, handler) 
	for method in ALL
		register!(router, path, method, handler)
	end
end