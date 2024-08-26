--!strict
local server = require(script.server)
export type server<data> = server.server<data>
export type server_settings<data> = server.settings<data>

local client = require(script.client)
export type client<data> = client.client<data>
export type client_settings<data> = client.settings<data>

return {
    server = server,
    client = client,
}
