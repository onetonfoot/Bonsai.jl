import FilePathsBase: /
using Base.Libc

export Static

abstract type AbstractHandler end

(handler::AbstractHandler)(args...) = handler.fn(args...)

struct Middleware  <: AbstractHandler 
    fn 
end

struct HttpHandler  <: AbstractHandler
	fn
end

struct Static{T <: AbstractPath}  <: AbstractHandler
    path::T
    lru::LRU{String,Array{UInt8}}
end

function Static(path::T; maxsize = 1000, exclude=r".*") where T <: AbstractPath
    Static{T}(
        normalize(path), 
        LRU{String,Array{UInt8}}(maxsize = maxsize)
    )
end


function (folder::Static{T})(stream::HTTP.Stream) where T
    folder(stream, stream.message.target)
end

function (folder::Static{T})(io, file; strict=true) where T

    if file isa AbstractString
        file = T(file)
    end

    # collecting and then splating handles joining paths starting with /
    file = normalize(joinpath(folder.path, collect(file)...))
    hasprefix = startswith(string(folder.path))
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

        body = read(file)

        # disable caching util we can implement it more robustly

        # body = get!(folder.lru, file_str) do
        #     read(file)
        # end

        Base.write(io, body)

        if io isa HTTP.Stream
            ext = extension(file)
            if haskey(MIME_TYPES, ext)
                HTTP.setheader(io, "Content-Type" => MIME_TYPES[ext])
            end
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

