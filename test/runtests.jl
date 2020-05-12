include("router.jl")
include("app.jl")
include("files.jl")

@testset "ws echo" begin
    server = ws_serve(port = 8082) do ws
        data = readavailable(ws)
        write(ws, data)
    end

    HTTP.WebSockets.open("ws://127.0.0.1:8082") do ws
        write(ws, "Hello")
        x = readavailable(ws)
        @test String(x) == "Hello"
    end
    close(server);
end
