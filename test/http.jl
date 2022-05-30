using Bonsai, Test, StructTypes, HTTP, JSON3, HTTP.Messages
using StructTypes: @Struct
using HTTP: Request
using URIs: URI

struct Payload
    x
end

StructTypes.StructType(::Type{Payload}) = StructTypes.Struct()

struct PayloadTyped
    x::Int
end

StructTypes.StructType(::Type{PayloadTyped}) = StructTypes.Struct()

@testset "Body" begin
    io = IOBuffer(JSON3.write(Payload(10)))
    req = Request()
    req.body = take!(io)
    @test Bonsai.read(req, Body(Payload)) == Payload(10)

    b = Body(error="test", message="kwconstructor")
    @test b.val  == (error ="test", message="kwconstructor")
end


@testset "convert_numbers!" begin
    @test Bonsai.convert_numbers!(Dict{Symbol,Any}(:x => "10"), PayloadTyped)[:x] == 10
end

@testset "Query" begin
    req = Request()
    # only on latest master currently
    req.url = URI("http://localhost?x=10")
    @test Bonsai.read(req, Query(Payload)) isa Payload
    @test Bonsai.read(req, Query(PayloadTyped)) isa PayloadTyped
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
        x_missing::Union{String,Missing}
    end

    @test Bonsai.read(req, Headers(A)).x_test == "wagwan"
    @test Bonsai.read(req, Headers(B)).x_missing |> ismissing

    bad_req = HTTP.Messages.Request()
    bad_req.headers = [
        "X-Something-Else" => "wagwan"
    ]

    @test_throws Exception Bonsai.read(bad_req, Headers(A))
end

# @testset "Cookies" begin
#     req = HTTP.Messages.Request()
#     req.headers = [
#         "Cookie" => "a=choco; b=1"
#     ]

#     @Struct struct C1
#         a::String
#         b::String
#     end

#     read_cookies = Bonsai.Cookies(C1)
#     @test read_cookies(req).b == "1"
# end