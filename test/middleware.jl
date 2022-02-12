using JSON2Julia: combine_middleware
using Dates

function timer(stream, next)
	x = now()
	next(stream)
	elapsed = x - now()
	@info elapsed
end

stream = nothing

function cors(stream, next)
	@info "CORS"
	next(stream)
end


# fn = apply_middleware(stream, [timer])

fn = combine_middleware(stream, [cors, timer ])
