module Bonsai

# This is needed for hot reloading to work correctly
__revise_mode__ = :eval
using Revise

using HTTP, JSON3, StructTypes, Dates, FilePaths
import HTTP: Request, Response, Stream

include("utils.jl")
include("mime_types.jl")
include("http.jl")
include("exceptions.jl")
include("json_schema.jl")
include("handlers.jl")
include("io.jl")
include("cancel_token.jl")
include("middleware.jl")
include("openapi.jl")
include("app.jl")
include("router.jl")
include("web_socket.jl")
include("server.jl")
# include("docs.jl")

end