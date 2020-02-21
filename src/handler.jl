using Cassette
using HTTP.Messages: Request


# TODO consider overiding == to compared structs fn field

struct Handler 
    fn::Function
end

(handler::Handler)(request::Request) = handler.fn(request)

Cassette.@context HandlerCtx

function Cassette.prehook(::HandlerCtx, fn, arg::Request) 
    println("________________")
    println("PRE: ", fn, arg)
    println("________________")
end

# function Cassette.posthook(::HandlerCtx, output, fn, args...) 
#     println("________________")
#     println("POST: ", fn, args...)
#     println("output: $output")
#     println("________________")
#     output
# end