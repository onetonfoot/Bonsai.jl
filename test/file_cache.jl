using JSON2Julia
using FilePaths

@testset "Static" begin
	write_file = Static(Path(@__DIR__))
	io = IOBuffer()
	b = read(joinpath(@__DIR__, "a.json"))
	write_file(io, "a.json")
	@test take!(io) == b
end