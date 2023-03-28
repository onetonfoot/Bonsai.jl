function _precompile_()
    ccall(:jl_generating_output, Cint, ()) == 1 || return nothing
    Base.precompile(Tuple{typeof(do_test_throws),ExecutionResult,Any,Any})   # time: 0.010533969
    Base.precompile(Tuple{typeof(do_test),ExecutionResult,Any})   # time: 0.007278203
end
