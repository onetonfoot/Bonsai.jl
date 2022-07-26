using Bonsai, Test, JSON3
using Bonsai: construct_error, convert_numbers!
using Base: @kwdef
using StructTypes

@kwdef struct AB
	a::Int
	b::Float64 
end

# It would be good to also supports default values
# https://github.com/JuliaData/StructTypes.jl/issues/53
@kwdef struct XYZ
	x::Int
	y::Float64 = 1.0
	z::String
end

StructTypes.StructType(::Type{AB}) = StructTypes.Struct()
StructTypes.StructType(::Type{XYZ}) = StructTypes.Struct()

@testset "read" begin
	ab =  (a = 10, b = 2.0)
	ab2 =  Dict{Symbol, Any}(:a => "10", :b => "2.0")

	@test Bonsai.read(ab, AB) isa AB
	@test Bonsai.read(convert_numbers!(ab2, AB), AB) isa AB
	@test Bonsai.read(JSON3.write(ab), AB) isa AB
end