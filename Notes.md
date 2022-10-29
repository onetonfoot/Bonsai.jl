# IO 

Clean up JSON construction and error handling so the functions can also be used from 
within websocket handlers with `Bonsai.read(msg, T)`

# Handlers

* Add `app.ws`
* Maybe rename HTTPParameter to HttpIo?

# OpenAPI


```julia

struct Custom{T}
  t
  val
end
```

* Need to track writes of headers

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


Oxygen


```julia
@get "/greet" function(req::HTTP.Request)
    return "hello world!"
end
```
