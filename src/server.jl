import HTTP
using HTTP: Response
using HTTP:Sockets
using HTTP.Sockets: IPAddr
using HTTP.Streams: Stream
using HTTP.URIs:  URI
import JSON

include("router.jl")
include("context.jl")

create_response(response :: Response) = response

function create_response(data :: AbstractString)
    response = Response(data)
    HTTP.setheader(response, "Content-Type" => "text/html")
    response
end

function create_response(data :: AbstractDict)
    response = data |> JSON.json |> Response
    HTTP.setheader(response, "Content-Type" => "application/json")
    response
end

function create_response(data :: Any)
    @warn "Unknown response type will pretend its json"
    response = data |> JSON.json |> Response
    HTTP.setheader(response, "Content-Type" => "application/json")
    response
end


function check_server_started(server, task :: Task, timeout=3.0)

    task_failed = timedwait(() -> !istaskdone(task), float(timeout))

    if task_failed == :timed_out
        close(server)
        rethrow(task.exception)
    end;
end

function ws_serve(f :: Function;
    port = 8081, binary=false, verbose=false, timeout=3)

    server = Sockets.listen(UInt16(port))

    task = @async HTTP.listen(Sockets.localhost, port; server=server, verbose=verbose) do http
        HTTP.WebSockets.upgrade(http; binary=binary) do ws
            while !eof(ws)
                f(ws)
            end
        end
    end

    check_server_started(server, task)
    @info "Started websocket server on port: $port"
    server
end


function http_serve(router :: Router; port = 8081, timeout=3.0, four_oh_four = x -> "404")

    server = Sockets.listen(UInt16(port))
    task = @async HTTP.serve(Sockets.localhost, port; server=server) do request
        trie = router.routes[request.method]
        uri =  URI(request.target)
        handler, route = get_handler(trie, String(uri.path), four_oh_four)
        context = Context(request, uri, route)
        @debug context
        context |> handler |> create_response
    end

    #For some reason this request is needed to update Routes in the sever
    @assert HTTP.get("http://localhost:$port/").status == 200
    check_server_started(server, task, timeout)
    @info "Started HTTP server on port: $port"

    server
end

stop(server) = close(server)