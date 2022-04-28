using NodeJS

export create_docs

const npx = joinpath(NodeJS.nodejs_path, "bin/npx")

function create_docs(o::OpenAPI)
	dir = mktempdir()
	JSON3.write(joinpath(dir, "open-api.json"), o)
	run(Cmd(`$npx redoc-cli build open-api.json`, dir=dir))
	read(joinpath(dir, "redoc-static.html"), String)
end