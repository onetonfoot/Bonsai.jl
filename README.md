# Bonsai

[![][action-img]][action-url]
[![codecov](https://codecov.io/gh/onetonfoot/Bonsai.jl/branch/master/graph/badge.svg?token=96CcO21IsK)](https://codecov.io/gh/onetonfoot/Bonsai.jl)

[action-img]: https://github.com/onetonfoot/Bonsai.jl/actions/workflows/ci.yaml/badge.svg
[action-url]: https://github.com/onetonfoot/Bonsai.jl/actions


# Intro

Each handler is a function with the signature `f(stream::HTTP.Stream)`, to 
register a handler use the respective HTTP method e.g  `get!(router::Router, "/", handler)`

```julia

function f(s::Stream)
	write(s, "Hello")
end

server = Router()
get!(router, "/",  f) # register handler 
start(server)
wait(sever) # block until server stop running
```


# Middleware 

Middleware is a function of the form `f(stream::HTTP.Stream, next)`, where `next` is the following handler/middleware in the stack. 

```julia
function timer(stream, next)
    x = now()
    # the next middleware or handler in the stack
    next(stream)
    elapsed = now() - x
    @info "$(stream.message.target) took $elapsed" 
end

server = Router()
all!(server, "*", timer)
start(server)
wait(server)
```

# Example

Please see the `examples` folder.