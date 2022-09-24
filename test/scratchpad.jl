using Bonsai
using HTTP: Request

app = App()

app.get["/"] = function(stream)
    query = Bonsai.read(
        stream,
        Query(name=Union{String, Nothing})
    )
    name = isnothing(query.name) ? "John Doe" : query.name  
    name = "hello"
    Bonsai.write( stream, Body("Hi, $name"))
end

# neither of these work?!!
# http://localhost:9091/?name=dom
# http://localhost:9091/


req = Request()
req.method = "GET"
req.target = "/"

Bonsai.gethandler(app, req)

start(app, port=9091)