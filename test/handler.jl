# if isdefined(@__MODULE__,:LanguageServer)
#     include("../src/Tree.jl")
#     using .Tree: has_handler, isvalidpath,  ws_serve 
#     using .Tree
# else
#     using Tree: has_handler, isvalidpath, ws_serve
#     using Tree

# end

# using Test, HTTP, JSON

# router = Router()

# router("/:rice") do req
#     p = path_params(req)
#     @info p
#     @info typeof(p)
#     "yayy"
# end

# server = http_serve(router)

# a = HTTP.get("http://localhost:8081/rice")

# stop(server