using UUIDs
using StructTypes
using StructTypes: @Struct

const Id = NamedTuple{(:id,), Tuple{String}}

@enum SaleStatus begin
    available
    pending
    sold
end

@Struct SaleStatus

struct Tag 
    id::String
    name::String
end

@Struct Tag

struct Category 
    id::String
    name::String
end

@Struct Category

const dog = Category("1", "dog")
const cat = Category("2", "cat")
const hamster = Category("3", "hamster")

"""
A pet
"""
Base.@kwdef struct Pet
    id::String = string(uuid4())
    name::String
    category::Category
    photo_urls::Array{String} = []
    tag::Array{Tag} = []
    status::SaleStatus = available
end

@Struct Pet

"""
A error
"""
struct Error
    code::Int
    type::String
end

@Struct Error