using Bonsai, JSON3, StructTypes
using Test
using StructTypes: @Struct
using Bonsai: fn_kwargs, parameters, ParameterObject,
	ResponseObject,  RequestBodyObject, 
	handler_writes, HttpParameter, http_parameters
using HTTP: Stream
using CodeInfoTools: code_inferred
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

@Struct struct Auth
	x_pass::String
end

function get_pets(stream; read_query=Query(Limit))
	pet = Pet(1,"bob", "cat")
	Bonsai.write(stream , pet)
end

function delete_pets(
	stream; 
	read_limit=Query(Limit), 
	read_offset=Query(Offset), 
	read_headers=Headers(Auth),
	x = 10,
)
	pet = Pet(1,"bob", "cat")
	Bonsai.write(stream , pet)
end

function update_pets(stream; read_body=Body(Pet))
end

@testset "Query" begin

	q1 = Query(Limit)
	q2 = Query(Offset)

	l1 = parameters(q1)
	@test length(l1) == 1

	l2 = parameters(q2)
	@test length(l2) == 2
end

@testset "Body" begin
	b1 = Body(Pet)
	@test RequestBodyObject(b1) isa RequestBodyObject
end

@testset "handler" begin
	kwargs = collect(values(fn_kwargs(get_pets, @__MODULE__)))
	(res_type, res_code) = handler_writes(get_pets)[1]
	@test Bonsai.parameters.(kwargs)[1][1] isa ParameterObject
	@test ResponseObject(Pet) isa ResponseObject
end

@testset "http_parameters" begin
	@test length(http_parameters(delete_pets)) == 3
end