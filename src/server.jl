using Revise
using Sockets
using HTTP: setstatus, setheader, header, hasheader
using HTTP.WebSockets: WebSocket, accept_hash, check_upgrade, WebSocketError

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


function ws_upgrade(http::HTTP.Stream; binary=false)

    @info "upgrading"

    check_upgrade(http)
    if !hasheader(http, "Sec-WebSocket-Version", "13")
        throw(WebSocketError(0, "Expected \"Sec-WebSocket-Version: 13\"!\n" *
                                "$(http.message)"))
    end

    setstatus(http, 101)
    setheader(http, "Upgrade" => "websocket")
    setheader(http, "Connection" => "Upgrade")
    key = header(http, "Sec-WebSocket-Key")
    setheader(http, "Sec-WebSocket-Accept" => accept_hash(key))

    startwrite(http)

    io = http.stream
    req = http.message
    ws = WebSocket(io; binary=binary, server=true, request=req)
    return ws
end

struct NoHandler <: Exception 
    target::String
end

function start(
      app::Router;
      host=ip"0.0.0.0", 
      port=8081,
      kwargs...)

    function handler_function(stream::HTTP.Stream)
        try 
            handler = match_handler(app, stream)
            all_handlers = match_middleware(app, stream)

            if !isnothing(handler)
                push!(all_handlers, (stream, next) -> handler(stream))
            end

            if isempty(all_handlers)
                throw(NoHandler(stream.message.target))
            end

            combined_handler = combine_middleware(all_handlers)

            fn = stream -> begin
                try
                    combined_handler(stream)
                catch e
                    app.error_handler(stream, e)
                end
            end  

            fn(stream)
        catch e
            rethrow(e)
        end
    end

    function serve_fn(server)
        HTTP.serve(
            HTTP.StreamHandlerFunction(handler_function), 
            host, port; server=server, kwargs...
        ) 
    end

    token = app.cancel_token
    addr = Sockets.InetAddr(host, port)
    app.inet_addr = addr
    running  = Threads.Atomic{Bool}(true)
    restarts  = Threads.Atomic{Int}(0)
    server_sockets = Channel(1)

    @info "Starting server"
    @async_logged "Server" begin
        while isopen(token)
            socket = Sockets.listen(addr)
            try
                put!(server_sockets, socket)
                Base.invokelatest(serve_fn, socket)
            catch e
                app.inet_addr = nothing
                if e isa Base.IOError && running[] 
                    continue
                else
                    rethrow()
                end
            end
        end
        @info "Shutdown server"
    end

    # This is like Revise.entr but we control the event loop. This is
    # necessary because we need to exit this loop cleanly when the user
    # cancels the server, regardless of any revision event.
    @async_logged "Revision Loop" while isopen(token)
            wait(Revise.revision_event)
            Revise.revise(throw=true)
            close(take!(server_sockets))
            restarts[] += 1
            if isopen(token)
                @info "Revision event $(restarts[])"
            end
    end

    app
end

function stop(app::Router) 
    close(app.cancel_token)
    app.inet_addr = nothing
end
Base.wait(app::Router) = wait(app.cancel_token)