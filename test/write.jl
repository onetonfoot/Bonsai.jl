using JET, InteractiveUtils # to use analysis entry points
using CodeInfoTools
using HTTP:Stream
using Bonsai

@testset "todo!" begin
	stream = 10

	function f(stream)
		Bonsai.write(stream, 200)
		Bonsai.write(stream, "ok", status_code=10)
	end


	function handler(stream::Stream)
		Bonsai.write(stream, "String")
		f(stream)
	end


	r = report_call(handler, Tuple{Stream}, analyzer=DispatchAnalyzer) 

	reports = JET.get_reports(r)

	# https://discourse.julialang.org/t/closure-over-a-function-with-keyword-arguments-while-keeping-access-to-the-keyword-arguments/15574

	# Keyword arguemnts create
	w = @which Bonsai.write(stream, "ok"; status_code=10)
	# (::Bonsai.var"#write##kw")(::Any, ::typeof(Bonsai.write), stream, data) in Bonsai at /home/dom/Code/Bonsai.jl/src/fns.jl:25

	# https://discourse.julialang.org/t/untyped-keyword-arguments/24228
	
end