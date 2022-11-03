using Bonsai, StructTypes, Test
using Bonsai: @data, description
using MacroTools: @capture

@data struct BaseModel 
	id::String
	created::String
end

@data struct User
	BaseModel...
	name::String
	age::Int
end

"hello"
@data struct T1
	x::Int = 0
	y::Float64 = 0
end

@data struct T2
	T1...
	z = 10
end

@data struct T8{T} 
	z::T = 1
end 

@data struct T5{T} 
	T1...
	z::T = 1
end 

@testset "@data" begin
	@test T1() isa T1
	@test strip(description(T1)) == "hello"
	@test fieldnames(User) == (:id, :created, :name, :age)
	@test StructTypes.constructfrom(T1, Dict()) == T1()
	@test StructTypes.constructfrom(T8{Int}, Dict()) isa T8{Int}
	@test StructTypes.constructfrom(T8{Float64}, Dict()) isa T8{Float64}
	@test StructTypes.constructfrom(T5{Float64}, Dict()) isa T5{Float64}
	@test StructTypes.constructfrom(T7{Float64}, Dict()) isa T7{Float64}
	@test_throws TypeError StructTypes.constructfrom(T7{String}, Dict())
end