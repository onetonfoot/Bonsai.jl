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

function kw_constructor_data_type(T; kwargs...)
    k = []
    v = []
    for (x, y) in kwargs
        @assert y isa DataType "Argument is not a DataType"
        push!(k, x)
        push!(v, y)
    end
    t = NamedTuple{tuple(k...),Tuple{v...}}
    T(t)
end

function kw_constructor(T; kwargs...)
    k = []
    v = []
    has_datatype = false

    for (x, y) in kwargs

        if y isa DataType
            has_datatype = true
        end

        push!(k, x)
        push!(v, y)
    end

    if has_datatype
        @assert all(map(x -> x isa DataType, v))
        t = NamedTuple{tuple(k...),Tuple{v...}}
        return T(t, nothing)
    else
        nt = values(kwargs)
        T(typeof(nt), nt)
    end
end


function convert_numbers!(data::AbstractDict, T)
    for (k, t) in zip(fieldnames(T), fieldtypes(T))
        if t <: Union{Number, Missing, Nothing}
            data[k] = Parsers.parse(Float64, data[k])
        end
    end
    data
end

function construct_error(T::DataType, d)
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

# Generic read that throws nice errors, more specific version
# for HTTP parameters defined in io.jl
function read(d, T::DataType)

    if d isa Union{AbstractString, AbstractArray{UInt8}, IO}
        d = JSON3.read(d)
    end

    try
        StructTypes.constructfrom(T, d)
    catch e
        maybe_e = construct_error(T, d)
        if isnothing(e)
            rethrow(e)
        else
            throw(maybe_e)
        end
    end
end