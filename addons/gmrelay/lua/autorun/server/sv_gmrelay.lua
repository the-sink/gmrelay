require("gwsockets")

if sv_gmrelay or not SERVER then return end
sv_gmrelay = true

local socket = GWSockets.createWebSocket("ws://localhost:27010")

util.AddNetworkString("DiscordMessage")

local function HexColor(hex, alpha)
    hex = hex:gsub("#","")
    return Color(tonumber("0x" .. hex:sub(1,2)), tonumber("0x" .. hex:sub(3,4)), tonumber("0x" .. hex:sub(5,6)), alpha or 255)
end

local function SendMessage(name, text)
    print(name .. ": " .. text)
    socket:write(util.TableToJSON({name = name, text = text}))
end

function socket:onMessage(text)
    local success, err = pcall(function()
        local data = util.JSONToTable(text)
        if data and data.name and data.color and data.text then
            net.Start("DiscordMessage")
                net.WriteString(data.name)
                net.WriteColor(HexColor(data.color))
                net.WriteString(data.text)
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

hook.Add("PlayerSay", "GMRelayChat", function(plr, text)
    SendMessage(plr:GetName(), text)
end)

hook.Add("PlayerInitialSpawn", "GMRelayJoin", function(plr)
    SendMessage("Server", "**" .. plr:GetName() .. "** has joined the server.")
end)

hook.Add("PlayerDisconnected", "GMRelayLeave", function(plr)
    SendMessage("Server", "**" .. plr:GetName() .. "** has left the server.")
end)

hook.Add("PlayerDeath", "GMRelayDied", function(victim, inflictor, attacker)
    if victim == attacker then
        SendMessage("Server", "**" .. victim:GetName() .. "** committed suicide.")
    elseif attacker:IsPlayer() then
        SendMessage("Server", "**" .. victim:GetName() .. "** was killed by **".. attacker:Nick() .."** using **".. inflictor:GetClass() ..".")
    else
        SendMessage("Server", "**" .. victim:GetName() .. "** was killed by **".. attacker:GetClass() .."**.")
    end
end)

socket:open()

timer.Create("GMRelaySocketConnector", 5, 0, function()
    if not socket:isConnected() then
        socket:open()
    end
end)
timer.Start("GMRelaySocketConnector")
