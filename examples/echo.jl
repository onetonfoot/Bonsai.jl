using Bonsai, FilePaths
using FilePathsBase: /
using AbstractTrees: print_tree
using HTTP: send

const app = App()
const static = Path(@__DIR__)

app.get("/") do stream
    Bonsai.write(stream, static / "index.html")
end

app.get("/ws") do stream
    ws_upgrade(stream) do ws
        for msg in ws
            @info msg
            send(ws, msg)
        end
    end
end

start(app, port=9999, verbose=true)