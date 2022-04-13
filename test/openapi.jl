using Bonsai, JSON3, StructTypes
using Test
using StructTypes: @Struct
using Bonsai: fn_kwargs, open_api
using HTTP: Stream
# https://raw.githubusercontent.com/OAI/OpenAPI-Specification/main/examples/v3.0/petstore.json
# https://blog.stoplight.io/openapi-json-schema#:~:text=You%20can%20use%20JSON%20Schema,generate%20an%20entire%20mock%20server.

@Struct struct Pet 
	id::Int64
	name::String
	tag::String
end

@Struct struct Limit
	limit::Int
end

@Struct struct Offset
	start::Int
	n::Int
end

function get_pets(stream; read_query=Query(Limit))
	pet = Pet(1,"bob", "cat")
	return [pet]
end

@testset "Query" begin

	q1 = Query(Limit)
	q2 = Query(Offset)

	l1 = open_api(q1)
	@test length(l1) == 1

	l2 = open_api(q2)
	@test length(l2) == 2
end

# @testset "handler" begin
	# kwargs = collect(values(fn_kwargs(handler.fn, @__MODULE__)))
	# 	router = Router()
	# 	get!(router, "/pets", get_pets)
	# 	Base.return_types(get_pets)
	# 	path, handler = router.paths[GET][1]
# end