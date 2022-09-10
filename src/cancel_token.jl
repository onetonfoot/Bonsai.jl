using Revise

struct CancelToken
    cancelled::Threads.Atomic{Bool}
    restarts::Threads.Atomic{Int}
    cond::Threads.Condition
end

CancelToken() = CancelToken(
    Threads.Atomic{Bool}(false),  
    Threads.Atomic{Int}(0),  
    Threads.Condition()
)

function Base.close(token::CancelToken)
    lock(token.cond) do
        token.cancelled[] = true
        notify(token.cond)
        notify(Revise.revision_event);
    end
end

Base.isopen(token::CancelToken) = lock(() -> !token.cancelled[], token.cond)

function Base.wait(token::CancelToken)  
    try
        lock(() -> wait(token.cond), token.cond)
    catch e 
        if e isa InterruptException
            close(token)
        else 
            rethrow()
        end
    end
end