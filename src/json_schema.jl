# object like json schema types
# https://json-schema.org/draft/2020-12/json-schema-core.html
# https://json-schema.org/understanding-json-schema/index.html
using StructTypes
using StructTypes: OrderedStruct, UnorderedStruct, Mutable, DictType
using StructTypes:  ArrayType
using StructTypes: StringType, NumberType, BoolType, NullType
using NamedTupleTools
using Dates
using UUIDs

const array_types = [ArrayType()]
const object_types = [OrderedStruct(), UnorderedStruct(), Mutable(), DictType()]
const primative_types = [StringType(), NumberType(), BoolType(), NullType()]

@enum JSONType str enum regex object boolean null array integer number

# whats is the signature for compound types
# bellow doesn't functions as intented
# json_type(::Type{Vector})  = array

json_type(::Type{Bool}) = boolean
json_type(::Type{<:Integer}) =  integer
json_type(::Type{<:Real}) =  number
json_type(::Type{Nothing}) =  null
json_type(::Type{String}) =  str
json_type(::Type{<:Enum}) =  str

array_type(::Type{Array{T}}) where T = T

function json_schema(::Type{T}, d = Dict{Symbol, Any}()) where T

	sT = StructTypes.StructType(T)

	# http://json-schema.org/understanding-json-schema/reference/object.html
	if sT in object_types
		d[:type] = object
		if !(sT == DictType())
			properties = Dict{String, Any}()
			StructTypes.foreachfield(T) do  i, field, field_type
				field_schema = json_schema(field_type)
				push!(properties, string(field) => field_schema)
			end
			d[:properties] = properties
		end
	# http://json-schema.org/understanding-json-schema/reference/array.html
	elseif sT in array_types
		d[:type] = array
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
			d[:enum] = Base.Enums.namemap(T) |> values |> collect
		end
		d[:type] = json_type(T)
	end
	return namedtuple(d)
end


# @enum JSONSchemaFormat 

function json_schema_format(x::Type{T}) where T

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
	type::Union{JSONType, Array{JSONType}} 

	# string related fields #
	maxLength::Union{Int, Missing} = missing
	minLength::Union{Int, Missing} = missing
	pattern::Union{Regex, Missing} = missing
	format::Union{String, Missing} = missing

	# number releated fields #
	multipleOf::Union{Int, Missing} = missing
	minimum::Union{Int, Missing} = missing
	exclusiveMinimum::Union{Int, Missing} = missing
	maximum::Union{Int, Missing} = missing
	exclusiveMaximum::Union{Int, Missing} = missing

	# object related fields #
	properties::Union{Dict{String, Any}, Missing} = missing
	parternProperties::Union{Dict{Regex, Any}, Missing} = missing
	additionalProperties::Union{Union{Bool, Any}, Missing} = missing
	required::Union{Array{String}, Missing} = missing
	propertiesNames::Union{Pair{String, String}, Missing} = missing
	minProperties::Union{Int, Missing} = missing
	maxProperties::Union{Int, Missing} = missing
	const_::Union{Any, Missing} = missing

	# array releated fields #
	items::Union{JSONType, Missing} = missing
	prefixItems::Union{Array{Pair{String, String}}, Missing} = missing
	additionalItem::Union{Bool, Missing} = missing
	contains::Union{JSONType, Missing} = missing
	unqiueItems::Union{Bool, Missing} = missing
	minItems::Union{Int, Missing} = missing
	maxItems::Union{Int, Missing} = missing

	# generic fields #
	title::Union{String, Missing} = missing
	description::Union{String, Missing} = missing
	examples::Union{Array{Any}, Missing} = missing
	deprecated::Union{Bool, Missing} = missing
	readOnly::Union{Bool, Missing} = missing
	writeOnly::Union{Bool, Missing} = missing
end


