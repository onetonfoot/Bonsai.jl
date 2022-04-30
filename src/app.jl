using Bonsai: CancelToken, register!
using Sockets: InetAddr

export App
# There must be a better way to handle multple app's

function path_params(stream)
	stream.context[:params]
end

mutable struct App 
	id::Int
	redocs::Union{String, Nothing}
	cancel_token::CancelToken
	inet_addr::Union{InetAddr, Nothing}
    paths::Node
    middleware::Node

	function App()
		id = rand(Int)
		return new(
			id,
			"/docs",
			CancelToken(),
			nothing,
			Node("*"),
			Node("*"),
		)
	end
end

function create_handler(app, method)
	return (fn, path) -> begin 
		handler = wrap_handler(fn)
		node = handler isa Middleware ? app.middelware : app.paths
		register!(
			node,
			method,
			path,
			handler
		)
	end
end

function Base.getproperty(app::App, s::Symbol)
	if s == :get
		return create_handler(app, GET)
	elseif s == :post
		return create_handler(app, POST)
	elseif s == :put
		return create_handler(app, POST)
	elseif s == :trace
		return create_handler(app, TRACE)
	elseif s == :delete
		return create_handler(app, DELETE)
	elseif s == :options
		return create_handler(app, OPTIONS)
	elseif s == :connect
		return create_handler(app, CONNECT)
	elseif s == :patch
		return create_handler(app, PATCH)
	else
		return Base.getfield(app, s)
	end
end
