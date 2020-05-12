include("mime_types.jl")
using FilePathsBase, FilePaths
using HTTP

struct Folder
    path::AbstractPath
    function Folder(path) 
        !isdir(path) && @warn "can't find folder $(joinpath(cwd(),path))"
        new(Path(normpath(path)))
    end
end

macro f_str(str)
    Folder(str)
end

#TODO implement 
function safe_path(root, path)
    joinpath(root, path)
end

function create_file_handler(path::AbstractPath)
    function handler(request)
        global MIME_TYPES
        mime_type = extension(path)
        @show request.target
        content_type = mime_type in keys(MIME_TYPES) ? MIME_TYPES[mime_type] : error("Unsupported mime type $mime_type")
        @show content_type
        file = read(path)
        res = Response(file)
        HTTP.setheader(res, "Content-Type" => content_type)
        res
    end
end