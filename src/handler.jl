using Cassette
using HTTP.Messages: Request


struct Handler 
    # TODO consider overiding == to compared structs fn field
    fn::Function
end

struct HandlerMetadata
    route::Array
end

(handler::Handler)(request::Request) = handler.fn(request)

Cassette.@context HandlerCtx

function Cassette.prehook(ctx::HandlerCtx, fn, arg::Request) 
    # Put pre request middleware here and store and info
    # in the metadata

    nothing
end


path_params(req::Request) = error("overdub failed!")

function path_params(req::Request, matched_path::Array) 
    uri = url(req)
    path = splitpath(String(uri.path))
    @assert length(path) == length(matched_path)
    dict = Dict{Symbol,String}()
    for (key, value) in zip(matched_path, path)
        if key isa Symbol
            dict[key] = value
        end
    end
    dict
end

function Cassette.overdub(ctx::HandlerCtx, ::typeof(path_params), x) 
    path_params(x, ctx.metadata.route)
end