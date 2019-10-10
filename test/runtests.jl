# using Revise
# using Pkg
# Pkg.activate("./")
using Test, Tree, HTTP

# For debug mode
# using Logging
# logger = SimpleLogger(stdout, Logging.Debug)
# global_logger(logger)

# TODO copy the relevant trie tests
# https://github.com/JuliaCollections/DataStructures.jl/blob/master/test/test_trie.jl

@testset "router" begin
    router = Router()
    f(x) = "hey"
    router(f, "/:something")
    @test router(f, "/hello") == "/hello"
    @test_throws ErrorException router(f, "/:something_else")
    router(f, "/:something/else")
end

@testset "server" begin

    router = Router()

    router("/hello") do req
        "Hello"
    end

    router("/world/:jello") do req
        "Jello!"
    end

    server = start(router)

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

