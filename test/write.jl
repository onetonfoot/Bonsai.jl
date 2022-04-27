using JET, InteractiveUtils # to use analysis entry points
using CodeInfoTools
using HTTP:Stream
using Bonsai
using StructTypes: @Struct
using StructTypes
using Bonsai: handler_writes
using Test

using Bonsai: OK, CREATED

@Struct struct A1
	data
end

@testset "handler_writes" begin

	function f(stream)
		Bonsai.write(stream, "ok", OK)
	end

	function handler(stream)
		if rand() > 0.5
			Bonsai.write(stream, A1(1), CREATED)
		else
			f(stream)
		end
	end

	l = handler_writes(handler)

	@test length(l) == 2
end