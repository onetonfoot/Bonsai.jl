using Bonsai, StructTypes
using Bonsai: @data, description

"hello"
@data struct T1
	x::Int = 0
	y::Float64 = 0
end

@testset "@data" begin
	@test T1() isa T1
	@test description(T1) == "hello"
end
