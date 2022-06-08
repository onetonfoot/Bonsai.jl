using StructTypes, URIs, HTTP.Messages
using CodeInfoTools: code_inferred

import StructTypes: StructType, NoStructType
import Base: |, ==

export Headers, Query, Body, Params, MissingHeaders, MissingCookies,
    GET, POST, PUT, DELETE, OPTIONS, CONNECT, TRACE, PATCH, ALL

include("dasherize.jl")


abstract type HttpParameter end

abstract type HttpMethod end
struct Get <: HttpMethod end
struct Post <: HttpMethod end
struct Put <: HttpMethod end
struct Delete <: HttpMethod end
struct Connect <: HttpMethod end
struct Options <: HttpMethod end
struct Trace <: HttpMethod end
struct Patch <: HttpMethod end
struct All <: HttpMethod end

Base.String(::HttpMethod) = "get"
Base.String(::Post) = "post"
Base.String(::Put) = "put"
Base.String(::Delete) = "delete"
Base.String(::Connect) = "connect"
Base.String(::Options) = "option"
Base.String(::Trace) = "trace"
Base.String(::Patch) = "patch"
Base.String(::All) = "*"

const GET = Get()
const POST = Post()
const PUT = Put()
const DELETE = Delete()
const OPTIONS = Options()
const CONNECT = Connect()
const TRACE = Trace()
const PATCH = Patch()
const ALL = All()

struct Cookies{T} <: HttpParameter
    t::Type{T}
end

struct Headers{T} <: HttpParameter
    t::Type{T}
    val::Union{T,Nothing}
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

Headers(;kwargs...) = kw_constructor(Headers; kwargs...)
Headers(t::DataType) =  Headers(t, nothing)

function fieldnames_to_header(T)
    fields = string.(fieldnames(T))
    l = []
    for i in fields
        push!(l, dasherize(i))
    end
    l
end

headerize(s) = dasherize(string(s))

struct Query{T} <: HttpParameter
    t::Type{T}
    val::Union{T,Nothing}
end

Query(t::DataType) = Query(t, nothing)
Query(; kwargs...) = kw_constructor_data_type(Query; kwargs...)

struct Body{T} <: HttpParameter
    t::Type{T}
    val::Union{T,Nothing}
end

Body(t::DataType) = Body(t, nothing)
Body(;kwargs...) = kw_constructor(Body; kwargs...)
Body(t) = Body(typeof(t), t)

function parameter_type(t::Type{<:HttpParameter})
    t.parameters[1]
end


struct Params{T} <: HttpParameter
    t::Type{T}
    val::Union{T,Nothing}
end

Params(; kwargs...) = kw_constructor_data_type(Params; kwargs...)
Params(t::DataType) = Params(t, nothing)

# https://www.juliabloggers.com/the-emergent-features-of-julialang-part-ii-traits/

function (c::Cookies{T})(stream) where {T}
    hs = headers(stream)
    cs = HTTP.Cookies.readcookies(hs, "")

    # TODO:
    # support fields other than strings!
    # how to handle additional cookie information such as 
    # maxage, expires e.g
    cookies::Dict{String,Any} = Dict(c.name => c.value for c in cs)
    fields = fieldnames(T)
    d::Dict{Symbol,Any} = Dict(i =>
        get(cookies, string(i), missing)
                               for i in fields
    )

    try
        convert_numbers!(d, T)
        StructTypes.constructfrom(T, d)
    catch e
        rethrow(e)
    end
end
