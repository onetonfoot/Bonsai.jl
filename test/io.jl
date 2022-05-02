using JET, InteractiveUtils # to use analysis entry points
using CodeInfoTools
using HTTP:Stream
using Bonsai
using StructTypes: @Struct
using StructTypes
using Bonsai: handler_writes, handler_reads, PathParams
using Test

@Struct struct A1
	data
end

@Struct struct H1
	x_test::String
end

@Struct struct Next
	x_next::String
end

@Struct struct Pet
	id::Int
	name::String
	tag::String
end

@Struct struct Limit 
	limit::Int
	offset::Union{Int, Missing}
end

@testset "handler_writes" begin

	function f(stream)
		Bonsai.write(stream, Body("ok"), ResponseCodes.Ok())
	end

	function handler(stream)
		if rand() > 0.5
			Bonsai.write(stream, Body(A1(1)), ResponseCodes.Created())
		else
			f(stream)
		end
	end

	# defining the mime type allows us to all write the correct
	# content-type header
	Bonsai.mime_type(::A1) = "application/json"
	@test length(handler_writes(handler)) == 3

	function g(stream)
		query = Bonsai.read(stream, Query(Limit))
		l = Pet[]

		for (i, pet) in values(pets)

			if !ismissing(query.offset) & i < query.offset
				continue
			end

			push!(l, pet)
			if i > query.limit
				break
			end
		end

		Bonsai.write(stream, Headers(x_next = "/pets?limit=$(query.limit+1)&offset=$(query.offset)"))
		Bonsai.write(stream, Body(pets = l))
	end


	@test length(Bonsai.handler_writes(g)) == 2
	@test length(Bonsai.handler_reads(g)) == 1
end

@testset "handler_reads" begin

	function g(stream)
		Bonsai.read(stream, PathParams(A))
	end

	l = handler_reads(g)
	@test length(l) == 1
end
