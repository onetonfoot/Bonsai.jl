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


# current implementation is hacked together from the JET examples without much
# understanding of how JET really works. Nevertheless it does the job, at a later
# date however this should probably be cleaned up. 

# At some point read this to better understand the abstract compiler interface
# https://github.com/JuliaLang/julia/blob/master/base/compiler/types.jl

# avoid kwargs in write due as it makes the analysis more complicated
# https://github.com/JuliaLang/julia/issues/9551
# https://discourse.julialang.org/t/untyped-keyword-arguments/24228
# https://discourse.julialang.org/t/closure-over-a-function-with-keyword-arguments-while-keeping-access-to-the-keyword-arguments/15574

const CC = Core.Compiler


const default_status = Status(:default)


function write(res::Response, headers::Headers{T}) where {T}
    val = headers.val
    if !isnothing(val)
        for (header, value) in zip(fieldnames(val), fieldvalues(val))
            HTTP.setheader(res, headerize(header) => value)
        end
    end
end

function write(res::Response, data::Body{T}) where {T}
    if StructTypes.StructType(T) == StructTypes.NoStructType()
        error("Unsure how to write type $T to stream")
    else
        # what is you wanted to write null to the body?
        if !isnothing(data.val)
            b = IOBuffer()
            JSON3.write(b, data.val, allow_inf=true)
            res.body = take!(b)
        end

        m = mime_type(T)
        if !isnothing(m)
            write(res, Headers(content_type=m))
        end
    end
end

function write(res::Response, data::Body{T}) where T <: AbstractPath
    body = Base.read(data.val)
    res.body = body
    m = mime_type(data.val)
    if !isnothing(m)
        write(res, Headers(content_type=m))
    end
end

function write(stream::Response, data::T) where {T}
    if StructTypes.StructType(T) != StructTypes.NoStructType()
        write(stream, Body(T))
        write(stream, Status(200))
    elseif T isa Exception
        write(stream, Body(string(data)))
        write(stream, Status(500))
    else
        error("Unable in infer correct write location please wrap in Body or Headers")
    end
end

write(stream::Stream{<:Request}, data) = write(stream.message.response, data)
write(stream::Stream{<:Request}, data...) = write(stream.message.response, data...)
write(res::Response, ::Status{T}) where T =  res.status = Int(T)
write(res::Response, ::Status{:default})  =  res.status = 200

# This function could be the entry point for the static analysis writes
# allow us to group together headers and status codes etc
function write(res::Response, args...) 
    for i in args
        write(res, i)
    end
end

read(stream::Stream{<:Request}, b::Body{T}) where {T} = read(stream.message, b)
read(stream::Stream{A,B}, b) where {A<:Request,B} = read(stream.message, b)
read(req::Request, ::Body{T}) where {T} = read(req.body, T)

function read(req::Request, ::Params{T}) where {T}
    if hasfield(Request, :context)
        d = req.context[:params]
        convert_numbers!(d, T)
        return read(d, T)
    else
        error("Params not supported on this version of HTTP")
    end
end

function read(req::Request, ::Query{T}) where {T}
    q::Dict{Symbol,Any} = Dict(Symbol(k) => v for (k, v) in queryparams(req.url))
    convert_numbers!(q, T)
    read(q, T)
end

function read(req::Request, ::Headers{T}) where {T}
    fields = fieldnames(T)
    d = Dict{Symbol,Any}()

    for i in fields
        h = headerize(i)
        if HTTP.hasheader(req, h)
            d[i] = HTTP.header(req, h)
        end
    end

    convert_numbers!(d, T)
    read(d, T)
end


#######
# JET #
#######

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
        ReportPass(analyzer)(WriteReport, analyzer, caller, src)
    end

    return ret
end


struct StreamAnalyzer{T} <: AbstractAnalyzer
    state::AnalyzerState
    opts::BitVector
    frame_filter::T
    __cache_key::UInt
end

function StreamAnalyzer(;
    ## a predicate, which takes `CC.InfernceState` and returns whether we want to analyze the call or not
    frame_filter=x::Core.MethodInstance -> true,
    jetconfigs...)
    state = AnalyzerState(; jetconfigs...)
    ## we want to run different analysis with a different filter, so include its hash into the cache key
    cache_key = state.param_key
    cache_key = hash(frame_filter, cache_key)
    return StreamAnalyzer(state, BitVector(), frame_filter, cache_key)
end

## AbstractAnalyzer API requirements
JETInterface.AnalyzerState(analyzer::StreamAnalyzer) = analyzer.state
JETInterface.AbstractAnalyzer(analyzer::StreamAnalyzer, state::AnalyzerState) = StreamAnalyzer(state, analyzer.opts, analyzer.frame_filter, analyzer.__cache_key)
JETInterface.ReportPass(analyzer::StreamAnalyzer) = StreamAnalysisPass()
JETInterface.get_cache_key(analyzer::StreamAnalyzer) = analyzer.__cache_key

struct StreamAnalysisPass <: ReportPass end
## ignore all reports defined by JET, since we'll just define our own reports
(::StreamAnalysisPass)(T::Type{<:InferenceErrorReport}, @nospecialize(_...)) = return

frame_ref = Ref{Any}()


function CC.finish!(analyzer::StreamAnalyzer, frame::Core.Compiler.InferenceState)

    caller = frame.result
    frame_ref[] = frame

    ## get the source before running `finish!` to keep the reference to `OptimizationState`
    src = caller.src
    ## run `finish!(::AbstractAnalyzer, ::CC.InferenceState)` first to convert the optimized `IRCode` into optimized `CodeInfo`
    ret = @invoke CC.finish!(analyzer::AbstractAnalyzer, frame::CC.InferenceState)

    if analyzer.frame_filter(frame.linfo)
        ReportPass(analyzer)(StreamReport, analyzer, caller, src)
    end

    return ret
end

@jetreport struct StreamReport <: InferenceErrorReport
    slottypes
end

@jetreport struct WriteReport <: InferenceErrorReport
    slottypes
end


@jetreport struct ReadReport <: InferenceErrorReport
    slottypes
end

JETInterface.print_report_message(::IO, ::WriteReport) =  "detected response io" 
JETInterface.print_report_message(::IO, ::ReadReport) =  "detected request io" 
JETInterface.print_report_message(::IO, ::StreamReport) =  "detected stream io" 

write_ref = Ref{Any}()
read_ref = Ref{Any}()

function (::DispatchAnalysisPass)(::Type{WriteReport}, analyzer::DispatchAnalyzer, caller::CC.InferenceResult, opt::CC.OptimizationState)
    (; src, linfo, slottypes, sptypes) = opt

    fn = get(slottypes, 1, nothing)
    io_type = get(slottypes, 2, nothing)
    data_type = get(slottypes, 3, nothing)
    # probably shouldn't be adding different report types here
    # but rather spliting them into serperate report passes...

    if fn == Core.Const((@__MODULE__).read) && 
       io_type <: Request

        read_ref[] = opt
        add_new_report!(analyzer, caller, ReadReport(caller, slottypes))

    elseif fn == Core.Const((@__MODULE__).write) && 
           io_type <: Response &&
           data_type <: HttpParameter

        write_ref[] = opt

        add_new_report!(analyzer, caller, WriteReport(caller, slottypes))
    end
end

function (::StreamAnalysisPass)(::Type{StreamReport}, analyzer::StreamAnalyzer, caller::CC.InferenceResult, opt::CC.OptimizationState)
    (; src, linfo, slottypes, sptypes) = opt

    fn = get(slottypes, 1, nothing)
    io_type = get(slottypes, 2, nothing)

    if fn == Core.Const((@__MODULE__).write) && 
           io_type <: Stream 
        write_ref[] = opt
        add_new_report!(analyzer, caller, StreamReport(caller, slottypes))
    end
end

extract_type(::Type{T}) where {T} = T

write_reports = Ref{Any}()
read_reports = Ref{Any}()

arg_types_ref = Ref{Any}()

function handler_writes(@nospecialize(handler))
    l = []

    for stream_report in Bonsai.handler_stream_writes(handler)
        _, io_type, arg_type = stream_report.slottypes
        status_code = Bonsai.get_status_code(arg_type)

        types = if arg_type <: Tuple
            Tuple{Response, arg_type.types...}
        else
            Tuple{Response, arg_type}
        end

        arg_types_ref[] = arg_type
        calls = JET.report_call(Bonsai.write, types, analyzer=DispatchAnalyzer)
        reports = JET.get_reports(calls)
        filter!(x ->  x isa  WriteReport, reports)
        push!(l, map(x ->  (CC.widenconst(x.slottypes[3]), status_code) , reports)...)
    end

    unique!(l)
end

function handler_stream_writes(@nospecialize(handler))
    calls = JET.report_call(handler, Tuple{Stream}, analyzer=StreamAnalyzer)
    reports = JET.get_reports(calls)
    return reports
end

extract_status_code(::Type{Status{T}}) where {T} = T

get_status_code(l) = 200

function get_status_code(l::Type{<:Tuple})
    for i in l.types
        if i <: Status # Etc Status{201} => 201
            return extract_status_code(i)
        end
    end
    return 200
end

function handler_reads(@nospecialize(handler))
    calls = JET.report_call(handler, Tuple{Stream}, analyzer=DispatchAnalyzer)
    reports = JET.get_reports(calls)
    filter!(x ->  x isa  ReadReport, reports)
    map(reports) do r
        res_type = r.slottypes[3]
        # extracts the type from Core.Const
        res_type = CC.widenconst(res_type)
        return res_type
    end |> unique!
end

handler_reads(handler::AbstractHandler) = handler_reads(handler.fn)

