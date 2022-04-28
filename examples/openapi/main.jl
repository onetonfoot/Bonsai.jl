using Bonsai, URIs, StructTypes
using StructTypes: @Struct

@Struct struct Limit 
	limit::Int
end

@Struct struct Pet
	id::Int
	name::String
	tag::String
end

@Struct struct Error 
	code::Int
	type::String
end

const pets = Dict(
	1 =>  Pet(
		1,
		"bobby",
		"dog"
	)
)

function create_pet(stream; read_pet = Body(Pet))
	pet = read_pet(stream)
	pets[pet.id] = pet
	@info "created pet" pet=pet
	Bonsai.write(stream, "", ResponseCodes.Created())
end

# TODO: a declartive way to extract path parameters
function get_pet(stream)

	id = parse(Int, URIs.splitpath(stream.message.target)[2])

	if haskey(pets, id)
		pet = pets[id]
		Bonsai.write(stream, pet, ResponseCodes.Ok())
	else
		err = Error(
			1,
			"Pet not found :("
		)
		Bonsai.write(stream, err, ResponseCodes.NotFound())
	end
end

# TODO: track header writes
function get_pets(stream)
end


router = Router()

get!(router, "/pet", get_pet)
post!(router, "/pet", create_pet)

const docs = create_docs(OpenAPI(router))

function docs_handler(stream)
	write(stream, docs)
end

get!(router, "/docs", docs_handler)

start(router, port=10000)
wait(router)