# Bonsai

[![Build Status](https://travis-ci.com/onetonfoot/Bonsai.jl.svg?branch=master)](https://travis-ci.com/onetonfoot/Bonsai.jl)
[![Coverage Status](https://coveralls.io/repos/github/onetonfoot/Bonsai.jl/badge.svg?branch=master)](https://coveralls.io/github/onetonfoot/Bonsai.jl?branch=master)

## Getting started

It's as simple as

```julia
app = App()

app("/path"; method = GET) do request
    reponse = "hello"
    return response
end

start(app)
```

Now visit `localhost:8081`.

The handler function takes a `HTTP.Request` and returns a `HTTP.Response`.

After your handler is called if it's return type isn't a `Response` it will be made into one by
calling `create_response`. You can overload `create_reponse` for your specific type to have more control.

```julia
create_response(t::Mytype)::HTTP.Response
```

This is already defined for `AbstractString` and `AbstractDict`, were the Content-Type header is set as `text/plain` and `application/json` respectively.

## Routing and Query Parameters

Routes can be defined for multiple methods by passing an array

```julia
app(handler, "/path"; method = [GET, POST])
```

They can be parametrized by using the syntax `/:x`. You can then access
the parameters in the handler with.

```julia
app("/route/:id", method = [GET, POST]) do request
    params = path_params(request)
    # Dict(:id => value)
end
```

Specific routes will be matched first take priority over variable routes, in other words `"/route/1"` will be matched before `"/route/:id"`. 

Query parameters can be accessed in a similar way.

```julia
query = query_params(request)
```

# Files

To serve a file pass the route and a [file path](https://github.com/rofinn/FilePaths.jl).

```julia
app("/",  p"index.html")
```
The MIME type will be inferred from the extension, the supported MIME types can be found [here](https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/MIME_types/Common_types). If the MIME-type is unsupported it can be added to the global `MIME_TYPES`.

# Folders

You can server folders using the following syntax

```julia
app("/img", p"images"; recursive=true, filter_fn=filepath->true)
```

`filter_fn` can be used to remove files you don't want to be served, it
should return a boolean.

If given a folder of the following structure.

```
images/
├── cat.jpeg
└── dog.jpeg
```

The routes generated would be `img/cat.jpeg` and `img/dog.jpeg`.

# Sessions

When instantiating the app you can pass data structure you want to use for the session, by default this will be a `Dict`.  But could be anything you want to use to store state e.g

```julia
app = App(session = ReidsSession()) 
```

The session can then be accessed in the handler.

```julia
app("/path") do req
    session = app.session
end
```

Since a `Dict` isn't thread-safe so this will likey change in the future to a different data structure, once parallelism is addressed.

# WebSockets

```julia
app(ws"/chat_room") do ws
    while isopen(ws)
        # do stuff
    end
end
```

# Middleware

Still thinking about the nicest way to implement this suggesting are welcome!

# Docker

Yet todo but will probably add a CLI using [Comonicon](https://github.com/Roger-luo/Comonicon.jl), that
can take a Julia project and generate a Dockerfile.

# Examples

For more examples see the `examples` folder.

# Useful Packages

Some packages that you may find useful to pair with `Bonsai`.

- [Octo.jl](https://github.com/wookay/Octo.jl) - a SQL Query DSL
