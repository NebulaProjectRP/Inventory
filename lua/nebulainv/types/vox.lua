local DEF = {}
DEF.Name = "VOX"
DEF.Help = "Voice over effects that react to certain events like:\n-Dying\n-Killing\n-Getting hurt\n-Doing a triple kill\n-Spawning\n-Dealing too much damage\n-Equipping a powerful weapon/melee"
DEF.Icon = 4

function DEF:OnEquip(ply, item)
    ply:SetNWString("Soundtrack.ID", item.class)
    return true
end

function DEF:OnUnequip(ply, item)
    ply:SetNWString("Soundtrack.ID", "")
    return true
end

NebulaInv:RegisterType("vox", DEF)