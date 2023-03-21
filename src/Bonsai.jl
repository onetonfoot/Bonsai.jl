module Bonsai

# This is needed for hot reloading to work correctly
__revise_mode__ = :eval
using Revise

using HTTP, JSON3, StructTypes, Dates, FilePaths, SnoopPrecompile
import HTTP: Request, Response, Stream

include("compose.jl")
include("utils.jl")
include("http.jl")
include("mime_types.jl")
include("exceptions.jl")
include("json_schema.jl")
include("macros.jl")
include("handlers.jl")
include("io.jl")
include("static_analysis.jl")
include("cancel_token.jl")
include("middleware.jl")
include("openapi.jl")
include("app.jl")
include("router.jl")
include("web_socket.jl")
include("server.jl")

@precompile_setup begin
    # Putting some things in `setup` can reduce the size of the
    # precompile file and potentially make loading faster.
    @precompile_all_calls begin

        req = Request()
        res = Response()


        l = [
            "a",
            2,
            Dict(:x => 10),
            [1, 2, 3],
            ["a", 2],
            (:x, :y, :z)
        ]

        for x in l
            write(res, Body(x))
            req.body = res.body
            read(req, Body(typeof(x)))
        end

        function index(stream)
        end


        req.body = JSON3.write(Dict(:x => 10))
        req.target = "/1/?color=blue&amount=10"
        req.context[:params] = Dict(:id => string(10))

        reads = [
            Route(id=String),
            Query(color=String, amount=Int),
            Headers(content_type=Union{Nothing,String}),
            Body(Dict)
        ]

        for x in reads
            try
                read(req, x)
            catch
            end
        end

        app = App()
        app.get["/{id}"] = index
        app.middleware["**"] = [cors]

        # we need to remove this call until we fix JET.jl
        open_api!(app)

        redirect_stderr(devnull) do
            try
                for i in 1:10
                    port = rand(1025:60000)
                    @async start(app)
                    sleep(1)
                    if isopen(app.cancel_token)
                        break
                    end
                end
                stop(app)
            catch
            finally
                stop(app)
            end
        end

        # all calls in this block will be precompiled, regardless of whether
        # they belong to your package or not (on Julia 1.8 and higher)
        # d = Dict(MyType(1) => list)
        # x = get(d, MyType(2), nothing)
        # last(d[MyType(1)])
    end
end

end