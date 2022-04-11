using JET.JETInterface
using Base.Core
using ExprManipulation

const CC = Core.Compiler


import JET:
    JET,
    @invoke,
    isexpr

function write(stream, data, status_code)
end

# for now avoid this due to 
# https://github.com/JuliaLang/julia/issues/9551
# which makes the anlysis more complicated
# function write(stream, data, status_code=200)
# end



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

	# Base.IdDict
	# objectid

    if analyzer.frame_filter(frame.linfo)
		ReportPass(analyzer)(WriteReport, analyzer, caller, src)
    end

    return ret
end

@reportdef struct WriteReport <: InferenceErrorReport end
JETInterface.get_msg(::Type{WriteReport}, args...) =
    return "detected write" #: signature of this MethodInstance
function (::DispatchAnalysisPass)(::Type{WriteReport}, analyzer::DispatchAnalyzer, caller::CC.InferenceResult, opt::CC.OptimizationState)
	(;src, linfo, slottypes, sptypes) = opt

	fn = get(src.slottypes, 1, nothing)

	# TODO how to reference parent module here?
	if fn == Core.Const(Bonsai.write)
		add_new_report!(analyzer, caller, WriteReport(linfo))
	end
end