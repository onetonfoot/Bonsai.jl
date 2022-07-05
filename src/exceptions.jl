
export NoHandler, DataMissingKey

struct NoHandler <: Exception
    stream::Stream
end

function Base.show(io::IO, e::NoHandler)
    print(
        io,
        "NoHandler(method=$(e.stream.message.method), target=$(e.stream.message.target))",
    )
end

struct MissingCookies{T} <: Exception
    t::Type{T}
    k::Vector{String}
end

struct MissingHeaders{T} <: Exception
    t::Type{T}
    k::Array{String}
end

struct DataMissingKey{T} <: Exception
    t::Type{T}
    struct_keys::Array{Symbol}
    data_keys::Array{Symbol}
end

function Base.show(io::IO, e::DataMissingKey)
    println(io, "DataMissingKey:")
    println(io, "  Expected - $(e.struct_keys)")
    print(io, "  Given    - $(e.data_keys)")
end
