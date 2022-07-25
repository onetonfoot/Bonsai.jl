# Bonsai

[![][action-img]][action-url]
[![codecov](https://codecov.io/gh/onetonfoot/Bonsai.jl/branch/master/graph/badge.svg?token=96CcO21IsK)](https://codecov.io/gh/onetonfoot/Bonsai.jl)

[action-img]: https://github.com/onetonfoot/Bonsai.jl/actions/workflows/ci.yaml/badge.svg
[action-url]: https://github.com/onetonfoot/Bonsai.jl/actions

This project is still in early development and likely to change pre 1.0
```
]add Bonsai
```

# Intro

A short intro

```julia
using Bonsai

app = App()

app.get("/") do stream
    Bonsai.write(stream, Body("Hi"))
end

start(app)
```


# Handlers

Each handler is a function with the signature `f(stream::HTTP.Stream)`.
The handler can read and write from the stream using either `Bonsai.read` or `Bonsai.write`, and a wrapper type (`Body`, `Query`, `Headers` or `Params`) to specify the location. The data type being read / written should have a [StructType](https://juliadata.github.io/StructTypes.jl/stable/) defined or be a `AbstractDict` or `NamedTuple`.

## Body

```julia
@Struct struct JsonPayload
    x::Int
    y::Float
    z::String
end

app.get("/") do stream
    payload = Bonsai.read(stream, Body(JsonPayload))
end
```

If you don't want to define a `struct` for you payload, instead you can use a
keyword constructor, this will read data into a named tuple.

```julia
payload = Bonsia.read(stream, Body(x=Int, y=Float, z=String))
```

Writing data is similar. 

```julia
Bonsia.write(stream, Body(x=1, y=1.0, z="hi"))
```

The write will try to set the correct content-type header for the data, however this can be changed if needed by over writting `mime_type`

```julia
Bonsai.mime_type(::MyType) = "text/plain"
```

The content type is defined for the following types already

* `Union{NamedTuple, AbstractDict}` - application/json
* `AbstractString` - text/plain
* `AbstractPath` - Will attempt to set the correct content type based on the file extension.


## Files

Writing files supports `AbstractPaths` defined in [FilePaths](https://github.com/rofinn/FilePaths.jl). The content type will be set based on the file extension.

```julia
file =  Path("data/some-file.json")
Bonsai.write(stream, Body(file))
```

A nice feature of this is we can easily use other `AbstractPath` implementations for example like that in [AWSS3](https://github.com/JuliaCloud/AWSS3.jl)

```julia
file = S3Path("s3://my.bucket/test1.txt") 
Bonsai.write(stream, Body(file))
```

## Headers

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

## Query and Path Parameters

Like the rest just use a wrapper combined with a type. 

```julia
app.get("/car/:id") do stream
    query = Bonsai.read(stream, Query(color = Union{Nothing, String}))
    params = Bonsai.read(stream, Params(id = Int))
end
```

To handle optional types you can use `Union{Nothing, String}`. 


## Web sockets

A web sockets can be obtained using `ws_upgrade`, bellow is an example of a echo socket.

```julia
app.get("/ws") do stream
    ws_upgrade(stream) do ws
        for msg in ws
            @info msg
            send(ws, msg)
        end
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

# Middleware 

Middleware is a function of the form `f(stream::HTTP.Stream, next)`, where `next` is the following handler/middleware in the list. The bellow the middleware logs the time taken for each request.

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

Middleware is called in the order it was added, with the matching handler (if any) called last.

# OpenAPI / Swagger

An open api spec can be generated for a `App` which can be used with tools like [Swagger UI](https://swagger.io/tools/swagger-ui/), to generate documentation.

```julia
open_api = OpenApi(app)
JSON3.write("open-api.json", open_api)
```

[JET](https://github.com/aviatesk/JET.jl) is used to analyze the code and detects all of the `Bonsai.read` and `Bonsai.write` calls, this information is then used to create the spec.

# Example

Please see the `examples` folder for more in depth examples