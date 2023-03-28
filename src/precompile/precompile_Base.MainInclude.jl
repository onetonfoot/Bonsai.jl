function _precompile_()
    ccall(:jl_generating_output, Cint, ()) == 1 || return nothing
    Base.precompile(Tuple{typeof(include),String})   # time: 0.004065219
end
