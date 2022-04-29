# Handlers

Removing the the kwargs and instead using `Bonsai.read` is visually cleaner, andnd using JET it should still be possible to track the calls
to generate the open-api schema

```julia
function f(stream; 
	read_query = Query(Limit)
)
	read_query(stream)

	Bonsai.write(stream, A)
end

function f(stream)
	Bonsai.read(stream, Query(Limit))

	Bonsai.write(stream, A)
end
```

How to extract path parameters? In a declarative way

```
Bonsai.read(stream, Param{Int}(idx))
```


Should the handlers path live closer to the handler function?

FastAPI

```python
from fastapi import FastAPI
app = FastAPI()

@app.get("/items/{item_id}")
async def read_item(item_id: int):
    return {"item_id": item_id}

```

Fibre

```go
package main

import "github.com/gofiber/fiber/v2"

func main() {
    app := fiber.New()

    app.Get("/", func(c *fiber.Ctx) error {
        return c.SendString("Hello, World 👋!")
    })

    app.Listen(":3000")
}

```

Genie

```julia

route("/", method = POST) do
  "Hello $(postpayload(:name, "Anon"))"
end
```

Express

```js
app.post('/', (req, res) => {
  res.send('POST request to the homepage')
})
```

Perhaps something like

```julia
app.get("/:id") do stream

end
```

However this poses the problem of how to extract the path parameters
from the stream elegantly. 

Cassette could be used but this may result in a performance hit. 

Another solution could be to use a wrapper type and then delegate the
other HTTP methods to the stream field. But I like to avoid 
obscuring the underlying API and it  does't make sense for this single usecase

<!-- https://github.com/JeffreySarnoff/TypedDelegation.jl -->

This would both allow us to catch write and read and setheaders


The following syntax could be used for other things

```julia
app.ws("/ws") do ws 

end
```

Although this is a little long 

```julia
app.middleware.get("/") do (stream, next)

end
```

# OpenAPI

Need a way to correctly guess the content type of writes to generate open-api, perhaps provide a function that can be overrided 

Need to track writes of headers


Should be able to use type as a handler to create the docs `OpenAPI`


# Routing

Should probably be using a tree like structure with static arrays