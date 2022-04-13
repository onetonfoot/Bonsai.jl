using CodeTracking
using ExprManipulation, ExprTools
using Base.Meta

function fn_expr(fn)
	ms = methods(fn)
	m = ms[1]
	types = tuple(m.sig.types[2:end]...)
	Meta.parse(code_string(fn, types))
end

# How to get the correct module :/
# https://discourse.julialang.org/t/get-the-name-of-the-invoking-module/22685/5

function fn_kwargs(fn, mod)
	expr = fn_expr(fn)
	def = splitdef(expr)
	d = Dict()
	m_expr = MExpr(:kw, Capture(:var), Capture(:expr))
	for i in def[:kwargs]
		m = match(m_expr, i)
		d[m.var] = mod.eval(m.expr)
	end
	d
end