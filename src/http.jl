using StructTypes, URIs, HTTP.Messages

import StructTypes: StructType, NoStructType
import Base: |, ==

export Header, Query, Body, HttpPath, 
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

struct Query{T}
    t::Type{T}
end

struct Body{T} 
	t::Type{T}
end

Base.@kwdef struct Header
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
			error("Invalid header value")
		end

		return value
	else

		if h.required 
			error("Missing header $(h.k)")
		end

		return nothing
	end
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

# Not puting a specipic type anotation on stream allows
# for easier tetsing
function (body::Body{T})(stream)::T where T
	try
		JSON3.read(stream, T)
	catch e
		@debug "Failed to convert body into $T"
		rethrow(e)
	end
end

response(req::Request)::Response = req.response