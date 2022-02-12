@testset "Body" begin
    struct Payload 
        x
    end

    StructType(::Type{Payload}) = StructTypes.Struct()

    io = IOBuffer( JSON3.write(Payload(10)))
    read_body = Body(Payload)
    @test read_body(io).x == 10
end