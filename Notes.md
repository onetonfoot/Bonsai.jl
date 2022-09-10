# IO 

Clean up JSON construction and error handling so the functions can also be used from 
within websocket handlers with `Bonsai.read(msg, T)`

# Handlers

* How to extract path parameters? In a declarative way
* How to structure handlers in a way that supports live reload?
* Add `app.all`

Add docs for summary documentation 

```julia
"Some documentation"
app.summary("/:id") 
```

Maybe add a web socket method

```julia
app.ws("/ws") do ws 

end
```

Need a easy way to get the handlers back maybe? However should this return the handler or the middleware,
perhaps a tuple of both (handler, middleware) or maybe the combined handler, this would be better for testing purposes.


```julia
app.get("/the handler")
```

Do we need to enforce at the call site that the route starts with a slash?

# OpenAPI

rename HTTPParameter to HttpIo. 

```julia

struct Custom{T}
  t
  val
end
```

* Need a way to correctly guess the content type of writes to generate open-api, perhaps provide a function that can be overrided. For example to support other stuff like DataFrames. `mime_type(::Type{T})`

* Need to track writes of headers
* Best to remove redoc and use swagger-ui, this will remove the NodesJS dep but will probably need to write a small react app

# Other Framework Handlers

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

https://github.com/ndortega/Oxygen.jl

# Error handling

If unable to create any of the struct their should be a
helpful error message printed


```julia
struct InvalidParameter{T} <: Exception
    t::Type{T}
    e::Exception
end
```

