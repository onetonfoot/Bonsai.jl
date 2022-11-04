using Bonsai, StructTypes, Test
using Bonsai: @data, description, get_default
using MacroTools: @capture
using Base.Meta: show_sexpr

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

@data struct T3{T} 
	z::T = 1
end 

# @macroexpand 
@data struct T4{T} 
	T1...
	z::T = 1
end 

@data struct T5
	a::Float64 = rand()
	b::Vector{String} = rand([["a", "b"]])
end 

@testset "get_default" begin
	ex  = get_default(:(b::Float = rand()))
	@test_nowarn eval(ex)
end

@testset "@data" begin
	@test T1() isa T1
	@test strip(description(T1)) == "hello"
	@test fieldnames(User) == (:id, :created, :name, :age)
	@test StructTypes.constructfrom(T1, Dict()) == T1()
	@test StructTypes.constructfrom(T3{Int}, Dict()) isa T3{Int}
	@test StructTypes.constructfrom(T3{Float64}, Dict()) isa T3{Float64}
	@test StructTypes.constructfrom(T4{Float64}, Dict()) isa T4{Float64}
	@test StructTypes.constructfrom(T5, Dict()) isa T5
end