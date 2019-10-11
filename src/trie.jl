import Base: setindex!, haskey, getindex, keys, getproperty, get, iterate

# Adapted from https://github.com/JuliaCollections/DataStructures.jl/blob/master/src/trie.jl

mutable struct Trie{T}
    value::T
    children::Dict{Union{String, Symbol},Trie{T}}
    is_key::Bool

    function Trie{T}() where T
        self = new{T}()
        self.children = Dict{Union{String, Symbol},Trie{T}}()
        self.is_key = false
        self
    end

    function Trie{T}(ks, vs) where T
        t = Trie{T}()
        for (k, v) in zip(ks, vs)
            t[k] = v
        end
        return t
    end

    function Trie{T}(kv) where T
        t = Trie{T}()
        for (k,v) in kv
            t[k] = v
        end
        return t
    end
end

# TODO  - remove any unused constructors

# Trie() = Trie{Any}()
# Trie(ks::AbstractVector{K}, vs::AbstractVector{V}) where {K<:AbstractString,V} = Trie{V}(ks, vs)
# Trie(kv::AbstractVector{Tuple{K,V}}) where {K<:AbstractString,V} = Trie{V}(kv)
# Trie(kv::AbstractDict{K,V}) where {K<:AbstractString,V} = Trie{V}(kv)
# Trie(ks::AbstractVector{K}) where {K<:AbstractString} = Trie{Nothing}(ks, similar(ks, Nothing))

function setindex!(t::Trie{T}, val, key::AbstractString) where T
    value = convert(T, val) # we don't want to iterate before finding out it fails
    node = t
    for char in spliturl(key)
        if char isa Symbol 
            for key in keys(node.children)
                if key isa Symbol && key != char
                    error("Symbols must be unique in each branch")
                end
            end
        end

        if !haskey(node.children, char)
            node.children[char] = Trie{T}()
        end
        node = node.children[char]
    end
    node.is_key = true
    node.value = value
end

function getindex(t::Trie, key::AbstractString)
    node = subtrie(t, key)
    if node != nothing && node.is_key
        return node.value
    end
    throw(KeyError("key not found: $key"))
end

function subtrie(t::Trie, prefix::AbstractString)
    node = t
    for char in spliturl(prefix)
        if !haskey(node.children, char)
            return nothing
        else
            node = node.children[char]
        end
    end
    node
end

function keys(t::Trie, prefix::AbstractString="", found=AbstractString[])
    if t.is_key
        push!(found, prefix)
    end
    for (char,child) in t.children
        suffix = char == "/" ? "" : "/"
        char = char isa String ? char : ":$(char)"
        keys(child, string(prefix,char) * suffix, found)
    end
    found
end

function haskey(t::Trie, key::AbstractString)
    node = subtrie(t, key)
    node != nothing && node.is_key
end

function get(t::Trie, key::AbstractString, notfound)
    node = subtrie(t, key)
    if node != nothing && node.is_key
        return node.value
    end
    notfound
end


function keys_with_prefix(t::Trie, prefix::AbstractString)
    st = subtrie(t, prefix)
    st != nothing ? keys(st,prefix) : []
end

# The state of a TrieIterator is a pair (t::Trie, i::Int),
# where t is the Trie which was the output of the previous iteration
# and i is the index of the current character of the string.
# The indexing is potentially confusing;
# see the comments and implementation below for details.
struct TrieIterator
    t::Trie
    str::AbstractString
end

# At the start, there is no previous iteration,
# so the first element of the state is undefined.
# We use a "dummy value" of it.t to keep the type of the state stable.
# The second element is 0
# since the root of the trie corresponds to a length 0 prefix of str.
function iterate(it::TrieIterator, (t, i) = (it.t, 0))
    if i == 0
        return it.t, (it.t, 1)
    elseif i == length(it.str) + 1 || !(it.str[i] in keys(t.children))
        return nothing
    else
        t = t.children[it.str[i]]
        return (t, (t, i + 1))
    end
end

path(t::Trie, str::AbstractString) = TrieIterator(t, str)
Base.IteratorSize(::Type{TrieIterator}) = Base.SizeUnknown()


function get_handler(t :: Trie, prefix :: AbstractString, handler :: Function = x -> "404")
    node = t
    route = Union{String, Symbol}[]
    for char in spliturl(prefix)
        if haskey(node.children, char)
            node = node.children[char]
            push!(route, char)
            continue
        end
        key, node = firstsymbol(node.children)
        if isnothing(node)
            return (handler, []) 
        else
            push!(route, key)
        end
    end
    node.is_key ? (node.value, route) : (handler, [])
end

function firstsymbol(t)
    for (key, value) in t
        if key isa Symbol
            return (key, value)
        end
    end
    (nothing, nothing)
end

# TODO move into another file/module along with other functions for manipultaing the URL

function spliturl(s::AbstractString)
    fragments = splitpath(s)
    path = map(fragments) do fragment
        if fragment[1] == ':'
           Symbol(fragment[2:end])
        else
            fragment
        end
    end 
    convert(Array{Union{String, Symbol}}, path)
end