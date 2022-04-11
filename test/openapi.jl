using Bonsai, JSON3, StructTypes
using StructTypes: @Struct
using Bonsai: fn_kwargs, json_schema
using HTTP: Stream
# https://raw.githubusercontent.com/OAI/OpenAPI-Specification/main/examples/v3.0/petstore.json
# https://blog.stoplight.io/openapi-json-schema#:~:text=You%20can%20use%20JSON%20Schema,generate%20an%20entire%20mock%20server.

@testset "todo!" begin
	@Struct struct Pet 
		id::Int64
		name::String
		tag::String
	end

	function get_pets(stream; read_query=Query(Limit))
		pet = Pet(1,"bob", "cat")
		return [pet]
	end

	function post_pets(stream)

	end

	function get_pet(stream)

	end


	router = Router()
	get!(router, "/pets", get_pets)
	Base.return_types(get_pets)

	path, handler = router.paths[GET][1]

	kwargs = collect(values(fn_kwargs(handler.fn, @__MODULE__)))


	# parameters
	function open_api(q::Query{T}) where T
		l = []
		StructTypes.foreachfield(T) do  i, field, field_type
			schema = json_schema(field_type)
			d = Dict(
				:name =>  field,
				:in => :query,
				:required => q.required,
				:schema => schema

			)
			push!(l, d)
		end
		l
	end

	@Struct struct Limit
		limit::Int
	end

	@Struct struct Offset
		start::Int
		n::Int
	end


	q1 = Query(Limit)
	q2 = Query(Offset)

	open_api(q1)
	open_api(q2)

	# traits used to add descriptions
	function tags(x)
	end

	function description(x)
	end

	HttpHandler()

	# components.schemas
	# components.schemas
	json_schema(Offset)
		
end
