using Bonsai, Test, FilePathsBase
using Bonsai: has_handler
using HTTP


@testset "files" begin

    folder = Path(@__DIR__) / "files"
    data = read(folder / "index.html")

    app = App()
    index_html = folder / "index.html"
    app("/",index_html)
    app("/path", index_html)

    @test has_handler(app.router.routes["GET"], "/")
    @test has_handler(app.router.routes["GET"], "/path")

    start(app)

    res =  HTTP.get("http://localhost:8081/")
    @test res.body == data

    res =  HTTP.get("http://localhost:8081/path")
    @test res.body == data

    stop(app)
end


@testset "folder" begin
    @testset "non recursive" begin
        folder = Path(@__DIR__) / "files"
        app = App()
        app("/", folder, recursive=false)
        @test !has_handler(app.router.routes["GET"], "/js/some_javascript.js")
        @test has_handler(app.router.routes["GET"], "/index.html")
    end

    @testset "recursive" begin
        app = App()
        folder = Path(@__DIR__) / "files"
        app("/", folder)

        @test has_handler(app.router.routes["GET"], "/index.html")
        @test has_handler(app.router.routes["GET"], "/js/some_javascript.js")

        start(app)

        response = HTTP.get("http://localhost:8081/js/some_javascript.js")
        headers = Dict(response.headers...) 
        @test headers["Content-Type"] == "text/javascript"
        js = read(folder / "js/some_javascript.js")
        @test response.body == js
        stop(app)
    end
end