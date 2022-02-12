export hp_str, HttpPath

# https://github.com/gofiber/fiber/blob/master/path.go
mutable struct PathSegment 
	s::String
	param_name::Union{Nothing, Symbol}
	is_last::Bool
	is_greedy::Bool 
end

function PathSegment(s::String)
	param_name = nothing
	if startswith(s, ":")
		param_name = Symbol(s[2:end])
	end

	is_last = false
	is_greedy = s == "*"

	PathSegment(
		s,
		param_name,
		is_last,
		is_greedy
	)

end

struct HttpPath
	path::String
	parameters::Type{<:NamedTuple}
	segments::Vector{PathSegment}
end

isgreedy(path::HttpPath) = any(map(x -> x.is_greedy, path.segments))

function HttpPath(s::AbstractString)

	segment_strs = splitpath(s)
	segments = PathSegment[]
	symbols = Symbol[]

	for i in segment_strs
		segment = PathSegment(i)
		push!(segments, segment)
		if !isnothing(segment.param_name)
			push!(symbols, segment.param_name)
		end
	end

	segments[length(segments)].is_last = true
	parameters = NamedTuple{(symbols..., ), NTuple{length(symbols), String}}

	HttpPath(
		s,
	    parameters,
		segments
	)
end


function ismatch(p::PathSegment, s::AbstractString)
	if p.is_greedy
		return true
	elseif !isnothing(p.param_name)
		return true
	else
		return p.s == s
	end
end

function match_path(p::HttpPath, s::AbstractString)

	strs = splitpath(s)
	path_parameters = []

	str_idx = 1
	match_idx =1

	if length(p.segments) < length(strs) && !last(p.segments).is_greedy
		return nothing
	end

	while str_idx <= length(strs)
		s = strs[str_idx]
		segment = p.segments[match_idx]

		if segment.is_greedy
			break
		end

		if !ismatch(segment, s)
			return nothing
		end

		if !isnothing(segment.param_name)
			push!(path_parameters, s)
		end


		match_idx +=1
		str_idx +=1
	end

	p.parameters(path_parameters)
end
