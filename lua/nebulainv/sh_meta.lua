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

AddCSLuaFile("types/suits.lua")
AddCSLuaFile("types/weapons.lua")
include("types/suits.lua")
include("types/weapons.lua")

local meta = FindMetaTable("Player")

function meta:getInventory()

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
        local data = net.ReadTable()
        if not NebulaInv.Inventory[id] then
            NebulaInv.Inventory[id] = {}
        end
        NebulaInv.Inventory[id].amount = net.ReadUInt(16)
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