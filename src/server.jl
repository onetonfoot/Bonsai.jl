import HTTP
using HTTP: Response
using HTTP:Sockets
using HTTP.Sockets: IPAddr
using HTTP.Streams: Stream
import JSON

include("router.jl")

create_response(response::Response) = response

function create_response(data::AbstractString)
    response = Response(data)
    HTTP.setheader(response, "Content-Type" => "text/html")
    response
end

function create_response(data::AbstractDict)
    response = response |> JSON.json |> Response
    HTTP.setheader(response, "Content-Type" => "application/json")
    response
end

function create_response(data::Any)
    @warn "Unknown response type will pretend its json"
    response = response |> JSON.json |> Response
    HTTP.setheader(response, "Content-Type" => "application/json")
    response
end

function start(router; port=8081, four_oh_four = x -> "404")
    @info "Starting server on port: $port"
    server = Sockets.listen(port)

    @async HTTP.serve(Sockets.localhost, port; server=server) do request
        trie = router.routes[request.method]
        url = request.target
        @debug url
        handler = get_handler(trie, url, four_oh_four)
        request |> handler |> create_response
    end
    server
end

stop(server) = close(server)
