include("trie.jl")

const GET     = "GET"
const POST    = "POST"
const PUT     = "PUT"
const PATCH   = "PATCH"
const DELETE  = "DELETE"
const OPTIONS = "OPTIONS"
const WS = "WS"

mutable struct Router
    routes::Dict{String,Trie{Handler}}
end

function Router()
    Dict{String,Trie{Handler}}(
        GET     => Trie{Handler}(),
        POST    => Trie{Handler}(),
        PUT     => Trie{Handler}(),
        PATCH   => Trie{Handler}(),
        DELETE  => Trie{Handler}(),
        OPTIONS => Trie{Handler}(),
        WS => Trie{Handler}()
    ) |> Router
end

function (router::Router)(handler::Function, path::AbstractString; method = GET)
    !isvalidpath(path) && error("Invalid path: $path")
    routes = router.routes[method]
    routes[path] = Handler(handler)
    @assert has_handler(routes, path)
    path
end

function isvalidpath(path::AbstractString)
    # TODO this isn't the most robust will let things like "//" pass
    # https://stackoverflow.com/questions/4669692/valid-characters-for-directory-part-of-a-url-for-short-links
    re = r"^[/a-zA-Z0-9-_.-~!$&'()*+,;@]+$"
    m = match(re, path)
    uri = URI(path)
    m !== nothing && m.match == path && uri.path == path
end