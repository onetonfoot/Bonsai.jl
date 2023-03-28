function _precompile_()
    ccall(:jl_generating_output, Cint, ()) == 1 || return nothing
    Base.precompile(Tuple{typeof(joinpath),PosixPath,String})   # time: 0.06556307
    Base.precompile(Tuple{typeof(Core.kwcall),NamedTuple{(:segments,), Tuple{NTuple{8, String}}},typeof(Path),PosixPath})   # time: 0.006528197
    Base.precompile(Tuple{typeof(join),NTuple{8, String},String})   # time: 0.00205056
end
