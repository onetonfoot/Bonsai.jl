# https://spec.openapis.org/oas/v3.1.0

# https://swagger.io/specification/
# module OpenAPIv3
using StructTypes
import HTTP.Handlers: Leaf

export OpenAPI, open_api!

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
    mapping::Dict{String,String}
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
    variables::Dict{String,ServerVariable}
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
    parameters::Dict{String,String}
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
    headers::Dict{String,HeaderObject}
    styled::Union{String,Nothing} = nothing
    explode::Union{Bool,Nothing} = nothing
    allowReserved::Bool = false
end

StructTypes.StructType(::Type{EncodingObject}) = StructTypes.Struct()
StructTypes.omitempties(::Type{EncodingObject}) = true


Base.@kwdef struct MediaTypeObject
    schema::JSONSchema
    example::Union{Any,Nothing} = nothing
    examples::Union{Dict{String,ExampleObject},Nothing} = nothing
    # only relevant for forms, I think?
    encoding::Union{Dict{String,EncodingObject},Nothing} = nothing
end

StructTypes.StructType(::Type{MediaTypeObject}) = StructTypes.UnorderedStruct()
StructTypes.omitempties(::Type{MediaTypeObject}) = true

MediaTypeObject(t::DataType) = MediaTypeObject(
    schema=json_schema(t)
)


Base.@kwdef struct ParameterObject
    name::String
    in::String # any of - query header path cookie
    description::Union{String,Nothing} = nothing
    required::Bool = true
    depecated::Bool = false
    allowEmptyValue::Bool = false
    style::Union{String,Nothing} = nothing
    explode::Union{Bool,Nothing} = nothing
    schema::Union{JSONSchema,Nothing} = nothing
    example::Union{Any,Nothing} = nothing
    examples::Union{Dict{String,ExampleObject},Nothing} = nothing
    content::Union{Dict{String,MediaTypeObject},Nothing} = nothing

    # only applies to query
    allowReserved::Union{Bool,Nothing} = nothing
end

StructTypes.StructType(::Type{ParameterObject}) = StructTypes.Struct()
StructTypes.omitempties(::Type{ParameterObject}) = true

struct OAuthFlowObject
    authorizationUrl::String
    tokenUrl::String
    refreshUrl::String
    scopes::Dict{String,String}
end

StructTypes.StructType(::Type{OAuthFlowObject}) = StructTypes.Struct()

struct SecurityRequirementObject
    # custom serialization
    requirements::Dict{String,Array{String}}
end

StructTypes.StructType(::Type{SecurityRequirementObject}) = StructTypes.Struct()

struct License
    name::String
    url::String
end

StructTypes.StructType(::Type{License}) = StructTypes.Struct()

Base.@kwdef struct RequestBodyObject
    description::Union{String,Nothing} = nothing
    content::Dict{String,MediaTypeObject}
    required::Bool = false
end

StructTypes.StructType(::Type{RequestBodyObject}) = StructTypes.Struct()
StructTypes.omitempties(::Type{RequestBodyObject}) = true

Base.@kwdef struct ResponseObject
    # keys are the content type
    # application/json => value
    content::Dict{String,MediaTypeObject}
    description::Union{String,Nothing} = nothing
    headers::Union{Dict{String,HeaderObject},Nothing} = nothing
    links::Union{Dict{String,LinkObject},Nothing} = nothing
end

StructTypes.StructType(::Type{ResponseObject}) = StructTypes.Struct()
StructTypes.omitempties(::Type{ResponseObject}) = true

struct ResponsesObject
    default::ResponseObject
    # needs custom serialization
    statusCodes::Dict{String,ResponseObject}
end

StructTypes.StructType(::Type{ResponsesObject}) = StructTypes.Struct()
StructTypes.omitempties(::Type{ResponsesObject}) = true

Base.@kwdef mutable struct OperationObject
    responses::Dict{String,ResponseObject}
    tags::Union{Array{String},Nothing} = nothing
    summary::Union{String,Nothing} = nothing
    description::Union{String,Nothing} = nothing
    externalDocs::Union{ExternalDocumentationObject,Nothing} = nothing
    operationId::String = string(uuid4())
    parameters::Array{ParameterObject} = nothing
    requestBody::Union{RequestBodyObject,Nothing} = nothing
    callbacks::Union{Dict{String,Dict},Nothing} = nothing
    depercated::Bool = false
    security::Union{Array{SecurityRequirementObject},Nothing} = nothing
    servers::Union{Array{ServerObject},Nothing} = nothing
end

StructTypes.StructType(::Type{OperationObject}) = StructTypes.Struct()
StructTypes.omitempties(::Type{OperationObject}) = true


Base.@kwdef mutable struct PathItemObject
    summary::Union{String,Nothing} = nothing
    description::Union{String,Nothing} = nothing
    get::Union{Nothing,OperationObject} = nothing
    put::Union{Nothing,OperationObject} = nothing
    post::Union{Nothing,OperationObject} = nothing
    delete::Union{Nothing,OperationObject} = nothing
    options::Union{Nothing,OperationObject} = nothing
    head::Union{Nothing,OperationObject} = nothing
    patch::Union{Nothing,OperationObject} = nothing
    trace::Union{Nothing,OperationObject} = nothing
    servers::Union{Nothing,Array{ServerObject}} = nothing
    parameters::Union{ParameterObject,Nothing} = nothing
end

StructTypes.StructType(::Type{PathItemObject}) = StructTypes.Struct()
StructTypes.omitempties(::Type{PathItemObject}) = true

struct CallbackObject
    # needs custom serialization
    callbacks::Dict{String,PathItemObject}
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

const PathsObject = Pair{String,PathItemObject}

Base.@kwdef struct Info
    title::String = ""
    description::Union{String,Nothing} = nothing
    termsOfService::Union{String,Nothing} = nothing
    contact::Union{Contact,Nothing} = nothing
    license::Union{License,Nothing} = nothing
    version::String = "3.0.0"
end

StructTypes.StructType(::Type{Info}) = StructTypes.Struct()

struct Components
    schema::Dict{String,Union{SchemaObject}}
    responses::Dict{String,ResponseObject}
    parameters::Dict{String,ResponseObject}
    examples::Dict{String,ExampleObject}
    requestBodies::Dict{String,RequestBodyObject}
    securitySchemes::Dict{String,SecuritySchemeObject}
    links::Dict{String,LinkObject}
    callbacks::Dict{String,CallbackObject}
end

StructTypes.StructType(::Type{Components}) = StructTypes.Struct()

Base.@kwdef mutable struct OpenAPI
    openapi::String = "3.0.0" # semantic version number
    info::Union{Info,Nothing} = nothing
    servers::Array{ServerObject} = []
    paths::Dict{String,PathItemObject} = Dict()
    components::Union{Components,Nothing} = nothing
    security::Array{SecurityRequirementObject} = []
    tags::Array{TagObject} = []
    externalDocs::Union{ExternalDocumentationObject,Nothing} = nothing
end

StructTypes.StructType(::Type{OpenAPI}) = StructTypes.Struct()
StructTypes.omitempties(::Type{OpenAPI}) = true

function open_api_parameters(leaf::Leaf)
    l = ParameterObject[]
    (; handler) = leaf
    for t in handler_reads(handler)
        push!(l, open_api_parameters(t)...)
    end
    l
end

function open_api_parameters(::Type{A}) where {A<:HttpParameter}

    T = parameter_type(A)

    l = ParameterObject[]

    in = if A <: Query
        "query"
    elseif A <: Route
        "path"
    elseif A <: Headers
        "header"
    else
        error("invalid type $A for ParameterObject")
    end

    StructTypes.foreachfield(T) do i, field, field_type
        schema = json_schema(field_type)
        d = (
            name=string(field),
            in=in,
            required=Missing <: field_type,
            schema=schema,
        )
        push!(l, ParameterObject(; d...))
    end
    l
end

function RequestBodyObject(::Type{Body{T}}) where {T}

    if StructType(T) == NoStructType()
        error("no struct type defined for $T")
    end

    media_type = MediaTypeObject(
        schema=json_schema(T),
    )

    RequestBodyObject(
        content=Dict(
            "application/json" => media_type
        ),
        description = doc_str(T),
        required=true,
    )
end

function ResponseObject(t::DataType)

    st = StructTypes.StructType(t)
    if st == NoStructType()
        error("unsuppored type $t")
    end

    media_type = MediaTypeObject(
        schema=JSONSchema(; json_schema(t)...),
    )

    ResponseObject(
        content=Dict(
            "application/json" => media_type
        ),
    )
end

function groupby_status_code(l)
    d = Dict()
    code = first(l)
    for i in l 
        if i <: Status
            code = i
            continue
        end
        writes = get(d, code, [])
        push!(writes, i)
        d[code] = writes
    end
    return d
end

OperationObject(h::HttpHandler) = OperationObject(h.fn)
OperationObject(h::Middleware) = OperationObject(h.fn)

function OperationObject(handler)
    writes = handler_writes(handler) |> groupby_status_code

    # filter!(x -> x isa Status, writes)
    responses = Dict{String,ResponseObject}()


    # for now we will ignore duplicate response codes
    # and assume everything is a json response 

    if !isempty(writes) 
        res_code = first(writes)
        for (res_code, res_types) in writes
            k = string(extract_status_code(res_code))


            content = Dict()
            headers = Dict()

            for res_type in res_types
                # ensure we are full type like Body{String} and not Body
                if res_type isa UnionAll
                    continue
                end

                # we can't know the mime type until we read the file :/
                # https://stackoverflow.com/questions/1176022/unknown-file-type-mime
                if res_type <: Body{<:AbstractPath}
                    continue
                elseif res_type <: Body 
                    k = mime_type(res_type)
                    content[k] = MediaTypeObject(res_type)
                elseif res_type <: Headers
                    #= 
                    TODO: support headsers in OpenAPI
                    need to define  json_schema for Headers
                    =#
                end
            end

            responses[k] = ResponseObject(
                content=content,
                headers=nothing
            )
        end
    end

    params = ParameterObject[]
    requestBody = nothing

    for p in handler_reads(handler)

        if p isa UnionAll
            continue
        end

        if p <: Body
            requestBody = RequestBodyObject(p)
        else p <: Union{Query, Route, Headers}
            push!(params, open_api_parameters(p)...)
        end
    end

    OperationObject(
        responses=responses,
        requestBody=requestBody,
        parameters=params,
    )
end

function OperationObject(leaf::Leaf) 
    o = OperationObject(leaf.handler)
    o.operationId = leaf.path
    return o
end

# function PathItemObject(leaves::Array{Leaf})
#     PathItemObject(;d...)
# end


function OpenAPI(app)

    paths = Dict{String, Dict{Symbol, Any}}()

    leaves = []
    for n in PostOrderDFS(app.paths)
        if !isempty(n.methods)
            push!(leaves, n.methods...)
        end
    end

    for leaf in leaves
        (; path, method) = leaf

        d = get(paths, path, Dict())
        o = OperationObject(leaf)

        method = Symbol(lowercase(method)) # "GET" -> :get
        docs = app.paths_docs[method]
        description = get(docs, path, nothing)
        o.description = description

        d[method] = o
        paths[path] = d
    end

    paths = Dict(
        k => PathItemObject(; v...) for (k, v) in paths
    )

    OpenAPI(
        paths=paths,
        info=Info()
    )
end


function open_api!(app)
    open_api = OpenAPI(app)
    html = Path(joinpath(@__DIR__, "../open_api/dist/index.html"))

    app.get["/docs/open-api.json"] = function(stream)
        Bonsai.write(stream, Body(open_api))
    end

    app.get["/docs"] = function(stream)
        Bonsai.write(stream, Body(html))
    end
end