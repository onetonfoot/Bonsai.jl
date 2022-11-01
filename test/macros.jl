using Bonsai, StructTypes
using Bonsai: @data, description

"hello"
@data struct T1
	x::Int = 0
	y::Float64 = 0
end

@data struct BaseModel 
	id::String
	created::String
end

@data struct User
	BaseModel...
	name::String
	age::Int
end

@testset "@data" begin
	@test T1() isa T1
	@test description(T1) == "hello"
	@test fieldnames(User) == (:id, :created, :name, :age)
end