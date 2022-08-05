using StructTypes, URIs, HTTP.Messages
using CodeInfoTools: code_inferred


import StructTypes: StructType, NoStructType
import Base: |, ==
import HTTP

export Headers, Query, Body, Params, Status, MissingHeaders, MissingCookies,
    GET, POST, PUT, DELETE, OPTIONS, CONNECT, TRACE, PATCH, ALL

include("dasherize.jl")

# https://developer.mozilla.org/en-US/docs/Web/HTTP/Status#information_responses
HTTP.statustext(::Val{T}) where T =  HTTP.statustext(Int(T))
HTTP.statustext(::Val{:default}) where T =  HTTP.statustext(200)

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


struct Headers{T} <: HttpParameter
    t::Type{T}
    val::Union{T,Nothing}
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
Query(; kwargs...) = kw_constructor(Query; kwargs...)

struct Body{T} <: HttpParameter
    t::Type{T}
    val::Union{T,Nothing}
end

Body(t::DataType) = Body(t, nothing)
Body(;kwargs...) = kw_constructor(Body; kwargs...)
Body(t) = Body(typeof(t), t)

function parameter_type(t::Type{<:HttpParameter}) 
    # This happens when type inference breaks and we get Params instead or Params{T}
    # hence in this case we will return a empty named tuple
    if t isa UnionAll
        NamedTuple{(), Tuple{}}
    else
        t.parameters[1]
    end
end

# maybe rename RouteParams as Params is so generic? 
# this is the only parameter that doesn't contina all of the information
# required to match from Bonsai.read(req, ::Params) 

struct Params{T} <: HttpParameter
    t::Type{T}
    val::Union{T,Nothing}
end

Params(; kwargs...) = kw_constructor(Params; kwargs...)
Params(t::DataType) = Params(t, nothing)

# https://www.juliabloggers.com/the-emergent-features-of-julialang-part-ii-traits/

struct Cookies{T} <: HttpParameter
    t::Type{T}
end

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

struct Status{T} <: HttpParameter
    val::Union{Int, Symbol}
end

Status(x) = Status{x}(x)