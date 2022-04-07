using CodeTracking
using ExprManipulation, ExprTools
using Base.Meta


function fn_expr(fn)
	ms = methods(fn)
	m = ms[1]
	types = tuple(m.sig.types[2:end]...)
	Meta.parse(code_string(fn, types))
end

function fn_kwargs(g)
	g_expr = fn_expr(g)
	g_def = splitdef(g_expr)
	d = Dict()
	m_expr = MExpr(:kw, Capture(:var), Capture(:expr))
	for i in g_def[:kwargs]
		m = match(m_expr, i)
		d[m.var] = eval(m.expr)
	end
	d
end

