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