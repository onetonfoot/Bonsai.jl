# TODO write a macro to handle this! @lint_fix using Tree
# julia> Pkg.dir(string(Tree))
if isdefined(@__MODULE__,:LanguageServer)
    include("../src/Tree.jl")
    using .Tree: has_handler, isvalidpath,  ws_serve 
    using .Tree
else
    using Tree: has_handler, isvalidpath, ws_serve
    using Tree

end

using Test, HTTP, JSON

# For debug mode
# using Logging
# logger = ConsoleLogger(stdout, Logging.Debug)
# global_logger(logger)

# TODO copy the relevant trie tests
# https://github.com/JuliaCollections/DataStructures.jl/blob/master/test/test_trie.jl

@testset "has_handler" begin

    trie = Tree.Trie{Function}()
    four_oh_four = ctx -> "404"
    trie["/:a/:b"] = ctx -> "a b"
    trie["/rice/:b"] = ctx -> "a b"
    trie["/hello/:world"] = ctx -> "what"

    @test has_handler(trie, "/rice/peas")
    @test has_handler(trie, "/jerk/chicken")
    @test has_handler(trie, "/hello/chicken")
    @test !has_handler(trie, "/anything")
end

@testset "ambiguous routes" begin

    trie = Tree.Trie{Function}()
    four_oh_four = ctx -> "404"
    trie["/:a/:b"] = ctx -> "a b"
    trie["/rice/:b"] = ctx -> "a b"
    trie["/hello/:world"] = ctx -> "what"
    @test_throws ErrorException setindex!(trie, x -> "ok", "/:a/:c")
    @test_throws ErrorException setindex!(trie, x -> "ok", "/rice/:peas")

end

@testset "isvalidpath" begin
    @test isvalidpath("/:something/else")
    @test !isvalidpath("/:something_else")
    @test !isvalidpath("/invalid path")
    @test !isvalidpath("/invalid?a=b")
end

@testset "router" begin
    router = Router()
    f(x) = "hey"
    router(f, "/:something")
    @test router(f, "/hello") == "/hello"
    @test_throws ErrorException router(f, "/:something_else")
    @test router(f, "/:something/else") == "/:something/else"
    @test_throws ErrorException router(f, "/invalid path")
    @test_throws ErrorException router(f, "/invalid?a=b")
end


@testset "server" begin

    router = Router()

    router("/hello") do ctx
        "Hello"
    end

    router("/world/:jello") do ctx
        "Jello!"
    end

    server = http_serve(router)

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

    stop(server)
end

@testset "path params" begin

    router = Router()

    router("/hello/:world") do req
        path_params(req)[:world] == "m8"
    end

    router("/:fried/:chicken") do req
        path_params(req)== Dict(:fried => "kfc" ,:chicken => "isgreat")
    end

    server = http_serve(router)

    @test HTTP.get("http://localhost:8081/hello/m8").body |> String == "true"
    @test HTTP.get("http://localhost:8081/kfc/isgreat").body |> String == "true"

    stop(server)
end


@testset "query params" begin
    router = Router()

    router("/rice") do req
        query_params(req)[:and] == "peas"
    end

    server = http_serve(router)

    @test HTTP.get("http://localhost:8081/rice?and=peas").body |> String == "true"

    stop(server)
end

@testset "json_payload" begin
    router = Router()

    router("/post", method=POST) do req
        json_payload(req) 
    end

    server = Tree.http_serve(router)

    d = Dict("some" => "json")
    res = HTTP.post("http://localhost:8081/post", [],  JSON.json(d))
    @test res.body |> String |> JSON.parse |> x -> x == d

    stop(server)
end


@testset "ws echo" begin
    server = ws_serve(port=8082) do ws
        data = readavailable(ws)
        write(ws, data)
    end

    HTTP.WebSockets.open("ws://127.0.0.1:8082") do ws
        write(ws, "Hello")
        x = readavailable(ws)
        @test String(x) == "Hello"
    end
    close(server);

end
