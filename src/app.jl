import Sockets: TCPServer

include("router.jl")
include("files.jl")

# TODO define show methods
mutable struct App{S}
    router::Router
    session::S
    server::Union{Nothing,TCPServer}
end

# TODO Dict is not thread safe :/ need to find a cross platform soultion
App(;session = Dict()) = App(Router(), session, nothing)

function (app::App)(handler, path, method::AbstractString = GET)     
    app.router(handler, path ; method = method)
end

# TODO needs test case
function (app::App)(handler::Function, path::AbstractString, method::Array)     
    [app.router(handler, path; method = m) for m in method]
end

function (app::App)(folder::Folder; recursive=true, filter=file->true)
end

"""
Args:

* route - the route that the files will be served from
* path - path to the folder to be served

Kw Args:
* recursive - if the folder should be recusively served
* filter - a function which should return a boolean indicating if the file should be served
"""
function (app::App)(route::AbstractString , folder::Folder; recusive=true, filter=file->true)
    # @assert endswith(route, ":file") "route should end with :file for example /images/:file"
end

"""
Args:
* path - path to the file to be served
"""
function (app::App)(path::AbstractPath)
    route = "/$(path.segments[end])"
    app(route, path)
end
"""
Args:
* route - route the file should be served from
* path  - path to the file to be served
"""
function (app::App)(route::AbstractString, path::AbstractPath)
    handler = create_file_handler(path)
    !isfile(path) && @warn "Can't find file $path"
    app.router(handler, route)
end
