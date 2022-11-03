using StructTypes, ExproniconLite

macro data(expr)
	s = JLKwStruct(expr)
	name = s.name
	esc(quote 
		Bonsai.@composite(Base.@kwdef($expr))
		if $(s.ismutable)
			StructTypes.StructType(::Type{$name}) = StructTypes.Mutable()
		else
			StructTypes.StructType(::Type{$name}) = StructTypes.Struct()
		end
		Bonsai.description(t::Type{$name}) = Bonsai.docstr(t)
	end)
end
