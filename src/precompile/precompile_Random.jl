function _precompile_()
    ccall(:jl_generating_output, Cint, ()) == 1 || return nothing
    Base.precompile(Tuple{typeof(copy!),TaskLocalRNG,Xoshiro})   # time: 0.020033354
end
