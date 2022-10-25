struct CancelToken
    cancelled::Threads.Atomic{Bool}
    cond::Threads.Condition
end

CancelToken() = CancelToken(
    Threads.Atomic{Bool}(false),  
    Threads.Condition()
)

function Base.close(token::CancelToken)
    lock(token.cond) do
        token.cancelled[] = true
        notify(token.cond)
    end
end

Base.isopen(token::CancelToken) = lock(() -> !token.cancelled[], token.cond)
Base.wait(token::CancelToken)  = lock(() -> wait(token.cond), token.cond)