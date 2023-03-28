function _precompile_()
    ccall(:jl_generating_output, Cint, ()) == 1 || return nothing
    Base.precompile(Tuple{typeof(iterate),Tuple{String, Int64, String, DataType, String, Int64, String, String, String}})   # time: 0.048812304
    Base.precompile(Tuple{typeof(convert),Type{Set{Type}},Set{DataType}})   # time: 0.045105405
    Base.precompile(Tuple{typeof(_unique!),typeof(identity),Vector{Any},Set{DataType},Int64,Int64})   # time: 0.04072934
    Base.precompile(Tuple{typeof(_str_sizehint),Any})   # time: 0.03480618
    Base.precompile(Tuple{typeof(|>),Vector{Type},typeof(unique!)})   # time: 0.030403346
    Base.precompile(Tuple{typeof(getindex),Vector{AbstractString},UnitRange{Int64}})   # time: 0.027484069
    Base.precompile(Tuple{typeof(push!),Set{DataType},Type})   # time: 0.0239542
    Base.precompile(Tuple{typeof(collect),Tuple{Symbol}})   # time: 0.022422347
    Base.precompile(Tuple{typeof(print),IOBuffer,Int64})   # time: 0.020999374
    Base.precompile(Tuple{typeof(setindex!),Dict{Symbol, Any},SubString{String},Symbol})   # time: 0.0163763
    Base.precompile(Tuple{Type{IOBuffer}})   # time: 0.013749962
    Base.precompile(Tuple{typeof(convert),Type{Vector{Pair{SubString{String}, SubString{String}}}},Vector{Pair{String, String}}})   # time: 0.012178809
    Base.precompile(Tuple{typeof(vect),SubString{String},Vararg{Any}})   # time: 0.011558133
    Base.precompile(Tuple{typeof(setindex_widen_up_to),Vector{LineNumberNode},Expr,Int64})   # time: 0.01036102
    Base.precompile(Tuple{typeof(copyto!),Vector{Type},Int64,Vector{DataType},Int64,Int64})   # time: 0.009918058
    Base.precompile(Tuple{typeof(==),NamedTuple{(:y,), Tuple{Union{Nothing, String}}},NamedTuple{(:y,), Tuple{Nothing}}})   # time: 0.006552657
    Base.precompile(Tuple{typeof(setindex!),Dict{Any, Nothing},Nothing,Type{Symbol}})   # time: 0.005729434
    Base.precompile(Tuple{typeof(fieldname),Type{NamedTuple{(:data,), Tuple{Vector{Float64}}}},Int64})   # time: 0.004009012
    Base.precompile(Tuple{Type{Dict{Symbol, Any}}})   # time: 0.003830671
    Base.precompile(Tuple{typeof(take!),IOBuffer})   # time: 0.003528405
    Base.precompile(Tuple{typeof(_unique!),typeof(identity),Vector{Type},Set{Type},Int64,Int64})   # time: 0.003017
    Base.precompile(Tuple{typeof(getindex),Type{Function},Function,Function})   # time: 0.002826991
    Base.precompile(Tuple{typeof(setindex_widen_up_to),Vector{Expr},Float64,Int64})   # time: 0.002770563
    Base.precompile(Tuple{Type{Dict{Any, Any}},Pair{Symbol, String}})   # time: 0.002733073
    Base.precompile(Tuple{typeof(setindex!),Dict{Symbol, Any},Float64,Symbol})   # time: 0.002530869
    Base.precompile(Tuple{typeof(getindex),Type{AbstractString},SubString{String},SubString{String},String})   # time: 0.002437909
    Base.precompile(Tuple{typeof(∉),Type,Set{DataType}})   # time: 0.0020058
    Base.precompile(Tuple{typeof(Core.kwcall),NamedTuple{(:sizehint,), Tuple{Int64}},Type{IOBuffer}})   # time: 0.001724166
    Base.precompile(Tuple{typeof(vect),Bool,Vararg{Bool}})   # time: 0.001600205
    Base.precompile(Tuple{typeof(collect),Tuple{Symbol, Symbol}})   # time: 0.001600014
    Base.precompile(Tuple{typeof(vect),Tuple{SubString{String}, String},Vararg{Tuple{SubString{String}, String}}})   # time: 0.001594634
    Base.precompile(Tuple{typeof(_unique!),typeof(identity),Vector{Type},Set{DataType},Int64,Int64})   # time: 0.001579884
    Base.precompile(Tuple{typeof(==),Dict{Symbol, String},Dict{Any, Any}})   # time: 0.001571646
    Base.precompile(Tuple{typeof(setindex_widen_up_to),Vector{DataType},Any,Int64})   # time: 0.001530752
    isdefined(Base, Symbol("#throw_need_pos_int#13")) && Base.precompile(Tuple{getfield(Base, Symbol("#throw_need_pos_int#13")),Int64})   # time: 0.001484336
    Base.precompile(Tuple{typeof(getindex),Type{String},String,String,String,String,Vararg{String}})   # time: 0.001448045
    Base.precompile(Tuple{Type{Set{DataType}}})   # time: 0.001227056
    Base.precompile(Tuple{typeof(setindex!),Dict{Symbol, Any},String,Symbol})   # time: 0.001131049
    Base.precompile(Tuple{RedirectStdStream,IOStream})   # time: 0.001113668
    Base.precompile(Tuple{typeof(convert),Type{Union{Nothing, Float64}},Any})   # time: 0.00107563
    Base.precompile(Tuple{typeof(vcat),String,String})   # time: 0.00106723
end
