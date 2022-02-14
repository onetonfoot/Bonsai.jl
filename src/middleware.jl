export middleware!

function cors(stream::Stream, next)

	if stream.message.method == OPTIONS
		headers = [
			"Access-Control-Allow-Origin" => "*",
			"Access-Control-Allow-Headers" => "*",
			"Access-Control-Allow-Methods" => "*",
		]
		for i in headers
			HTTP.setheader(stream, i)
		end

		HTTP.setstatus(stream, 200)
	else
		HTTP.setheader(stream, "Access-Control-Allow-Origin" => "*")
		HTTP.setstatus(stream, 200)
	end

	next(stream)
end

function combine_middleware(middleware)
	i = length(middleware)

	if i == 0
		return x -> x
	end

	fns = Function[stream -> middleware[i](stream, identity)]
	for i in reverse(1:length(middleware)-1)
		fn = stream ->  middleware[i](stream, fns[i+1]) 
		pushfirst!(fns, fn)
	end
	return fns[1]
end


function middleware!(router::Router, path::HttpPath, method::HttpMethod, handler)
	paths = router.middleware[method]
	_register!(paths, path, handler)
end

function middleware!(router::Router, path::HttpPath, methods::Tuple{Vararg{HttpMethod}}, handler)
	for method in methods
		middleware!(router, path, method, handler)
	end
end

middleware!(router::Router, handler) = middleware!(router, HttpPath("*"), ALL, handler)