using Test
using Bonsai: fn_kwargs, Cookie, Header

@testset "fn_kwargs" begin
	function g(s::Int; y = 10) 
		return s + 1
	end

	@test fn_kwargs(g)[:y] == 10

	function f(s; read_cookie = Cookie("chocolate"), read_header = Header("footer")) 
		return s + 1
	end

	f_kwargs = fn_kwargs(f)

	@test f_kwargs[:read_cookie] isa Cookie
	@test f_kwargs[:read_header] isa Header
end
