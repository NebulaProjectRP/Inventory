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

function DEF:OpenMenu(menu)
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