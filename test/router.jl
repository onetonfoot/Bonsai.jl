using Test
using Bonsai
using Bonsai: register!, Node, Params, matchall

@testset "register!" begin
	r = Node("*")

	# matches
	register!(r, GET, "/fish/{id}" , x -> 1)
	register!(r, GET, "/fish/super", x -> 2)
	register!(r, GET, "/fish/**"   , x -> 3)
	# wrong method
	register!(r, PUT, "/fish/**", x -> 4)
	# wrong path
	register!(r, PUT, "/turtle/super", x -> 5)
	p = "/fish/super"
	params = Params()
	segments = split(p, "/"; keepempty=false)
	ms = matchall(r, params, "GET", segments, 1)
	@test sort(map(x -> x(nothing), ms)) == [1,2,3]
end