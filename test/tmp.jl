using JET.JETInterface
const CC = Core.Compiler
import JET:
    JET,
    @invoke,
    isexpr

struct DispatchAnalyzer{T} <: AbstractAnalyzer
    state::AnalyzerState
    opts::BitVector
    frame_filter::T
    __cache_key::UInt
end
function DispatchAnalyzer(;
    # a predicate, which takes `CC.InfernceState` and returns whether we want to analyze the call or not
    frame_filter = x::Core.MethodInstance->true,
    jetconfigs...)
    state = AnalyzerState(; jetconfigs...)
    # we want to run different analysis with a different filter, so include its hash into the cache key
    cache_key = state.param_key
    cache_key = hash(frame_filter, cache_key)
    return DispatchAnalyzer(state, BitVector(), frame_filter, cache_key)
end

# AbstractAnalyzer API requirements
JETInterface.AnalyzerState(analyzer::DispatchAnalyzer)                          = analyzer.state
JETInterface.AbstractAnalyzer(analyzer::DispatchAnalyzer, state::AnalyzerState) = DispatchAnalyzer(state, analyzer.opts, analyzer.frame_filter, analyzer.__cache_key)
JETInterface.ReportPass(analyzer::DispatchAnalyzer)                             = DispatchAnalysisPass()
JETInterface.get_cache_key(analyzer::DispatchAnalyzer)                          = analyzer.__cache_key

struct DispatchAnalysisPass <: ReportPass end
# ignore all reports defined by JET, since we'll just define our own reports
(::DispatchAnalysisPass)(T::Type{<:InferenceErrorReport}, @nospecialize(_...)) = return

function CC.finish!(analyzer::DispatchAnalyzer, frame::CC.InferenceState)
    caller = frame.result

    # get the source before running `finish!` to keep the reference to `OptimizationState`
    src = caller.src

    # run `finish!(::AbstractAnalyzer, ::CC.InferenceState)` first to convert the optimized `IRCode` into optimized `CodeInfo`
    ret = @invoke CC.finish!(analyzer::AbstractAnalyzer, frame::CC.InferenceState)

    if analyzer.frame_filter(frame.linfo)
        if isa(src, Core.Const) # the optimization was very successful, nothing to report
        elseif isnothing(src) # means, compiler decides not to do optimization
            ReportPass(analyzer)(OptimizationFailureReport, analyzer, caller, src)
        elseif isa(src, CC.OptimizationState) # the compiler optimized it, analyze it
            ReportPass(analyzer)(RuntimeDispatchReport, analyzer, caller, src)
        else # and thus this pass should never happen
            # as we should already report `OptimizationFailureReport` for this case
            throw("got $src, unexpected source found")
        end
    end

    return ret
end

@reportdef struct OptimizationFailureReport <: InferenceErrorReport end
function JETInterface.print_report(io::IO, (; sig)::OptimizationFailureReport)
    JET.default_report_printer(io, "failed to optimize", sig)
end
function (::DispatchAnalysisPass)(::Type{OptimizationFailureReport}, analyzer::DispatchAnalyzer, result::CC.InferenceResult)
    add_new_report!(analyzer, result, OptimizationFailureReport(result.linfo))
end

@reportdef struct RuntimeDispatchReport <: InferenceErrorReport end
function JETInterface.print_report(io::IO, (; sig)::RuntimeDispatchReport)
    JET.default_report_printer(io, "runtime dispatch detected", sig)
end

function (::DispatchAnalysisPass)(::Type{RuntimeDispatchReport}, analyzer::DispatchAnalyzer, caller::CC.InferenceResult, opt::CC.OptimizationState)
    (; sptypes, slottypes) = opt
    for (pc, x) in enumerate(opt.src.code)
        if isexpr(x, :call)
            ft = CC.widenconst(CC.argextype(first(x.args), opt.src, sptypes, slottypes))
            ft <: Core.Builtin && continue # ignore `:call`s of the builtin intrinsics
            add_new_report!(analyzer, caller, RuntimeDispatchReport((opt, pc)))
        end
    end
end