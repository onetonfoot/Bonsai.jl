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

struct WebRequest
    stream::HTTP.Stream
    done::Threads.Event
end

struct HandlerQueue
    queue::Channel{WebRequest}
    count::Threads.Atomic{Int}
    shutdown::Threads.Atomic{Bool}
    function HandlerQueue(queuesize=1024)
        new(Channel{WebRequest}(queuesize), Threads.Atomic{Int}(0), Threads.Atomic{Bool}(false))
    end
end

function handle_error(stream, e)
    if e isa NoHandler
        @warn e
    else
        @error "Unhandled Error" e = (e, catch_backtrace())
    end
    request::Request = stream.message
    request.response.request = request
    HTTP.setstatus(stream, 500)
    startwrite(stream)
    Base.write(stream, request.response.body)
end

function respond(stream::HTTP.Stream, app::App)
    try
        app(stream)
    catch e
        handle_error(stream, e)
    end
end

function start(
    app::App;
    host=ip"0.0.0.0",
    port=8081,
    kwargs...)

    queue = HandlerQueue()

    function streamhandler(stream::HTTP.Stream)
        try
            app.current_connections += 1
            if app.current_connections < app.connection_limit
                t = Threads.@spawn respond(stream, app)
                wait(t)
            else
                @warn "Dropping connection..."
                HTTP.setstatus(stream, 529)
                Base.write(stream, "Server overloaded.")
            end
        catch e
            # should never hit this code
            handle_error(stream, e)
        finally
            app.current_connections -= 1
        end
    end

    # https://github.com/JuliaLang/julia/issues/46635
    errormonitor(
        # can't use thread @spawn otherwise this  breaks revise, why I don't know
        @async while isopen(app.cancel_token)
            addr = Sockets.InetAddr(host, port)
            tcp_server = Sockets.listen(addr)
            app.server = tcp_server

            http_server = HTTP.serve!(
                streamhandler,
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
        # https://github.com/JuliaLang/julia/issues/45055
        # seems to be broken on 1.9
        wait(app.cancel_token)
    catch e
        if e isa InterruptException
        else
            @error e
        end
    finally
        stop(app)
        queue.shutdown[] = true
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