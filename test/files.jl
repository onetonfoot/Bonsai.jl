using Bonsai, Test, FilePathsBase
using Bonsai: has_handler
using HTTP

@testset "files" begin
    data = read("./files/index.html")

    app = App()
    app(p"files/index.html")
    app("/path", p"files/index.html")

    @test has_handler(app.router.routes["GET"], "/index.html")
    @test has_handler(app.router.routes["GET"], "/path")

    start(app)

    res =  HTTP.get("http://localhost:8081/index.html")
    @test res.body == data

    res =  HTTP.get("http://localhost:8081/path")
    @test res.body == data

    stop(app)
end


@testset "folder" begin
    @testset "non recursive" begin
        app = App()
        app("/", f"files", recursive=false)

        @test !has_handler(app.router.routes["GET"], "/js/some_javascript.js")
        @test has_handler(app.router.routes["GET"], "/index.html")
    end

    @testset "recursive" begin
        app = App()
        app("/", f"./files")

        @test has_handler(app.router.routes["GET"], "/index.html")
        @test has_handler(app.router.routes["GET"], "/js/some_javascript.js")

        start(app)

        response = HTTP.get("http://localhost:8081/js/some_javascript.js")
        headers = Dict(response.headers...) 
        @test headers["Content-Type"] == "text/javascript"
        js = read("./files/js/some_javascript.js")
        @test response.body == js
        stop(app)
    end
end