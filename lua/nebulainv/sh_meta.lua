NebulaInv = NebulaInv or {
    Items = {},
    Decryptors = {},
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

