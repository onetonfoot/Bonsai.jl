using Test, FilePaths, Bonsai

@testset "Static" begin
	write_file = Static(Path(@__DIR__))
	io = IOBuffer()
	b = read(joinpath(@__DIR__, "data/a.json"))
	write_file(io, "data/a.json")
	@test take!(io) == b

	io = IOBuffer()
	write_file(io, "i-dont-exist")
	@test length(take!(io)) > 0
end