using SnoopCompile, Bonsai, ProfileView
using Bonsai.HTTP, Bonsai.StructTypes, Bonsai.JSON3

function run_test_suite()

    paths = [
        joinpath(@__DIR__, "../test/app.jl"),
        joinpath(@__DIR__, "../test/middleware.jl"),
        joinpath(@__DIR__, "../test/router.jl"),
        joinpath(@__DIR__, "../test/io.jl"),
        joinpath(@__DIR__, "../test/http.jl"),
        joinpath(@__DIR__, "../test/handlers.jl"),
        joinpath(@__DIR__, "../test/utils.jl"),
    ]

    for path in paths
        include(path)
    end
end

tinf = @snoopi_deep run_test_suite()
ttot, pcs = SnoopCompile.parcel(tinf);
SnoopCompile.write(joinpath(@__DIR__, "../src/precompile"), pcs)