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

