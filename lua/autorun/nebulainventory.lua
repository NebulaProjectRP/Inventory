MsgC(Color(125, 200, 255), "[INV] ", color_white, "Loading inventory system\n")
AddCSLuaFile("nebulainv/sh_meta.lua")
include("nebulainv/sh_meta.lua")

if SERVER then
    include("nebulainv/sv_init.lua")
    include("nebulainv/sv_meta.lua")
end

MsgC(Color(125, 200, 255), "[INV] ", color_white, "Finished inventory system\n")
