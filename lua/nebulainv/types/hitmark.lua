local DEF = {}
DEF.Name = "Hitmark Sound"
DEF.Help = "Makes a cool sound when you hit and kill someone"
DEF.Icon = 6

function DEF:OnEquip(ply, item)
    ply:SetNWString("HitSound", item.class)
    return true
end

function DEF:OnUnequip(ply, item)
    ply:SetNWString("HitSound", "")
    return true
end

NebulaInv:RegisterType("hitmark", DEF)