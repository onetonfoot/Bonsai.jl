# Bonsai

[![][action-img]][action-url]
[![codecov](https://codecov.io/gh/onetonfoot/Bonsai.jl/branch/master/graph/badge.svg?token=96CcO21IsK)](https://codecov.io/gh/onetonfoot/Bonsai.jl)

[action-img]: https://github.com/onetonfoot/Bonsai.jl/actions/workflows/ci.yaml/badge.svg
[action-url]: https://github.com/onetonfoot/Bonsai.jl/actions

This project is still in early development 
and many of the features rely on `HTTP.jl` master branch 
so use with caution.

# Handlers

Each handler is a function with the signature `f(stream::HTTP.Stream)`.
The handler can read and write data from the stream using `Bonsai.read` and `Bonsai.write`. 

## Reading 

Use `Bonsai.read` and a wrapper type
`Body`, `Query`, `Headers` or `PathParams` to specify the location
or the data.  The data type being read must have a `StructType` defined or be a `AbstractDict` or `NamedTuple`.


### All

```julia
using Bonsai
using StructTypes: @Struct

@Struct struct JsonPayload
    x::Int
    y::Float
    z::String
end

app.get("/") do stream
    payload = Bonsai.read(stream, Body(JsonPayload))
end

# blocks until server stops running
start(app)
```

Kwargs constructors exist for the wrapper types which can be used to return a `NamedTuple`

### Headers

```julia
app.get("/") do stream
    headers = Bonsai.read(stream, Headers(content_type=String))
    if headers.content_type == "application/json"
        # write some json
    else
        # do something else
    end
end
```

For `Headers` the keys will be transformed using `Bonsai.headerize` and 
the matching is case insensitive.

```julia
Bonsai.headerize(:content_type)
# "content-type"
```

## Writing

In a similar manner data can be written using `Bonsai.write`

```julia
app.get("/") do stream
    Bonsai.write(
        stream, Body(
            x = 1,
            y = 2
        )
    )
end
```

You can overide mime type for type in `Body(::T)` to also set the correct `Content-Type` header, during writing. For example

```julia
Bonsai.mime_type(::MyType) = "text/plain"
```

This is already defined for the following

* NamedTyple - application/json
* AbstractString - text/plain
* StructType(::T) - applicaiton/json
* AbstractPath - Will attempt to set the correct mime_type base on the file extension


## Websockets

A web sockets can be obtained using `ws_upgrade`, bellow is an example of a echo socket.

```julia
app.get("/ws") do stream
    ws = Bonsai.ws_upgrade(stream)
    try
        while !eof(ws)
            data = readavailable(ws)
            s = String(data)
            write(ws, s)
        end
    catch e
        @error e
    finally
        close(ws)
    end
end
```

# Routing

Routing relies on the router from `HTTP`, as such the functionality is the same (see the copied doc stings bellow).

The following path types are allowed for matching:
  * `/api/widgets`: exact match of static strings
  * `/api/*/owner`: single `*` to wildcard match any string for a single segment
  * `/api/widget/{id}`: Define a path variable `id` that matches any valued provided for this segment; path variables are available in the request context like `req.context[:params]["id"]`
  * `/api/widget/{id:[0-9]+}`: Define a path variable `id` that only matches integers for this segment
  * `/api/**`: double wildcard matches any number of trailing segments in the request path; must be the last segment in the path

The type `PathParams`  can be used to obtain the variables.

# Middleware 

Middleware is a function of the form `f(stream::HTTP.Stream, next)`, where `next` is the following handler/middleware in the stack. Bellow the middleware logs the time taken for each request.

```julia
app = App()

app.get("**") do stream, next
    x = now()
    next(stream)
    elapsed = now() - x
    @info "$(stream.message.target) took $elapsed" 
end

app.get("/") do stream
	Bonsai.write(s, Body("Hello"))
end

start(server)
```

# OpenAPI

An open api spec can be generated for a `App` which can be used with tools like [Swagger UI](https://swagger.io/tools/swagger-ui/), to generate documentation.

```julia
app = App()

# add some handlers

open_api = OpenApi(app)
JSON3.write("open-api.json", open_api)
```

[JET](https://github.com/aviatesk/JET.jl) is used to analyze the code and detects all of the `Bonsai.read` and `Bonsai.write` calls, this information is then used to create the spec.

# Example

Please see the `examples` folder for more in depth examples