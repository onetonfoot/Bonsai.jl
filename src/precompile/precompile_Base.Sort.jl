function _precompile_()
    ccall(:jl_generating_output, Cint, ()) == 1 || return nothing
    Base.precompile(Tuple{typeof(sort!),Vector{Symbol}})   # time: 0.019723723
end
