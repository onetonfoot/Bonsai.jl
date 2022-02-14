using Bonsai
using Bonsai: combine_middleware, match_middleware
using Dates

t = false
c = false

@testset "combine_middleware" begin

	function timer(stream, next)
		x = now()
		next(stream)
		elapsed = x - now()
		@info elapsed
		global t
		t = true
	end

	function cors(stream, next)
		next(stream)
		global c
		c = true
	end

	fn = combine_middleware([cors, timer ])
	fn(nothing)
	@test c && t
end

@testset "middleware!" begin
	r = Router()
	function f(stream, next) end
	middleware!(r, f)
	@test all(length.(values(r.middleware)) .== 1)
end

@testset "match_middleware" begin
	r = Router()
	function f(stream, next) end
	middleware!(r, f)
	@test length(match_middleware(r, GET, "/")) == 1
end