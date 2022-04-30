export HttpPath

# https://github.com/gofiber/fiber/blob/master/path.go


struct HttpPath
	path::String
	parameters::Type{<:NamedTuple}
end

isgreedy(path::HttpPath) = any(map(x -> x.is_greedy, path.segments))

function HttpPath(s::AbstractString)

	if s[1] != '*' && s[1] != '/'
		throw(InvalidHttpPath(s))
	end

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

HttpPath(s::HttpPath) = s


function isvalidpath(path::AbstractString)
    # https://stackoverflow.com/questions/4669692/valid-characters-for-directory-part-of-a-url-for-short-links
    re = r"^[/a-zA-Z0-9-_.-~!$&'()*+,;@]+$"
    m = match(re, path)
    uri = URI(path)
    m !== nothing && m.match == path && uri.path == path && !("//" in path)
end