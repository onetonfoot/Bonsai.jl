# https://swagger.io/specification/
module OpenAPIv3

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


struct EncodingObject
	contentType::String
	headers::Dict{String, HeaderObject}
	styled::String
	explode::Bool
	allowReserved::Bool
end

struct MediaTypeObject
	schema::SchemaObject
	example::Any
	examples::Dict{String, ExampleObject}
	encoding::Dict{String, EncodingObject}
end


@enum In query header path cookie

struct ParameterObject
	name::String
	in::In
	description::String
	required::Bool
	depecated::Bool
	allowEmptyValue::Bool
	style::String
	explode::Bool
	allowReserved::Bool
	schema::SchemaObject
	example::Any
	examples::Dict{String, ExampleObject}
	content::Dict{String, MediaTypeObject}
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


struct RequestBodyObject
	description::String
	content::Dict{String, MediaTypeObject}
	required::Bool
end


struct ResponseObject
	description::String
	headers::Dict{String, HeaderObject}
	content::String
	links::Dict{String, LinkObject}
end

struct ResponsesObject
	default::ResponseObject
	# needs custom serialization
	statusCodes::Dict{String, ResponseObject}
end


# note to self start from here
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

end