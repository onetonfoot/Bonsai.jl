import HTTP
using HTTP:Sockets
using HTTP.Sockets: IPAddr
using HTTP.Streams: Stream
using HTTP.URIs:  URI
using HTTP.Messages: Response
import JSON

include("router.jl")
include("context.jl")

# TODO need unit tests for create_response


function create_response(data::AbstractString)
    response = HTTP.Response(data)
    HTTP.setheader(response, "Content-Type" => "text/plain")
    response
end

function create_response(data::AbstractDict)
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

function ws_serve(f::Function;
    port = 8081, binary = false, verbose = false, timeout = 3)

    server = Sockets.listen(UInt16(port))

    task = @async HTTP.listen(Sockets.localhost, port; server = server, verbose = verbose) do http
        HTTP.WebSockets.upgrade(http; binary = binary) do ws
            while !eof(ws)
                f(ws)
            end
        end
    end

    check_server_started(server, task)
    @info "Started websocket server on port: $port"
    server
end


function http_serve(router::Router; port = 8081, timeout = 3.0, four_o_four = four_o_four)

    router.routes

    server = Sockets.listen(UInt16(port))
    task = @async HTTP.serve(Sockets.localhost, port; server = server) do request
        trie = router.routes[request.method]
        uri =  URI(request.target)
        handler, route = get_handler(trie, String(uri.path), four_o_four)
        Cassette.overdub(HandlerCtx() ,handler, request) |> x -> _create_response(x, uri.path)
    end

    # For some reason this request is needed to update Routes in the sever
    @assert HTTP.get("http://localhost:$port/").status == 200
    check_server_started(server, task, timeout)
    @info "Started HTTP server on port: $port"

    server
end

# TODO: Should warn if server is already closed
stop(server) = close(server)