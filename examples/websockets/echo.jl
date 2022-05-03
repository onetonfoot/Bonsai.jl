# using Bonsai, FilePaths

# function ws_handler(stream)
# 	ws = Bonsai.ws_upgrade(stream)
	
# 	try
# 		while !eof(ws)
# 			data = readavailable(ws)
# 			@info String(data)
# 			write(ws, data)
# 		end
# 	catch e
# 		@error e
# 	finally
# 		close(ws)
# 	end
# end

# const static = Static(Path(@__DIR__))

# function index_handler(stream)
# 	static(stream, "index.html")
# end

# router = Router()
# get!(router, "/", index_handler)
# get!(router, "/ws", ws_handler)
# start(router, port=9999, verbose=true)
# wait(router)