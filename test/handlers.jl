using Test, Bonsai
using Bonsai.FilePaths
using Bonsai.FilePathsBase: /
using Bonsai.JSON3
using Bonsai.HTTP: Response, Request


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
