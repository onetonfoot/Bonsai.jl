using JET, InteractiveUtils # to use analysis entry points
using CodeInfoTools
using HTTP:Stream
using Bonsai
using StructTypes: @Struct
using StructTypes
using Bonsai: handler_responses
using Test

using Bonsai: OK, CREATED

@Struct struct A
	data
end

@testset "handler_responses" begin

	function f(stream)
		Bonsai.write(stream, "ok", OK)
	end

	function handler(stream)
		if rand() > 0.5
			Bonsai.write(stream, A(1), CREATED)
		else
			f(stream)
		end
	end

	l = handler_responses(handler)

	@test length(l) == 2
end