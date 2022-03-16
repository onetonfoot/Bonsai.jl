using Bonsai, Test, StructTypes, HTTP
struct Payload 
    x
end

StructTypes.StructType(::Type{Payload}) = StructTypes.Struct()

@testset "Body" begin
    io = IOBuffer( JSON3.write(Payload(10)))
    read_body = Body(Payload)
    @test read_body(io).x == 10
end


@testset "Query" begin

    router = Router()

    function fn(stream)
        read_query = Query(Payload)
        q = read_query(stream)
        JSON3.write(stream, q)
    end

    get!(router, "*", fn)

    port = 10000
    start(router, port=port)
    res = HTTP.get("http://localhost:$port?x=10")
    @test res.status == 200
    stop(router)
end