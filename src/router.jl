include("trie.jl")

const GET     = "GET"
const POST    = "POST"
const PUT     = "PUT"
const PATCH   = "PATCH"
const DELETE  = "DELETE"
const OPTIONS = "OPTIONS"

mutable struct Router
    routes :: Dict{String,Trie{Function}}
end

function Router()
    Dict{String,Trie{Function}}(
        GET     => Trie{Function}(),
        POST    => Trie{Function}(),
        PUT     => Trie{Function}(),
        PATCH   => Trie{Function}(),
        DELETE  => Trie{Function}(),
        OPTIONS => Trie{Function}(),
    ) |> Router
end

function (router :: Router)(handler, path :: AbstractString; method=GET)
    !isvalidpath(path) && error("Invalid path: $path")
    routes = router.routes[method]
    routes[path] = handler
    @assert has_handler(routes, path)
    path
end

function isvalidpath(path :: AbstractString)
    # TODO this isn't the most robust will let things like "//" pass
    re = r"^[/.:a-zA-Z0-9-]+$"
    m = match(re, path)
    m != nothing && m.match == path
end