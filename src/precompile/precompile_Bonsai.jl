const __bodyfunction__ = Dict{Method,Any}()

# Find keyword "body functions" (the function that contains the body
# as written by the developer, called after all missing keyword-arguments
# have been assigned values), in a manner that doesn't depend on
# gensymmed names.
# `mnokw` is the method that gets called when you invoke it without
# supplying any keywords.
function __lookup_kwbody__(mnokw::Method)
    function getsym(ast, arg)
        isa(arg, Symbol) && return arg
        isa(arg, GlobalRef) && return arg.name
        if isa(arg, Core.SSAValue)
            arg = ast.code[arg.id]
            return getsym(ast, arg)
        end
    end

    f = get(__bodyfunction__, mnokw, nothing)
    if f === nothing
        fmod = mnokw.module
        # The lowered code for `mnokw` should look like
        #   %1 = mkw(kwvalues..., #self#, args...)
        #        return %1
        # where `mkw` is the name of the "active" keyword body-function.
        ast = Base.uncompressed_ast(mnokw)
        if isa(ast, Core.CodeInfo) && length(ast.code) >= 2
            callexpr = ast.code[end-1]
            if isa(callexpr, Expr) && callexpr.head == :call
                fsym = callexpr.args[1]
                if isa(fsym, Symbol)
                    f = getfield(fmod, fsym)
                elseif isa(fsym, GlobalRef)
                    if fsym.mod === Core && fsym.name === :_apply
                        f = getfield(mnokw.module, getsym(ast, callexpr.args[2]))
                    elseif fsym.mod === Core && fsym.name === :_apply_iterate
                        f = getfield(mnokw.module, getsym(ast, callexpr.args[3]))
                    else
                        f = getfield(fsym.mod, fsym.name)
                    end
                else
                    f = missing
                end
            else
                f = missing
            end
        else
            f = missing
        end
        __bodyfunction__[mnokw] = f
    end
    return f
end

function _precompile_()
    ccall(:jl_generating_output, Cint, ()) == 1 || return nothing
    Base.precompile(Tuple{typeof(write),Stream,Headers{NamedTuple{(:header,),Tuple{String}}}})   # time: 2.2988083
    Base.precompile(Tuple{typeof(write),Response,Body{NamedTuple{(:x,),Tuple{Int64}}}})   # time: 2.1992393
    Base.precompile(Tuple{typeof(headerize),Symbol})   # time: 2.164023
    Base.precompile(Tuple{typeof(write),Response,Headers{NamedTuple{(:content_type,),Tuple{String}}}})   # time: 2.1166892
    Base.precompile(Tuple{typeof(write),Response,Headers{NamedTuple{(:header,),Tuple{String}}}})   # time: 2.0835173
    Base.precompile(Tuple{typeof(read),HTTP.Streams.Stream{A<:HTTP.Messages.Request,B<:Core.IO},Query})   # time: 0.96762437
    Base.precompile(Tuple{typeof(handler_writes),Any})   # time: 0.69667375
    Base.precompile(Tuple{typeof(Core.kwcall),NamedTuple{(:id, :color),Tuple{DataType,DataType}},typeof(kw_constructor),Type})   # time: 0.11900312
    Base.precompile(Tuple{typeof(getmiddleware),App,Request})   # time: 0.10577414
    Base.precompile(Tuple{typeof(write),Stream,Body{NamedTuple{(:x,),Tuple{Int64}}}})   # time: 0.09205892
    Base.precompile(Tuple{typeof(write),Response,Body{String},Status{201}})   # time: 0.06865481
    Base.precompile(Tuple{typeof(read),Dict{Any,Any},DataType})   # time: 0.031720627
    Base.precompile(Tuple{typeof(Core.kwcall),NamedTuple{(:header,),Tuple{String}},Type{Headers}})   # time: 0.02950376
    Base.precompile(Tuple{typeof(construct_error),DataType,JSON3.Object{Vector{UInt8},Vector{UInt64}}})   # time: 0.02322583
    Base.precompile(Tuple{typeof(Core.kwcall),NamedTuple{(:x,),Tuple{Int64}},Type{Body}})   # time: 0.022858528
    Base.precompile(Tuple{typeof(Core.kwcall),NamedTuple{(:color,),Tuple{DataType}},Type{Query}})   # time: 0.021564905
    Base.precompile(Tuple{typeof(setindex!),CreateMiddleware,Vector{Function},String})   # time: 0.01607091
    Base.precompile(Tuple{typeof(read),Request,Route{NamedTuple{(:id,),Tuple{Int64}}}})   # time: 0.016059436
    Base.precompile(Tuple{typeof(read),Request,Headers{NamedTuple{(:x_next,),Tuple{String}}}})   # time: 0.015223521
    Base.precompile(Tuple{typeof(write),Response,Body{PosixPath}})   # time: 0.014884812
    Base.precompile(Tuple{typeof(read),Request,Query{NamedTuple{(:y,),Tuple{Union{Nothing,String}}}}})   # time: 0.014723092
    Base.precompile(Tuple{typeof(Core.kwcall),NamedTuple{(:id,),Tuple{DataType}},Type{Route}})   # time: 0.014646934
    Base.precompile(Tuple{typeof(read),Request,Route{NamedTuple{(:x,),Tuple{String}}}})   # time: 0.014077245
    isdefined(Bonsai, Symbol("#_field_name#5")) && Base.precompile(Tuple{getfield(Bonsai, Symbol("#_field_name#5")),Expr})   # time: 0.011492283
    Base.precompile(Tuple{typeof(Core.kwcall),NamedTuple{(:x, :y),Tuple{Int64,Float64}},Type{Body}})   # time: 0.01000522
    Base.precompile(Tuple{typeof(Core.kwcall),NamedTuple{(:x, :y),Tuple{DataType,DataType}},Type{Body}})   # time: 0.008596082
    Base.precompile(Tuple{typeof(handler_reads),Any})   # time: 0.00729835
    Base.precompile(Tuple{typeof(read),NamedTuple{(:a, :b),Tuple{Int64,Float64}},DataType})   # time: 0.006895304
    Base.precompile(Tuple{typeof(Core.kwcall),NamedTuple{(:error, :message),Tuple{String,String}},Type{Body}})   # time: 0.006244926
    Base.precompile(Tuple{typeof(Core.kwcall),NamedTuple{(:content_type,),Tuple{String}},Type{Headers}})   # time: 0.005384445
    Base.precompile(Tuple{typeof(Core.kwcall),NamedTuple{(:y,),Tuple{Union}},Type{Query}})   # time: 0.005269121
    Base.precompile(Tuple{typeof(spliturl),String})   # time: 0.005232004
    Base.precompile(Tuple{typeof(Core.kwcall),NamedTuple{(:x,),Tuple{DataType}},Type{Route}})   # time: 0.00513121
    Base.precompile(Tuple{typeof(Core.kwcall),NamedTuple{(:x_next,),Tuple{DataType}},Type{Headers}})   # time: 0.004608333
    Base.precompile(Tuple{typeof(Core.kwcall),NamedTuple{(:x,),Tuple{DataType}},Type{Query}})   # time: 0.003575695
    Base.precompile(Tuple{typeof(convert_numbers!),Dict{Any,Any},Type})   # time: 0.003463286
    Base.precompile(Tuple{typeof(gethandlers),App,Request})   # time: 0.003460286
    isdefined(Bonsai, Symbol("#_field_kw#6")) && Base.precompile(Tuple{getfield(Bonsai, Symbol("#_field_kw#6")),Any})   # time: 0.00333146
    Base.precompile(Tuple{Type{Status},Int64})   # time: 0.003187899
    Base.precompile(Tuple{typeof(write),Stream,Body{String},Status{201}})   # time: 0.003142989
    Base.precompile(Tuple{typeof(combine_middleware),Vector{Function}})   # time: 0.002716805
    Base.precompile(Tuple{typeof(getindex),CreateMiddleware,String})   # time: 0.002696335
    Base.precompile(Tuple{typeof(gethandler),App,Request})   # time: 0.002680445
    Base.precompile(Tuple{typeof(convert_numbers!),Dict{Symbol,Any},Type})   # time: 0.002601102
    Base.precompile(Tuple{typeof(combine_middleware),Vector{Any}})   # time: 0.002584136
    Base.precompile(Tuple{typeof(read),HTTP.Streams.Stream{A<:HTTP.Messages.Request,B<:Core.IO},Route})   # time: 0.002568127
    Base.precompile(Tuple{Type{Query},DataType})   # time: 0.002217689
    Base.precompile(Tuple{typeof(write),Response,Status{201}})   # time: 0.002194738
    Base.precompile(Tuple{Type{Headers},DataType})   # time: 0.002117839
    Base.precompile(Tuple{typeof(setindex!),CreateMiddleware,Function,String})   # time: 0.00199732
    Base.precompile(Tuple{typeof(construct_error),DataType,JSON3.Object{Base.CodeUnits{UInt8,String},Vector{UInt64}}})   # time: 0.001952182
    Base.precompile(Tuple{Type{Route},Type{NamedTuple{(:id,),Tuple{Int64}}},Nothing})   # time: 0.001862422
    Base.precompile(Tuple{Type{Query},Type{NamedTuple{(:y,),Tuple{Union{Nothing,String}}}},Nothing})   # time: 0.001759281
    Base.precompile(Tuple{Type{Route},Type{NamedTuple{(:id, :color),Tuple{Int64,String}}},Nothing})   # time: 0.001602885
    let fbody = try
            __lookup_kwbody__(which(kw_constructor, (Type{Route},)))
        catch missing
        end
        if !ismissing(fbody)
            precompile(fbody, (Base.Pairs{Symbol,DataType,Tuple{Symbol,Symbol},NamedTuple{(:id, :color),Tuple{DataType,DataType}}}, typeof(kw_constructor), Type{Route},))
        end
    end   # time: 0.001553336
    Base.precompile(Tuple{Type{Headers},Type{NamedTuple{(:x_next,),Tuple{String}}},Nothing})   # time: 0.001450776
    Base.precompile(Tuple{Type{Route},Type{NamedTuple{(:x,),Tuple{String}}},Nothing})   # time: 0.001449037
    Base.precompile(Tuple{Type{Body},Type{NamedTuple{(:x, :y),Tuple{String,Float64}}},Nothing})   # time: 0.001426166
    Base.precompile(Tuple{Type{Route},Type{NamedTuple{(:x,),Tuple{Int64}}},Nothing})   # time: 0.001367136
    Base.precompile(Tuple{typeof(get_default),Expr})   # time: 0.001248698
    isdefined(Bonsai, Symbol("#_field_kw#6")) && Base.precompile(Tuple{getfield(Bonsai, Symbol("#_field_kw#6")),Expr})   # time: 0.001074699
    Base.precompile(Tuple{Type{Body},PosixPath})   # time: 0.001045749
end
