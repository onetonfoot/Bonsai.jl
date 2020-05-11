using Bonsai, Test, FilePathsBase
using Bonsai: has_handler
using HTTP

@testset "files" begin
    data = read("files/index.html")

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

    @testset "recursive" begin
        index = read("files/index.html")
        js = read("files/js/some_javascript.js")

        app = App()
        app(f"/files")

        @test has_handler(app.router.routes["GET"], "/files/js/some_javascript.js")
        @test has_handler(app.router.routes["GET"], "/files/index.html")

        start(app)

        response = HTTP.get("http://localhost:8081/files/js/some_javascript.js")
        headers = Dict(response.headers...) 
        @test headers["Content-Type"] == "text/javascript"
        stop(app)
    end

    @testset "non recursive" begin
        app = App()
        app(f"/files", recursive=false)

        @test !has_handler(app.router.routes["GET"], "/files/js/some_javascript.js")
        @test has_handler(app.router.routes["GET"], "/files/index.html")
        stop(app)
    end

    @testset "route" begin
        app = App()
        app("/some_files",f"/files")

        @test has_handler(app.router.routes["GET"], "/some_files/index.html")
        @test has_handler(app.router.routes["GET"], "/some_files/js/some_javascript.js")
    end
end