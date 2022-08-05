using Bonsai, Test, StructTypes, HTTP, JSON3, HTTP.Messages
using StructTypes: @Struct
using HTTP: Request
using URIs: URI

@Struct struct Payload
    x
end

@Struct struct PayloadTyped
    x::Int
end

@Struct struct PayloadMissing
    x
    y::Union{Float64, Nothing}
end

@testset "Body" begin
    # constructors
    b = Body("ok")
    @test b.val == "ok"
    @test b.t == String

    b = Body(error="test", message="kwconstructor")
    @test b.t == NamedTuple{(:error, :message), Tuple{String, String}}
    @test b.val  == (error ="test", message="kwconstructor")

    b = Body(x=String, y=Float64)
    @test b.t == NamedTuple{(:x, :y), Tuple{String, Float64}}
    @test isnothing(b.val)

    # reading
    io = IOBuffer(JSON3.write(Payload(10)))
    req = Request()
    req.body = take!(io)
    @test Bonsai.read(req, Body(Payload)) == Payload(10)

    io = IOBuffer(JSON3.write(Payload(10)))
    req = Request()
    req.body = take!(io)
    payload = Bonsai.read(req, Body(PayloadMissing)) 
    @test payload.x  == 10
    @test isnothing(payload.y) 
end

@testset "Query" begin
    # constructors
    @test Query(x=String).val |> isnothing 

    # reading - requires HTTP master
    req = Request()
    req.url = URI("http://localhost?x=10")
    @test Bonsai.read(req, Query(Payload)) isa Payload
    @test Bonsai.convert_numbers!(Dict{Symbol,Any}(:x => "10"), PayloadTyped)[:x] == 10
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
        x_missing::Union{String, Nothing}
    end

    @test Bonsai.read(req, Headers(A)).x_test == "wagwan"
    @test Bonsai.read(req, Headers(B)).x_missing |> isnothing

    bad_req = HTTP.Messages.Request()
    bad_req.headers = [
        "X-Something-Else" => "wagwan"
    ]

    @test_throws Exception Bonsai.read(bad_req, Headers(A))
end

@testset "Params" begin
    req = HTTP.Messages.Request()
    # Base.match(app, req) should perform this for us
    req.context[:params] = Dict{Any, Any}(:id => "10")
    @test Bonsai.read(req, Params(id=Int)).id == 10
end