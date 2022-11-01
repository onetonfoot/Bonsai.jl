using StructTypes

macro data(expr)
    expr = macroexpand(__module__, expr) # to expand @static
    expr isa Expr && expr.head === :struct || error("Invalid usage of @kwdef")
    expr = expr::Expr
	mutable = expr.args[1]
	name = expr.args[2]
	esc(quote 
		Base.@kwdef($expr)
		if $mutable
			StructTypes.StructType(::Type{$name}) = StructTypes.Mutable()
		else
			StructTypes.StructType(::Type{$name}) = StructTypes.Struct()
		end
		Bonsai.description(t::Type{$name}) = Bonsai.docstr(t)
	end)
end
