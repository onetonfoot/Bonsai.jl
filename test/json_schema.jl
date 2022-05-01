using Test, Bonsai, StructTypes
using StructTypes: @Struct
using Bonsai: json_schema, JSONSchema, json_schema_format
using NamedTupleTools
using Dates

@enum Fruit apple orange

@Struct struct FruitBasket
	total::Int
	prices::Vector{Int}
	fruit::Vector{Fruit}
end

@testset "json_schema_format" begin
	@test json_schema_format(DateTime) == "date-time"
end

@testset "json_schema" begin

	@test !isnothing(json_schema(Fruit).enum)
	@test !isnothing(json_schema(Vector{Int}).items)


	@test !isnothing(json_schema(Tuple{Int, String}).prefixItems)
	@test Bonsai.json_schema(typeof(Body(x=10))) isa JSONSchema
	@test Bonsai.json_schema(typeof(Headers(x_next=12))) isa JSONSchema
end

@testset "JSONSchema" begin
	@test json_schema(FruitBasket) isa JSONSchema
	@test length(Bonsai.union_types(Union{Missing, Int, Nothing})) == 3
    @test length(Bonsai.json_schema(Union{Missing, Int, Nothing}).oneOf) == 2
end
