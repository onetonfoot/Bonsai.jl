using Bonsai, FilePaths
using FilePathsBase: /


static_handler = Static(Path(@__DIR__))

function index_handler(stream) 
	static_handler(stream, "data/index.html")
end

function data_handler(stream) 
	file = stream.method.target
	static_handler(stream, joinpath("data", file))
end

function main()
    router = Router()
    get!(router, "data", data)
    get!(router, "*", index)
    wait(start(router))
end


main()