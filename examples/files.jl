using Bonsai, FilePaths
using FilePathsBase: /
using HTTP

folder = Path(@__DIR__) / "data"
app = App()
app.hot_reload = true

app.get("/") do stream
    Bonsai.write(stream, folder / "index.html")
    HTTP.setheader(stream, "Content-Type" => "text/plain")
end

app.get("**") do stream, next
    try
        next(stream)
    catch e
        @error e
        Bonsai.write(stream, Body(error=repr(e)))
    end
end


start(app, port=10001)
wait(app)
stop(app)