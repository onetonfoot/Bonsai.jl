using StructTypes

macro data(expr)
    expr = macroexpand(__module__, expr) # to expand @static
    expr isa Expr && expr.head === :struct || error("Invalid usage of @kwdef")
    expr = expr::Expr
	name = expr.args[2]
	@info name
	esc(quote 
		Base.@kwdef($expr)
		StructTypes.StructType(::Type{$name}) = StructTypes.Struct()
		Bonsai.description(t::Type{$name}) = Bonsai.docstr(t)
	end)
end
