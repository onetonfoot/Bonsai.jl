using Bonsai, FilePaths
using FilePathsBase: /
using HTTP

app = App()

app.get["/"] = function(stream)
    html = Path(@__DIR__) / "html"
    Bonsai.write(stream, Body(html / "index.html"))
end

app.get["/files/{path:.*}"] = function(stream)
    (path,) =  Bonsai.read(stream,  Route(path=AbstractPath))
    file = Path(@__DIR__) / "data" / path
    Bonsai.write(stream, Body(file))
end

start(app, port=10001)