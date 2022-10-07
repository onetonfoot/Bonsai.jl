"""
Has a field fn which takes stream as it's first argument

fn(stream, ...)
"""
abstract type AbstractHandler end

(handler::AbstractHandler)(args...) = handler.fn(args...)

mutable struct Middleware  <: AbstractHandler 
    fn 
    function Middleware(fn)
        new(fn)
    end
end

mutable struct HttpHandler  <: AbstractHandler
	fn

    function HttpHandler(fn)
        new(fn)
    end
end