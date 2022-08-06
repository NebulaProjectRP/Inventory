MsgC(Color(125, 200, 255), "[INV] ", color_white, "Loading inventory system\n")
AddCSLuaFile("nebulainv/sh_meta.lua")
AddCSLuaFile("nebulainv/sh_storedata.lua")
AddCSLuaFile("nebulainv/cl_store.lua")
include("nebulainv/sh_meta.lua")
include("nebulainv/sh_storedata.lua")

if SERVER then
    include("nebulainv/sv_init.lua")
    include("nebulainv/sv_meta.lua")
    include("nebulainv/sv_unbox.lua")
    include("nebulainv/sv_store.lua")
else
    include("nebulainv/cl_store.lua")
end

MsgC(Color(125, 200, 255), "[INV] ", color_white, "Finished inventory system\n")
