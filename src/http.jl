using StructTypes, URIs, HTTP.Messages
using StringCases: dasherize
using CodeInfoTools: code_inferred

import StructTypes: StructType, NoStructType
import Base: |, ==

export Headers, Query, Body, HttpPath, MissingHeaders, MissingCookies,
	GET, POST, PUT, DELETE, OPTIONS, CONNECT, TRACE, PATCH, ALL


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

String(::HttpMethod) = "get"
String(::Post) = "post"
String(::Put) = "put"
String(::Delete) = "delete"
String(::Connect) = "connect"
String(::Options) = "option"
String(::Trace) = "trace"
String(::Patch) = "patch"

|(a::HttpMethod, b::HttpMethod) = (a, b)
|(a::Tuple{Vararg{HttpMethod}}, b::HttpMethod) = (a..., b)
|(a::HttpMethod, b::Tuple{Vararg{HttpMethod}}) = (a, b...)

const GET = Get()
const POST = Post()
const PUT = Put()
const DELETE = Delete()
const OPTIONS = Options()
const CONNECT = Connect()
const TRACE = Trace()
const PATCH = Patch()
const ALL = GET | POST | PUT | DELETE | OPTIONS | CONNECT | TRACE | PATCH

function Base.convert(::Type{HttpMethod}, x::AbstractString)
	if x == "GET"
		GET
	elseif x == "POST"
		POST
	elseif x == "PUT"
		PUT
	elseif x == "DELETE"
		DELETE
	elseif x == "OPTIONS"
		OPTIONS
	elseif x == "CONNECT"
		CONNECT
	elseif x == "TRACE"
		TRACE
	elseif x == "PATCH"
		PATCH
	else 
		error("$x isn't a http method")
	end
end

(==)(a::Union{AbstractString, Symbol}, b::HttpMethod) = b == a
(==)(::Get, b) = b == "GET" || b == :GET
(==)(::Post, b) = b == "POST" || b == :POST
(==)(::Put, b) = b == "PUT" || b == :PUT
(==)(::Delete, b) = b == "DELETE" || b == :DELETE
(==)(::Options, b) = b == "OPTIONS" || b == :OPTIONS
(==)(::Connect, b) = b == "CONNECT" || b == :CONNECT
(==)(::Trace, b) = b == "TRACE" || b == :TRACE
(==)(::Patch, b) = b == "PATCH" || b == :PATCH

(==)(a::Tuple{Vararg{HttpMethod}} , b::Tuple{Vararg{HttpMethod}}) = b == a

struct MissingCookies{T} <: Exception
	t::Type{T}
	k::Vector{String}
end

struct Cookies{T} <: HttpParameter
	t::Type{T}
end

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

struct MissingHeaders{T} <: Exception
	t::Type{T}
	k::Array{String}
end

function fieldnames_to_header(T)
	fields = string.(fieldnames(T))
	l = []
	for i in fields
		push!(l, dasherize(i))
	end
	l
end

struct Headers{T} <: HttpParameter
	t::Type{T}
end

Header(t::T) where T = Header{T}(t)
headerize(s) = dasherize(string(s))

struct Query{T} <: HttpParameter
    t::Type{T}
end


struct Body{T} <: HttpParameter
	t::Type{T}
end


# https://www.juliabloggers.com/the-emergent-features-of-julialang-part-ii-traits/