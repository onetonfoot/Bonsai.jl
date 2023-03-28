function _precompile_()
    ccall(:jl_generating_output, Cint, ()) == 1 || return nothing
    Base.precompile(Tuple{Type{JLKwStruct},Expr})   # time: 0.14900176
    Base.precompile(Tuple{typeof(split_field_if_match),Symbol,Expr,Bool})   # time: 0.015824387
    Base.precompile(Tuple{typeof(flatten_blocks),Expr})   # time: 0.005438406
    Base.precompile(Tuple{typeof(Core.kwcall),NamedTuple{(:name, :type, :isconst, :default, :doc, :line), Tuple{Symbol, Symbol, Bool, Float64, Nothing, LineNumberNode}},Type{JLKwField}})   # time: 0.001612535
    Base.precompile(Tuple{typeof(Core.kwcall),NamedTuple{(:name, :type, :isconst, :default, :doc, :line), Tuple{Symbol, Symbol, Bool, NoDefault, Nothing, LineNumberNode}},Type{JLKwField}})   # time: 0.001531295
end
