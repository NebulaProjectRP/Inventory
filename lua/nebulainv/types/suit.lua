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

function DEF:Build(data, id)
    local suit = NebulaSuits.Data[data.class]
    if not suit then
        MsgN("NebulaSuits: Invalid suit class '" .. data.class .. "'")
        return
    end
    local ENT = {}
    ENT.Base = "neb_suitcrate"
    ENT.PrintName = suit.Name
    ENT.Spawnable = true
    ENT.Category = "NebulaRP Suits"
    ENT.Suit = data.class
    scripted_ents.Register(ENT, "neb_suitcrate_" .. data.class)

    local item = {}
    item.name = suit.Name
    item.Stats = {
        Health = suit.Health,
        Armor = suit.Armor,
        Speed = suit.Speed,
    }
    return item
end

function DEF:OpenMenu(menu, v)
    menu:AddOption("Equip Suit", function()
        net.Start("Nebula.Inv:UseItem")
        net.WriteString(v.id)
        net.SendToServer()
    end)
end

function DEF:CreateEditor(panel, container, data)
    panel:AddControl("DLabel", {
        Text = "Suit Name",
        Font = NebulaUI:Font(20),
        TextColor = color_white,
        Tall = 20,
    })
    panel.ClassName = panel:AddControl("nebula.textentry", {
        PlaceholderText = "The Ballz Squater",
        Tall = 28,
    })
end

NebulaInv:RegisterType("suit", DEF)