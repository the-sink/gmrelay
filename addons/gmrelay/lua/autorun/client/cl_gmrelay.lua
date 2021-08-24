if cl_gmrelay or not CLIENT then return end
cl_gmrelay = true

local function discordMessageReceived(length, player)
    local name = net.ReadString()
    local color = net.ReadColor()
    local text = net.ReadString()

    chat.AddText("[Discord] ", color, name, ": ", Color(255, 255, 255), text)
end

net.Receive("DiscordMessage", discordMessageReceived)