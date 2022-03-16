using Test
using FilePaths
using HTTP: Stream, Request
using HTTP
using Bonsai: HttpHandler

@testset "start" begin
	file_handler = Static(Path(@__DIR__))
	function index(stream) 
		file_handler(stream, "index.html")
	end
	router = Router()
	get!(router, "/", HttpHandler(index))
	get!(router, "*", file_handler)
	port = 9081
	t =  start(router, port=port)
	res = HTTP.get("http://localhost:$port/")
	@test res.status == 200
	res = HTTP.get("http://localhost:$port/a.json")
	@test res.status == 200

	stop(t)
end