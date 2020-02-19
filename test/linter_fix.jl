# https://github.com/julia-vscode/julia-vscode/issues/307#issuecomment-583698992
if isdefined(@__MODULE__,:LanguageServer)
    include("../src/Tree.jl")
    using .Tree
else
    using Tree 
end