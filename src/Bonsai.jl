module Bonsai

using HTTP, JSON3, StructTypes, Dates, LRUCache, FilePaths
import HTTP: Request, Response, Stream
using Base.Meta: show_sexpr

using ExprManipulation

export ResponseCodes

# we need keep a reference to the original atdoc function
# because atdoc! will overwrite it but i need i later 
const expander = Core.atdoc

__init__() = (Core.atdoc!(doc_hook); nothing)

# const setter! = Core.atdoc!

doc_hook(args...) = expander(args...)
# I don't know if this second one is needed but it's here because I adapted the code
# from  https://github.com/JuliaDocs/DocStringExtensions.jl/blob/master/src/templates.jl
# which also had it :/
doc_hook() = Core.atdoc!(expander)

_expr = Ref{Any}(nothing)
_doc_expr = Ref{Any}(nothing)

# this hack let's use document expression that should normally be allowed
# such as app.get("/index") do stream end
function doc_hook(a::LineNumberNode, b::Module, c::String, expr::Expr)

	# @info "args" a=a b=b c=c d=expr
	# @info "typeof" a=typeof(a) b=typeof(b) c=typeof(c) d=typeof(expr)

	# this won't hanlde the case of assigment although it's unlikely you need that
	# f = app.get("/") do stream end
	mexpr = MExpr(:do, MExpr(:call, Capture(:_), Capture(:route)), Capture(:_))

	m = match(mexpr, expr)

	if !isnothing(m)
		app = expr.args[1].args[1].args[1]
		method = expr.args[1].args[1].args[2].value
		app = eval(getfield(b, app))

		route = m.route

		# handles cases where route is passed in as a variable
		if !(route isa AbstractString)
			route = eval(getfield(b, route))
		end

		# @info  "route" route=route app= app
		# show_sexpr(expr)
		_expr[] = expr

		v = gensym()

		# we need to modify the expression to assign to a variable
		# so we are able to associate documentation with the handler
		expr = quote
			$v = $expr;
		end

		app.paths_docs[method][route] = c
	end
 	return expander(a,b,c,expr)
end


include("ResponseCodes.jl")
include("mime_types.jl")
include("http.jl")
include("exceptions.jl")
include("json_schema.jl")
include("handlers.jl")
include("io.jl")
include("cancel_token.jl")
include("router.jl")
include("middleware.jl")
include("openapi.jl")
include("app.jl")
include("server.jl")
include("docs.jl")

end