using HTTP: Request, Response, Stream
using JET.JETInterface
using InteractiveUtils # to use `gen_call_with_extracted_types_and_kwargs`
const CC = Core.Compiler
import JET: JET

struct DispatchAnalyzer{T} <: AbstractAnalyzer
    state::AnalyzerState
    analysis_cache::AnalysisCache
    opts::BitVector
    frame_filter::T # a predicate, which takes `CC.InfernceState` and returns whether we want to analyze the call or not
end

## AbstractAnalyzer API requirements
JETInterface.AnalyzerState(analyzer::DispatchAnalyzer) = analyzer.state
JETInterface.AbstractAnalyzer(analyzer::DispatchAnalyzer, state::AnalyzerState) = DispatchAnalyzer(state, analyzer.analysis_cache, analyzer.opts, analyzer.frame_filter)
JETInterface.ReportPass(analyzer::DispatchAnalyzer) = DispatchAnalysisPass()
JETInterface.AnalysisCache(analyzer::DispatchAnalyzer) = analyzer.analysis_cache

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
        ReportPass(analyzer)(ReadReport, analyzer, caller, src)
        # ReportPass(analyzer)(StreamReport, analyzer, caller, src)
    end

    return ret
end

@jetreport struct WriteReport <: InferenceErrorReport
    slottypes
end


@jetreport struct ReadReport <: InferenceErrorReport
    slottypes
end

JETInterface.print_report_message(io::IO, ::WriteReport) = print(io, "write calls")
JETInterface.print_report_message(io::IO, ::ReadReport) = print(io, "read calls")


function (::DispatchAnalysisPass)(::Type{WriteReport}, analyzer::DispatchAnalyzer, caller::CC.InferenceResult, opt::CC.OptimizationState)
    (; src, linfo, slottypes, sptypes) = opt
    fn = get(slottypes, 1, nothing)
    io_type = get(slottypes, 2, nothing)
    data_type = get(slottypes, 3, nothing)
    # probably shouldn't be adding different report types here
    # but rather spliting them into serperate report passes...
    if fn == Core.Const((@__MODULE__).write) &&
       io_type <: Response &&
       data_type <: HttpParameter
        add_new_report!(analyzer, caller, WriteReport(caller, slottypes))
    end
end

function (::DispatchAnalysisPass)(::Type{ReadReport}, analyzer::DispatchAnalyzer, caller::CC.InferenceResult, opt::CC.OptimizationState)
    (; src, linfo, slottypes, sptypes) = opt

    fn = get(slottypes, 1, nothing)
    io_type = get(slottypes, 2, nothing)
    data_type = get(slottypes, 3, nothing)
    if fn == Core.Const((@__MODULE__).read) &&
       io_type <: Request
        add_new_report!(analyzer, caller, ReadReport(caller, slottypes))
    end
end

extract_type(::Type{T}) where {T} = T

# ## Usages
#
# So we defined our analyzer.
# Let's set up utility analysis entries first:


## the constructor for creating a new configured `DispatchAnalyzer` instance
function DispatchAnalyzer(;
    frame_filter=x::Core.MethodInstance -> true,
    jetconfigs...)
    state = AnalyzerState(; jetconfigs...)
    ## just for the sake of simplicity, create a fresh code cache for each `DispatchAnalyzer` instance (i.e. don't globalize the cache)
    analysis_cache = AnalysisCache()
    return DispatchAnalyzer(state, analysis_cache, BitVector(), frame_filter)
end

function report_dispatch(args...; jetconfigs...)
    @nospecialize args jetconfigs
    analyzer = DispatchAnalyzer(; jetconfigs...)
    return analyze_and_report_call!(analyzer, args...; jetconfigs...)
end

macro report_dispatch(ex0...)
    return InteractiveUtils.gen_call_with_extracted_types_and_kwargs(__module__, :report_dispatch, ex0)
end

function get_status_code(l::Type{<:Tuple})
    # put inside so it's easier to test as we can import
    # this file with Status type being defined
    for i in l.types
        if i <: Status # Etc Status{201} => 201
            return extract_status_code(i)
        end
    end
    return 200
end

function handler_reads(@nospecialize(handler))
    result = report_dispatch(handler, Tuple{Stream})
    reports = JET.get_reports(result)
    filter!(x -> x isa ReadReport, reports)
    map(reports) do r
        res_type = r.slottypes[3]
        # extracts the type from Core.Const
        res_type = CC.widenconst(res_type)
        return res_type
    end |> unique!
end

function handler_writes(@nospecialize(handler))

    result = report_dispatch(handler, Tuple{Stream})
    reports = JET.get_reports(result)
    filter!(x -> x isa WriteReport, reports)
    l = []

    for report in reports
        _, io_type, arg_type = report.slottypes

        types = if arg_type <: Tuple
            Tuple{Response,arg_type.types...}
        else
            Tuple{Response,arg_type}
        end

        calls = Bonsai.report_dispatch(Bonsai.write, types)
        reports = JET.get_reports(calls)
        filter!(x -> x isa WriteReport, reports)
        push!(l, map(x -> CC.widenconst(x.slottypes[3]), reports)...)
    end

    has_status_code = any(map(x -> x <: Status, l))

    if !has_status_code
        push!(l, Status{200})
    end

    unique!(l)
    # so that the first write is always a status code
    reverse(l)
end

extract_status_code(::Type{Status{T}}) where {T} = T

function groupby_status_code(l)
    d = Dict()
    code = first(l)
    for i in l
        if i <: Status
            code = i
            continue
        end
        writes = get(d, code, [])
        push!(writes, i)
        d[code] = writes
    end
    return d
end
