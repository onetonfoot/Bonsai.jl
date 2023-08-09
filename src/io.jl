using Base.Core
using StructTypes
import JET:
    JET,
    @invoke,
    isexpr

using HTTP: Stream, Response, Request
using FilePathsBase: AbstractPath
import Parsers

# current implementation is hacked together from the JET examples without much
# understanding of how JET really works. Nevertheless it does the job but
# at a later date this should probably be cleaned up. 

# At some point read this to better understand the abstract compiler interface
# https://github.com/JuliaLang/julia/blob/master/base/compiler/types.jl

# Avoid kwargs in write due as it makes the analysis more complicated
# https://github.com/JuliaLang/julia/issues/9551
# https://discourse.julialang.org/t/untyped-keyword-arguments/24228
# https://discourse.julialang.org/t/closure-over-a-function-with-keyword-arguments-while-keeping-access-to-the-keyword-arguments/15574

# const default_status = Status(:default)

function write(res::Response, headers::Headers{T}) where {T}
    val = headers.val
    if !isnothing(val)
        for (header, value) in zip(fieldnames(val), fieldvalues(val))
            HTTP.setheader(res, headerize(header) => value)
        end
    end
end

function write(res::Response, data::Body{T}) where {T}
    if StructTypes.StructType(T) == StructTypes.NoStructType()
        error("Unsure how to write type $T to stream")
    else
        # what is you wanted to write null to the body?
        if !isnothing(data.val)
            b = IOBuffer()
            JSON3.write(b, data.val, allow_inf=true)
            res.body = take!(b)
        end

        m = mime_type(T)
        if !isnothing(m)
            write(res, Headers(content_type=m))
        end
    end
end

function write(res::Response, data::Body{T}) where {T<:AbstractPath}
    body = Base.read(data.val)
    res.body = body
    m = mime_type(data.val)
    if !isnothing(m)
        write(res, Headers(content_type=m))
    end
end

function write(stream::Stream, data...)
    for i in data
        write(stream.message.response, i)
    end
end
write(res::Response, ::Status{T}) where {T} = res.status = Int(T)
write(res::Response, ::Status{:default}) = res.status = 200

# This function could be the entry point for the static analysis writes
# allow us to group together headers and status codes etc
function write(res::Response, args...)
    # ensures that status codes are always written last
    # this is needed so that group by status code works
    # correctly for 
    args = sort([args...], by=x -> x isa Status)
    for i in args
        write(res, i)
    end
end

# This is super hacky but splatting breaks JET interfence so instead 
# this stupid hack should suffice for now 
read(stream::Stream, a, b) = (read(stream, a), read(stream, b))
read(stream::Stream, a, b, c) = (read(stream, a), read(stream, b), read(stream, c))
read(stream::Stream, a, b, c, d) = (read(stream, a), read(stream, b), read(stream, c), read(stream, d))
read(stream::Stream, a, b, c, d, e) = (read(stream, a), read(stream, b), read(stream, c), read(stream, d), read(stream, e))
read(stream::Stream, a, b, c, d, e, f) = (read(stream, a), read(stream, b), read(stream, c), read(stream, d), read(stream, e), read(stream, f))
read(stream::Stream, a, b, c, d, e, f, g) = (read(stream, a), read(stream, b), read(stream, c), read(stream, d), read(stream, e), read(stream, f), read(stream, g))

# This results in method ambiguties
# function read(stream::Stream, tail...)
#     tuple([read(stream, i) for i in tail]...)
# end

# messagetoread(http::Stream{<:Response}) = http.message.
# messagetoread(http::Stream{<:Request}) = http.message.response
# read(::HTTP.Streams.Stream{A, B}, ::Union{DataType, UnionAll}) where {A<:HTTP.Messages.Request, B} =

read(stream::Stream{A,B}, b) where {A<:Request,B} = read(stream.message, b)
# we need to be explit here to allow JET analysis to work
# read(stream::Stream{<:Request,<:Response}, b::Body{T}) where {T} = read(stream.message, b)
# what does this case handle again :/  mayeb connection ppols?
# read(stream::Stream{A,B}, b) where {A<:Request,B} = read(stream.message, b)
read(req::Request, ::Body{T}) where {T} = read(req.body, T)

function read(req::Request, ::Route{T}) where {T}
    d = req.context[:params]
    convert_numbers!(d, T)
    return read(d, T)
end

function read(req::Request, ::Query{T}) where {T}
    q::Dict{Symbol,Any} = Dict(Symbol(k) => v for (k, v) in queryparams(req.url))
    convert_numbers!(q, T)
    read(q, T)
end

function read(req::Request, ::Headers{T}) where {T}
    fields = fieldnames(T)
    d = Dict{Symbol,Any}()

    for i in fields
        h = headerize(i)
        if HTTP.hasheader(req, h)
            d[i] = HTTP.header(req, h)
        end
    end

    convert_numbers!(d, T)
    read(d, T)
end