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

    
    
end