function cors(stream::Stream, next)

    headers = [
        "Access-Control-Allow-Origin" => "*",
        "Access-Control-Allow-Headers" => "*",
        "Access-Control-Allow-Methods" => "*",
    ]

    res = stream.message.response
    # @info "cors middelware" target = stream.message.target method = stream.message.method

    if stream.message.method == "OPTIONS"
        for i in headers
            HTTP.setheader(res, i)
        end
    else
        for i in headers
            HTTP.setheader(res, i)
        end
        next(stream)
    end
end

function combine_middleware(middleware::Vector)
    i = length(middleware)

    if i == 0
        return x -> x
    end

    fns = Function[stream->middleware[i](stream, identity)]
    for i in reverse(1:length(middleware)-1)
        fn = stream -> middleware[i](stream, fns[i+1])
        pushfirst!(fns, fn)
    end
    return fns[1]
end