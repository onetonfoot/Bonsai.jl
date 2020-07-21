import HTTP
using HTTP:Sockets
using HTTP.Sockets: IPAddr
using HTTP.Streams: Stream
using HTTP.URIs:  URI
using HTTP.Messages: Response
using HTTP.Handlers
import JSON

# TODO need unit tests for create_response
include("app.jl")
include("web_socket.jl")

function create_response(data::AbstractString)::Response
    response = HTTP.Response(data)
    HTTP.setheader(response, "Content-Type" => "text/plain")
    response
end

function create_response(data::AbstractDict)::Response
    response = data |> JSON.json |> HTTP.Response
    HTTP.setheader(response, "Content-Type" => "application/json")
    response
end

create_response(data::Any) = data  

function _create_response(data::Any, path)
    response = create_response(data)

    if response isa Response
        response
    else
        @warn "Unknown response $(typeof(data)) for $path pretending it is a string"
        create_response(repr(data))
    end
end

function check_server_started(server, task::Task, timeout = 3.0)

    task_failed = timedwait(()->!istaskdone(task), float(timeout))

    if task_failed == :timed_out
        close(server)
        rethrow(task.exception)
    end;
end


"""
Starts the application

Args:
* app::App

Kw Args:
* port - the port you want to server on
* four_o_four - handler for unmatched routes
"""
function start(app::App; port = 8081, four_o_four = four_o_four)

    router = app.router
    server = Sockets.listen(UInt16(port))
    app.server = server

    @info "Starting HTTP server on port: $port"

    task = @async HTTP.serve(Sockets.localhost, port; server = server, stream=true) do stream::HTTP.Stream
        if HTTP.WebSockets.is_upgrade(stream.message)
            ws = ws_upgrade(stream)
            return ws_handler(ws)
        else
            fn = RequestHandlerFunction() do request
                trie = router.routes[request.method]
                uri =  URI(request.target)
                handler, route = get_handler(trie, String(uri.path), four_o_four)
                Cassette.overdub(HandlerCtx(metadata = HandlerMetadata(route)), handler, request) |> x->_create_response(x, uri.path)
            end
            HTTP.handle(fn, stream)
        end
    end

    app.server_task = task
    # For some reason this request is needed to update Routes in the sever
    # @assert HTTP.get("http://localhost:$port/").status == 200
    # timeout = 10.0
    # check_server_started(server, task, timeout)
    app
end

# TODO: Should warn if server is already closed
"""Stops the app"""
stop(app::App) = close(app.server)

Base.wait(app::App) = wait(app.server_task)