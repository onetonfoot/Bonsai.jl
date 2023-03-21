using JSON3, StructTypes, Test, Bonsai
using HTTP.Messages
using Sockets
using Sockets: InetAddr
import StructTypes: StructType

using Base.Meta: show_sexpr
using AbstractTrees

include("http.jl")
include("utils.jl")
include("handlers.jl")
include("middleware.jl")
include("mime_type.jl")
include("router.jl")
include("io.jl")
include("static_analysis.jl")
include("app.jl")
include("openapi.jl")