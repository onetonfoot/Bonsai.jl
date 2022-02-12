using JSON2Julia: Router, register!, @p_str
using HTTP: Stream, Request
using HTTP

function index(req::Stream)

end

function index(req::HTTP.Stream)

end

methods(index, (Stream, ))

methods(index)

router = Router()

register!(router, p"/", "GET", index)