function _precompile_()
    ccall(:jl_generating_output, Cint, ()) == 1 || return nothing
    Base.precompile(Tuple{typeof(trymatch),OrBind,Expr})   # time: 0.18182315
    Base.precompile(Tuple{typeof(trymatch),OrBind,Symbol})   # time: 0.010852557
    Base.precompile(Tuple{typeof(match),TypeBind,Symbol,Dict{Any, Any}})   # time: 0.005469366
    Base.precompile(Tuple{typeof(match),Symbol,Float64,Dict{Any, Any}})   # time: 0.005144658
    Base.precompile(Tuple{typeof(match),Nothing,Nothing,Dict{Any, Any}})   # time: 0.005144222
    Base.precompile(Tuple{typeof(match_inner),OrBind,Expr,Dict{Any, Any}})   # time: 0.00296393
    Base.precompile(Tuple{typeof(match),QuoteNode,QuoteNode,Dict{Any, Any}})   # time: 0.002735205
    Base.precompile(Tuple{typeof(trymatch),Expr,Symbol})   # time: 0.001496845
    Base.precompile(Tuple{typeof(match),OrBind,Expr,Dict{Any, Any}})   # time: 0.001256137
end
