function _precompile_()
    ccall(:jl_generating_output, Cint, ()) == 1 || return nothing
    Base.precompile(Tuple{typeof(istopfunction),Any,Symbol})   # time: 0.03126976
end
