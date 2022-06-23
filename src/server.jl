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


macro async_logged(exs...)
    if length(exs) == 2
        taskname, body = exs
    elseif length(exs) == 1
        taskname = "Task"
        body = only(exs)
    end
    quote
        @async try
            $(esc(body))
        catch exc
            @error string($(esc(taskname)), " failed") exception = (exc, catch_backtrace())
            rethrow()
        end
    end
end

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

    function serve_fn(server) end

    app.inet_addr = addr
    app.cancel_token = CancelToken()

    server = Sockets.listen(addr)

    @async HTTP.serve(
        handler_function,
        host, port; server=server, stream=true, kwargs...
    )

    app.server = server
    @info "Started Server"
end

function stop(app::App)
    @info "Stopping Server"
    close(app.cancel_token)
    close(app.server)
    app.inet_addr = nothing
end

Base.wait(app::App) = wait(app.cancel_token)