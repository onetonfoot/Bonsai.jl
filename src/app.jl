import Sockets: TCPServer

include("router.jl")
include("context.jl")

mutable struct App{S}
    router::Router
    session::S
    server::Union{Nothing, TCPServer}
end

App() = App(Router(), Dict(), nothing)
App(;session=Dict()) = App(Router(), session, nothing)

function (app::App)(handler, path ; method = GET)     
    app.router(handler, path ; method = method)
end