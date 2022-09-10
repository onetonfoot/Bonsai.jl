using Test
using Bonsai
using Bonsai: register!, Node, match_middleware, split_route
using URIs
using HTTP
using HTTP: Request
using AbstractTrees

using Bonsai: gethandler, getmiddleware


@testset "getmiddleware" begin
    req = Request()
    req.method = "get"

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
    req.target = "/files/1"
    req.method = "get"

    app = App()
    app.get["/files/**"] = (stream) -> "**"
    app.get["/files/hello.txt"] = (stream) -> "hello.txt"
    app.get["/files/{id:\\d+}"] = (stream) -> "hello.txt"

    @test gethandler(app, req)[2] == "/files/{id:\\d+}"
    req.target = "/files/abc"

    @test gethandler(app, req)[2] == "/files/**"
end

# @testset "register!" begin
#     r = Node("*")

#     # 3 get routes
#     register!(r, GET, "/fish/{id}", x -> 1)
#     register!(r, GET, "/fish/super", x -> 2)
#     register!(r, GET, "/fish/**", x -> 3)
#     # 1 put
#     register!(r, PUT, "/fish/**", x -> 4)
#     # no fish route
#     register!(r, PUT, "/turtle/super", x -> 5)

#     p = "/fish/super"
#     params = Dict()
#     segments = split(p, "/"; keepempty=false)
#     ms = match_middleware(r, params, "GET", segments, 1)
#     @test sort(map(x -> x(nothing), ms)) == [1, 2, 3]

#     match(r, "GET", p)

# end

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


# @testset "app with middleware" begin
#     app = App()

#     app.get("**") do stream, next
#     end

#     app.get("/") do stream, next
#     end

#     app.get("**") do stream

#     end

#     req = HTTP.Request()
#     req.method = "GET"
#     req.url = URI("/")
#     handler, middleware = match(app, req)

#     @test !isnothing(handler) 
#     @test length(middleware) == 2
# end

# @testset "/" begin
#     app = App()

#     app.get("/") do stream
#     end

#     req = HTTP.Request()
#     req.method = "GET"
#     req.url = URI("/")
#     handler, middleware = match(app, req)
#     @test !isnothing(handler)
# end
