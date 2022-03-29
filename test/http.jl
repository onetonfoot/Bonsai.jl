using Bonsai, Test, StructTypes, HTTP, JSON3, HTTP.Messages

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

@testset "Header" begin

    req = HTTP.Messages.Request()
    req.headers = [
            "X-Test" => "wagwan"
    ]

    read_header = Header("X-Test")
    read_header_precidate = Header("X-Test") do v
        v == "wagwan"
    end
    read_header_not_required = Header("X-Nothing", required=false)

    @test read_header_precidate(req) == "wagwan"
    @test read_header(req) == "wagwan"
    @test isnothing(read_header_not_required(req))

    bad_req = HTTP.Messages.Request()
    bad_req.headers = [
            "X-Something-Else" => "wagwan"
    ]
    
    @test_throws MissingHeader read_header(bad_req)

    bad_req2 = HTTP.Messages.Request()
    bad_req2.headers = [
            "X-Test" => "hello"
    ]

    @test_throws InvalidHeader read_header_precidate(bad_req2)
end