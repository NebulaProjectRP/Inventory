MsgC(Color(125, 200, 255), "[INV] ", color_white, "Loading inventory system\n")
AddCSLuaFile("nebulainv/sh_meta.lua")
AddCSLuaFile("nebulainv/cl_store.lua")
include("nebulainv/sh_meta.lua")

if SERVER then
    include("nebulainv/sv_init.lua")
    include("nebulainv/sv_meta.lua")
    include("nebulainv/sv_unbox.lua")
    include("nebulainv/sv_store.lua")
else
    include("nebulainv/cl_store.lua")
end

MsgC(Color(125, 200, 255), "[INV] ", color_white, "Finished inventory system\n")
