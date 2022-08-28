local DEF = {}

DEF.Name = "Accessory"
DEF.Help = "Equip purely cosmetic items like backpacks or wings"
DEF.Icon = 4

function DEF:OnEquip(ply, item)
    if SERVER then
        ply:equipAccessory(item.id, 1)
    end
    return true
end

function DEF:OnUnequip(ply, item)
    if SERVER then
        ply:equipAccessory(nil, 1)
    end
    return true
end

function DEF:CreateEditor(panel, container, data)
    /*
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
    */
end

function DEF:Build(data, id)
    local item = data
    item.name = data.Name
    return item
end

NebulaInv:RegisterType("accessory", DEF)