# Bonsai

[![][action-img]][action-url]
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)
[![codecov](https://codecov.io/gh/onetonfoot/Bonsai.jl/branch/master/graph/badge.svg?token=96CcO21IsK)](https://codecov.io/gh/onetonfoot/Bonsai.jl)
[![](https://img.shields.io/badge/Documentation-stable-blue.svg)](https://onetonfoot.github.io/Bonsai.jl/)

[action-img]: https://github.com/onetonfoot/Bonsai.jl/actions/workflows/ci.yaml/badge.svg
[action-url]: https://github.com/onetonfoot/Bonsai.jl/actions


This project is still in early development and likely to change pre 1.0

# Installation

```
]add Bonsai
```

# Documentation

A quick example

```julia
using Bonsai, HTTP

const app = App()

function index(stream::HTTP.Stream)
    query = Bonsai.read( stream, Query(name=Union{String, Nothing}))
    name = isnothing(query.name) ? "John Doe" : query.name  
    Bonsai.write(stream, Body("Hi, $name"))
end

app.get["/"] = index
start(app, port=9091)

```

For usage please see the [documentation](https://onetonfoot.github.io/Bonsai.jl/)
