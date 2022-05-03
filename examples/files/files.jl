using Bonsai, FilePaths
using FilePathsBase: /

const folder = Path(@__DIR__) / "data"
const app = App()

app.get("/") do stream
    Bonsai.write(stream , folder / "index.html")
end

OpenAPI(app)

start(app, port=10000)
wait(app)
