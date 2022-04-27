using Bonsai, Test, StructTypes, HTTP, JSON3, HTTP.Messages
using  StructTypes: @Struct

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


@testset "convert_numbers!" begin
    @test Bonsai.convert_numbers!(Dict{Symbol, Any}(:x => "10"), PayloadTyped)[:x] == 10
end

@testset "Query" begin

    router = Router()

    try
        port = 10000
        start(router, port=port)

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


        res = HTTP.get("http://localhost:$port/any?x=10")
        @test res.status == 200


        res = HTTP.get("http://localhost:$port/typed?x=10")
        @test res.status == 200
    catch
    finally
        stop(router)
    end
end


@testset "Header" begin

    req = HTTP.Messages.Request()
    req.headers = [
            "X-Test" => "wagwan"
    ]

    @Struct struct A 
        x_test::String
    end

    @Struct struct B
        x_missing::Union{String, Missing}
    end


    read_header = Headers(A)
    read_header_not_required = Headers(B)

    StructTypes.constructfrom(A, Dict(:x_test => "ok"))


    @test read_header(req).x_test == "wagwan"
    @test read_header_not_required(req).x_missing |> ismissing

    bad_req = HTTP.Messages.Request()
    bad_req.headers = [
            "X-Something-Else" => "wagwan"
    ]

    @test_throws Exception read_header(bad_req)

    bad_req2 = HTTP.Messages.Request()
    bad_req2.headers = [
            "X-Test" => "hello"
    ]
end

@testset "Cookies" begin

    req = HTTP.Messages.Request()

    req.headers = [
        "Cookie" => "a=choco; b=1"
    ]

    @Struct struct C1
        a::String
        b::String
    end

    read_cookies = Bonsai.Cookies(C1)

    @test read_cookies(req).b == "1"

end