using JET, InteractiveUtils # to use analysis entry points
using CodeInfoTools
using HTTP:Stream
using Bonsai
using StructTypes: @Struct
using StructTypes
using Bonsai: handler_writes
using Test

@Struct struct A1
	data
end

@testset "handler_writes" begin

	function f(stream)
		Bonsai.write(stream, "ok", ResponseCodes.Ok())
	end

	function handler(stream)
		if rand() > 0.5
			Bonsai.write(stream, A1(1), ResponseCodes.Created())
		else
			f(stream)
		end
	end

	l = handler_writes(handler)

	@test length(l) == 2
end