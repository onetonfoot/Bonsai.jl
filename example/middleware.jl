using Bonsai, Dates

function timer(stream, next)
    x = now()
    # the next middleware or handler in the stack
    next(stream)
    elapsed = now() - x
    @info "$(stream.message.target) took $elapsed" 
end

function file_handler(stream)
    file = read(joinpath(@__DIR__, "index.html"))
    write(stream, file)
end

function main()
    router = Router()
    get!(router, "*", file_handler)
    all!(router, timer)
    wait(start(router))
end

main()