export Static

import FilePathsBase: /
using Base.Libc

struct Static{T <: AbstractPath} 
    path::T
    lru::LRU{String,Array{UInt8}}
end

function Static(path::T; maxsize = 1000, exclude=r".*") where T <: AbstractPath
    Static{T}(
        normalize(path), 
        LRU{String,Array{UInt8}}(maxsize = maxsize)
    )
end

function (folder::Static{T})(io, file; strict=true) where T

    if file isa AbstractString
        file = T(file)
    end

    # collecting and then splating handles join paths starting the /
    file = normalize(joinpath(folder.path, collect(file)...))
    hasprefix = startswith(string(folder.path))
    file_str = string(file)

    if strict && !hasprefix(file_str)
        error("File above folder")
    end

    try 
        body = get!(folder.lru, file_str) do
            read(file)
        end

        write(io, body)

        if io isa HTTP.Stream
            HTTP.setstatus(io, 200)
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
            HTTP.setstatus(io, 404)
        else
            rethrow(e)
        end
    end
end