using JET, InteractiveUtils # to use analysis entry points
using CodeInfoTools
using HTTP: Stream
using Bonsai
using StructTypes: @Struct
using StructTypes
using HTTP.Messages: Request, Response
using Bonsai: handler_writes, handler_reads, PathParams
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
    offset::Union{Int,Missing}
end


@testset "Bonsai.read" begin
    req = Request()
    req.body = Vector{UInt8}(JSON3.write(Pet(1, "bob", "dog")))
    req.url = URI("http://locahost:4040/pets?limit=10&offset=5")
    req.headers = [
        "X-Next" => "Some Value"
    ]
    req.method = "GET"
    app = App()
    app.get("{x}") do stream
    end
    match(app, req)
    @test Bonsai.read(req, Query(Limit)) isa Limit
    @test Bonsai.read(req, Headers(x_next=String)) isa NamedTuple
    @test_skip Bonsai.read(req, PathParams(x=String))
end

@testset "handler_writes" begin

    function f(stream)
        Bonsai.write(stream, Body("ok"), ResponseCodes.Ok())
    end

    function h(stream)
        if rand() > 0.5
            Bonsai.write(stream, Body(A1(1)), ResponseCodes.Created())
        else
            f(stream)
        end
    end

    # defining the mime type allows us to all write the correct
    # content-type header
    Bonsai.mime_type(::A1) = "application/json"
    @test length(Bonsai.handler_writes(h)) == 4


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

    @test length(Bonsai.handler_writes(g)) == 2
    Bonsai.mime_type(::T) where {T<:NamedTuple} = "application/json"
    # Ideally we'd pick up on the Content-Type writes
    @test_skip length(Bonsai.handler_writes(g)) == 3
    @test length(Bonsai.handler_reads(g)) == 1
end


@testset "AbstractPath" begin
    f = Path(@__DIR__) / "data/c.json"

    function file(stream)
        f = Path(@__DIR__) / "data/c.json"
        Bonsai.write(stream, f)
    end

    @test length(Bonsai.handler_writes(file)) == 1
end


@testset "handler_reads" begin

    function g(stream)
        Bonsai.read(stream, PathParams(A))
    end

    l = handler_reads(g)
    @test length(l) == 1
end
