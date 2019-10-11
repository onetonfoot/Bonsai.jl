# using Revise
# using Pkg
# Pkg.activate("./")
using Test, Tree, HTTP

# For debug mode
# using Logging
# logger = ConsoleLogger(stdout, Logging.Debug)
# global_logger(logger)

# TODO copy the relevant trie tests
# https://github.com/JuliaCollections/DataStructures.jl/blob/master/test/test_trie.jl

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

@testset "context" begin

    router = Router()

    router("/hello/:world") do ctx
        ctx.path_params[:world] == "world"
    end

    router("/:fried/:chicken") do ctx
        ctx.path_params[:fried] == "kfc"
        ctx.path_params[:chicken] == "isgreat"
    end

    router("/rice") do ctx
        ctx.query_params[:and] == "peas"
    end

    server = start(router)

    @test HTTP.get("http://localhost:8081/hello/world").body |> String == "true"
    @test HTTP.get("http://localhost:8081/kfc/isgreat").body |> String == "true"
    @test HTTP.get("http://localhost:8081/rice?and=peas").body |> String == "true"

    stop(server)

end

# router = Router()


# router("/hello") do req
#     "Hello"
# end

# router("/world/:jello") do req
#     "Jello!"
# end

# server = start(router)

# stop(server)