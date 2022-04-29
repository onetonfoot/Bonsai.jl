using Bonsai
using CodeInfoTools
using HTTP: Stream
using Bonsai: handler_writes
using StructTypes
using Test

struct A2
	data
end

StructTypes.StructType(::Type{A2}) = StructTypes.Struct()

@testset "handler_writes" begin 
	app = Bonsai.App()
	app.get("/path") do stream
		Bonsai.write(stream, "header" => "value")
		Bonsai.write(stream, [1,2])
		Bonsai.write(stream, 100, ResponseCodes.Ok())
		Bonsai.write(stream, Dict(:x => :10))
		Bonsai.write(stream, (x = 10,))
		Bonsai.write(stream, A2(10), ResponseCodes.Default())
	end
	h = app.router.paths[GET][1][2]
	# for debuging
	# code_inferred(h.fn, Tuple{Stream})
	@test length(Bonsai.handler_writes(h.fn)) == 6
end

@testset "handler_writes" begin 
	app = Bonsai.App()
	app.get("/path") do stream
		Bonsai.read(stream, Headers(A2))
		Bonsai.read(stream, Query(A2))
		Bonsai.read(stream, Body(A2))
	end
	h = app.router.paths[GET][1][2]

	Bonsai.handler_reads(h.fn)

	@test length(Bonsai.handler_reads(h.fn)) == 3
end