using JET.JETInterface
using Base.Core
using ExprManipulation
import JET:
    JET,
    @invoke,
    isexpr

const CC = Core.Compiler

# avoid kwargs in write due as it makes the analysis more complicated
# https://github.com/JuliaLang/julia/issues/9551
# https://discourse.julialang.org/t/untyped-keyword-arguments/24228
# https://discourse.julialang.org/t/closure-over-a-function-with-keyword-arguments-while-keeping-access-to-the-keyword-arguments/15574

function write(stream, data, status_code = ResponseCodes.Ok())
    Base.write(stream, data)
    HTTP.setstatus(stream, Int(status_code))
end

function write(stream::IOBuffer, data, status_code = ResponseCodes.Ok())
    Base.write(stream, data)
end

struct DispatchAnalyzer{T} <: AbstractAnalyzer
    state::AnalyzerState
    opts::BitVector
    frame_filter::T
    __cache_key::UInt
end


function DispatchAnalyzer(;
    ## a predicate, which takes `CC.InfernceState` and returns whether we want to analyze the call or not
    frame_filter = x::Core.MethodInstance->true,
    jetconfigs...)
    state = AnalyzerState(; jetconfigs...)
    ## we want to run different analysis with a different filter, so include its hash into the cache key
    cache_key = state.param_key
    cache_key = hash(frame_filter, cache_key)
    return DispatchAnalyzer(state, BitVector(), frame_filter, cache_key)
end

## AbstractAnalyzer API requirements
JETInterface.AnalyzerState(analyzer::DispatchAnalyzer)                          = analyzer.state
JETInterface.AbstractAnalyzer(analyzer::DispatchAnalyzer, state::AnalyzerState) = DispatchAnalyzer(state, analyzer.opts, analyzer.frame_filter, analyzer.__cache_key)
JETInterface.ReportPass(analyzer::DispatchAnalyzer)                             = DispatchAnalysisPass()
JETInterface.get_cache_key(analyzer::DispatchAnalyzer)                          = analyzer.__cache_key

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

@reportdef struct WriteReport <: InferenceErrorReport 
    slottypes
end

JETInterface.get_msg(::Type{WriteReport}, args...) =
    return "detected write" #: signature of this MethodInstance
function (::DispatchAnalysisPass)(::Type{WriteReport}, analyzer::DispatchAnalyzer, caller::CC.InferenceResult, opt::CC.OptimizationState)
	(;src, linfo, slottypes, sptypes) = opt

	fn = get(slottypes, 1, nothing)
	if fn != Core.Const((@__MODULE__).write)
        return
    end

    status_code = get(slottypes, 4, nothing)
    if !(status_code isa Core.Const)
        return
    end

    status_code = get(slottypes, 3, nothing)
    if !(status_code isa Type)
        return
    end

    add_new_report!(analyzer, caller, WriteReport(caller, slottypes))
end

# TODO: needs another instance to handle Core.Const
extract_type(::Type{T}) where T = T

function handler_writes(handler)
	calls = JET.report_call(handler, Tuple{Stream}, analyzer=DispatchAnalyzer ) 
	reports = JET.get_reports(calls)
	l = map(reports) do r
		res_type = r.slottypes[3]
		res_code = r.slottypes[4].val
        # @debug "writes" type=res_type code=res_code
		(extract_type(res_type), res_code)
	end
end