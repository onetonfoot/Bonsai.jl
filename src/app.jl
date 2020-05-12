import Sockets: TCPServer

include("router.jl")
include("files.jl")

# TODO define show methods
mutable struct App{S}
    router::Router
    session::S
    server::Union{Nothing,TCPServer}
    server_task::Union{Nothing, Task}
end

# TODO Dict is not thread safe :/ need to find a cross platform soultion
App(;session = Dict()) = App(Router(), session, nothing, nothing)

function (app::App)(handler, path, method::AbstractString = GET)     
    app.router(handler, path ; method = method)
end

# TODO needs test case
function (app::App)(handler::Function, path::AbstractString, method::Array)     
    [app.router(handler, path; method = m) for m in method]
end


"""
Args:
* path - path to the file to be served
"""
(app::App)(path::AbstractPath) = app("/$(path.segments[end])", path)

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

"""
Args:

* route - the route that the files will be served from
* path - path to the folder to be served

Kw Args:
* recursive - if the folder should be recusively served
* filter_fn(path::Path)::Boolean - a function which should return a Boolean indicating if the file should be served
"""
function (app::App)(route::AbstractString , folder::Folder; recursive=true, filter_fn=file->true)

    files = if recursive
        files = filter(filter_fn, collect(walkpath(folder.path)))
        filter!(isfile, files)
    else
        files = map(x ->folder.path / x,  readdir(folder.path))
        filter!(filter_fn, files)
        filter!(isfile, files)
    end

    routes = map(files) do file
        replace(string(file), Regex("^" * string(folder.path)) => route)
    end

    for (route, file) in zip(routes, files)
        app(route, file)
    end
end