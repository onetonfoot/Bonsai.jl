using StructTypes, URIs
import StructTypes: StructType, NoStructType
import Base: |, ==

export Query, Body, HttpPath, 
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
		TRACE
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
(==)(::Patch, b) = b == "PATCH" || b == :TRACE

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

# https://www.juliabloggers.com/the-emergent-features-of-julialang-part-ii-traits/

function (query::Query{T})(req::Request)::T where T
	try
		q = queryparams(URI(req.target))
		JSON3.read(q, T)
	catch e
		@error "Failed to convert query into $T"
		rethrow(e)
	end
end

function (body::Body{T})(req::Request)::T where T
	try
		JSON3.read(req.body, T)
	catch e
		@error "Failed to convert body into $T"
		rethrow(e)
	end
end

response(req::Request)::Response = req.response