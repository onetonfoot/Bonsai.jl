using Mkcert, MbedTLS

function ssl(domains::AbstractString)
    p1 = run(`mkcert -install`)
    dir = mktempdir()
    run(setenv(`mkcert -cert-file cert.pem -key-file key.pem $domains`, dir=dir))
    return MbedTLS.SSLConfig(
        joinpath(dir, "cert.pem"),
        joinpath(dir, "key.pem"),
    )
end

function ssl(domains::Array)
    s = join(domains, " ")
    ssl(s)
end