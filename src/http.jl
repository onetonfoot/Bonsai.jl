using StructTypes, URIs, HTTP.Messages
using StringCases: dasherize
using CodeInfoTools: code_inferred

import StructTypes: StructType, NoStructType
import Base: |, ==

export Headers, Query, Body, HttpPath, MissingHeaders, MissingCookies,
	GET, POST, PUT, DELETE, OPTIONS, CONNECT, TRACE, PATCH, ALL,
	# Status Codes
	CREATED, Ok

	# https://developer.mozilla.org/en-US/docs/Web/HTTP/Status#information_responses
abstract type ResponseCode end
abstract type SuccessCode end
abstract type InfoCode end

struct Ok <: SuccessCode end
struct Created <: SuccessCode end


const OK = Ok()
const CREATED = Created()

Base.Int(::ResponseCode) = error("todo!")
Base.Int(::Ok) = 200
Base.Int(::Created) = 201

HTTP.statustext(code::ResponseCode) = HTTP.statustext(Int(code))


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


headerize(s::Symbol) = dasherize(string(s))

function (hs::Headers{T})(stream) where T
	fields = fieldnames(T)
	d = Dict()

	# TODO:
	# support fields other than strings!

	for i in fields
		h = headerize(i)
		if HTTP.hasheader(stream, h)
			d[i] = HTTP.header(stream, h)
		else
			d[i] = missing
		end
	end

	@info d

	try
		convert_numbers!(d, T)
		StructTypes.constructfrom(T, d)
	catch e
		rethrow(e)
	end
end

struct Query{T} <: HttpParameter
    t::Type{T}
end

# https://www.juliabloggers.com/the-emergent-features-of-julialang-part-ii-traits/

function (query::Query{T})(stream::HTTP.Stream)::T where T
	try
		q::Dict{Symbol, Any} = Dict(Symbol(k) => v for (k,v) in queryparams(URI(stream.message.target)))
		convert_numbers!(q, T)
		StructTypes.constructfrom(T, q)
	catch e
		@debug "Failed to convert query into $T"
		rethrow(e)
	end
end

struct Body{T} <: HttpParameter
	t::Type{T}
end

# Not puting a specipic type anotation on stream allows
# for easier testing
function (body::Body{T})(stream)::T where T
	try
		JSON3.read(stream, T)
	catch e
		@debug "Failed to convert body into $T"
		rethrow(e)
	end
end

response(req::Request)::Response = req.response

function convert_numbers!(data::AbstractDict, T)
	for (k, t) in zip(fieldnames(T), fieldtypes(T))
		if	t <: Number
			@info t
			data[k] = parse(t, data[k])
		end
	end
	data
end

function http_parameters(f)
	ci = code_inferred(f, Tuple{Stream})
	l = []

	for i in ci.ssavaluetypes
		if i isa Core.Const && i.val isa HttpParameter
			push!(l, i.val)
		end
	end
	l
end