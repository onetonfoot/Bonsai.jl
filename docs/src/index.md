# Tree

## Getting started

It's a simple as creating and instance of the app, adding a route then starting the server

```julia
app = App()

app("/path"; method = GET) do request
    # your code here
    reponse = "hello"
    return response
end

start(app)
```

The response can be of any type however if you need more control you can overload `create_response` for specific types.

```julia
create_response(t::Mytype)::Response
```

This defined for `AbstractString` and `Dict` already.

## Routing and Query Parameters

Routes can be defined for multiple methods by passing an array

```julia
app(handler, "/path", [GET, POST])
```

Routes can be parametrized by using the syntax `/:x`. You can then access
the parameters the handler.

```julia
app("/route/:id", method = [GET, POST]) do request
    params = path_params(request)
    # Dict(:id => value)
end
```

Query parameters can be accessed in a similar way

```julia
query = query_params(request)
```

Specific routes like `/path` take priority over variable routes such as `/:path`.

## Sessions

When instantiating the app you can pass any data structure you want to use for the session, by default this will be a `Dict`. The session can then be accessed in the handler.

```julia
app("/path") do req
    session = app.session
end
```

## Middleware

Currently not implemented

## WebSockest

Currently not implemented
