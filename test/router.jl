using Test
using Bonsai
using Bonsai: register!, Node, split_route, HttpHandler
using URIs
using HTTP
using HTTP: Request
using AbstractTrees

using Bonsai: gethandler, getmiddleware


@testset "getmiddleware" begin
    req = Request()
    req.method = "GET"

    app = App()
    app.get["/files/hello.txt"] = [(stream, next) -> 1]
    app.get["/files/**"] = [(stream, next) -> 2, (stream, next) -> 3]
    req.target = "/files/hello.txt"
    @test map(fn -> fn(nothing, nothing), getmiddleware(app, req)) == [1,2,3]

    req.target = "/files/1"

    @test map(fn -> fn(nothing, nothing), getmiddleware(app, req)) == [2,3]
end

@testset "gethandler" begin
    req = Request()
    req.method = "GET"
    req.target = ""
    app = App()

    app.get["/"] = (stream) -> "index"
    @test gethandler(app, req)[2] == "/"

    req.target = "/files/1"
    app.get["/files/**"] = (stream) -> "**"
    app.get["/files/hello.txt"] = (stream) -> "hello.txt"
    app.get["/files/{id:\\d+}"] = (stream) -> "hello.txt"

    @test gethandler(app, req)[2] == "/files/{id:\\d+}"
    @test gethandler(app, req)[1] isa HttpHandler

    req.target = "/files/abc"
    @test gethandler(app, req)[2] == "/files/**"
end

# @testset "match" begin
#     app = App()
#     app.get("/{x}") do stream
#     end
#     req = Request()
#     req.url = URI("http://locahost:4040/pet")
#     req.method = "GET"
#     # mutates the request storing the match in ctx
#     match(app, req)
#     @test haskey(req.context[:params], :x)
#     @test req.context[:params][:x] == "pet"
# end


# @testset "app" begin
#     app = App()

#     app.get("/") do stream
#     end

#     node = app.paths
#     method = "GET"

#     handler, params = Base.match(node,  method, "/")
#     @test !isnothing(handler) && isempty(params)

#     req = HTTP.Request()
#     req.method = "GET"
#     req.url = URI("/")
#     handler, middleware = match(app, req)
#     @test !isnothing(handler) && isempty(middleware)
# end