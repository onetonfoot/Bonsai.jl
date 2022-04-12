using JSON3, StructTypes, Test, Bonsai
using HTTP.Messages
using Sockets
using Sockets: InetAddr
import StructTypes: StructType

include("http.jl")
include("path.jl")
include("handlers.jl")
include("middleware.jl")
include("router.jl")
include("write.jl")