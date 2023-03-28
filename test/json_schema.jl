using Test, Bonsai, Dates
using Bonsai: json_schema, JSONSchema, json_schema_format
using Bonsai.NamedTupleTools,
    Bonsai.JSON3
Bonsai.StructTypes
using Bonsai.StructTypes: @Struct

@enum Fruit apple orange

"""
Fruit basket order
"""
struct FruitBasket
    total::Int
    discount::Union{Float64,Nothing}
    prices::Vector{Int}
    fruit::Vector{Fruit}
end

@Struct FruitBasket

@testset "json_schema_format" begin
    @test json_schema_format(DateTime) == "date-time"
end

@testset "json_schema" begin

    @test !isnothing(json_schema(Fruit).enum)
    @test !isnothing(json_schema(Vector{Int}).items)

    @test !isnothing(json_schema(Tuple{Int,String}).prefixItems)
    @test Bonsai.json_schema(typeof(Body(x=10))) isa JSONSchema
    @test Bonsai.json_schema(typeof(Headers(x_next=12))) isa JSONSchema
end


@testset "doc_str" begin
    @test !isnothing(Bonsai.doc_str(FruitBasket))
end

@testset "JSONSchema" begin
    @test json_schema(FruitBasket) isa JSONSchema
    @test length(Bonsai.union_types(Union{Missing,Int,Nothing})) == 3
    @test length(Bonsai.json_schema(Union{Missing,Int,Nothing}).oneOf) == 2

    @test !is_required(Union{Nothing,Float64})
    @test is_required(Int)
    @test json_schema(FruitBasket).required == ["total", "prices", "fruit"]
end