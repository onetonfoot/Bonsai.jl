function _precompile_()
    ccall(:jl_generating_output, Cint, ()) == 1 || return nothing
    isdefined(URIs, Symbol("#8#10")) && Base.precompile(Tuple{getfield(URIs, Symbol("#8#10")),Vector{AbstractString}})   # time: 0.014085974
    Base.precompile(Tuple{typeof(decodeplus),SubString{String}})   # time: 0.00202098
    Base.precompile(Tuple{typeof(unescapeuri),String})   # time: 0.001862442
end
