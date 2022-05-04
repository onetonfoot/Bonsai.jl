using StructTypes, URIs, HTTP.Messages
using CodeInfoTools: code_inferred

import StructTypes: StructType, NoStructType
import Base: |, ==

export Headers, Query, Body, PathParams, MissingHeaders, MissingCookies,
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
	val::Union{T, Nothing}
end

function Headers(val)
	Headers(typeof(val), val)
end

function Headers(t::DataType)
	Headers(t, nothing)
end

function Headers(;kwargs...)
	nt = values(kwargs)
	Headers(typeof(nt), nt)
end

struct Query{T} <: HttpParameter
    t::Type{T}
end

struct Body{T} <: HttpParameter
	t::Type{T}
	val::Union{T, Nothing}
end

function Body(val)
	Body(typeof(val), val)
end

function Body(t::DataType)
	Body(t, nothing)
end

function Body(;kwargs...)
	nt = values(kwargs)
	Body(typeof(nt), nt)
end

function parameter_type(t::Type{<:HttpParameter}) 
	t.parameters[1]
end


struct PathParams{T} <: HttpParameter
	t::Type{T}
end

struct MissingCookies{T} <: Exception
	t::Type{T}
	k::Vector{String}
end

struct MissingHeaders{T} <: Exception
	t::Type{T}
	k::Array{String}
end

# https://www.juliabloggers.com/the-emergent-features-of-julialang-part-ii-traits/

function (c::Cookies{T})(stream) where T
	hs = headers(stream)
	cs = HTTP.Cookies.readcookies(hs, "")

	# TODO:
	# support fields other than strings!
	# how to handle additional cookie information such as 
	# maxage, expires e.g
	cookies::Dict{String, Any} = Dict(c.name => c.value for c in cs)
	fields = fieldnames(T)
	d::Dict{Symbol, Any} = Dict( i => 
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

function fieldnames_to_header(T)
	fields = string.(fieldnames(T))
	l = []
	for i in fields
		push!(l, dasherize(i))
	end
	l
end

headerize(s) = dasherize(string(s))