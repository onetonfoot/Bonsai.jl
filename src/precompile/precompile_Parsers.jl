function _precompile_()
    ccall(:jl_generating_output, Cint, ()) == 1 || return nothing
    Base.precompile(Tuple{typeof(parse),Type{Float64},Union{AbstractString, IO, AbstractVector{UInt8}}})   # time: 0.19807285
end
