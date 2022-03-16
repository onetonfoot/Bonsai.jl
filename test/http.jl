using Bonsai, Test, StructTypes, HTTP, JSON3
struct Payload 
    x
end

StructTypes.StructType(::Type{Payload}) = StructTypes.Struct()

struct PayloadTyped
    x::Int
end

StructTypes.StructType(::Type{PayloadTyped}) = StructTypes.Struct()

@testset "Body" begin
    io = IOBuffer( JSON3.write(Payload(10)))
    read_body = Body(Payload)
    @test read_body(io).x == 10

    router = Router()

    function fn(stream)
        read_data = Body(Payload)
        q = read_data(stream)
        JSON3.write(stream, q)
    end

    post!(router, "*", fn)

    port = 10003
    start(router, port=port)

    res = HTTP.post("http://localhost:$port", [], JSON3.write(Dict(:x => 10)))
    @test res.status == 200
    stop(router)
end


@testset "Query" begin

    router = Router()

    function fn(stream)
        read_query = Query(Payload)
        q = read_query(stream)
        JSON3.write(stream, q)
    end

    function fn_typed(stream)
        read_query = Query(PayloadTyped)
        q = read_query(stream)
        JSON3.write(stream, q)
    end

    get!(router, "/any", fn)
    get!(router, "/typed", fn_typed)

    port = 10000
    start(router, port=port)

    res = HTTP.get("http://localhost:$port/any?x=10")
    @test res.status == 200


    res = HTTP.get("http://localhost:$port/typed?x=10")

    stop(router)
end