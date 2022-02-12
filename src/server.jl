using Revise
using Sockets
using HTTP: RequestHandlerFunction

export start

# Live reload functionality is adapted from here
# https://github.com/JuliaWeb/HTTP.jl/issues/587

# Due to some issues with InteruptExceptions we need to implement this 
# in a different way
# https://github.com/JuliaLang/julia/issues/25790#issuecomment-618986924

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
    cancelled::Threads.Atomic{Bool}
    restarts::Threads.Atomic{Int}
    cond::Threads.Condition
end

CancelToken() = CancelToken(
    Threads.Atomic{Bool}(false),  
    Threads.Atomic{Int}(0),  
    Threads.Condition()
)

function Base.close(token::CancelToken)
    lock(token.cond) do
        token.cancelled[] = true
        notify(token.cond)
        notify(Revise.revision_event);
    end
end
Base.isopen(token::CancelToken) = lock(() -> !token.cancelled[], token.cond)
Base.wait(token::CancelToken)   = lock(() -> wait(token.cond), token.cond)

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

    token = CancelToken()
    addr = Sockets.InetAddr(host, port)
    running  = Threads.Atomic{Bool}(true)
    restarts  = Threads.Atomic{Int}(0)
    server_sockets = Channel(1)

    @info "Starting server"
    @async_logged "Server" begin
        while isopen(token)
            socket = Sockets.listen(addr)
            try
                put!(server_sockets, socket)
                Base.invokelatest(serve, socket)
            catch e
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

    token
end