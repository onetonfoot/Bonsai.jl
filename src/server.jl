using Sockets
using HTTP: setstatus, setheader, header, hasheader
using HTTP.WebSockets: WebSocket, WebSocketError

export start, stop


# Much of the code is adapted from here
# https://github.com/JuliaWeb/HTTP.jl/issues/587

# Some other related issues
# https://github.com/JuliaLang/julia/issues/36217
# https://github.com/JuliaLang/julia/issues/25790#issuecomment-618986924

# using Base.Threads: Atomic
# using Base: check_channel_state

function start(
    app::App;
    host=ip"0.0.0.0",
    port=8081,
    kwargs...)


    # https://github.com/JuliaLang/julia/issues/46635

    errormonitor(
        # can't use thread @spawn otherwise this
        # breaks revise
        @async while isopen(app.cancel_token)
            addr = Sockets.InetAddr(host, port)
            tcp_server = Sockets.listen(addr)
            app.server = tcp_server

            http_server = HTTP.serve!(
                # doesn't seem to make a difference
                app,
                host, port; server=tcp_server, stream=true, kwargs...
            )

            wait(Revise.revision_event)
            @debug "server revision event"
            Revise.revise(throw=true)

            if !isopen(app.cancel_token)
                break
            end

            close(tcp_server)
            sleep(0.1)
        end
    )
    
    @info "Server running $(host):$(port), hold Ctrl+C to stop"

    try
        wait(app.cancel_token)
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

function stop(app::App)
    try
        close(app.cancel_token)
    catch
    finally
        app.cancel_token = CancelToken()
    end

    try
        close(app.server)
    catch
    finally
        app.server = nothing
    end
end