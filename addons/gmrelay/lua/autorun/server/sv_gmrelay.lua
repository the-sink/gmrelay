require("gwsockets")

if sv_gmrelay or not SERVER then return end
sv_gmrelay = true

local socket = GWSockets.createWebSocket("ws://localhost:27010")

util.AddNetworkString("DiscordMessage")

function HexColor(hex, alpha)
    hex = hex:gsub("#","")
    return Color(tonumber("0x" .. hex:sub(1,2)), tonumber("0x" .. hex:sub(3,4)), tonumber("0x" .. hex:sub(5,6)), alpha or 255)
end

function socket:onMessage(text)
    local success, err = pcall(function()
        local name, color, text = string.match(text, "name:(.+)\ncolor:(.+)\ntext:(.+)")
        if name and color and text then
            net.Start("DiscordMessage")
                net.WriteString(name)
                net.WriteColor(HexColor(color))
                net.WriteString(text)
            net.Broadcast()
        end
    end)

    if not success then
        print("Could not send Discord message signal, error: " .. err)
    end
end

function socket:onError(err)
    print("error: " .. err)
end

function socket:onConnected()
    print("connected to websocket")
end

function socket:onDisconnected()
    print("disconnected from websocket")
end

timer.Create("GMRelaySocketConnector", 5, 0, function()
    if not socket:isConnected() then
        socket:open()
    end
end)

hook.Add("PlayerSay", "GMRelayChat", function(plr, text)
    socket:write("-name:" .. plr:GetName() .. "-text:" .. text)
end)

hook.Add("PlayerInitialSpawn", "GMRelayJoin", function(plr)
    socket:write("-name:Server-text:**" .. plr:GetName() .. "** has joined the server.")
end)

hook.Add("PlayerDisconnected", "GMRelayLeave", function(plr)
    socket:write("-name:Server-text:**" .. plr:GetName() .. "** has left the server.")
end)

hook.Add("PlayerDeath", "GMRelayDied", function(victim, _inflictor, attacker)
    if victim == attacker then
        socket:write("-name:Server-text:**" .. victim:GetName() .. "** committed suicide.")
    else
        socket:write("-name:Server-text:**" .. victim:GetName() .. "** was killed by **".. attacker:GetName() .."**!")
    end
end)