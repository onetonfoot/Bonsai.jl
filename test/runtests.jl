using JSON3, StructTypes, Test, JSON2Julia
using HTTP.Messages
using Sockets
using Sockets: InetAddr
import StructTypes: StructType
using JSON2Julia: main


include("http.jl")
include("path.jl")
include("middleware.jl")
include("router.jl")


main()