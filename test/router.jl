using Test
using Bonsai
using Bonsai: register!, Node, Params, match_middleware
using URIs
using HTTP

@testset "match" begin
    app = App()
    app.get("/{x}") do stream
    end
    req = Request()
    req.url = URI("http://locahost:4040/pet")
    match(app, req)
    @test_skip haskey(req.context[:params], "x")
end

@testset "register!" begin
    r = Node("*")

    # matches
    register!(r, GET, "/fish/{id}", x -> 1)
    register!(r, GET, "/fish/super", x -> 2)
    register!(r, GET, "/fish/**", x -> 3)
    # wrong method
    register!(r, PUT, "/fish/**", x -> 4)
    # wrong path
    register!(r, PUT, "/turtle/super", x -> 5)
    p = "/fish/super"
    params = Params()
    segments = split(p, "/"; keepempty=false)
    ms = match_middleware(r, params, "GET", segments, 1)
    @test sort(map(x -> x(nothing), ms)) == [1, 2, 3]
end


@testset "app" begin

    app = App()
    app.get("**") do stream, next

    end
    app.get("**") do stream

    end

    req = HTTP.Request()
    req.method = "GET"
    req.target = "/"
    handler, middleware = match(app, req)
    @test !isnothing(handler)
    @test !isempty(middleware)
end

@testset "/" begin
    app = App()

    app.get("/") do stream
    end

    req = HTTP.Request()
    req.method = "GET"
    req.target = "/"
    handler, middleware = match(app, req)
    @test !isnothing(handler)
end
