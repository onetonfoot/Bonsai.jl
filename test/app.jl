using Bonsai
using Bonsai.HTTP: Stream
using Bonsai: handler_writes
using Bonsai: StructTypes
using Test

struct A2
    data
end

StructTypes.StructType(::Type{A2}) = StructTypes.Struct()

@testset "setindex! and getindex" begin
    app = App()
    @test_nowarn app.get["/path"] = function (stream) end
    @test_nowarn app.get["/path"]
end

@testset "handler_writes" begin
    app = Bonsai.App()
    app.get("/path") do stream
        Bonsai.write(stream, Headers(header="value"))
        Bonsai.write(stream, Body(x=10))
        Bonsai.write(stream, Body(a=A2(10)))
    end
    h = app.get["/path"]
    @test length(Bonsai.handler_writes(h.fn)) == 5
end

@testset "handler_reads" begin
    app = Bonsai.App()
    app.get("/path/{id}") do stream
        Bonsai.read(stream, Headers(A2))
        Bonsai.read(stream, Body(A2))
        Bonsai.read(stream, Query(color=String))
        Bonsai.read(stream, Route(id=Int))
    end
    h = app.get["/path/{id}"]
    @test length(Bonsai.handler_reads(h.fn)) == 4
end

@testset "show" begin
    app = Bonsai.App()
    app.get("/path") do stream
    end
    app.get("/path/{id}") do stream
    end
    app.get("/a") do stream
    end
    app.get("/a/b") do stream
    end
    app.get("/a/b/c") do stream
    end
    app.get("/a/c") do stream
    end

    io = IOBuffer()
    Base.show(io, app)
    # Base.show(stdout, app)
end