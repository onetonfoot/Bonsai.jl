"""
    ws_upgrade(http::HTTP.Stream)
Upgrade the HTTP request in the stream to a websocket.
"""
function ws_upgrade(http::HTTP.Stream)
    # adapted from HTTP.WebSockets.upgrade; note that here the upgrade will always
    # have  the right format as it always triggered by after a Response
    HTTP.setstatus(http, 101)
    HTTP.setheader(http, "Upgrade" => "websocket")
    HTTP.setheader(http, "Connection" => "Upgrade")
    key = HTTP.header(http, "Sec-WebSocket-Key")
    HTTP.setheader(http, "Sec-WebSocket-Accept" => HTTP.WebSockets.accept_hash(key))
    HTTP.startwrite(http)

    io = http.stream
    return HTTP.WebSockets.WebSocket(io; server=true)
end

struct WebSocketPath
    s::String
end

macro ws_str(s)
    WebSocketPath(s)
end
