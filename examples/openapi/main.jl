using Bonsai, URIs, StructTypes
using JSON3
using StructTypes: @Struct

const app = App()

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

app.post("/pets/:id") do stream
	pet = Bonsai.read(stream, Body(Pet))
	pets[pet.id] = pet
	@info "created pet" pet=pet
	Bonsai.write(stream, "ok")
end

app.get("/pets/:id") do stream
	id = parse(Int, URIs.splitpath(stream.message.target)[2])
	if haskey(pets, id)
		pet::Pet = pets[id]
		Bonsai.write(stream, pet, ResponseCodes.Ok())
	else
		err = Error(
			1,
			"Pet not found :("
		)
		Bonsai.write(stream, err, ResponseCodes.NotFound())
	end
end

app.get("*") do stream, next
	try
		@info "NEXT" next
		next(stream)
	catch e
		println("Error caught")
		Bonsai.write(stream, string(e), ResponseCodes.InternalServerError())
		println(e)
	end
end


JSON3.write(joinpath(@__DIR__, "openapi.json"), OpenAPI(app))

start(app, port=10001)



wait(router)

stop(app)