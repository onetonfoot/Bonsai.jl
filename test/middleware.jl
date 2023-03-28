using Bonsai
using Bonsai: combine_middleware, Middleware, getmiddleware, CreateMiddleware
using Bonsai.URIs
using Dates
using Bonsai.HTTP: Request

t = false
c = false

@testset "setindex! and getindex" begin
    l = [false, false]
    app = App()

    function fn1(stream, next)
        l[1] = true
    end

    function fn2(stream, next)
        l[2] = true
    end

    @test app.middleware isa CreateMiddleware

    app.middleware.get["**"] = [fn1, fn2]
    @test length(app.middleware.get["**"]) == 2

    app.middleware.get["**"] = fn1
    @test length(app.middleware.get["**"]) == 1

end


@testset "combine_middleware" begin

    function timer(stream, next)
        x = now()
        next(stream)
        elapsed = x - now()
        global t
        t = true
    end

    function cors(stream, next)
        next(stream)
        global c
        c = true
    end

    fn = combine_middleware([timer, cors])
    fn(nothing)
    @test c && t
    @test combine_middleware([])(true)
end
