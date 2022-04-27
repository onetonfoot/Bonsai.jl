using Bonsai, FilePaths
using FilePathsBase: /

static_handler = Static(Path(@__DIR__) / "data")

function index_handler(stream)
    # we can call the handler to write specfic files to the stream
    static_handler(stream ,"index.html")
end

router = Router()
get!(router, "/", index_handler)

# Or use it directly serve all of the files in the data folder
get!(router, "*", static_handler)
start(router, port=10000)

print(router)

main()