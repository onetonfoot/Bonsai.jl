
@testset "todo!" begin

	@enum Fruit apple orange

	@Struct struct FruitBasket
		total::Int
		prices::Array{Int}
		fruit::Array{Fruit}
	end

	json_schema(Fruit)
	json_schema(Tuple{Int, String})[:prefixItems]
	json_schema(FruitBasket)
	
end

