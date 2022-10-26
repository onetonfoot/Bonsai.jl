# object like json schema types
# https://json-schema.org/draft/2020-12/json-schema-core.html
# https://json-schema.org/understanding-json-schema/index.html
# https://opis.io/json-schema
using StructTypes
using StructTypes: OrderedStruct, UnorderedStruct, Mutable, DictType
using StructTypes: ArrayType
using StructTypes: StringType, NumberType, BoolType, NullType
using NamedTupleTools
using Dates
using UUIDs
using Base.Docs

const array_types = [ArrayType()]
const object_types = [OrderedStruct(), UnorderedStruct(), Mutable(), DictType()]
const primative_types = [StringType(), NumberType(), BoolType(), NullType()]



function union_types(t)
    l = []
    if t.a isa Union
        push!(l, union_types(t.a)...)
    else
        push!(l, t.a)
    end

    if t.b isa Union
        push!(l, union_types(t.b)...)
    else
        push!(l, t.b)
    end
    l
end

# whats is the signature for compound types
# bellow doesn't functions as intented
# json_type(::Type{Vector})  = array

json_type(::Type{Bool}) = "boolean"
json_type(::Type{<:Integer}) = "integer"
json_type(::Type{<:Real}) = "number"
json_type(::Type{Nothing}) = "null"
json_type(::Type{Missing}) = "null"
json_type(::Type{String}) = "string"
json_type(::Type{<:Enum}) = "string"

array_type(::Type{<:Vector{T}}) where {T} = T
array_type(::Type{<:Array{T}}) where {T} = T

json_schema(::Type{Headers{T}}, d=Dict{Symbol,Any}()) where {T} = json_schema(T, d)
json_schema(::Type{Body{T}}, d=Dict{Symbol,Any}()) where {T} = json_schema(T, d)

# Might it would be better to define a trait for this
function doc_str(fn)

    if fn isa Type
        fn = extract_type(fn)
    end

    md = Docs.doc(fn)
    s = repr(md)


    # @info "docs" fn typeof(fn) s


    if startswith(s, "No documentation found.")
        return nothing
    else
        return s
    end
end


function json_schema(::Type{T}, d=Dict{Symbol,Any}()) where {T}

    if T isa Union
        return JSONSchema(
            oneOf=unique(json_schema.(union_types(T)))
        )
    end

    sT = StructTypes.StructType(T)

    # http://json-schema.org/understanding-json-schema/reference/object.html
    if sT in object_types
        d[:type] = "object"
        # This isn't needed in swagger so leave out
        # d[:description] = doc_str(T)
        if !(sT == DictType())
            properties = Dict{String,Any}()
            StructTypes.foreachfield(T) do i, field, field_type
                field_schema = json_schema(field_type)
                push!(properties, string(field) => field_schema)
            end
            d[:properties] = properties
        end
        # http://json-schema.org/understanding-json-schema/reference/array.html
    elseif sT in array_types
        d[:type] = "array"
        if T <: Tuple
            d[:prefixItems] = map(x -> json_schema(x), T.types)
        end
        if T <: Array
            aT = array_type(T)
            if aT isa Union
                error("union types in arrays are not supported")
            end
            d[:items] = json_schema(aT)
        end
    elseif sT in primative_types
        if T <: Enum
            d[:description] = doc_str(T)
            d[:enum] = Base.Enums.namemap(T) |> values |> collect .|> String
        else
            d[:type] = json_type(T)
        end
    else
        error("unable to determin json_schema for $T")
    end

    schema = JSONSchema(; d...)

    if isnothing(schema.type) &&
       isnothing(schema.anyOf) &&
       isnothing(schema.enum) &&
       isnothing(schema.oneOf) &&
       isnothing(schema.not)
        @warn "No data type in schema"
    end

    return schema
end


# @enum JSONSchemaFormat 

# str enum regex object boolean null array integer number
JSONSchemaType = String

function json_schema_format(x::Type{T}) where {T}

    # renaming valid formats
    # "hostname"
    # "idn-hostname"
    # "ipv4"
    # "ipv6"
    # "uri-reference"
    # "iri"
    # "ir-reference"
    # "uri-template"
    # "json-pointer"

    return if x <: DateTime
        "date-time"
    elseif x <: Time
        "time"
    elseif x <: Date
        "date"
    elseif x <: TimePeriod
        "duration"
    elseif x <: AbstractString
        "email"
        "idn-email"
    elseif x <: UUID
        "uuid"
    elseif x <: Regex
        "regex"
    elseif x <: URI
        "uri"
    else
        error("unsupported type $x")
    end
end


Base.@kwdef struct JSONSchema
    # can it really be and array of types?
    type::Union{Nothing,JSONSchemaType} = nothing

    enum::Union{Nothing,Vector{String}} = nothing

    # schema composition
    allOf::Union{Nothing,Vector{JSONSchema}} = nothing
    anyOf::Union{Vector{JSONSchema},Nothing} = nothing
    oneOf::Union{Nothing,Vector{JSONSchema}} = nothing
    not::Union{Nothing,Vector{JSONSchema}} = nothing

    # string related fields #
    maxLength::Union{Int,Nothing} = nothing
    minLength::Union{Int,Nothing} = nothing
    pattern::Union{Regex,Nothing} = nothing
    format::Union{String,Nothing} = nothing

    # number releated fields #
    multipleOf::Union{Int,Nothing} = nothing
    minimum::Union{Int,Nothing} = nothing
    exclusiveMinimum::Union{Int,Nothing} = nothing
    maximum::Union{Int,Nothing} = nothing
    exclusiveMaximum::Union{Int,Nothing} = nothing

    # object related fields #
    properties::Union{Dict{String,Any},Nothing} = nothing
    parternProperties::Union{Dict{Regex,Any},Nothing} = nothing
    additionalProperties::Union{Union{Bool,Any},Nothing} = nothing
    required::Union{Array{String},Nothing} = nothing
    propertiesNames::Union{Pair{String,String},Nothing} = nothing
    minProperties::Union{Int,Nothing} = nothing
    maxProperties::Union{Int,Nothing} = nothing
    const_::Union{Any,Nothing} = nothing

    # array releated fields #
    items::Union{JSONSchema,Nothing,Bool} = nothing
    prefixItems::Union{Vector{JSONSchema},Nothing} = nothing
    additionalItem::Union{Bool,Nothing} = nothing
    contains::Union{Vector{JSONSchema},Nothing} = nothing
    unqiueItems::Union{Bool,Nothing} = nothing
    minItems::Union{Int,Nothing} = nothing
    maxItems::Union{Int,Nothing} = nothing

    # generic fields #
    title::Union{String,Nothing} = nothing
    description::Union{String,Nothing} = nothing
    examples::Union{Array{Any},Nothing} = nothing
    deprecated::Union{Bool,Nothing} = nothing
    readOnly::Union{Bool,Nothing} = nothing
    writeOnly::Union{Bool,Nothing} = nothing
end

StructTypes.StructType(::Type{JSONSchema}) = StructTypes.Struct()
StructTypes.omitempties(::Type{JSONSchema}) = true