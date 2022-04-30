using Test
using Bonsai: R
using Bonsai.R: Node, find, isvariable, segment

@testset "router" begin
	r = R.Router()
	# matches
	R.register!(r, "GET", "/fish/{id}", x -> 1)
	R.register!(r, "GET", "/fish/super", x -> 2)
	R.register!(r, "GET", "/fish/**", x -> 3)
	# wrong method
	R.register!(r, "PUT", "/fish/**", x -> 4)
	# wrong path
	R.register!(r, "PUT", "/turtle/super", x -> 5)
	p = "/fish/super"
	params = R.Params()
	segments = split(p, "/"; keepempty=false)
	ms = R.matchall(r.routes, params, "GET", segments, 1)
	@test sort(map(x -> x(nothing), ms)) == [1,2,3]
end