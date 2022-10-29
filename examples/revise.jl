module Server

using Bonsai, HTTP, DataFrames, CSV, Tables

function Bonsai.write(stream::HTTP.Stream, df::DataFrame)
	io = IOBuffer()
	CSV.write(io, df)
	data = String(take!(io))
    Bonsai.write(
        stream,
        Body(data),
		Headers(
			content_type="text/csv",
			# content_disposition="inline" # or attachment
		)
    )
end

function index(stream)
	df = DataFrame(A=1:4, B=["M", "F", "F", "M"])
	Bonsai.write(stream, Body("/hello guys"))
end

const app = App()

app.get["/"] = index 

function start()
	Bonsai.start(app, port=9095)
end

end

