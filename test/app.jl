using Bonsai: has_handler, isvalidpath, Handler
using Bonsai
using Test, HTTP, JSON

@testset "server" begin

    app = App()

    app("/hello") do ctx
        "Hello"
    end

    app("/world/:jello") do ctx
        "Jello!"
    end

    start(app)

    res = HTTP.get("http://localhost:8081/hello")
    @test String(res.body) == "Hello"

    res = HTTP.get("http://localhost:8081")
    @test String(res.body) == "404"

    res = HTTP.get("http://localhost:8081/world")
    @test String(res.body) == "404"

    res = HTTP.get("http://localhost:8081/world/a")
    @test String(res.body) == "Jello!"

    res = HTTP.get("http://localhost:8081/world/b")
    @test String(res.body) == "Jello!"

    stop(app)
end

@testset "path params" begin

    app = App()

    app("/hello/:world") do req
        path_params(req)[:world] == "m8"
    end

    app("/:fried/:chicken") do req
        path_params(req) == Dict(:fried => "kfc", :chicken => "isgreat")
    end

    server = start(app)

    @test HTTP.get("http://localhost:8081/hello/m8").body |> String == "true"
    @test HTTP.get("http://localhost:8081/kfc/isgreat").body |> String == "true"

    stop(app)
end


@testset "query params" begin
    app = App()

    app("/rice") do req
        query_params(req)[:and] == "peas"
    end

    start(app)

    @test HTTP.get("http://localhost:8081/rice?and=peas").body |> String == "true"

    stop(app)
end

@testset "json_payload" begin
    app = App()

    app("/post", POST) do req
        json_payload(req) 
    end

    server = start(app)

    d = Dict("some" => "json")
    res = HTTP.post("http://localhost:8081/post", [],  JSON.json(d))
    @test res.body |> String |> JSON.parse |> x->x == d

    stop(app)
end


@testset "session" begin

    app = App()

    app("/set") do request
        app.session["key"] = "value"
    end

    app("/get") do request
        app.session["key"]
    end

    start(app)

    HTTP.get("http://localhost:8081/set")
    @test HTTP.get("http://localhost:8081/get").body |> String == "value"

    stop(app)
end

@testset "web sockets" begin

    app = App()

    ws"/hello"

    app(ws"/hello") do ws
        while !eof(ws)
            data = readavailable(ws)
            write(ws, data)
        end
    end

    start(app)

    HTTP.WebSockets.open("ws://127.0.0.1:8081/hello") do ws
        write(ws, "hello")
        x = readavailable(ws)
        @test String(x) == "hello"
    end

    stop(app)
end