using Bonsai, JSON3, StructTypes
using Test
using StructTypes: @Struct
using Bonsai: open_api_parameters, ParameterObject,
	ResponseObject,  RequestBodyObject, 
	handler_writes, HttpParameter, handler_reads, mime_type, docstr, description
using CodeInfoTools: code_inferred
using Bonsai: PathItemObject, MediaTypeObject, ParameterObject, OperationObject, OpenAPI
# https://raw.githubusercontent.com/OAI/OpenAPI-Specification/main/examples/v3.0/petstore.json
# https://blog.stoplight.io/openapi-json-schema#:~:text=You%20can%20use%20JSON%20Schema,generate%20an%20entire%20mock%20server.

@Struct struct Id
	id::Int
end

"a pet desc"
struct Pet1
	id::Int64
	name::String
	tag::String
end

Bonsai.description(t::Type{Pet1}) = docstr(t)

@Struct Pet1

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
	@test_throws Exception open_api_parameters(Body)
end

@testset "Body" begin
	b1 = Body(Pet1)
	@test RequestBodyObject(typeof(b1)) isa RequestBodyObject
end

@testset "docstr" begin
	@test !isnothing(docstr(Body{Pet1}))
end

@testset "handler_reads" begin
	function handler(stream)
		 Bonsai.read(
			stream,
			Body(Pet1),
			Query(Limit1)
		)
	end
	@test Bonsai.handler_reads(handler) == [  Body{Pet1}, Query{Limit1}]
end

@testset "OpenAPI" begin

	app = App()

	app.get["/pets/{id:\\d+}"] = function(stream)
		params = Bonsai.read(
			stream,
			Route(Id)
			# This doesn't work with open api at the moment sadly
			# Route(id=Int)
		)
		pet = Pet1(params.id, "bob", "dog")
		Bonsai.write(stream, Body(pet))
	end


	app.post["/pets/"] = function(stream)
		body = Bonsai.read(stream, Body(Pet1))
	end

	get_pets = app.get["/pets/{id:\\d+}"]
	id_read = Bonsai.handler_reads(get_pets.fn)
	id_read = Bonsai.handler_reads(get_pets.fn)[1] 
	@test id_read <: Route &&  !(id_read isa UnionAll)
	@test Body{Pet1} in Bonsai.handler_writes(get_pets.fn)

	create_pets = app.post["/pets/"]
	@test Body{Pet1} in Bonsai.handler_reads(create_pets.fn)

	@test Bonsai.RequestBodyObject(
		Bonsai.handler_reads(create_pets.fn)[1]
	) isa Bonsai.RequestBodyObject

	api = OpenAPI(app)

	@test api isa OpenAPI

    o = api.paths["/pets/{id:\\d+}"]
	@test haskey(o.get.responses, "200")
	@test !isnothing(description(Body{Pet1}))
	@test !isnothing(docstr(Body{Pet1}))
	@test !isnothing(o.get.responses["200"].description)
end	

# test globals don't break it

# const V1 = "0.2.2"

# function version(stream)
#     Bonsai.write(stream, Body(V1))
# end

# OperationObject(version) isa  Oper
