using HTTP.URIs: URI, queryparams
using HTTP.Messages: Request

# TODO refactor this to remove the Context struct
# instead should overload functions to query_params etc from the request struct

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
