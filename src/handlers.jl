import FilePathsBase: /
using Base.Libc

"""
Has a field fn which takes stream as it's first argument

 fn(stream, ...)
"""
abstract type AbstractHandler end

(handler::AbstractHandler)(args...) = handler.fn(args...)

mutable struct Middleware  <: AbstractHandler 
    fn 
    function Middleware(fn)
        if isnothing(safe_which(fn, Tuple{Any, Any}))
            error("Invalid function signature must match fn(::Stream, next::Any)")
        end
        new(fn)
    end
end

mutable struct HttpHandler  <: AbstractHandler
	fn

    function HttpHandler(fn)
        if isnothing(safe_which(fn, Tuple{Any}))
            error("Invalid function signature must match fn(::Stream)")
        end
        new(fn)
    end
end

function safe_which(fn, args)
    try
        which(fn, args)
    catch
        nothing
    end
end