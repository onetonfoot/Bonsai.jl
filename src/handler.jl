using HTTP.Messages: Request
using HTTP.URIs: URI, queryparams
using HTTP.Messages: Request
using Cassette

include("context.jl")

Cassette.@context HandlerCtx

struct Handler 
    # TODO consider overiding == to compared structs fn field
    fn::Function
end

struct HandlerMetadata
    route::Array
end

(handler::Handler)(request::Request) = handler.fn(request)


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


url(req::Request) = URI(req.target)


function query_params(req::Request)
    uri = url(req)
    dict = Dict{Symbol,String}()

    if isempty(uri.query)
        return dict
    end

    for (key, value) in queryparams(uri)
        dict[Symbol(key)] = value
    end
    dict
end

function json_payload(request::Request; parser=JSON.parse)
    @assert request.method === POST "Method not post"
    copy(request.body) |> String |> parser
end