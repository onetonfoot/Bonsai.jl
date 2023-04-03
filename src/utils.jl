macro async_logged(exs...)
    if length(exs) == 2
        taskname, body = exs
    elseif length(exs) == 1
        taskname = "Task"
        body = only(exs)
    end
    quote
        @async try
            $(esc(body))
        catch exc
            @error string($(esc(taskname)), " failed") exception = (exc, catch_backtrace())
            rethrow()
        end
    end
end

function kw_constructor(T; kwargs...)
    k = []
    v = []
    has_datatype = false

    for (x, y) in kwargs

        if y isa DataType || y isa Union
            has_datatype = true
        end
        push!(k, x)
        push!(v, y)
    end

    if has_datatype
        # this is currnt only be used with Query and Params
        # e.g Route(id=Int) or Query(color=String, size=String)
        # however in it's current form it breaks type inference
        # with JET as it just returns Query not Query{T}
        @assert all(map(x -> x isa DataType || x isa Union, v)) "All or none must be DataType's"
        t = NamedTuple{tuple(k...),Tuple{v...}}
        return T(t, nothing)
    else
        nt = values(kwargs)
        T(typeof(nt), nt)
    end
end


function convert_numbers!(data::AbstractDict, T)
    for (k, t) in zip(fieldnames(T), fieldtypes(T))
        if t <: Union{Number,Missing,Nothing}
            data[k] = Parsers.parse(Float64, data[k])
        end
    end
    data
end

function construct_error(T::DataType, d)

    if StructTypes.StructType(d) in Set([
        StructTypes.ArrayType(),
        StructTypes.StringType(),
        StructTypes.BoolType(),
        StructTypes.NullType(),
        StructTypes.NumberType(),
    ])
        # TODO: how to better handle these types
        return nothing
    end


    struct_keys = collect(fieldnames(T))


    data_keys = collect(keys(d))
    ks = Symbol[]

    for k in struct_keys
        if !(k in data_keys)
            push!(ks, k)
        end
    end

    if isempty(ks)
        return nothing
    else
        return DataMissingKey(T,
            sort!(struct_keys),
            sort!(data_keys),
        )
    end
end

StructTypes.StructType(::Type{<:AbstractPath}) = StructTypes.StringType()

# This doesn't seem to work because Path is a function not a data type ?
# StructTypes.StructType(::Type{typeof(Path)}) = StructTypes.StringType()
# StructTypes.StructType(::Type{Path}) = StructTypes.StringType()


# UnionAll catch stuff like Array{Float64}
function read(d::Union{AbstractString,AbstractArray{UInt8}}, T::Union{DataType,UnionAll})

    d = JSON3.read(d)

    try
        return StructTypes.constructfrom(T, d)
    catch e
        maybe_e = construct_error(T, d)
        if isnothing(e)
            rethrow(e)
        else
            throw(maybe_e)
        end
    end
end

function read(d::Union{AbstractDict,NamedTuple}, T::Union{DataType,UnionAll})

    d = JSON3.write(d) |> JSON3.read

    try
        return StructTypes.constructfrom(T, d)
    catch e
        maybe_e = construct_error(T, d)
        if isnothing(e)
            rethrow(e)
        else
            throw(maybe_e)
        end
    end
end