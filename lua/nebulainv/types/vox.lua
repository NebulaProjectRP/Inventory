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

function DEF:CreateEditor(panel, container, data)
    panel:AddControl("DLabel", {
        Text = "Soundtrack Sample",
        Font = NebulaUI:Font(20),
        TextColor = color_white,
        Tall = 20,
    })
    panel.ClassName = panel:AddControl("nebula.textentry", {
        PlaceholderText = "nebula_feedback/lua/autorun/sh_vox.lua | 'Quake'",
        Tall = 28,
    })
end

function DEF:Build(data, id)
    local item = data
    item.class = id
    item.name = data.Name
    return item
end

NebulaInv:RegisterType("vox", DEF)