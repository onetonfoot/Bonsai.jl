import Sockets: TCPServer

include("router.jl")
include("context.jl")

mutable struct App{S}
    router::Router
    session::S
    server::Union{Nothing,TCPServer}
end


# TODO dIit is not thread safe :/
# mayeb use Redis.jl instead but this
# would require a check to make sure it's installed
# on the machine, probaly best done in a different package
App(;session = Dict()) = App(Router(), session, nothing)

function (app::App)(handler, path, method::AbstractString = GET)     
    app.router(handler, path ; method = method)
end

# TODO add test case
function (app::App)(handler::Function, path::AbstractString, method::Array)     
    [app.router(handler, path; method = m) for m in method]
end