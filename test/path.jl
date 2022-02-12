using JSON2Julia: Path, PathSegment, @p_str, match_path

@testset "Path" begin
    p1 = p"/hello/:world"
    p2 = p"/hello/world"

    @test !isnothing(match_path(p"/", "/"))
    @test !isnothing(match_path(p1, "/hello/world"))
    @test !isnothing(match_path(p2, "/hello/world"))
    @test isnothing(match_path(p2, "/hello/mate"))
    @test isnothing(match_path(p2, "/hello/world/mate"))
end