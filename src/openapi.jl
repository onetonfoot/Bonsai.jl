# https://spec.openapis.org/oas/v3.1.0

# https://swagger.io/specification/
# module OpenAPIv3
using StructTypes

struct ExternalDocumentationObject
	description::String
	url::String
end

StructTypes.StructType(::Type{ExternalDocumentationObject}) = StructTypes.Struct() 

struct TagObject
	name::String
	description::String
	externalDocs::ExternalDocumentationObject
end

StructTypes.StructType(::Type{TagObject}) = StructTypes.Struct() 

struct DiscriminatorObject
	propertyName::String
	mapping::Dict{String, String}
end

StructTypes.StructType(::Type{DiscriminatorObject}) = StructTypes.Struct() 

struct SchemaObject
	nullable::Bool
	discriminator::DiscriminatorObject
	readOnly::Bool
	writeOnly::Bool
	externalDocs::ExternalDocumentationObject
	example::Any
	deprecated::Bool
end

StructTypes.StructType(::Type{SchemaObject}) = StructTypes.Struct() 

struct ServerVariable
	enum::Array{String}
	default::String
	description::String
end

StructTypes.StructType(::Type{ServerVariable}) = StructTypes.Struct() 

struct ServerObject
	url::String
	description::String
	variables::Dict{String, ServerVariable}
end

StructTypes.StructType(::Type{ServerObject}) = StructTypes.Struct() 

struct HeaderObject
	description::String
	required::Bool
	depecated::Bool
	allowEmptyValue::Bool
	style::String
	explode::Bool
	allowReserved::Bool
end

StructTypes.StructType(::Type{HeaderObject}) = StructTypes.Struct() 

struct LinkObject
	operationRef::String
	operationId::String
	parameters::Dict{String, String}
	requestBody::String
	description::String
	server::ServerObject
end

StructTypes.StructType(::Type{LinkObject}) = StructTypes.Struct() 

struct Contact
	name::String
	url::String
	email::String
end

StructTypes.StructType(::Type{Contact}) = StructTypes.Struct() 

struct ExampleObject
	summary::String
	description::String
	# can have either value or external value not both
	value::Any
	externalValue::String
end

StructTypes.StructType(::Type{ExampleObject}) = StructTypes.Struct() 

Base.@kwdef struct EncodingObject
	contentType::String # */* for unknown formats
	headers::Dict{String, HeaderObject}
	styled::Union{String, Nothing} = nothing
	explode::Union{Bool, Nothing} = nothing
	allowReserved::Bool = false
end

StructTypes.StructType(::Type{EncodingObject}) = StructTypes.Struct() 
StructTypes.omitempties(::Type{EncodingObject}) = true


Base.@kwdef struct MediaTypeObject
	schema::JSONSchema
	example::Union{Any, Nothing} = nothing
	examples::Union{Dict{String, ExampleObject}, Nothing} = nothing
	# only relevant for forms, I think?
	encoding::Union{Dict{String, EncodingObject}, Nothing} = nothing
end

StructTypes.StructType(::Type{MediaTypeObject}) = StructTypes.UnorderedStruct() 
StructTypes.omitempties(::Type{MediaTypeObject}) = true

MediaTypeObject(t::DataType) = MediaTypeObject(
	schema = JSONSchema(;json_schema(t)...)
)

@enum In query header path cookie

Base.@kwdef struct ParameterObject
	name::String
	in::In
	description::Union{String, Nothing} = nothing
	required::Bool = true
	depecated::Bool = false
	allowEmptyValue::Bool = false
	style::Union{String, Nothing} = nothing
	explode::Union{Bool, Nothing} = nothing
	schema::Union{JSONSchema, Nothing} = nothing
	example::Union{Any, Nothing} = nothing
	examples::Union{Dict{String, ExampleObject}, Nothing} = nothing
	content::Union{Dict{String, MediaTypeObject}, Nothing} = nothing

	# only applies to query
	allowReserved::Union{Bool, Nothing} = nothing
end

StructTypes.StructType(::Type{ParameterObject}) = StructTypes.Struct() 
StructTypes.omitempties(::Type{ParameterObject}) = true

struct OAuthFlowObject
	authorizationUrl::String
	tokenUrl::String
	refreshUrl::String
	scopes::Dict{String, String}
end

StructTypes.StructType(::Type{OAuthFlowObject}) = StructTypes.Struct() 

struct SecurityRequirementObject
	# custom serialization
	requirements::Dict{String, Array{String}}
end

StructTypes.StructType(::Type{SecurityRequirementObject}) = StructTypes.Struct() 

struct License 
	name::String
	url::String
end

StructTypes.StructType(::Type{License}) = StructTypes.Struct() 

Base.@kwdef struct RequestBodyObject
	description::Union{String, Nothing} = nothing
	content::Dict{String, MediaTypeObject}
	required::Bool = false
end

StructTypes.StructType(::Type{RequestBodyObject}) = StructTypes.Struct() 
StructTypes.omitempties(::Type{RequestBodyObject}) = true

Base.@kwdef struct ResponseObject
	# keys are the content type
	# application/json => value
	content::Dict{String, MediaTypeObject}
	description::Union{String, Nothing} = nothing
	headers::Union{Dict{String, HeaderObject}, Nothing} = nothing
	links::Union{Dict{String, LinkObject}, Nothing} = nothing
end

StructTypes.StructType(::Type{ResponseObject}) = StructTypes.Struct() 
StructTypes.omitempties(::Type{ResponseObject}) = true

struct ResponsesObject
	default::ResponseObject
	# needs custom serialization
	statusCodes::Dict{String, ResponseObject}
end

StructTypes.StructType(::Type{ResponsesObject}) = StructTypes.Struct() 
StructTypes.omitempties(::Type{ResponsesObject}) = true

Base.@kwdef mutable struct OperationObject
	responses::Dict{String, ResponseObject}
	tags::Union{Array{String}, Nothing} = nothing
	summary::Union{String, Nothing} = nothing
	description::Union{String, Nothing} = nothing
	externalDocs::Union{ExternalDocumentationObject, Nothing} = nothing
	operationId::String = string(uuid4())
	parameters::Array{ParameterObject} = nothing
	requestBody::Union{RequestBodyObject, Nothing} = nothing
	callbacks::Union{Dict{String, Dict}, Nothing} = nothing
	depercated::Bool = false
	security::Union{Array{SecurityRequirementObject}, Nothing} = nothing
	servers::Union{Array{ServerObject}, Nothing} = nothing
end

StructTypes.StructType(::Type{OperationObject}) = StructTypes.Struct() 
StructTypes.omitempties(::Type{OperationObject}) = true


Base.@kwdef struct PathItemObject
	summary::Union{String, Nothing} = nothing
	description::Union{String, Nothing} = nothing
	get::Union{Nothing, OperationObject} = nothing
	put::Union{Nothing, OperationObject} = nothing
	post::Union{Nothing, OperationObject} = nothing
	delete::Union{Nothing, OperationObject} = nothing
	options::Union{Nothing, OperationObject} = nothing
	head::Union{Nothing, OperationObject} = nothing
	patch::Union{Nothing, OperationObject} = nothing
	trace::Union{Nothing, OperationObject} = nothing
	servers::Union{Nothing, Array{ServerObject}}  = nothing
	parameters::Union{ParameterObject, Nothing} = nothing
end

StructTypes.StructType(::Type{PathItemObject}) = StructTypes.Struct() 
StructTypes.omitempties(::Type{PathItemObject}) = true

struct CallbackObject
	# needs custom serialization
	callbacks::Dict{String, PathItemObject}
end

StructTypes.StructType(::Type{CallbackObject}) = StructTypes.Struct() 

struct OAuthFlowsObject
	implict::OAuthFlowObject
	password::OAuthFlowObject
	clientCredntials::OAuthFlowObject
	authorizationCode::OAuthFlowObject
end

StructTypes.StructType(::Type{OAuthFlowsObject}) = StructTypes.Struct() 

struct SecuritySchemeObject
	type::String
	description::String
	name::String
	in::String
	scheme::String
	bearerFormatString
	flows::OAuthFlowsObject
	openIdConnectUrl::String
end

StructTypes.StructType(::Type{SecuritySchemeObject}) = StructTypes.Struct() 

const PathsObject = Pair{String, PathItemObject} 

Base.@kwdef struct Info 
	title::String = ""
	description::Union{String, Nothing} = nothing
	termsOfService::Union{String, Nothing} = nothing
	contact::Union{Contact, Nothing} = nothing
	license::Union{License, Nothing} = nothing
	version::String  = "3.0.0"
end

StructTypes.StructType(::Type{Info}) = StructTypes.Struct() 

struct Components
	schema::Dict{String, Union{SchemaObject}}
	responses::Dict{String, ResponseObject}
	parameters::Dict{String, ResponseObject}
	examples::Dict{String, ExampleObject}
	requestBodies::Dict{String, RequestBodyObject}
	securitySchemes::Dict{String, SecuritySchemeObject}
	links::Dict{String, LinkObject}
	callbacks::Dict{String, CallbackObject}
end

StructTypes.StructType(::Type{Components}) = StructTypes.Struct() 

Base.@kwdef mutable struct OpenAPI
	openapi::String = "3.0" # semantic version number
	info::Union{Info, Nothing} = nothing
	servers::Array{ServerObject} = []
	paths::Dict{String, PathItemObject} = Dict()
	components::Union{Components, Nothing} = nothing
	security::Array{SecurityRequirementObject} = []
	tags::Array{TagObject} = []
	externalDocs::Union{ExternalDocumentationObject, Nothing} = nothing
end

StructTypes.StructType(::Type{OpenAPI}) = StructTypes.Struct() 
StructTypes.omitempties(::Type{OpenAPI}) = true

function open_api_parameters(http_path::HttpPath) 
	l = ParameterObject[]

	nt = http_path.parameters
	for (k,t) in zip(fieldnames(nt), nt.types)
		schema = JSONSchema(;json_schema(t)...)
		d = (
			name =  string(k),
			in = path,
			required = true,
			schema = schema,
		)
		push!(l, ParameterObject(;d...))
	end
	l
end

function open_api_parameters(::Headers{T}) where T
	l = ParameterObject[]
	StructTypes.foreachfield(T) do  i, field, field_type
		schema = JSONSchema(;json_schema(field_type)...)
		d = (
			name =  headerize(string(field)),
			in = header,
			required = Missing <: field_type,
			schema = schema,
		)
		push!(l, ParameterObject(;d...))
	end
	l
end


function open_api_parameters(::Query{T}) where T
	l = ParameterObject[]
	StructTypes.foreachfield(T) do  i, field, field_type
		schema = JSONSchema(;json_schema(field_type)...)
		d = (
			name =  string(field),
			in = query,
			required = !(Missing <: field_type),
			schema = schema,
			allowReserved = false,

		)
		push!(l, ParameterObject(;d...))
	end
	l
end

function RequestBodyObject(::Body{T}) where T

	if StructType(T) ==  NoStructType()
		error("no struct type defined for $T")
	end

	media_type = MediaTypeObject(
		schema = JSONSchema(;json_schema(T)...),
	)

	RequestBodyObject(
		content = Dict(
			"application/json" => media_type
		),
		required = true,
	)
end

function ResponseObject(t::DataType)

	st = StructTypes.StructType(t)
	if st ==  NoStructType()
		error("unsuppored type $t")
	end

	media_type = MediaTypeObject(
		schema = JSONSchema(;json_schema(t)...),
	)

	ResponseObject(
		content = Dict(
			"application/json" => media_type
		),
	)
end

OperationObject(h::HttpHandler) = OperationObject(h.fn)
OperationObject(h::Middleware) = OperationObject(h.fn)

function OperationObject(handler)
	writes = handler_writes(handler)
	responses = Dict{String, ResponseObject}()
	# for now we will ignore duplicate response codes
	# and assume everything is a json response 
	for (res_type, res_code) in writes
		k =  string(Int(res_code))
		responses[k] = ResponseObject(
			content = Dict(
				"application/json" => MediaTypeObject(res_type)
			)
		)
	end

	params = ParameterObject[]

	for p in http_parameters(handler)
		push!(params, open_api_parameters(p)...)
	end

	OperationObject(
		responses = responses,
		parameters = params,
	)
end

function OpenAPI(r::Router)

	paths = Dict()

	for (method, values) in r.paths
		m = Symbol(String(method))
		for v in values
			path, handler = v
			d = get(paths, path.path, Dict{Symbol, Any}())
			o = OperationObject( handler)
			o.operationId = path.path
			push!(o.parameters, open_api_parameters(path)...)
			d[m] = o
			paths[path.path] = d
		end
	end

	paths = Dict(
		k => PathItemObject(;v...) for (k, v) in paths
	)

	OpenAPI(
		paths = paths,
		info = Info()
	)
end