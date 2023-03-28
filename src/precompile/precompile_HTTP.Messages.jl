function _precompile_()
    ccall(:jl_generating_output, Cint, ()) == 1 || return nothing
    Base.precompile(Tuple{Type{Request}})   # time: 0.040711544
    Base.precompile(Tuple{typeof(hasheader),Request,String})   # time: 0.012996155
end
