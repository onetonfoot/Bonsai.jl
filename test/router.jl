using Test
using FilePaths
using FilePathsBase: /
using HTTP: Stream, Request
using HTTP
using Bonsai: HttpHandler


@testset "start" begin
	router = Router()
	try
		file_handler = Static(Path(@__DIR__) / "data")
		function index(stream) 
			file_handler(stream, "index.html")
		end
		get!(router, "/", HttpHandler(index))
		get!(router, "*", file_handler)
		port = 9081
		start(router, port=port)
		res = HTTP.get("http://localhost:$port/")
		@test res.status == 200

		res = HTTP.get("http://localhost:$port/?x=100")
		@test res.status == 200

		res = HTTP.get("http://localhost:$port/a.json")
		@test res.status == 200
	catch e
	finally
		stop(router)
	end
end