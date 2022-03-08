local DEF = {}
DEF.Name = "Case"
DEF.Help = "Used to unbox items to use in your inventory"
DEF.Icon = 3
function DEF:OnUse(ply, item)
    local b = NebulaInv:Unbox(ply, item.class, ply.luckValue)
    return b
end

NebulaInv:RegisterType("case", DEF)