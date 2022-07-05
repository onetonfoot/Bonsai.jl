# does this really need it's own file...
import HTTP.WebSockets: upgrade, send
export ws_upgrade, send
const ws_upgrade = upgrade;
