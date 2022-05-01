using Test, Bonsai, StructTypes
using StructTypes: @Struct
using Bonsai: json_schema, JSONSchema, json_schema_format
using NamedTupleTools
using Dates

@enum Fruit apple orange

@Struct struct FruitBasket
	total::Int
	prices::Array{Int}
	fruit::Array{Fruit}
end

@testset "json_schema_format" begin
	@test json_schema_format(DateTime) == "date-time"
end

@testset "json_schema" begin
	@test :enum in fieldnames(json_schema(Fruit))
	@test :items in fieldnames(json_schema(Array{Int}))
	@test :prefixItems in fieldnames(json_schema(Tuple{Int, String}))
end

@testset "JSONSchema" begin
	nt = json_schema(FruitBasket)
	@test JSONSchema(;nt...) isa JSONSchema
end

Bonsai.json_schema(typeof(Body(x=10)))
Bonsai.json_schema(typeof(Headers(x_next=12)))

function g()
	a::Union{Int, Missing} = mi
	a
end

t = Union{Missing, Int}

t1 = Union{Missing, Nothing, Int}

a = g()





Union{Int, Missing} isa Union

Bonsai.json_schema(Union{Missing, Int, Nothing})

Bonsai.union_types(Union{Missing, Int, Nothing})

Missing(10)

StructTypes.StructType(Union{Missing,Int})