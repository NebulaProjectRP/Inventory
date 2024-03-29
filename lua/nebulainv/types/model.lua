local DEF = {}

DEF.Name = "Model"
DEF.Help = "Disguise of whatever crap you want, you paid for it"
DEF.Icon = 5

function DEF:OnEquip(ply, item, instance)
    if (ply:hasSuit()) then
        return false, "You cannot equip a model while wearing armor"
    end

    local model = instance and instance.id or item.class
    ply.isUsingModel = model
    if (instance and instance.id) then
        ply.isUsingWorkshop = true
        ply:SetWorkshopModel(model)
    else
        ply.isUsingWorkshop = nil
        ply:SetModel(model)
    end
    return true
end

function DEF:OnUnequip(ply, item)
    if (ply:hasSuit()) then
        return false, "You cannot unequip a model while wearing armor"
    end

    ply.isUsingModel = nil
    ply:SetWorkshopModel(nil)
    hook.Run("PlayerSetModel", ply)
    return true
end

function DEF:CreateEditor(panel, container, data)
    panel:AddControl("DLabel", {
        Text = "Workshop ID",
        Font = NebulaUI:Font(20),
        TextColor = color_white,
        Tall = 20,
    })
    panel.ClassName = panel:AddControl("nebula.textentry", {
        PlaceholderText = "2799291250",
        Tall = 28,
    })
end

NebulaInv:RegisterType("model", DEF)