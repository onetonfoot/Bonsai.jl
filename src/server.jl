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



# function ws_upgrade(http::HTTP.Stream)
#     # adapted from HTTP.WebSockets.upgrade; note that here the upgrade will always
#     # have  the right format as it always triggered by after a Response
#     HTTP.setstatus(http, 101)
#     HTTP.setheader(http, "Upgrade" => "websocket")
#     HTTP.setheader(http, "Connection" => "Upgrade")
#     key = HTTP.header(http, "Sec-WebSocket-Key")
#     HTTP.setheader(http, "Sec-WebSocket-Accept" => HTTP.WebSockets.accept_hash(key))
#     HTTP.startwrite(http)
#     io = http.stream
#     return HTTP.WebSockets.WebSocket(io; server=true)
# end

function start(
    app::App;
    host=ip"0.0.0.0",
    port=8081,
    kwargs...)


    if !isnothing(app.redocs)
        docs = create_docs(OpenAPI(app))
        app.get(app.redocs) do stream
            HTTP.setheader(stream, "Content-Type" => "text/html; charset=UTF-8")
            HTTP.setstatus(stream, 200)
            Base.write(stream, docs)
        end
    end

    function handler_function(stream::HTTP.Stream)
        try
            app(stream)
        catch e
            @error "an error occured" e = typeof(e)
            # HTTP.setstatus(stream, 500)
            # Base.write(stream, HTTP.statustext(500))
            rethrow(e)
        end
    end

    function serve_fn(server) end

    token = app.cancel_token
    addr = Sockets.InetAddr(host, port)
    app.inet_addr = addr
    running = Threads.Atomic{Bool}(true)
    restarts = Threads.Atomic{Int}(0)
    server_sockets = Channel(1)

    server = Sockets.listen(addr)

    @async HTTP.serve(
        handler_function,
        host, port; server=server, stream=true, kwargs...
    )

    app.server = server

    # @info "Starting server"
    # @async_logged "Server" begin
    #     while isopen(token)
    #         # It this needed? Do we need to start a new server if we already invoke the latest app handlers?
    #         socket = Sockets.listen(addr)
    #         try
    #             put!(server_sockets, socket)
    #             # Is this involde latest needed?
    #             serve_fn(socket)
    #         catch e
    #             app.inet_addr = nothing
    #             if e isa Base.IOError && running[]
    #                 continue
    #             else
    #                 rethrow()
    #             end
    #         end
    #     end
    #     @info "Shutdown server"
    # end

    # This is like Revise.entr but we control the event loop. This is
    # necessary because we need to exit this loop cleanly when the user
    # cancels the server, regardless of any revision event.
    @async_logged "Revision Loop" while isopen(token)
        wait(Revise.revision_event)
        @info "Revision event"
        #     Revise.revise(throw=false)
        #     close(take!(server_sockets))
        #     # stop(app)
        #     # start(app)
        #     restarts[] += 1
        #     if isopen(token)
        #         @info "Revision event $(restarts[])"
        #     end
    end



    @info "Started Server"
    app
end

function stop(app::App)
    close(app.cancel_token)
    close(app.server)
    app.inet_addr = nothing
end

Base.wait(app::App) = wait(app.cancel_token)