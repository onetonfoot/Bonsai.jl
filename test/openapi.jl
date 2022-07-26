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
	id::String
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
end

@testset "Body" begin
	b1 = Body(Pet1)
	@test RequestBodyObject(typeof(b1)) isa RequestBodyObject
end

@testset "OpenAPI" begin

	app = App()

	"""
	Adds a new pet to the store
	"""
	app.post("/pets/") do stream
		body = Bonsai.read(stream, Body(Id))
	end

	app.get("/pets/{id:\\d+}") do stream
		pets = [ Pet1(body.id, "bob", "cat") for i in 1:10]
		Bonsai.write(pets)
	end

	get_pets, _ = match(app.paths, "GET", "/pets/1")
	create_pets, _ = match(app.paths, "POST", "/pets")

	@test_skip Bonsai.RequestBodyObject(
		Bonsai.handler_reads(create_pets.fn)[1]
	) isa Bonsai.RequestBodyObject

	@test_skip OpenAPI(app) isa OpenAPI
	# JSON3.write("tmp.json",  OpenAPI(app))
end