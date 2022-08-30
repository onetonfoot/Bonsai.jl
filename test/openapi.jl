using Bonsai, JSON3, StructTypes
using Test
using StructTypes: @Struct
using Bonsai: open_api_parameters, ParameterObject,
	ResponseObject,  RequestBodyObject, 
	handler_writes, HttpParameter, handler_reads
using CodeInfoTools: code_inferred
using Bonsai: PathItemObject, MediaTypeObject, ParameterObject, OperationObject, OpenAPI
# https://raw.githubusercontent.com/OAI/OpenAPI-Specification/main/examples/v3.0/petstore.json
# https://blog.stoplight.io/openapi-json-schema#:~:text=You%20can%20use%20JSON%20Schema,generate%20an%20entire%20mock%20server.

@Struct struct Id
	id::Int
end

@Struct struct Pet1
	id::Int64
	name::String
	tag::String
end

@Struct struct Limit1
	limit::Int
	offset::Int
end

@Struct struct Offset
	start::Int
	n::Int
end

@Struct struct AuthHeaders
	x_pass::String
	x_user::String
end

@testset "Query" begin
	@test length(open_api_parameters(Query{Limit1})) == 2
	@test length(open_api_parameters(Query{Offset})) == 2
	@test_throws Exception open_api_parameters(Tuple{})
	@test_throws Exception open_api_parameters(Body{Offset})
end

@testset "Body" begin
	b1 = Body(Pet1)
	@test RequestBodyObject(typeof(b1)) isa RequestBodyObject
end

@testset "OpenAPI" begin


	app = App()

	"""
	Get pet by it's id
	"""
	app.get("/pets/{id:\\d+}") do stream
		params = Bonsai.read(
			stream,
			Params(Id)
			# This doesn't work with open api at the moment sadly
			# Params(id=Int)
		)
		pet = Pet1(params.id, "bob", "dog")
		Bonsai.write(stream, Body(pet))
	end

	"""
	Creates a new pet
	"""
	app.post("/pets/") do stream
		body = Bonsai.read(stream, Body(Pet1))
	end

	get_pets, _ = match(app.paths, "GET", "/pets/1")
	id_read = Bonsai.handler_reads(get_pets.fn)[1] 
	@test id_read <: Params &&  !(id_read isa UnionAll)
	@test (Body{Pet1}, 200) in Bonsai.handler_writes(get_pets.fn)

	create_pets, _ = match(app.paths, "POST", "/pets")
	@test Body{Pet1} in Bonsai.handler_reads(create_pets.fn)

	@test Bonsai.RequestBodyObject(
		Bonsai.handler_reads(create_pets.fn)[1]
	) isa Bonsai.RequestBodyObject

	@test OpenAPI(app) isa OpenAPI
	# JSON3.write("tmp.json",  OpenAPI(app))
end