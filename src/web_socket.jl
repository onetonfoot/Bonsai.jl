import HTTP.WebSockets: upgrade, send
export ws_upgrade, send
const ws_upgrade = upgrade;

# function ws_upgrade(fn, stream)
#     ws = ws_upgrade(stream)
#     try
#         while !eof(ws)
#             fn(ws)
#         end
#     catch e
#         rethrow(e)
#     finally
#         close(ws)
#     end
# end