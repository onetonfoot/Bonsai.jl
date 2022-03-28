using StructTypes, URIs, HTTP.Messages, HTTP.Cookies

import StructTypes: StructType, NoStructType
import Base: |, ==

export Header, Query, Body, HttpPath, InvalidHeader, MissingHeader,
	GET, POST, PUT, DELETE, OPTIONS, CONNECT, TRACE, PATCH, ALL

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

(==)(a, b::Tuple{Vararg{HttpMethod}}) = b == a
function (==)(a::Tuple{Vararg{HttpMethod}}, b) 
	for i in a 
		if i == b
			return true
		end
	end
	return false
end

struct InvalidCookie <: Exception
	k::String
end

struct MissingCookie <: Exception
	k::String
end

Base.@kwdef struct Cookie
	# ::Cookie -> ::Bool
	fn::Function
	k::String
	required::Bool = true
end

function Cookie(fn::Function, k::AbstractString; required=true)
	Cookie(fn, k, required)
end

function Cookie(k::AbstractString; required=true)
	function fn(value)
		true
	end
	Cookie(fn, k, required)
end

function (c::Cookie)(stream)

	hs = headers(stream)
	cs = Cookies.readcookies(hs, c.k)
	present = !isempty(cs)

	if present
		value = cs[1]
		valid = c.fn(value)

		if !valid 
			throw(InvalidCookie(c.k))
		end

		return value
	else

		if c.required 
			throw(MissingCookie(c.k))
		end

		return nothing
	end
end


struct InvalidHeader <: Exception
	k::String
end

struct MissingHeader <: Exception
	k::String
end

function show(io::IO, e::MissingHeader)
	print(io, "Missing header for $(e.k)")
end

function show(io::IO, e::MissingHeader)
	print(io, "Invalid header for $(e.k)")
end

Base.@kwdef struct Header
	# ::String -> ::Bool
	fn::Function
	k::String
	required::Bool = true
end

function Header(fn::Function, k::AbstractString; required=true)
	Header(fn, k, required)
end

function Header(k::AbstractString; required=true)
	function fn(value)
		true
	end
	Header(fn, k, required)
end

function (h::Header)(stream)
	present = hasheader(stream, h.k)

	if present
		value = header(stream, h.k)
		valid = h.fn(value)

		if !valid 
			throw(InvalidHeader(h.k))
		end

		return value
	else

		if h.required 
			throw(MissingHeader(h.k))
		end

		return nothing
	end
end

struct Query{T}
    t::Type{T}
end

# https://www.juliabloggers.com/the-emergent-features-of-julialang-part-ii-traits/

function (query::Query{T})(stream::HTTP.Stream)::T where T
	try
		q::Dict{Any, Any} = queryparams(URI(stream.message.target))

		for (k,v) in q
			if !isnothing(match(r"\d+", v))
				q[k] = parse(Int, v)
			end
		end

		JSON3.read(JSON3.write(q), T)
	catch e
		@debug "Failed to convert query into $T"
		rethrow(e)
	end
end

struct Body{T} 
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