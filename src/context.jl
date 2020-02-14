using HTTP: Request
using HTTP.URIs: URI

struct Context
    request::Request
    query_params::Dict{Symbol,String}
    path_params::Dict{Symbol,String}
    uri::URI
end

function query_params(uri::URI)

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

function path_params(uri::URI, matched_path::Array) 
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

function Context(request::Request, uri::URI, matched_path::Array)
    path = String(uri.path)
    r_params = isempty(matched_path) ? Dict() : path_params(uri, matched_path)
    q_params = isempty(matched_path) ? Dict() : query_params(uri)
    Context(request, q_params, r_params, uri)
end