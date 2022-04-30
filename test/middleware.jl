using Bonsai
using Bonsai: combine_middleware, Middleware
using URIs
using Dates

t = false
c = false

@testset "combine_middleware" begin

	function timer(stream, next)
		x = now()
		next(stream)
		elapsed = x - now()
		global t
		t = true
	end

	function cors(stream, next)
		next(stream)
		global c
		c = true
	end

	fn = combine_middleware([timer, cors ])
	fn(nothing)
	@test c && t
end