using Bonsai, FilePaths
using FilePathsBase: /
using AbstractTrees: print_tree

const app = App()
const static = Path(@__DIR__)

app.get("/") do stream
    Bonsai.write(stream, static / "index.html")
end

app.get("/ws") do stream
    ws = Bonsai.ws_upgrade(stream)
    try
        while !eof(ws)
            data = readavailable(ws)
            s = String(data)
            write(ws, s)
        end
    catch e
        @error e
    finally
        close(ws)
    end
end


start(app, port=9999, verbose=true)
stop(app)
wait(router)