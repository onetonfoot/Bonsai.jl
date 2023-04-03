module Bonsai

# This is needed for hot reloading to work correctly
__revise_mode__ = :eval
using Revise

using HTTP, JSON3, StructTypes, Dates, FilePaths, SnoopPrecompile
import HTTP: Request, Response, Stream

include("compose.jl")
include("utils.jl")
include("http.jl")
include("mime_types.jl")
include("exceptions.jl")
include("json_schema.jl")
include("macros.jl")
include("handlers.jl")
include("io.jl")
include("static_analysis.jl")
include("cancel_token.jl")
include("middleware.jl")
include("openapi.jl")
include("app.jl")
include("router.jl")
include("web_socket.jl")
include("certs.jl")
include("server.jl")

precompile() = include("precompile.jl")
@precompile_all_calls precompile()

end