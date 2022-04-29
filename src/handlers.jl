import FilePathsBase: /
using Base.Libc

export Folder

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
    lru::LRU{String,Array{UInt8}}
end

function Folder(path::T; maxsize = 1000, exclude=r".*") where T <: AbstractPath
    Folder{T}(
        normalize(path), 
        LRU{String,Array{UInt8}}(maxsize = maxsize)
    )
end


function (folder::Folder{T})(stream::HTTP.Stream) where T
    folder(stream, stream.message.target)
end

function (folder::Folder{T})(io, file; strict=true) where T

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

