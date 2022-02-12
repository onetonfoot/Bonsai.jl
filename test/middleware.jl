using Bonsai: combine_middleware
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


