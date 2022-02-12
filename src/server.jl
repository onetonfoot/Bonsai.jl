using Revise
using Sockets
using HTTP: RequestHandlerFunction

export start

# Stolen from here
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

struct CancelToken
    cancelled::Ref{Bool}
    cond::Threads.Condition
end

CancelToken() = CancelToken(Ref(false), Threads.Condition())

function Base.close(token::CancelToken)
    lock(token.cond) do
        token.cancelled[] = true
        notify(token.cond)
    end
end
Base.isopen(token::CancelToken) = lock(() -> !token.cancelled[], token.cond)
Base.wait(token::CancelToken)   = lock(() -> wait(token.cond), token.cond)


# -------------------------------------------------------------------------------
# The server function
function run_server(serve, token::CancelToken, host=ip"127.0.0.1", port=8081)
    # @info "Starting HTTP server on address: $inet"
    addr = Sockets.InetAddr(host, port)

    server_sockets = Channel(1)
    @sync begin
        @async_logged "Server" begin
            while isopen(token)
                @info "Starting server on $port"
                socket = Sockets.listen(addr)
                try
                    put!(server_sockets, socket)
                    Base.invokelatest(serve, socket)
                catch exc
                    if exc isa Base.IOError && !isopen(socket)
                        # Ok - server restarted
                        continue
                    end
                    close(socket)
                    rethrow()
                end
            end
            @info "Exited server loop"
        end

        @async_logged "Revision loop" begin
            # This is like Revise.entr but we control the event loop. This is
            # necessary because we need to exit this loop cleanly when the user
            # cancels the server, regardless of any revision event.
            while isopen(token)
                @info "Revision event"
                wait(Revise.revision_event)
                Revise.revise(throw=true)
                # Restart the server's listen loop.
                close(take!(server_sockets))
            end
            @info "Exited revise loop"
        end

        wait(token)
        @assert !isopen(token)
        notify(Revise.revision_event) # Trigger revise loop one last time.
        @info "Server done"
    end
end

function ws_upgrade(http::HTTP.Stream)
    # adapted from HTTP.WebSockets.upgrade; 
    HTTP.setstatus(http, 101)
    HTTP.setheader(http, "Upgrade" => "websocket")
    HTTP.setheader(http, "Connection" => "Upgrade")
    key = HTTP.header(http, "Sec-WebSocket-Key")
    HTTP.setheader(http, "Sec-WebSocket-Accept" => HTTP.WebSockets.accept_hash(key))
    HTTP.startwrite(http)
    io = http.stream
    return HTTP.WebSockets.WebSocket(io; server=true)
end

function four_o_four(stream::HTTP.Stream)
    HTTP.setstatus(stream, 404)
end


function start(
      app::Router;
      host=ip"0.0.0.0", 
      port=8081,
      kw...)
    function serve(server)
        HTTP.serve(server = server, stream=true, kw...) do stream::HTTP.Stream
            try 
                handler = match_handler(app, stream)
                middleware = match_middleware(app, stream)

                if !isnothing(handler)
                    push!(middleware, (stream, next) -> handler(stream))
                end

                all_handlers = combine_middleware(middleware)
                HTTP.handle(HTTP.StreamHandlerFunction(all_handlers), stream)
            catch e
                error_handler = stream -> app.error_handler(stream, e)
                HTTP.handle(HTTP.StreamHandlerFunction(error_handler), stream)
            end
        end
    end

    @sync begin
        token = CancelToken()
        @async run_server(serve, token, host, port)
        try 
            while true
                s = readline()
                if strip(s) == "q"
                    break
                else 
                    continue
                end
            end
        catch e
            if e isa InterruptException
            else
                rethrow(e)
            end
        finally
            close(token)
        end
    end
end