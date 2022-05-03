# using Bonsai, HTTP

# function timer_middleware(stream, next)
#     x = now()
#     # the next middleware or handler in the stack
#     next(stream)
#     elapsed = now() - x
#     @info "$(stream.message.target) took $elapsed" 
# end

# function error_middleware(stream, next)
#     try
#         next(stream)
#     catch e
#         @error e
#         code = InternalServerError()
#         Bonsai.write(stream, HTTP.statustext(code), code)
#     end
# end

# function error_handler(stream)
#     error("Oh no")
# end

# function index_handler(stream)
#     Bonsai.write(stream, "ok")
# end


# router = Router()
# # make sure error handler is the first middleware
# all!(router, "*", error_middleware)
# all!(router, "*", timer_middleware)
# get!(router, "*", file_handler)
# get!(router, "/error", error_handler)
# wait(start(router))
