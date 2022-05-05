using JET.JETInterface
using Base.Core
using StructTypes
import JET:
    JET,
    @invoke,
    isexpr

using HTTP: Stream
using FilePathsBase: AbstractPath
import Parsers

const CC = Core.Compiler

# avoid kwargs in write due as it makes the analysis more complicated
# https://github.com/JuliaLang/julia/issues/9551
# https://discourse.julialang.org/t/untyped-keyword-arguments/24228
# https://discourse.julialang.org/t/closure-over-a-function-with-keyword-arguments-while-keeping-access-to-the-keyword-arguments/15574


write(stream::Stream{<:Request}, data, status_code=ResponseCodes.Default()) = write(stream.message.response, data, status_code)

function write(res::Response, headers::Headers{T}, status_code=ResponseCodes.Default()) where {T}
    val = headers.val
    if !isnothing(val)
        for (header, value) in zip(fieldnames(val), fieldvalues(val))
            HTTP.setheader(res, headerize(header) => value)
        end
    end
    # HTTP.setstatus(stream, Int(status_code))
end

function write(res::Response, data::Body{T}, status_code=ResponseCodes.Default()) where {T}
    if StructTypes.StructType(T) == StructTypes.NoStructType()
        error("Unsure how to write type $T to stream")
    else
        if !isnothing(data.val)
            b = IOBuffer()
            JSON3.write(b, data.val)
            res.body = take!(b)
        end

        m = mime_type(T)
        if !isnothing(m)
            write(res, Headers(content_type=m), status_code)
        end
    end
    HTTP.setstatus(res, Int(status_code))
end

# Code Inference is broken for this
function write(res::Response, data::T, status_code=ResponseCodes.Default()) where {T<:AbstractPath}
    file = Base.read(data)
    write(res, Body(file))
    m = mime_type(file)
    if !isnothing(m)
        write(res, Headers(content_type=m))
    end
end

function write(stream::Response, data::T, status_code=ResponseCodes.Default()) where {T}
    if StructTypes.StructType(T) != StructTypes.NoStructType()
        write(stream, Body(T), status_code)
    elseif T isa Exception
        write(stream, Body(string(data)), status_code)
    else
        error("Unable in infer correct write location please wrap in Body or Headers")
    end
end

function write(stream::Response, data::Int) where {T}
    HTTP.setstatus(stream, data)
end

read(stream::Stream{<:Request}, b::Body{T}) where {T} = read(stream.message, b)
read(stream::Stream{A,B}, b) where {A<:Request,B} = read(stream.message, b)

function read(req::Request, ::Body{T}) where {T}
    try
        return JSON3.read(req.body, T)
    catch e
        @debug "Failed to convert body into $T"
        rethrow(e)
    end
end

function read(req::Request, ::PathParams{T}) where {T}
    try
        if hasfield(Request, :context)
            StructTypes.constructfrom(T, req.context[:params])
        else
            error("PathParams not supported on this version of HTTP")
        end
    catch e
        @debug "Failed to convert path params into $T"
        rethrow(e)
    end
end

function convert_numbers!(data::AbstractDict, T)
    for (k, t) in zip(fieldnames(T), fieldtypes(T))
        if t <: Union{Number,Missing,Nothing}
            data[k] = Parsers.parse(Float64, data[k])
        end
    end
    data
end

function read(req::Request, ::Query{T}) where {T}
    try
        q::Dict{Symbol,Any} = Dict(Symbol(k) => v for (k, v) in queryparams(req.url))
        @info q
        convert_numbers!(q, T)
        StructTypes.constructfrom(T, q)
    catch e
        @debug "Failed to convert query into $T"
        rethrow(e)
    end
end

function read(req::Request, ::Headers{T}) where {T}
    fields = fieldnames(T)
    d = Dict()

    for i in fields
        h = headerize(i)
        if HTTP.hasheader(req, h)
            d[i] = HTTP.header(req, h)
        else
            d[i] = missing
        end
    end

    try
        convert_numbers!(d, T)
        StructTypes.constructfrom(T, d)
    catch e
        rethrow(e)
    end
end

struct DispatchAnalyzer{T} <: AbstractAnalyzer
    state::AnalyzerState
    opts::BitVector
    frame_filter::T
    __cache_key::UInt
end


function DispatchAnalyzer(;
    ## a predicate, which takes `CC.InfernceState` and returns whether we want to analyze the call or not
    frame_filter=x::Core.MethodInstance -> true,
    jetconfigs...)
    state = AnalyzerState(; jetconfigs...)
    ## we want to run different analysis with a different filter, so include its hash into the cache key
    cache_key = state.param_key
    cache_key = hash(frame_filter, cache_key)
    return DispatchAnalyzer(state, BitVector(), frame_filter, cache_key)
end

## AbstractAnalyzer API requirements
JETInterface.AnalyzerState(analyzer::DispatchAnalyzer) = analyzer.state
JETInterface.AbstractAnalyzer(analyzer::DispatchAnalyzer, state::AnalyzerState) = DispatchAnalyzer(state, analyzer.opts, analyzer.frame_filter, analyzer.__cache_key)
JETInterface.ReportPass(analyzer::DispatchAnalyzer) = DispatchAnalysisPass()
JETInterface.get_cache_key(analyzer::DispatchAnalyzer) = analyzer.__cache_key

struct DispatchAnalysisPass <: ReportPass end
## ignore all reports defined by JET, since we'll just define our own reports
(::DispatchAnalysisPass)(T::Type{<:InferenceErrorReport}, @nospecialize(_...)) = return


function CC.finish!(analyzer::DispatchAnalyzer, frame::Core.Compiler.InferenceState)

    caller = frame.result

    ## get the source before running `finish!` to keep the reference to `OptimizationState`
    src = caller.src
    ## run `finish!(::AbstractAnalyzer, ::CC.InferenceState)` first to convert the optimized `IRCode` into optimized `CodeInfo`
    ret = @invoke CC.finish!(analyzer::AbstractAnalyzer, frame::CC.InferenceState)

    if analyzer.frame_filter(frame.linfo)
        ReportPass(analyzer)(IoReport, analyzer, caller, src)
    end

    return ret
end

@reportdef struct IoReport <: InferenceErrorReport
    slottypes
end

JETInterface.get_msg(::Type{IoReport}, args...) =
    return "detected io" #: signature of this MethodInstance

function (::DispatchAnalysisPass)(::Type{IoReport}, analyzer::DispatchAnalyzer, caller::CC.InferenceResult, opt::CC.OptimizationState)
    (; src, linfo, slottypes, sptypes) = opt

    fn = get(slottypes, 1, nothing)
    if fn == Core.Const((@__MODULE__).read)

        add_new_report!(analyzer, caller, IoReport(caller, slottypes))

    elseif fn == Core.Const((@__MODULE__).write)

        status_code = get(slottypes, 4, nothing)
        if !(status_code isa Core.Const)
            return
        end

        data = get(slottypes, 3, nothing)
        if !(data isa Type)
            return
        end

        add_new_report!(analyzer, caller, IoReport(caller, slottypes))
    end
end

# TODO: needs another instance to handle Core.Const
extract_type(::Type{T}) where {T} = T

function handler_writes(@nospecialize(handler))
    calls = JET.report_call(handler, Tuple{Stream}, analyzer=DispatchAnalyzer)
    reports = JET.get_reports(calls)
    fn = Core.Const((@__MODULE__).write)
    filter!(x -> x.slottypes[1] == fn, reports)
    l = map(reports) do r
        res_type = r.slottypes[3]
        res_code = r.slottypes[4].val
        # @debug "writes" type=res_type code=res_code
        (extract_type(res_type), res_code)
    end
    unique!(l)
end


function handler_reads(@nospecialize(handler))
    calls = JET.report_call(handler, Tuple{Stream}, analyzer=DispatchAnalyzer)
    reports = JET.get_reports(calls)
    fn = Core.Const((@__MODULE__).read)
    filter!(x -> x.slottypes[1] == fn, reports)
    l = map(reports) do r
        res_type = r.slottypes[3]
        # @debug "writes" type=res_type code=res_code
        (extract_type(res_type))
    end
    unique!(l)
end

handler_reads(handler::AbstractHandler) = handler_reads(handler.fn)

