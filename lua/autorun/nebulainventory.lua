MsgC(Color(125, 200, 255), "[Inventory] ", color_white, "Loading inventory system\n")
AddCSLuaFile("nebulainv/sh_meta.lua")
AddCSLuaFile("nebulainv/sh_storedata.lua")
AddCSLuaFile("nebulainv/cl_store.lua")
AddCSLuaFile("nebulainv/cl_trade.lua")
AddCSLuaFile("nebulainv/cl_quickinv.lua")
include("nebulainv/sh_meta.lua")
include("nebulainv/sh_storedata.lua")

if SERVER then
    include("nebulainv/sv_init.lua")
    include("nebulainv/sv_meta.lua")
    include("nebulainv/sv_unbox.lua")
    include("nebulainv/sv_store.lua")
    include("nebulainv/sv_trade.lua")
else
    include("nebulainv/cl_store.lua")
    include("nebulainv/cl_trade.lua")
    include("nebulainv/cl_quickinv.lua")
end

MsgC(Color(125, 200, 255), "[Inventory] ", color_white, "Finished inventory system\n")
