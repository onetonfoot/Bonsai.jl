using Bonsai, Test
using Bonsai: @data, convert_numbers!
using Bonsai.StructTypes
using Bonsai.JSON3
import Bonsai

@data struct AB
    a::Int
    b::Float64
end

@data mutable struct XYZ
    x::Int
    y::Float64 = 1.0
    z::String
end

@testset "read" begin
    ab = (a=10, b=2.0)
    ab2 = Dict{Symbol,Any}(:a => "10", :b => "2.0")

    @test Bonsai.read(ab, AB) isa AB
    @test Bonsai.read(convert_numbers!(ab2, AB), AB) isa AB
    @test Bonsai.read(JSON3.write(ab), AB) isa AB

    s = """{"data" : [1,2,3]}"""
    t = typeof((data=Float64[],))
    @test Bonsai.read(s, t) isa t

    s = """[1,2,3]"""
    t = Array{Float64}
    @test Bonsai.read(s, t) isa t
end

@testset "kw_constructor" begin
    p = Bonsai.kw_constructor(Route; id=Int, color=String)
    @test p.t == NamedTuple{(:id, :color),Tuple{Int64,String}}
    @test isnothing(p.val)
    @test_throws Exception Bonsai.kw_constructor(Params; id=Int, color="blue")
end


#= 
TODO: When we can't parse a particular struct in read it would be nice to throw 
a more specific error but we can come back to this once 
https://github.com/quinnj/JSON3.jl/issues/268 has been addressed

nestedT = typeof((
    x=1, y=2, z=(
        a=1, b=2, c=(
            x=2,)
    )
))

valid_str = """{"a": 1, "b": 2, "c":4}"""
invalid_str = """{"a": 1 }"""

e = Bonsai.read(invalid_str, AB)
JSON3.read(invalid_str, AB)
st = Bonsai.read(invalid_str, AB)
StructTypes.constructfrom(AB, JSON3.read(valid_str))
JSON3.read("""{"a": 1 }""", Float64)

@data struct A
    a::Int
    b::String
    c::X
end

ok = """{
    "a": 1,
    "b": "hi",
    "c": {
        "x": 100,
        "y": "hello",
        "z": "world"
    }
}"""


# good = """ { "x": 1, "y": 2, "z": "hi" } """

using StructTypes, JSON3

struct X
    x::Int
    y::Float64
    z::String
end

StructTypes.StructType(::Type{X}) = StructTypes.Struct()

bad_json = """ { "x": 1, "y": 2, "z": 1 } """


JSON3.read(bad, X)

StructTypes.constructfrom(X, JSON3.read(bad))

e = try
catch e
    return e
end
=#