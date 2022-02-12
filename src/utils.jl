
function isvalidpath(path::AbstractString)
    # https://stackoverflow.com/questions/4669692/valid-characters-for-directory-part-of-a-url-for-short-links
    re = r"^[/a-zA-Z0-9-_.-~!$&'()*+,;@]+$"
    m = match(re, path)
    uri = URI(path)
    m !== nothing && m.match == path && uri.path == path && !("//" in path)
end

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