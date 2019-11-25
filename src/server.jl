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


function check_server_started(server, task::Task, timeout=3.0)

    task_failed = timedwait(() -> !istaskdone(task), float(timeout))

    if task_failed == :timed_out
        close(server)
        rethrow(task.exception)
    end;
end

function ws_serve(f :: Function;
    port = 8081,
    binary=false, verbose=false, timeout=3
    )

    server = Sockets.listen(UInt16(port))

    task = @async HTTP.listen(Sockets.localhost, port; server=server, verbose=verbose) do http
        HTTP.WebSockets.upgrade(f, http; binary=binary)
    end

    check_server_started(server, task)
    server
end


function http_serve(f :: Function; port = 8081, timeout=3.0)
    server = Sockets.listen(UInt16(port))
    task = @async HTTP.serve(f, Sockets.localhost, port; server=server) 
    check_server_started(server, task, timeout)
    server
end


function start(router; http_port = 8081, ws_port = http_port + 1, four_oh_four = x -> "404")
    @info "Starting server on port: $http_port"

    http_server = http_serve() do request
        trie = router.routes[request.method]
        uri =  URI(request.target)
        handler, route = get_handler(trie, String(uri.path), four_oh_four)
        context = Context(request, uri, route)
        @debug context
        context |> handler |> create_response
    end

    #For some reason this request is needed to update Routes in the sever
    @assert HTTP.get("http://localhost:$http_port/").status == 200

    # TODO if you want to start just a http or just  ws server
    # Should split into ws_start and HTTP start that just take a router
    ws_server = ws_serve(port=ws_port) do ws
        while !eof(ws)
            data = readavailable(ws)
            write(ws, data)
        end
    end


    Server(http_server, ws_server)
end

struct Server
    http_server
    ws_server
end

function stop(server::Server) 
    close(server.http_server)
    close(server.ws_server)
end
