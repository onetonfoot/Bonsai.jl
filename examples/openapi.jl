using Bonsai, URIs, StructTypes
using JSON3
using StructTypes: @Struct

const app = App()

"""
limit - How many items to return at one time (max 100)
offset - Offset to start returning pets from
"""
struct Limit
    limit::Int
    offset::Union{Int, Nothing}
end

const Id = NamedTuple{(:id,), Tuple{Int}}

struct Pet
    id::Int
    name::String
    tag::String
end

"""
code - a numerical error code
"""
struct Error
    code::Int
    type::String
end

@Struct Limit
@Struct Error
@Struct Pet

const pets::Dict{Int, Pet} = Dict(
    1 => Pet(
        1,
        "bobby",
        "dog"
    )
)

"""
Shows all the pets
"""
app.get("/") do stream
    Bonsai.write(stream, Body(JSON3.write(pets)))
end

"""
Create a new pet
"""
app.post("/pets") do stream
    pet = Bonsai.read(stream, Body(Pet))
    global pets::Dict{Int, Pet}
    # pets[pet.id] = pet
    Bonsai.write(stream, Body("ok"))
end

"""
Look up a specific pet
"""
app.get("/pets/{id}") do stream
    id = Bonsai.read(stream, Route(Id))
    global pets
    if haskey(pets, id)
        pet::Pet = pets[id]
        Bonsai.write(stream, Body(pet))
    else
        Bonsai.write(stream, Body("pet not found"), Status(404))
    end
end

open_api!(app)

start(app, port=10004)