using Bonsai
using Bonsai: combine_middleware, Middleware
using URIs
using Dates
using HTTP: Request

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
	@test combine_middleware([])(true)
end


app = App()

app.get("**") do stream, next
end

req = Request()
req.method = "GET"
req.target = "/"
match(app, req)