using Bonsai, Test
using Bonsai: ws_upgrade
using HTTP

# @testset "start and stop" begin
# 	router = Router()
# 	start(router, port=9999, verbose=true)
# 	stop(router)
# 	@test true
# end

# @testset "web socket" begin
# 	function f(stream)
# 		ws = ws_upgrade(stream)
# 		try
# 			for i in ["hello", "mate"]
# 				write(ws, i)
# 			end
# 		finally
# 			close(ws)
# 		end
# 	end

# 	router = Router()
# 	get!(router, "/", f)
# 	start(router, port=9999, verbose=true)
# 	l = []

# 	HTTP.WebSockets.open("ws://127.0.0.1:9999") do ws
# 		while !eof(ws) && isopen(ws)
# 			x = readavailable(ws)
# 			if isempty(x)
# 				continue
# 			end
# 			push!(l, String(x))
# 		end
# 	end

# 	stop(router)
# 	@test l == ["hello", "mate"]
# end