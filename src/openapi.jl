# https://swagger.io/specification/
# module OpenAPIv3

struct ExternalDocumentationObject
	description::String
	url::String
end

struct TagObject
	name::String
	description::String
	externalDocs::ExternalDocumentationObject
end

struct DiscriminatorObject
	propertyName::String
	mapping::Dict{String, String}
end

struct SchemaObject
	nullable::Bool
	discriminator::DiscriminatorObject
	readOnly::Bool
	writeOnly::Bool
	externalDocs::ExternalDocumentationObject
	example::Any
	deprecated::Bool
end

struct ServerVariable
	enum::Array{String}
	default::String
	description::String
end

struct ServerObject
	url::String
	description::String
	variables::Dict{String, ServerVariable}
end

struct HeaderObject
	description::String
	required::Bool
	depecated::Bool
	allowEmptyValue::Bool
	style::String
	explode::Bool
	allowReserved::Bool
end

struct LinkObject
	operationRef::String
	operationId::String
	parameters::Dict{String, String}
	requestBody::String
	description::String
	server::ServerObject
end

struct Contact
	name::String
	url::String
	email::String
end


struct ExampleObject
	summary::String
	description::String
	# can have either value or external value not both
	value::Any
	externalValue::String
end


Base.@kwdef struct EncodingObject
	contentType::String # */* for unknown formats
	headers::Dict{String, HeaderObject}
	styled::Union{String, Missing} = missing
	explode::Union{Bool, Missing} = missing
	allowReserved::Bool = false
end

Base.@kwdef struct MediaTypeObject
	schema::JSONSchema
	example::Union{Any, Missing} = missing
	examples::Union{Dict{String, ExampleObject}, Missing} = missing
	# only relevant for forms, I think?
	encoding::Union{Dict{String, EncodingObject}, Missing} = missing
end

@enum In query header path cookie

Base.@kwdef struct ParameterObject
	name::String
	in::In
	description::Union{String, Missing} = missing
	required::Bool = true
	depecated::Bool = false
	allowEmptyValue::Bool = false
	style::Union{String, Missing} = missing
	explode::Union{Bool, Missing} = missing
	# only applies to query
	allowReserved::Union{Bool, Missing} = missing
	schema::Union{JSONSchema, Missing} = missing
	example::Union{Any, Missing} = missing
	examples::Union{Dict{String, ExampleObject}, Missing} = missing
	content::Union{Dict{String, MediaTypeObject}, Missing} = missing
end

struct OAuthFlowObject
	authorizationUrl::String
	tokenUrl::String
	refreshUrl::String
	scopes::Dict{String, String}
end

struct SecurityRequirementObject
	# custom serialization
	requirements::Dict{String, Array{String}}
end

struct License 
	name::String
	url::String
end

Base.@kwdef struct RequestBodyObject
	description::Union{String, Missing} = missing
	content::Dict{String, MediaTypeObject}
	required::Bool = false
end


Base.@kwdef struct ResponseObject
	description::Union{String, Missing} = missing
	headers::Union{Dict{String, HeaderObject}, Missing} = missing
	content::Dict{String, MediaTypeObject}
	links::Union{Dict{String, LinkObject}, Missing} = missing
end

struct ResponsesObject
	default::ResponseObject
	# needs custom serialization
	statusCodes::Dict{String, ResponseObject}
end

struct OperationObject
	tags::Array{String}
	summary::Union{String, Nothing}
	description::Union{String, Nothing}
	externalDocs::Union{ExternalDocumentationObject, Nothing}
	operationId::String
	parameters::Array{ParameterObject}
	requestBody::Union{RequestBodyObject, Nothing}
	responses::Union{ResponseObject, Nothing}
	callbacks::Dict{String, Dict{String, Union{String, Array{String}}}}
	depercated::Bool
	security::Array{SecurityRequirementObject}
	servers::Array{ServerObject}
end

struct PathItemObject
	summary::Union{String, Nothing}
	description::Union{String, Nothing}
	get::Union{String, OperationObject}
	put::Union{String, OperationObject}
	post::Union{String, OperationObject}
	delete::Union{String, OperationObject}
	options::Union{String, OperationObject}
	head::Union{String, OperationObject}
	patch::Union{String, OperationObject}
	trace::Union{String, OperationObject}
	servers::Array{ServerObject}
	parameters::Union{ParameterObject, Nothing}
end

struct CallbackObject
	# needs custom serialization
	callbacks::Dict{String, PathItemObject}
end

struct OAuthFlowsObject
	implict::OAuthFlowObject
	password::OAuthFlowObject
	clientCredntials::OAuthFlowObject
	authorizationCode::OAuthFlowObject
end

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

const PathsObject = Pair{String, PathItemObject} 

struct Info 
	title::String 
	description::Union{String, Nothing}
	termsOfService::Union{String, Nothing}
	contact::Union{Contact, Nothing}
	license::Union{License, Nothing}
	version::String  
end

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

struct OpenAPI
	openapi::String # semantic version number
	info::Union{Info, Nothing}
	servers::Array{ServerObject}
	paths::Union{PathsObject, Nothing}
	components::Union{Components, Nothing}
	security::Array{SecurityRequirementObject}
	tags::Array{TagObject}
	externalDocs::Union{ExternalDocumentationObject, Nothing}
end


function parameters(q::Query{T}) where T
	l = ParameterObject[]
	StructTypes.foreachfield(T) do  i, field, field_type
		schema = JSONSchema(;json_schema(field_type)...)
		d = (
			name =  string(field),
			in = query,
			required = q.required,
			schema = schema,
			allowReserved = false,

		)
		push!(l, ParameterObject(;d...))
	end
	l
end

function RequestBodyObject(b::Body{T}) where T

	if StructType(T) ==  NoStructType()
		error("unsuppored type $T")
	end

	media_type = MediaTypeObject(
		schema = JSONSchema(;json_schema(T)...),
	)

	RequestBodyObject(
		content = Dict(
			"application/json" => media_type
		),
		required = b.required,
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