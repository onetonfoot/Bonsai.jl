using Test
using Bonsai

app = App()

app.get("/ws") do stream
	ws_upgrade(stream) do ws 
		for msg in ws
            s = String(msg)
			@info s
            send(ws, s)
		end
	end
end

start(app, port=9099)