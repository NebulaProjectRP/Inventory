local DEF = {}
DEF.Name = "Weapon"
DEF.Help = "It's a weapon, you kill people with it!"
DEF.Icon = 1

function DEF:OnEquip(ply, item)
    ply:Give(item.class)
    return true
end

function DEF:OnUnequip(ply, item)
    local hasWeapon = ply:HasWeapon(item.class)
    if (not hasWeapon) then return false end

    ply:StripWeapon(item.class)
    ply:addItem(item.ID, 1)
end

NebulaInv:RegisterType("weapon", DEF)