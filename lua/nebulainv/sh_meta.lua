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
    local slotID = net.ReadUInt(16)
    local id = net.ReadString()
    local amount = net.ReadUInt(16)
    MsgN(amount)

    local newItem = {
        id = id,
        am = amount,
        data = {}
    }

    for k = 1, net.ReadUInt(8) do
        newItem.data[net.ReadString()] = net.ReadString()
    end

    if (NebulaInv.Inventory[slotID]) then
        NebulaInv.Inventory[slotID] = newItem
    else
        table.insert(NebulaInv.Inventory, slotID, newItem)
    end

    if IsValid(NebulaInv.Panel) then
        NebulaInv.Panel:PopulateItems()
    end
end)

net.Receive("Nebula.Inv:NetworkItem", function()
    local id = net.ReadUInt(32)
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

function NebulaInv:RegisterItem(class, id, data)
    local name_id = class .. "_" .. id
    local def = self.Types[class]
    if not def then
        error("NebulaInv:RegisterItem: Type " .. class .. " not found!")
    end

    timer.Simple(1, function()
        local temp = def:Build(data, id)
        if not temp then
            MsgN("failed to create item " .. name_id)
            return
        end
        temp.type = class
        temp.imgur = data.imgur
        temp.rarity = data.rarity or 1
        temp.id = name_id
        self.Items[name_id] = temp
    end)
end

MsgC(Color(100, 100, 255), "[Nebula]",color_white, "Loading Type!\n", Color(100, 100, 100))
for k, v in pairs(file.Find("nebulainv/types/*.lua", "LUA")) do
    if SERVER then
        AddCSLuaFile("nebulainv/types/" .. v)
    end
    include("nebulainv/types/" .. v)
    MsgC("\tRegistering " .. string.sub(v, 1, #v - 4) .. "...\n")
end
MsgC(Color(100, 100, 255), "[Nebula]",color_white, "Finished loading Items Types!\n")


for k, v in pairs(file.Find("nebulainv/items/*.lua", "LUA")) do
    if SERVER then
        AddCSLuaFile("nebulainv/items/" .. v)
    end
    timer.Simple(0, function()
        include("nebulainv/items/" .. v)
        MsgC("\tLoading def " .. string.sub(v, 1, #v - 4) .. "...\n")
    end)
end

if SERVER then return end

function NebulaInv:LoadItems()

    MsgC(Color(100, 200, 50), "[Nebula]",color_white, "Downloading player items...\n")
    MsgN("players/" .. LocalPlayer():SteamID64())
    http.Fetch(NebulaAPI.HOST .. "players/" .. LocalPlayer():SteamID64(), function(dt)
        MsgC(Color(100, 200, 50), "[Nebula]",color_white, "Finished downloading items!\n")
        local json = util.JSONToTable(dt)
        local inv = json.inventory or {}
        NebulaInv.Inventory = util.JSONToTable(inv.items)
        NebulaInv.Loadout = util.JSONToTable(inv.loadout)
        NebulaInv.Decals = util.JSONToTable(inv.decals)
        LocalPlayer():loadMining(json.mining or {})
    end, function(err)
        MsgN(err)
    end)
    /*
    --Items definitions are not longer needed
    MsgC(Color(100, 200, 50), "[Nebula]",color_white, "Downloading items database...\n")
    http.Fetch(NebulaAPI.HOST .. "items", function(data)
        NebulaInv.Items = util.JSONToTable(data)
        for k, v in pairs(NebulaInv.Items) do
            if (isstring(v.extraData)) then
                v.extraData = util.JSONToTable(v.extraData)
            end
        end
        
    end)
    */
end

concommand.Add("neb_requestinv", function()
    if ((last_request or 0) < CurTime()) then
        last_request = CurTime() + 3
        NebulaInv:LoadItems()
    else
        notification.AddLegacy("Please wait before requesting again! " .. math.Round(last_request - CurTime()) .. " seconds", NOTIFY_ERROR, 5)
    end
end)

hook.Add("InitPostEntity", "NebulaInv.LoadItems", function()
    NebulaInv:LoadItems()
end)
