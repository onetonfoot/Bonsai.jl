using HTTP.URIs: URI
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

    for str in split(String(uri.query), "&")
        key, value = split(str, "=")
        dict[Symbol(key)] = value
    end
    dict
end

function json_payload(request::Request; parser=JSON.parse)
    @assert request.method === POST "Method not post"
    copy(request.body) |> String |> parser
end


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
