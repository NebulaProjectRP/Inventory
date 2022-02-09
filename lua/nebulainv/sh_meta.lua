NebulaInv = NebulaInv or {
    Items = {},
    Decryptors = {},
}

NebulaInv.Rarities = {
    [1] = Color(148, 182, 190),
    [2] = Color(51, 102, 214),
    [3] = Color(164, 55, 207),
    [4] = Color(95, 212, 59),
    [5] = Color(218, 49, 105),
    [6] = Color(251, 255, 43),
}

AddCSLuaFile("types/suit.lua")
AddCSLuaFile("types/weapon.lua")
include("types/suit.lua")
include("types/weapon.lua")

local meta = FindMetaTable("Player")

function meta:getInventory()
    return (CLIENT and NebulaInv.Inventory or self._inventory) or {}
end

net.Receive("Nebula.Inv:AddItem", function(l, ply)
    if not NebulaInv.Inventory then
        NebulaInv.Inventory = {}
    end
    local isCustom = net.ReadBool()
    if (not isCustom) then
        NebulaInv.Inventory[net.ReadUInt(32)] = net.ReadUInt(16)
    else
        local id = net.ReadString()
        local amount = net.ReadUInt(16)
        local data = net.ReadTable()
        if not NebulaInv.Inventory[id] then
            NebulaInv.Inventory[id] = {}
        end
        NebulaInv.Inventory[id].amount = amount
        if (table.Count(data) > 0) then
            NebulaInv.Inventory[id].data = data
        end
    end
end)

net.Receive("Nebula.Inv:NetworkItem", function()
    id = net.ReadUInt(32)
    NebulaInv.Items[id] = {
        name = net.ReadString(),
        id = id,
        icon = net.ReadString(),
        rarity = net.ReadUInt(3),
        class = net.ReadString(),
        type = net.ReadString(),
        perm = net.ReadBool()
    }
end)

if SERVER then return end

function NebulaInv:LoadItems()
    MsgC(Color(100, 200, 50), "[Nebula]",color_white, "Downloading items database...\n")
    http.Fetch(NebulaAPI .. "items", function(data)
        NebulaInv.Items = util.JSONToTable(data)
        MsgC(Color(100, 200, 50), "[Nebula]",color_white, "Downloading player items...\n")
        http.Fetch(NebulaAPI .. "players/" .. LocalPlayer():SteamID64(), function(data)
            MsgC(Color(100, 200, 50), "[Nebula]",color_white, "Finished downloading items!\n")
            local inv = util.JSONToTable(data)
            NebulaInv.Inventory = util.JSONToTable(inv.items)
            NebulaInv.Loadout = util.JSONToTable(inv.loadout)
        end)
    end)
end

hook.Add("InitPostEntity", "NebulaInv.LoadItems", function()
    NebulaInv:LoadItems()
end)