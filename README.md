# Bonsai

## Getting started

Create a instance of the app, add a route then starting the server

```julia
app = App()

app("/path"; method = GET) do request
    reponse = "hello"
    return response
end

start(app)
```

Now vist `localhost:8081`.

The handler function should take a `HTTP.Request` and return a `HTTP.Response`.
If the return type isn't a `Response` then it will be made into one by `create_response`, you can
overload this function for any type from more control.

## Routing and Query Parameters

Routes can be defined for multiple methods by passing an array

```julia
app(handler, "/path"; method = [GET, POST])
```

Routes can be parametrized by using the syntax `/:x`. You can then access
the parameters in the handler with.

```julia
app("/route/:id", method = [GET, POST]) do request
    params = path_params(request)
    # Dict(:id => value)
end
```

Specific routes will be matched first, in other words `"/route/1"` will be matched before `"/route/:id"`.
Query parameters can be accessed in a similar way.

```julia
query = query_params(request)
```

Specific routes like `/path` take priority over variable routes such as `/:path`.

# Serving Files

## Files

To serve a single file from `"/index.html"`. 

```julia
app(p"index.html")
```

By default the file will be served from the index, but you can specify a route with.

```julia
app("/page", p"page.html")
```

The mime type will be infered from the extension, the supported mime type can be found [here](https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/MIME_types/Common_types). If the mime type is 
unsuported it can be added to the global `MIME_TYPES`.

## Folders

Serving folders

```julia
app(f"images")
```

Serving from a specific route

```julia
app("/img", f"images")
```

## Create Response

After your your handler is called if it's return type isn't a `Response` it will be made into one by
calling `create_response`. You can overload `create_reponse` for your specific type to have more control.

```julia
create_response(t::Mytype)::HTTP.Response
```

This is already defined for `AbstractString` and `AbstractDict`, were the Content-Type header is set as `text/plain` and `application/json` respectively.

## Sessions

When instantiating the app you can pass any data structure you want to use for the session, by default this will be a `Dict`. The session can then be accessed in the handler.

```julia
app("/path") do req
    session = app.session
end
```

Note `Dict` isn't thread safe so this will likey change in the future to a differnt data structure.

# Examples

For more examples see the `examples` folder.

# TODO

## Docker

## Middleware

## WebSockets

# Useful Packages

Some packages that you may find useful to pair wtih `Bonsai`.

- [Octo.jl](https://github.com/wookay/Octo.jl) - a SQL Query DSL
