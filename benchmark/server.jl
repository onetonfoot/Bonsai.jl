using Bonsai, JSON3

const app = App()

function index(stream)
    Bonsai.write(stream, Body("ok"))
end

app.get["/"] = index

# TODO: make some plots with Makie

function benchmark(nconnections, total_reqs)
    #  bombardier -c 1000 -n 100000 http://localhost:7517 -o json
end



start(app, port=7517)