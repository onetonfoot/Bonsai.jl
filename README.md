# Bonsai

[![][action-img]][action-url]
[![codecov](https://codecov.io/gh/onetonfoot/Bonsai.jl/branch/master/graph/badge.svg?token=96CcO21IsK)](https://codecov.io/gh/onetonfoot/Bonsai.jl)

[action-img]: https://github.com/onetonfoot/Bonsai.jl/actions/workflows/ci.yaml/badge.svg
[action-url]: https://github.com/onetonfoot/Bonsai.jl/actions

This project is in currently still in early development so use with caution

# Intro

Each handler is a function with the signature `f(stream::HTTP.Stream)`

```julia
app = App()

app.get("/") do stream
	Bonsai.write(s, Body("Hello"))
end

start(app)
wait(app) # block until server stops running
```


# Middleware 

Middleware is a function of the form `f(stream::HTTP.Stream, next)`, where `next` is the following handler/middleware in the stack. 

```julia
app = App()

app.get("**") do stream, next
    x = now()
    # the next middleware or handler in the stack
    next(stream)
    elapsed = now() - x
    @info "$(stream.message.target) took $elapsed" 
end

app.get("/") do stream
	Bonsai.write(s, Body("Hello"))
end

start(server)
wait(server)
```

# Example

Please see the `examples` folder for more details