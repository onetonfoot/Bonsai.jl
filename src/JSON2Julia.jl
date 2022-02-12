module JSON2Julia

using HTTP, JSON3, StructTypes, Dates, LRUCache, FilePaths
import HTTP: Request, Response, Stream
import FilePathsBase: /

include("mime_types.jl")
include("path.jl")
include("http.jl")
include("router.jl")
include("middleware.jl")
include("file_cache.jl")
include("server.jl")

export write_types

function write_types(json_data; mutable = false)
    file = tempname()
    JSON3.writetypes(
        json_data, file,
        module_name = :Module1, mutable = mutable
    )
    return file
end

write_file = Static(Path(@__DIR__) / "../frontend/dist/", exclude=r"node_modules")

function index_handler(stream::Stream)
    write_file(stream, "index.html")
end

function file_handler(stream::Stream)
    filename = stream.message.target
    write_file(stream, filename)
end

struct Payload
    mutable::Bool
    json::Dict
end

StructType(::Type{Payload}) = StructTypes.Struct()
read_payload = Body(Payload)

function api_handler(req::Request)
    data = read_payload(req)
    println(data)
    file = write_types(JSON3.write(data.json), mutable = data.mutable)
    content = read(file, String)
    return Response(
        200,
        body=content
    )
end

function timer(stream, next)
    x = now()
    next(stream)
    elapsed = now() - x
    @info stream.message.target elapsed
end

function main()
    router = Router()
    register!(router, "/", GET, index_handler)
    register!(router, "/api", POST, api_handler)
    register!(router, "*", GET, file_handler)
    middleware!(router, timer)
    start(router)
end

end # module
