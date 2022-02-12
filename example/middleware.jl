using Bonsai, Dates

function timer(stream, next)
    x = now()
    # the next middleware or handler in the stack
    next(stream)
    elapsed = now() - x
    # @info stream.message.target elapsed
end

function file_handler(stream)
    file = read(joinpath(@__DIR__, "index.html"))
    write(stream, file)
end

function main()
    router = Router()
    register!(router, "*", GET, file_handler)
    middleware!(router, timer)
    start(router)
end

main()
