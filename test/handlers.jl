using Test, FilePaths, Bonsai
using HTTP: Response, Request
using FilePathsBase: /
using JSON3


@testset "Path" begin
	file = joinpath(Path(@__DIR__), "data/a.json")

	# writing
	res = Response()
	Bonsai.write(res, Body(file))
	k, v = res.headers[1]
	@test k == "content-type" 
	@test v == "application/json"
	@test JSON3.read(res.body, Dict) isa Dict
end


@testset "Dict" begin
	req = Request()
	d = Dict(:x => "10")
	s = JSON3.write(d)
	req.body = s
	json = Bonsai.read(req, Body(Dict))
	@test d == json
end
