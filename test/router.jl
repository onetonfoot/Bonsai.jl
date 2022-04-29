using Test
using FilePaths
using FilePathsBase: /
using HTTP: Stream, Request
using HTTP
using Bonsai: HttpHandler


@testset "start" begin
	#TODO: Switch to tree based implementation
	router = Router()
end