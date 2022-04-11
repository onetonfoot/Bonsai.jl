# object like json schema types
# https://json-schema.org/understanding-json-schema/index.html
using StructTypes
using StructTypes: OrderedStruct, UnorderedStruct, Mutable, DictType
using StructTypes:  ArrayType
using StructTypes: StringType, NumberType, BoolType, NullType

const array_types = [ArrayType()]
const object_types = [OrderedStruct(), UnorderedStruct(), Mutable(), DictType()]
const primative_types = [StringType(), NumberType(), BoolType(), NullType()]

json_type(::Type{Array}) = :array
json_type(::Type{Bool}) = :boolean
json_type(::Type{<:Integer}) =  :integer
json_type(::Type{<:Real}) =  :number
json_type(::Type{Nothing}) =  :null
json_type(::Type{Missing}) =  :null
json_type(::Type{AbstractDict}) =  :object
json_type(::Type{String}) =  :string

array_type(::Type{Array{T}}) where T = T

function json_schema(::Type{T}, d = Dict{Symbol, Any}()) where T

	sT = StructTypes.StructType(T)

	# http://json-schema.org/understanding-json-schema/reference/object.html
	if sT in object_types
		d[:type] = :object
		if !(sT == DictType())
			properties = Dict{Symbol, Any}()
			StructTypes.foreachfield(T) do  i, field, field_type
				field_schema = json_schema(field_type)
				push!(properties, field => field_schema)
			end
			d[:properties] = properties
		end
	# http://json-schema.org/understanding-json-schema/reference/array.html
	elseif sT in array_types
		d[:type] = :array
		if T <: Tuple
			d[:prefixItems] = map(x -> json_schema(x), T.types)
		end
		if T <: Array 
			aT = array_type(T)
			if aT isa Union
				@warn "union types in arrays are not supported"
				return d
			end
			d[:items] = json_schema(aT)
		end
	elseif sT in primative_types
		if T <: Enum
			d[:enum] = Base.Enums.namemap(T) |> values |> collect
		else 
			d[:type] = json_type(T)
		end
	end
	return d
end