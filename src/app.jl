using Bonsai: CancelToken, register!

export App
# There must be a better way to handle multple app's

const app_id = Threads.Atomic{Int}(rand(Int))
const d = Dict()


function path_params(stream)
    app_id
	id = app_id[]
	global d
	d[id]
end

mutable struct App 
	id::Int
	redocs::Union{String, Nothing}
	router::Router
	cancel_token::CancelToken
	inet_addr::Union{InetAddr, Nothing}

	function App()
		id = rand(Int)
		d[id] = Dict() 
		return new(
			id,
			"/docs",
			Router(),
			CancelToken(),
			nothing,
		)
	end
end

function create_handler(app, method)
	return (fn, path) -> register!(
		app.router,
		path,
		method,
		fn
	)
end

struct AppMiddleware
	app::App
end

# there should be a nicer way todo this, it's written in this
# odd fashinion to help the compiler with type inference which 
# is needed  for openapi generation

function Base.getproperty(mid::AppMiddleware, s::Symbol)
	if s == :get
		return create_handler(mid.app, GET)
	elseif s == :post
		return create_handler(mid.app, POST)
	elseif s == :put
		return create_handler(mid.app, POST)
	elseif s == :trace
		return create_handler(mid.app, TRACE)
	elseif s == :delete
		return create_handler(mid.app, DELETE)
	elseif s == :options
		return create_handler(mid.app, OPTIONS)
	elseif s == :connect
		return create_handler(mid.app, CONNECT)
	elseif s == :patch
		return create_handler(mid.app, PATCH)
	else
		return Base.getfield(mid, s)
	end
	# getproperty(app.app, s)
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
	elseif s == :middleware
		return AppMiddleware(app)
	else
		return Base.getfield(app, s)
	end
end
