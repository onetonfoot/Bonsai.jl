using Test, FilePaths, Bonsai
using HTTP: Response
using FilePathsBase: /
using JSON3


@testset "Path" begin
	file = joinpath(Path(@__DIR__), "data/a.json")

	# writing
	res = Response()
	Bonsai.write(res, file)
	k, v = res.headers[1]
	@test k == "content-type" 
	@test v == "application/json"
	@test JSON3.read(res.body, Dict) isa Dict
end