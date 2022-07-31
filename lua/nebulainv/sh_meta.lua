NebulaInv = NebulaInv or {
    Items = {},
    Decryptors = {},
    Types = {},
    Market = {}
}

NebulaInv.Rarities = {
    [1] = Color(148, 182, 190),
    [2] = Color(51, 102, 214),
    [3] = Color(164, 55, 207),
    [4] = Color(95, 212, 59),
    [5] = Color(218, 49, 105),
    [6] = Color(251, 255, 43),
}

local meta = FindMetaTable("Player")

function meta:getInventory()
    return (CLIENT and NebulaInv.Inventory or self._inventory) or {}
end

function meta:hasItem(id)
    return self:getInventory()[id] != nil
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

    if IsValid(NebulaInv.Panel) then
        NebulaInv.Panel:PopulateItems()
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
        perm = net.ReadBool(),
        extraData = net.ReadTable()
    }
end)

function NebulaInv:GetReference(id)
    if (string.StartWith(id, "unique_")) then
        id = tonumber(string.Explode("_", id)[2])
    end
    return self.Items[id]
end

function NebulaInv:RegisterType(type, data)
    if not self.Types then
        self.Types = {}
    end

    if (not self.Types[type]) then
        self.Types[type] = {}
    end
    self.Types[type] = data
end

local a, b = file.Find("nebulainv/types/*", "LUA")
MsgC(Color(100, 100, 255), "[Nebula]",color_white, "Loading Type!\n", Color(100, 100, 100))
for k, v in pairs(file.Find("nebulainv/types/*.lua", "LUA")) do
    if SERVER then
        AddCSLuaFile("nebulainv/types/" .. v)
    end
    include("nebulainv/types/" .. v)
    MsgC("\tRegistering " .. string.sub(v, 1, #v - 4) .. "...\n")
end
MsgC(Color(100, 100, 255), "[Nebula]",color_white, "Finished loading Items Types!\n")

if SERVER then return end

function NebulaInv:LoadItems()
    MsgC(Color(100, 200, 50), "[Nebula]",color_white, "Downloading items database...\n")
    http.Fetch(NebulaAPI.HOST .. "items", function(data)
        NebulaInv.Items = util.JSONToTable(data)
        for k, v in pairs(NebulaInv.Items) do
            if (isstring(v.extraData)) then
                v.extraData = util.JSONToTable(v.extraData)
            end
        end
        MsgC(Color(100, 200, 50), "[Nebula]",color_white, "Downloading player items...\n")
        http.Fetch(NebulaAPI.HOST .. "players/" .. LocalPlayer():SteamID64(), function(data)
            MsgC(Color(100, 200, 50), "[Nebula]",color_white, "Finished downloading items!\n")
            local json = util.JSONToTable(data)
            local inv = json.inventory or {}
            NebulaInv.Inventory = util.JSONToTable(inv.items)
            NebulaInv.Loadout = util.JSONToTable(inv.loadout)
            NebulaInv.Decals = util.JSONToTable(inv.decals)
            LocalPlayer():loadMining(json.mining or {})
        end)
    end)
end

hook.Add("InitPostEntity", "NebulaInv.LoadItems", function()
    NebulaInv:LoadItems()
end)
