# if isdefined(@__MODULE__, :LanguageServer)
#     include("../src/Tree.jl")
#     using .Tree
# else
#     using Tree

# end
using Documenter
push!(LOAD_PATH,"../src/")
using Tree

makedocs(sitename = "Tree")