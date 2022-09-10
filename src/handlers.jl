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
end

mutable struct HttpHandler  <: AbstractHandler
	fn
end

function fn(io, file; strict=true) 
    if file isa AbstractString
        file = T(file)
    end


    try 

        if !isfile(file)
            @warn "File not found $file"
                # the http server errors if we write a empty string
            Bonsai.write(io, "File not found", ResponseCodes.NotFound())
            return 
        end

        body = Base.read(file)

        # disable caching util we can implement it more robustly

        # body = get!(folder.lru, file_str) do
        #     read(file)
        # end

        Base.write(io, body)

        if io isa HTTP.Stream
            HTTP.setheader(io, "Content-Type" => mime_type(file))
        end
    catch e 
        # I'm unsure if the error codes are the same on windows
        # https://www.thegeekstuff.com/2010/10/linux-error-codes/
        if e isa SystemError && e.errnum == Libc.ENOENT && io isa HTTP.Stream
            @warn e
        else
            rethrow(e)
        end
    end
end