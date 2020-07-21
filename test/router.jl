using Bonsai: has_handler, isvalidpath, Handler
using Bonsai
using Test, HTTP, JSON


# For debug mode
# using Logging
# logger = ConsoleLogger(stdout, Logging.Debug)
# global_logger(logger)

# TODO copy the relevant trie tests
# https://github.com/JuliaCollections/DataStructures.jl/blob/master/test/test_trie.jl

@testset "has_handler" begin

    trie = Bonsai.Trie{Handler}()
    four_oh_four = Handler(ctx->"404")
    trie["/:a/:b"] = Handler(ctx->"a b")
    trie["/rice/:b"] = Handler(ctx->"a b")
    trie["/hello/:world"] = Handler(ctx->"what")

    @test has_handler(trie, "/rice/peas")
    @test has_handler(trie, "/jerk/chicken")
    @test has_handler(trie, "/hello/chicken")
    @test !has_handler(trie, "/anything")
end

@testset "ambiguous routes" begin

    trie = Bonsai.Trie{Function}()
    four_oh_four = ctx->"404"
    trie["/:a/:b"] = ctx->"a b"
    trie["/rice/:b"] = ctx->"a b"
    trie["/hello/:world"] = ctx->"what"
    @test_throws ErrorException setindex!(trie, x->"ok", "/:a/:c")
    @test_throws ErrorException setindex!(trie, x->"ok", "/rice/:peas")

end

@testset "isvalidpath" begin
    @test isvalidpath("/:something/else")
    @test isvalidpath("/:something_else")
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