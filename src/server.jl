using Revise
using Sockets
using HTTP: setstatus, setheader, header, hasheader
using HTTP.WebSockets: WebSocket, WebSocketError

export start, stop

# Due to some issues with InteruptExceptions we need close with a cancel token
# https://github.com/JuliaLang/julia/issues/25790#issuecomment-618986924

# Much of the code is adapted from here
# https://github.com/JuliaWeb/HTTP.jl/issues/587

# HTTP use serve and (non-blocking) server! 
# then to shutdown close and forceclose. It would be nice
# to follow these conventions aswell.

function start(
    app::App;
    host=ip"0.0.0.0",
    port=8081,
    kwargs...)

    addr = Sockets.InetAddr(host, port)

    function handler_function(stream::HTTP.Stream)
        try
            app(stream)
        catch e
            rethrow(e)
        end
    end

    app.inet_addr = addr
    app.cancel_token = CancelToken()
    server = Sockets.listen(addr)

    # Seems to be some changes to how this functions with HTTP 1.0
    # should probably revist this code once we don't support 0.9 anymore
    @async HTTP.serve(
        handler_function,
        host, port; server=server, stream=true, kwargs...
    )

    app.server = server

    @info "Started Server on $(host):$(port)"

    wait(app)

    try
        stop(app)
    catch 
        
    end
end

function stop(app::App)
    isnothing(app.server) && return

    if isopen(app.server)
        close(app.cancel_token)
        close(app.server)
        app.inet_addr = nothing
        @info "Stopped Server"
    end
end

function Base.isopen(app::App)
    isnothing(app.server) && return false
    isopen(app.server)
end


Base.wait(app::App) = wait(app.cancel_token)