# if isdefined(@__MODULE__, :LanguageServer)
#     include("../src/Tree.jl")
#     using .Bonsai
# else
#     using Bonsai

# end
using Documenter
push!(LOAD_PATH,"../src/")
using Bonsai

makedocs(sitename = "Tree")