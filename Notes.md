# Handlers

* How to extract path parameters? In a declarative way
* How to structure handlers in a way that supports live reload?
* Add `app.all`


Path parameters

```julia
app.get("/:id") do stream
      path_params()

end
```

How to associate documentation with the handler in a intuative way?

```julia
"Some documentation"
app.get("/:id") do stream

end
```

Maybe add a web socket method

```julia
app.ws("/ws") do ws 

end
```

# OpenAPI

rename HTTPParameter to HttpIo or better use a interface so people can easily extend for there own types

```julia

struct Custom{T}
  t
  val
end
```

* Need a way to correctly guess the content type of writes to generate open-api, perhaps provide a function that can be overrided. For example to support other stuff like DataFrames. `mime_type(::Type{T})`

* Need to track writes of headers
* Best to remove redoc and use swagger-ui, this will remove the NodsJS dep but will probably need to write a small react app

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


# Error handling

If unable to create any of the struct their should be a
helpful error message printed


```julia
struct InvalidParameter{T} <: Exception
    t::Type{T}
    e::Exception
end
```
