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

function start(router; port=8081, four_oh_four = x -> "404")
    @info "Starting server on port: $port"
    server = Sockets.listen(port)

    @async HTTP.serve(Sockets.localhost, port; server=server) do request
        trie = router.routes[request.method]
        uri =  URI(request.target)
        handler, route = get_handler(trie, String(uri.path), four_oh_four)
        context = Context(request, uri, route)
        @debug context
        context |> handler |> create_response
    end
    server
end

stop(server) = close(server)