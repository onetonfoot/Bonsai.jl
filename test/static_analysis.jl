using Bonsai
using HTTP: Request, Response, Stream
using Bonsai: @data, handler_reads, handler_writes, groupby_status_code
using JET
using StructTypes

@data struct Limit
    limit::Int
    offset::Union{Int,Missing}
end

@testset "Bonsai.write" begin

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


    Bonsai.report_dispatch(g, Tuple{Stream})

    Bonsai.report_dispatch(h, Tuple{Stream})

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
    function j(stream)
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

    @test Bonsai.handler_reads(j) == [Query{Limit}]
    @test length(Bonsai.handler_writes(j)) == 4
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
    @test !isempty(req.body)
    @test length(Bonsai.handler_writes(file_handler)) == 3
end

@testset "handler_reads" begin

    function g(stream)
        Bonsai.read(stream, Route(id=Int))
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