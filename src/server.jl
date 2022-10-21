using Sockets
using HTTP: setstatus, setheader, header, hasheader
using HTTP.WebSockets: WebSocket, WebSocketError

export start, stop

# Due to some issues with InteruptExceptions we need close with a cancel token
# https://github.com/JuliaLang/julia/issues/25790#issuecomment-618986924

# Much of the code is adapted from here
# https://github.com/JuliaWeb/HTTP.jl/issues/587

using Base.Threads: Atomic
using Base: check_channel_state


# HTTP use serve and (non-blocking) server! 
# then to shutdown close and forceclose. It would be nice
# to follow these conventions aswell.

# function start(
#     app::App,
#     addr::InetAddr,
#     kwargs...
#     )

# end

# https://github.com/JuliaLang/julia/issues/36217

function start(
    app::App;
    host=ip"0.0.0.0",
    port=8081,
    kwargs...)

    addr = Sockets.InetAddr(host, port)

    app.inet_addr = addr
    app.cancel_token = CancelToken()
    server = Sockets.listen(addr)

    # Seems to be some changes to how this functions with HTTP 1.0
    # should probably revist this code once we don't support 0.9 anymore
    @async HTTP.serve(
        # doesn't seem to make a difference
        x -> Base.invokelatest(app, x),
        host, port; server=server, stream=true, kwargs...
    )

    app.server = server

    @info "Started Server on $(host):$(port)"

    # This is like Revise.entr but we control the event loop. This is
    # necessary because we need to exit this loop cleanly when the user
    # cancels the server, regardless of any revision event.
    try
        @async while isopen(app.cancel_token)
            wait(Revise.revision_event)

            @info "Revision event"

            if !isopen(app.cancel_token)
                break
            end

            close(server)
            sleep(0.1)
            server = Sockets.listen(addr)
            app.server = server

            @async HTTP.serve(
                app,
                host, port; server=server, stream=true, kwargs...
            )

        end

        wait(app.cancel_token)

        @info "Exited revise loop"
    catch e
        if e isa InterruptException
        else
            @error e
        end
    finally
        stop(app)
        notify(Revise.revision_event)
    end
end

function restart(app::App)

end

function stop(app::App)
    isnothing(app.server) && return

    try
        close(app.cancel_token)
        close(app.server)
    catch
        # app.inet_addr = nothing
    end
end

function Base.isopen(app::App)
    isnothing(app.server) && return false
    isopen(app.server)
end


Base.wait(app::App) = wait(app.cancel_token)