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

function DEF:CreateEditor(panel, container, data)
    panel:AddControl("DLabel", {
        Text = "Hitsound ID",
        Font = NebulaUI:Font(20),
        TextColor = color_white,
        Tall = 20,
    })
    panel.ClassName = panel:AddControl("nebula.textentry", {
        PlaceholderText = "something_something",
        Tall = 28,
    })
end

function DEF:Build(data, id)
    local item = {}
    item.sound = id
    return item
end

NebulaInv:RegisterType("hitmark", DEF)