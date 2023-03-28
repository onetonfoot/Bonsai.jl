using Bonsai

using Sockets
using Sockets: InetAddr
using Base.Meta: show_sexpr

using Bonsai.StructTypes,
    Bonsai.HTTP,
    Bonsai.JSON3,
    Bonsai.AbstractTrees,
    Bonsai.HTTP.Messages

import Bonsai.StructTypes: StructType


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
# currently broken
# include("server.jl") 