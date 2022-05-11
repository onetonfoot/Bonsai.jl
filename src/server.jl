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

    addr = Sockets.InetAddr(host, port)

    if !isnothing(app.docs)
        # app.get(app.docs) do stream
        #     @info "docs"
        #     html = create_docs_html(app)
        #     Bonsai.write(stream, Body(html))
        #     Bonsai.write(stream, Header(content_type="text/html; charset=UTF-8"))
        # end

        # app.get(app.docs * ".json") do stream
        #     @info "docs json"
        #     json = JSON3.write(OpenAPI(app))
        #     Bonsai.write(stream, Body(json))
        # end
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

    app.inet_addr = addr
    app.cancel_token = CancelToken()

    server = Sockets.listen(addr)

    @async HTTP.serve(
        handler_function,
        host, port; server=server, stream=true, kwargs...
    )

    app.server = server
    @info "Started Server"
    # wait(app.cancel_token)

    # if !isnothing(app.inet_addr)
    #     stop(app)
    # end
end

function stop(app::App)
    @info "Stopping Server"
    close(app.cancel_token)
    close(app.server)
    app.inet_addr = nothing
end

Base.wait(app::App) = wait(app.cancel_token)