@testset "write_types" begin
    a = joinpath(@__DIR__, "a.json") |> x -> read(x, String)
    b = joinpath(@__DIR__, "b.json") |> x -> read(x, String)
    @test write_types(a) isa String
    @test write_types(b) isa String
end


main()

@testset "Query and Body" begin
    body = JSON3.write(Dict( :x => 1))
    req = Request( "GET", "exmaple.com?x=10", [], body)

    struct Payload 
        x
    end
    StructType(::Type{Payload}) = StructTypes.Struct()

    query = Query(Payload)
    p1 =  query(req)
    body = Body(Payload)
    p2 = body(req)

    @test p1.x == p2.x
end