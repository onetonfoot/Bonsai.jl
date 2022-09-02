using NodeJS

export create_docs

const npx = joinpath(NodeJS.nodejs_path, "bin/npx")

function create_docs(o)
    dir = mktempdir()
    JSON3.write(joinpath(dir, "open-api.json"), o)
    run(Cmd(`$npx redoc-cli build open-api.json`, dir=dir))
    Base.read(joinpath(dir, "redoc-static.html"), String)
end

function create_docs_html(app)
    s = Base.read(joinpath(@__DIR__, "html/swagger-ui.html"), String)
    return replace(s, "//=docs_url=//" => """ '$(app.docs).json' """)
end