using Revise
using Sockets
using HTTP: setstatus, setheader, header, hasheader
using HTTP.WebSockets: WebSocket, WebSocketError

export start, stop

# Due to some issues with InteruptExceptions we need to implement live
# reload using a cancel token
# https://github.com/JuliaLang/julia/issues/25790#issuecomment-618986924

# Much of the code is adapted from here
# https://github.com/JuliaWeb/HTTP.jl/issues/587


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

    @async HTTP.serve(
        handler_function,
        host, port; server=server, stream=true, kwargs...
    )

    app.server = server
    @info "Started Server"
    wait(app)
end

function stop(app::App)
    @info "Stopping Server"
    close(app.cancel_token)
    close(app.server)
    app.inet_addr = nothing
end

Base.wait(app::App) = wait(app.cancel_token)