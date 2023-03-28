using Bonsai, Test

using Bonsai.JET,
    Bonsai.InteractiveUtils,
    Bonsai.JSON3,
    Bonsai.StructTypes,
    Bonsai.URIs

import Bonsai.StructTypes: @Struct
import Bonsai.HTTP: Stream
import Bonsai.FilePathsBase: /
import Bonsai.HTTP.Messages: Request, Response
import Bonsai.FilePaths: Path

@Struct struct A1
    data
end

@Struct struct H1
    x_test::String
end

@Struct struct Next
    x_next::String
end

@Struct struct Pet
    id::Int
    name::String
    tag::String
end

@Struct struct Limit
    limit::Int
    offset::Union{Int,Missing}
end

@Struct struct AnId
    id::Int
end

@testset "DataMissingKey" begin
    j_typo = """
        {
            "limi" : 10,
            "offset" : 1
        }
    """

    req = Request()
    req.body = Vector{UInt8}(j_typo)
    @test_throws Bonsai.DataMissingKey Bonsai.read(req, Body(Limit))
end


@testset "Bonsai.read" begin
    req = Request()
    req.body = Vector{UInt8}(JSON3.write(Pet(1, "bob", "dog")))
    req.target = "http://locahost:4040/pets?limit=10&offset=5"
    req.url = URI("http://locahost:4040/pets?limit=10&offset=5")
    req.headers = [
        "X-Next" => "Some Value"
    ]
    req.method = "GET"
    app = App()
    app.get["/{x}"] = function (stream) end

    # calling match on the request adds the parameters to it req.context
    Bonsai.gethandlers(app, req)

    @test Bonsai.read(req, Query(Limit)) isa Limit
    @test Bonsai.read(req, Headers(x_next=String)) isa NamedTuple
    @test Bonsai.read(req, Route(x=String)) == (x="pets",)
end

@testset "Headers and Status Code" begin
    res = Response()
    Bonsai.write(res, Body("ok"))
    @test !isempty(res.body)
    Bonsai.write(res, Bonsai.Status(201))
    @test res.status == 201
    Bonsai.write(res, Headers(content_type="json and that"))
    @test !isempty(res.headers)

    res = Response()

    @test_nowarn Bonsai.write(
        res,
        Body("ok"),
        # FilePaths also exportsd this
        Bonsai.Status(201),
    )

    @test_nowarn Bonsai.write(
        res,
        Body("ok"),
        # FilePaths also exportsd this
        Bonsai.Status(201),
    )
end