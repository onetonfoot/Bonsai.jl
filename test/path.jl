using Bonsai: HttpPath, PathSegment, match_path, InvalidHttpPath

@testset "Path" begin
    p1 = HttpPath("/hello/:world")
    p2 = HttpPath("/hello/world")
    p3 = HttpPath("/hello/*")

    @test !isnothing(match_path(HttpPath("/"), "/"))
    @test !isnothing(match_path(p1, "/hello/world"))
    @test match_path(p1, "/hello/world").world == "world"
    @test !isnothing(match_path(p2, "/hello/world"))
    @test isnothing(match_path(p2, "/hello/mate"))
    @test !isnothing(match_path(p3, "/hello/world/mate"))

    # doesn't start with a /
    @test_throws InvalidHttpPath HttpPath("hello")
end