using Bonsai, JSON3, StructTypes
using Test
using StructTypes: @Struct
using Bonsai: open_api_parameters, ParameterObject,
	ResponseObject,  RequestBodyObject, 
	handler_writes, HttpParameter, http_parameters
using HTTP: Stream
using CodeInfoTools: code_inferred
using Bonsai: PathItemObject, MediaTypeObject, ParameterObject, OperationObject, OpenAPI
# https://raw.githubusercontent.com/OAI/OpenAPI-Specification/main/examples/v3.0/petstore.json
# https://blog.stoplight.io/openapi-json-schema#:~:text=You%20can%20use%20JSON%20Schema,generate%20an%20entire%20mock%20server.

@Struct struct Id
	id::String
end

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

@Struct struct AuthHeaders
	x_pass::String
	x_user::String
end

@testset "Query" begin

	q1 = Query(Limit)
	q2 = Query(Offset)

	l1 = open_api_parameters(q1)
	@test length(l1) == 1

	l2 = open_api_parameters(q2)
	@test length(l2) == 2
end

@testset "Body" begin
	b1 = Body(Pet)
	@test RequestBodyObject(b1) isa RequestBodyObject
end

@testset "http_parameters" begin
	@test length(http_parameters(delete_pets)) == 3
	p = HttpPath("/pets/:id")
	@test length(open_api_parameters(HttpPath("/pets/:id"))) == 1
end

@testset "handler" begin
	Bonsai.OperationObject(get_pets) 
end

# @testset "OpenAPI" begin
	app = App()

	app.post("/pets/") do stream
		body = Bonsai.read(stream, Body(Id))
	end

	app.get("/pets/") do stream
		pet = Pet(body.id,"bob", "cat")
		Bonsai.write(stream , pet)
	end

	app.get("/pets/:id") do stream
		pets = [ Pet(body.id, "bob", "cat") for i in 1:10]
		Bonsai.write(pets)
	end

	# delete!(r, "/pets", delete_pets)
	# get!(r, "/pets/:id", get_pets)

	h = app.router.paths[POST][1][2]

	a = Bonsai.handler_reads(h.fn)[1]

	Bonsai.RequestBodyObject(a)

	OpenAPI(app) 
	# create_docs(o)
	# JSON3.write("p.json", o)
	# npx @redocly/openapi-cli preview-docs p.json
	@test o isa OpenAPI

# end


# app.docs("", Redoc)