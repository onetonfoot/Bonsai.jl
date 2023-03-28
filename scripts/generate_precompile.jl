# generate_precompile.jl
using SnoopCompile, Bonsai, ProfileView
using Bonsai.HTTP, Bonsai.StructTypes, Bonsai.JSON3

function run_my_project()

    paths = [
        joinpath(@__DIR__, "../test/app.jl"),
        joinpath(@__DIR__, "../test/middleware.jl"),
        joinpath(@__DIR__, "../test/router.jl"),
        joinpath(@__DIR__, "../test/io.jl"),
        joinpath(@__DIR__, "../test/http.jl"),
        joinpath(@__DIR__, "../test/handlers.jl"),
        joinpath(@__DIR__, "../test/utils.jl"),
    ]

    #=
        ideally we would walk the expression and transform using
        import statments from StructTypes to Bonsai.StructTypes
        we could then use the test suite to generate precompile
        statements without modifying the test src. But for now 
        well just to the dump thing a modify the src cos I cba
        to get into ast right now.

        If the approach works well it could be put in a package
    =#

    for path in paths
        include(path)
    end
end

tinf = @snoopi_deep run_my_project()
# tinf = @snoopi_deep include(joinpath(@__DIR__, "/test/app.jl"))

# ProfileView.@profview flamegraph(tinf)

# show(plot)
ttot, pcs = SnoopCompile.parcel(tinf);
SnoopCompile.write(joinpath(@__DIR__, "../src/precompile"), pcs)


# ProfileView.@profview plot


# using Base.Meta

# using StructTypes
# using StructTypes, JSON3

# import StructTypes: @Struct
# import StructTypes: @Struct, SomeOtherThing