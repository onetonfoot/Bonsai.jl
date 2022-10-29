using Bonsai, URIs, StructTypes
using JSON3
using StructTypes: @Struct
using UUIDs


"""
limit - How many items to return at one time (max 100)
offset - Offset to start returning pets from
"""
struct Limit
    limit::Int
    offset::Union{Int, Nothing}
end

const Id = NamedTuple{(:id,), Tuple{String}}

@enum SaleStatus begin
    available
    pending
    sold
end

struct Tag 
    id::String
    name::String
end

struct Category 
    id::String
    name::String
end

const dog = Category("1", "dog")
const cat = Category("2", "cat")
const hamster = Category("3", "hamster")

"""
A Pet
"""
Base.@kwdef struct Pet
    id::String = string(uuid4())
    name::String
    category::Category
    photo_urls::Array{String} = []
    tag::Array{Tag} = []
    status::SaleStatus = available
end

"""
Code - a numerical error code
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
            name = "bob",
            category = dog
    ),
    2 => Pet(
            name = "su",
            category = cat
    ),
)


"Update an existing pet"
function update_pet(stream)
end

"""
Shows all the pets
"""
function list_pets(stream)
    Bonsai.write(stream, Body(JSON3.write(pets)))
end

"""
Update a new pet to the store
"""
function create_pet(stream)
    global pets
    pet = Bonsai.read(stream, Body(Pet))
    pets[pet.id] = pet
    Bonsai.write(stream, Body("ok"))
end

function find_pet(id)
    if rand() > 0.5
        pet = Pet(name="bobby", category=dog)
        return pet
    else
        return nothing
    end
end

"""
Finds pet by ID
"""
function get_pet(stream)
    id = Bonsai.read(stream, Route(Id))
    pet = find_pet(id)
    # when returning multiple status codes we must also
    # write the 200 status code to ensure that open-api
    # spec correctly groups the writes
    if !isnothing(pet)
        Bonsai.write(stream, Body(pet), Status(200))
    else
        Bonsai.write(stream, Body("Pet not found"), Status(404))
    end
end

function find_by_status(stream)
    (;status) = Bonsai.read(stream, Query(status=Union{SaleStatus, Nothing}))

    if isnothing(status)
        Bonsai.write(stream,  Body("Invalid Status value"), Status(400))
        return
    end

    pets = Pet[]
    Bonsai.write(stream,  Body(pets))
end

function register_handlers!(app)
    app.get["/"] = list_pets
    app.post["/pets"] = create_pet
    app.get["/pets/{id}"] = get_pet
end

function register_middleware!(app)
end

const app = App()

function setup_app(app)
    register_middleware!(app)
    register_handlers!(app)
    JSON3.write(
        "pet-store.json",
        OpenAPI(app)
    )
    open_api!(app)
end


# only start the app if file is run as a script
if abspath(PROGRAM_FILE) == @__FILE__
    setup_app(app)
    start(app, port=10004)
end