# https://swagger.io/specification/
module Swagger

@enum In query header path cookie

struct Parameter
	name::String
	required::Bool
	in::In
	description::String
	depecated::Bool
	allowEmptyValue::Bool

	explode::Bool
	allowReserved::Bool
	schema::Schema
end

struct Contact
	name::String
	url::String
	email::String
end

struct License 
	name::String
	url::String
end

struct ServerVariable
	enum::Array{String}
	default::String
	description::String
end

struct Components
	schema::Dict{String, Union{Schema, Object, ReferenceObject}}
	responses::Dict{String, Response, Object, ReferenceObject}
	parameters::Dict{String, Response, Object, ReferenceObject}
	examples::Dict{String, Example, Object, ReferenceObject}
	requestBodies::Dict{String, Union{Request, BodyObject, ReferenceObject}}
	securitySchemes::Dict{String, SecuritySchemeObject, ReferenceObject}
	links::Dict{String, LinkObject, ReferenceObject}
	callbacks::Dict{String, CallbackObject, ReferenceObject}
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
	servers::Array{SeversObject}
	parameters::Union{ParametersObject, Nothing}
end


# note to self start from here
struct OperationObject
	tags::Array{String}
	summary::Union{String, Nothing}
	description::Union{String, Nothing}
	externalDocs::Union{ExternalDocumentaionObject, Nothing}
	operationId::String
	parameters::Array{ParamterObject}
	requestBody::Union{RequestBodyObject, Nothing}
	responses::Union{ResponseObject, Nothing}
end

const PathsObject = Pair{String, PathItemObject} 


struct Sever 
	url::String
	description::String
	variables::Dict{String, ServerVariable}
end

struct OpenAPI
	openapi::String # semantic version number
	info::Union{Info, Nothing}
	servers::Array{Servers}
	paths::Union{Paths, Nothing}
	components::Union{Components, Nothing}
	security::Array{Security}
	tags::Array{Tags}
	externalDocs::Union{ExternalDocs, Nothing}
end


struct Info 
	title::String 
	description::Union{String, Nothing}
	termsOfService::Union{String, Nothing}
	contact::Union{Contact, Nothing}
	license::Union{License, Nothing}
	version::String  
end

end