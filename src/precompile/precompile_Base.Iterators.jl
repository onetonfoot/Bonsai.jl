function _precompile_()
    ccall(:jl_generating_output, Cint, ()) == 1 || return nothing
    Base.precompile(Tuple{typeof(iterate),Zip{Tuple{Tuple{Symbol}, Tuple{DataType}}}})   # time: 0.005704592
    Base.precompile(Tuple{typeof(iterate),Zip{Tuple{Tuple{Symbol, Symbol}, Tuple{DataType, Union}}},Tuple{Int64, Int64}})   # time: 0.005276247
    Base.precompile(Tuple{typeof(iterate),Zip{Tuple{Tuple{Symbol, Symbol}, Tuple{DataType, Union}}}})   # time: 0.004584266
    Base.precompile(Tuple{typeof(iterate),Zip{Tuple{Tuple{Symbol}, Tuple{DataType}}},Tuple{Int64, Int64}})   # time: 0.001829951
end
