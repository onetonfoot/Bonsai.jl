using StructTypes	
using StructTypes: StructType

struct Payload 
    x
end

StructType(::Type{Payload}) = StructTypes.Struct()

@testset "Body" begin

    io = IOBuffer( JSON3.write(Payload(10)))
    read_body = Body(Payload)
    @test read_body(io).x == 10
end