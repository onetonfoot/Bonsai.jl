using Bonsai, Test



@testset "start and stop" begin
	router = Router()
	start(router, port=9999, verbose=true)
	stop(router)
	@test true
end



