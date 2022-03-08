local DEF = {}
DEF.Name = "Suit/Armor"
DEF.Help = "Equip a powerful armature that will help you to fight"
DEF.Icon = 2

function DEF:OnUse(ply, item)
    if (ply:hasSuit()) then
        ply:notify("You already have armor!")
        return false
    end

    ply:applySuit(item.class)
    return true
end

NebulaInv:RegisterType("suit", DEF)