using Bonsai: CancelToken, register!

export App
# There must be a better way to handle multple app's

const app_id = Threads.Atomic{Int}(rand(Int))
const d = Dict{Tuple{Int, String}, Any}()


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
		# d[id] = Dict() 
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
