module Server

__revise_mode__ = :eval

using Revise, Bonsai

const app = App()

app.get["/"] = function(stream)
	Bonsai.write(stream, Body("oka bye 5"))
end

function start()
	Bonsai.start(app, port=9095)
end

end
