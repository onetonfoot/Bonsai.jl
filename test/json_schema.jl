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
