local DEF = {}
DEF.Name = "Weapon"
DEF.Help = "It's a weapon, you kill people with it!"
DEF.Icon = 1

function DEF:OnEquip(ply, item)
    ply:Give(item.class)
    return true
end

function DEF:OpenMenu(menu)
    menu:AddOption("Equip Weapon", function()                
        net.Start("Nebula.Inv:UseItem")
        net.WriteString(v.id)
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
