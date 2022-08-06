local DEF = {}
DEF.Name = "Weapon"
DEF.Help = "It's a weapon, you kill people with it!"
DEF.Icon = 1

function DEF:OnEquip(ply, item)
    ply:Give(item.class)
    return true
end

function DEF:OnUse(ply, item)
    ply:Give(item.class)
    return true
end

function DEF:OpenMenu(menu, item, slot)
    local ref = NebulaInv.Items[item.id]
    if (ref.rarity >= 4) then
        Derma_Message("You cannot use weapons with this rarity, you have to equip it in your weapon slots!", "NebulaRP", "Ok")
        return
    end
    menu:AddOption("Equip Weapon", function()
        local prompted = cookie.GetNumber("weapon_equip_prompt", 0)
        if (not prompted) then
            Derma_Query("You will use a weapon, this means you will equip it and you will not be able to return it into your inventory\nIf you want to recover your weapon, equip it in the weapon slot", "NebulaRP", "Continue", function()
                cookie.Set("weapon_equip_prompt", 1)
                net.Start("Nebula.Inv:UseItem")
                net.WriteUInt(slot, 16)
                net.SendToServer()
            end, "Cancel")
            return
        end
        net.Start("Nebula.Inv:UseItem")
        net.WriteUInt(slot, 16)
        net.SendToServer()
    end)
end

function DEF:CreateEditor(panel, container, data)
    panel:AddControl("DLabel", {
        Text = "Entity/Weapon Class",
        Font = NebulaUI:Font(20),
        TextColor = color_white,
        Tall = 20,
    })
    panel.ClassName = panel:AddControl("nebula.textentry", {
        PlaceholderText = "weapon_physgun",
        Text = data.class or "",
        Tall = 28,
    })
end

function DEF:OnUnequip(ply, item)
    local hasWeapon = ply:HasWeapon(item.class)
    if (not hasWeapon) then return false end

    ply:StripWeapon(item.class)
    ply:addItem(item.ID, 1)
end

function DEF:Build(data, id)
    local wep = weapons.GetStored(data.classname)
    if not wep then
        MsgN("Nebula: Weapon " .. data.classname .. " not found!")
        return
    end
    local item = table.Copy(data)
    item.name = wep.PrintName
    item.class = data.classname
    return item
end

NebulaInv:RegisterType("weapon", DEF)
