using Test
using Bonsai
using Bonsai: register!, Node, HttpHandler
using Bonsai.URIs
using Bonsai.HTTP
using Bonsai.HTTP: Request
using Bonsai.AbstractTrees
using Bonsai: gethandler, getmiddleware

@testset "getmiddleware" begin
    app = App()
    # this doesn't match the index route is that 
    app.middleware["**"] = [
        function (stream, next) end
    ]
    app.middleware.get["**"] = [
        function (stream, next) end
    ]
    req = Request()
    req.method = "POST"
    req.target = "/"
    length(getmiddleware(app, req)) == 1
    req.method = "GET"
    length(getmiddleware(app, req)) == 2
end


@testset "gethandler" begin
    req = Request()
    req.method = "GET"
    req.target = ""
    app = App()

    app.get["/"] = (stream) -> "index"
    @test gethandler(app, req)[2] == "/"
    req.target = "/"
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