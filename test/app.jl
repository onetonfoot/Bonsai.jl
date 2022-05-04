using Bonsai
using Bonsai: Params
using CodeInfoTools
using HTTP: Stream
using Bonsai: handler_writes
using StructTypes
using Test

struct A2
    data
end

StructTypes.StructType(::Type{A2}) = StructTypes.Struct()

@testset "handler_writes" begin
    app = Bonsai.App()
    app.get("/path") do stream
        Bonsai.write(stream, Headers(header="value"))
        Bonsai.write(stream, Body(x=10))
        Bonsai.write(stream, Body(a=A2(10)))
    end
    h = match(app.paths, Params(), "GET", ["path"], 1)
    # for debuging
    # code_inferred(h.fn, Tuple{Stream})
    # Bonsai.handler_writes(h.fn)
    @test length(Bonsai.handler_writes(h.fn)) == 3
end

@testset "handler_reads" begin
    app = Bonsai.App()
    app.get("/path") do stream
        Bonsai.read(stream, Headers(A2))
        Bonsai.read(stream, Query(A2))
        Bonsai.read(stream, Body(A2))
    end
    h = match(app.paths, Params(), "GET", ["path"], 1)
    @test length(Bonsai.handler_reads(h.fn)) == 3
end

# using Bonsai, HTTP

# app = Bonsai.App()

# app.get("/data") do stream
#     @info "SERVER"
#     Bonsai.write(stream, Body(rand(10^6)))
# end

# start(app, port=7864)

# stop(app)

# res = HTTP.get("http://localhost:7864/data")

# try
#     start(app, port=7864)
#     sleep(1)
#     #http://localhost:7864/data
#     res = HTTP.get("http://localhost:7864/data")
#     @info res
# catch e
#     @error e
# finally
#     stop(app)
# end

# how to get this to pass
# app = Bonsai.App()

# "some function documenation"
# app.get("/test-docs") do stream
# end