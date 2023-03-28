function _precompile_()
    ccall(:jl_generating_output, Cint, ()) == 1 || return nothing
    Base.precompile(Tuple{typeof(read),AbstractString})   # time: 1.2761518
    Base.precompile(Tuple{typeof(read),Union{Base.AbstractCmd, IO}})   # time: 0.8798176
    Base.precompile(Tuple{typeof(read),Vector{UInt8},Type{Dict}})   # time: 0.64593446
    Base.precompile(Tuple{typeof(write),Dict{Symbol, Any}})   # time: 0.19516796
    Base.precompile(Tuple{typeof(write),Dict})   # time: 0.08232345
    Base.precompile(Tuple{WriteClosure{Vector{UInt8}, NamedTuple{(), Tuple{}}},Int64,Symbol,Type{String},String})   # time: 0.038982812
    Base.precompile(Tuple{typeof(write),NamedTuple{(:a, :b), Tuple{Int64, Float64}}})   # time: 0.035005193
    Base.precompile(Tuple{typeof(Core.kwcall),NamedTuple{(:allow_inf,), Tuple{Bool}},typeof(write),IOBuffer,Nothing})   # time: 0.029873826
    Base.precompile(Tuple{typeof(Core.kwcall),NamedTuple{(:allow_inf,), Tuple{Bool}},typeof(write),StringType,Vector{UInt8},Int64,Int64,Symbol})   # time: 0.009606841
    Base.precompile(Tuple{WriteClosure{Vector{UInt8}, NamedTuple{(), Tuple{}}},Int64,Symbol,Type{Int64},Int64})   # time: 0.008640433
    Base.precompile(Tuple{typeof(write),StringType,Vector{UInt8},Int64,Int64,SubString{String}})   # time: 0.0056534
    Base.precompile(Tuple{WriteClosure{Vector{UInt8}, NamedTuple{(), Tuple{}}},Int64,Symbol,Type{Any},Any})   # time: 0.003744572
    Base.precompile(Tuple{var"##_#75",Base.Pairs{Symbol, Union{}, Tuple{}, NamedTuple{(), Tuple{}}},WriteClosure{Vector{UInt8}, NamedTuple{(), Tuple{}}},Int64,Symbol,Type,Int64})   # time: 0.002665803
end
