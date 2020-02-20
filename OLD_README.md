# Tree

[![Build Status](https://travis-ci.com/onetonfoot/Tree.svg?branch=master)](https://travis-ci.com/onetonfoot/Tree)
[![codecov](https://codecov.io/gh/onetonfoot/Tree/branch/master/graph/badge.svg)](https://codecov.io/gh/onetonfoot/Tree)


Tree aims to provides a simple API to make writing HTTP servers quick and easy.

# Introduction

The simplest usecase would be

```julia
router = Router()

router("/hello") do ctx
    "Hello"
end

server = http_serve(router)
```

This will start a serve on localhost on port 8081;


# Routing


Routes can be matched in two ways, absoulute or using path parameters.

## Absolute

```julia
router("/chicken/") do ctx
    "Fried chicken is great!"
end

router("/fish/") do ctx
    "But fish is healther"
end

# This would match  /chicken/ and /fish/
```

## Path Parameters

You can match variable routes using the bellow syntax

```julia
router("/hello/:someone") do ctx
    "Jello!"
end

# This would match
# /hello/bob
# /hello/john
# /hello/mark
```

You can access the path paramters with `ctx.path_params`

```julia
# GET request to 
# /hello/bob

ctx.path_params
# Dict(:someone => "bob")
```

If ambigous routes are provided the router will chuck an error.


```julia
router("/hello/:someone") do ctx
    "Jello!"
end

router("/hello/:someone_else") do ctx
    "Jello!"
end

# Error Ambiogous Route!
```

## Query Parameters

Query params can be accessed in the same way.

```julia
# GET request to /rice?and=peas
ctx.query_params
# Dict(:and => "peas")
```

 (path) you can use the ctx struct, which looks like. 


## Context Struct


If you need more data about the request, you can access the request object and URI from the context struct which looks like


```julia
struct Context
    request::Request
    query_params::Dict{Symbol,String}
    path_params::Dict{Symbol,String}
    uri::URI
end
```

# Reponses

Each route should define a function that returns a response object. 


## Create Response

By default `AbstractString`

```julia
function create_response(data::AbstractString)
    response = Response(data)
    HTTP.setheader(response, "Content-Type" => "text/html")
    response
end
```

For find grained control you can override `create_response`,
for your Type.


```julia
function create_response(data::MyType)::Reponse
    # Consturcts a repsonse 
    response
end
```

## Other request types POST, DELETE, etc.

For example if we had a server with the following router

```julia
router("/rice") do ctx
    ctx.query_params[:and] == "peas"
end
```

And we issued a requets like

```julia
HTTP.get("http://localhost:8081/rice?and=peas")
```

The context would contain


```julia
ctx.query_params 

```

For more examples see the examples folder


# Future plans

Need to add support for serving static files.

It would be nice to add better support for web sockets however this will have wait until this [issue](https://github.com/JuliaWeb/HTTP.jl/issues/474) is resolved.


Some form of middleware would also be great but currently I can't think of a great way to implement this, suggestions are welcome!


