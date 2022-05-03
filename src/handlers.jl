import FilePathsBase: /
using Base.Libc

"""
Has a field fn which takes stream as it's first argument

 fn(stream, ...)
"""
abstract type AbstractHandler end

(handler::AbstractHandler)(args...) = handler.fn(args...)

struct Middleware  <: AbstractHandler 
    fn 
end

struct HttpHandler  <: AbstractHandler
	fn
end

struct Folder{T <: AbstractPath}  <: AbstractHandler
    path::T
    fn

    function Folder(path::T) where T <: AbstractPath

         function fn(io, file; strict=true) 

            if file isa AbstractString
                file = T(file)
            end

            # collecting and then splating handles joining paths starting with /
            file = normalize(joinpath(path, collect(file)...))
            hasprefix = startswith(string(path))
            file_str = string(file)

            if strict && !hasprefix(file_str)
                error("File above folder")
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


        new{T}(
            normalize(path), 
            fn
        )

    end
end

