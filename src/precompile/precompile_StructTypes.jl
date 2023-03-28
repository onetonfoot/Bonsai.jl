function _precompile_()
    ccall(:jl_generating_output, Cint, ()) == 1 || return nothing
    Base.precompile(Tuple{typeof(constructfrom),Type{Vector{Float64}},Any})   # time: 0.009731685
    Base.precompile(Tuple{DictClosure,Int64,Symbol,Type{Int64}})   # time: 0.008217649
    Base.precompile(Tuple{StructClosure{NamedTuple{(:a, :b), Tuple{Int64, Float64}}},Int64,Symbol,Type{Int64}})   # time: 0.007649334
    Base.precompile(Tuple{typeof(constructfrom),Type{Float64},Any})   # time: 0.00691487
    Base.precompile(Tuple{DictClosure,Int64,Symbol,Type{Union{Missing, Int64}}})   # time: 0.002074479
    isdefined(StructTypes, Symbol("#20#21")) && Base.precompile(Tuple{getfield(StructTypes, Symbol("#20#21")),Any})   # time: 0.00193141
    Base.precompile(Tuple{DictClosure,Int64,Symbol,Type{Union{Nothing, Float64}}})   # time: 0.001914592
    Base.precompile(Tuple{typeof(constructfrom),Type{Union{Missing, Int64}},Int64})   # time: 0.001555595
    Base.precompile(Tuple{StructClosure,Int64,Symbol,Type{Any}})   # time: 0.001360297
end
