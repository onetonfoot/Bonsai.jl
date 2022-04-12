# Bonsai

[![][action-img]][action-url]
[![codecov](https://codecov.io/gh/onetonfoot/Bonsai.jl/branch/master/graph/badge.svg?token=96CcO21IsK)](https://codecov.io/gh/onetonfoot/Bonsai.jl)

[action-img]: https://github.com/onetonfoot/Bonsai.jl/actions/workflows/ci.yaml/badge.svg
[action-url]: https://github.com/onetonfoot/Bonsai.jl/actions


# Intro

```julia

# Handler function
function f(s::Stream)
	write(s, "Hello")
end

server = Router()
# Register handler 
get!(router, "/",  f)
start(server)
# Block until server stop running
wait(sever)
```

# Handlers

Each handler is a function with the following signature `f(stream::HTTP.Stream)`. 

To register a handler to the router use the function named after the respective HTTP method e.g  `get!, post!, patch!` . The responde to evert HTTP method you can use `all!`

# Middleware 

Middleware is a function of the form `f(stream::HTTP.Stream, next)`. Where `next` is the next handler/middleware in the stack. 


Middleware is called sequentially in the order it is register.

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