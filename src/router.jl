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

function (router::Router)(handler, path :: AbstractString; method=GET)
    routes = router.routes[method]
    routes[path] = handler
    path
end


