using JET, InteractiveUtils 
using CodeInfoTools
using HTTP: Stream
using JSON3
using Bonsai
using StructTypes: @Struct
using StructTypes
using HTTP.Messages: Request, Response
using Bonsai: handler_writes, handler_reads, groupby_status_code
using Test
using FilePaths: Path
using FilePathsBase: /
using URIs

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
    offset::Union{Int, Missing}
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
    app.get["/{x}"] = function(stream)
    end
    # calling match on the request adds the parameters to it req.context
    Bonsai.gethandlers(app, req)

    @test Bonsai.read(req, Query(Limit)) isa Limit
    @test Bonsai.read(req, Headers(x_next=String)) isa NamedTuple
    @test Bonsai.read(req, Route(x=String)) == (x = "pets", )
end

@testset "Bonsai.write" begin

    res = Response()
    Bonsai.write(res, Body("ok"))
    @test !isempty(res.body)
    Bonsai.write(res, Bonsai.Status(201))
    @test res.status == 201
    Bonsai.write(res, Headers(content_type = "json and that"))
    @test !isempty(res.headers)

    res = Response()

    @test_nowarn Bonsai.write(
        res,
        Body("ok"),
        # FilePaths also exportsd this
        Bonsai.Status(201),
    )


    function g(stream)
        Bonsai.write(stream, Body("ok"), Bonsai.Status(201))
    end

    function h(stream)
        if rand() > 0.5
            Bonsai.write(stream, Body(A1(1)), Bonsai.Status(200))
        else
            Bonsai.write(stream, Body("err"), Bonsai.Status(500))
        end
    end

    # defining the mime type allows us to all write the correct
    # content-type header
    Bonsai.mime_type(::A1) = "application/json"
    g_writes = Bonsai.handler_writes(g)
    g_status = filter(x -> x <: Bonsai.Status, g_writes)
    @test length(g_status) == 1
    @test g_status[1] == Bonsai.Status{201}

    h_writes = Bonsai.handler_writes(h) |> groupby_status_code
    @test length(h_writes) == 2
end


@testset "Bonsai.read and Bonsai.write" begin

    function g(stream)
        query = Bonsai.read(stream, Query(Limit))
        l = Pet[]

        for (i, pet) in values(pets)

            if !ismissing(query.offset) & i < query.offset
                continue
            end

            push!(l, pet)
            if i > query.limit
                break
            end
        end

        Bonsai.write(stream, Headers(x_next="/pets?limit=$(query.limit+1)&offset=$(query.offset)"))
        Bonsai.write(stream, Body(pets=l))
    end

    @test Bonsai.handler_reads(g) == [Query{Limit}]
    @test length(Bonsai.handler_writes(g)) == 4
end


@testset "AbstractPath" begin

    function file_handler(stream)
        file = Path((@__DIR__, "data/c.json"))
        # oddly this break the type inference but the above doesn't
        # file = Path(@__DIR__) /  "data/c.json"
        Bonsai.write(stream, Body(file))
    end


    req = Response()
    file_handler(req)
    @test !isempty(req.body )
    @test length(Bonsai.handler_writes(file_handler)) == 3
end


@testset "handler_reads" begin

    function g(stream)
        Bonsai.read(stream, Route(id = Int))
    end

    l = handler_reads(g)
    # is type Route not Route{NamedTuple}
    @test_skip length(l) == 1

    function g2(stream)
        Bonsai.read(stream, Route(AnId))
    end

    l = handler_reads(g2)
    @test l[1] == Route{AnId}
end
