using FilePaths
using HTTP: Stream, Request
using HTTP

@testset "register!" begin
	file_handler = Static(Path(@__DIR__))
	function index(stream) 
		file_handler(stream, "index.html")
	end
	router = Router()
	register!(router, "/", GET, index)
	register!(router, "*", GET, file_handler)
	t =  start(router)
	res = HTTP.get("http://localhost:8081/")
	@assert res.status == 200

	res = HTTP.get("http://localhost:8081/a.json")
	@assert res.status == 200
	close(t)
end