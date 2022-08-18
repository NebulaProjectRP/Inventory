local DEF = {}

DEF.Name = "Suit/Armor"
DEF.Help = "Equip a powerful armature that will help you to fight"
DEF.Icon = 2

function DEF:OnUse(ply, item)
    if (ply:hasSuit()) then
        ply:notify("You already have armor!")
        return false
    end

    PrintTable(item)
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
    item.class = data.class
    item.Stats = {
        Health = suit.Health,
        Armor = suit.Armor,
        Speed = suit.Speed,
    }
    return item
end

function DEF:OpenMenu(menu, item, slot)
    menu:AddOption("Equip Suit", function()
        net.Start("Nebula.Inv:UseItem")
        net.WriteUInt(slot, 16)
        net.SendToServer()
    end)

    menu:AddOption("Drop Suit", function()
        net.Start("Nebula.Inv:DropItem")
        net.WriteUInt(slot, 16)
        net.SendToServer()
    end)
end

function DEF:DropItem(ply, item, slot, amount)
    local suit = ents.Create("neb_suitcrate_" .. item.class)
    local tr = util.TraceLine({
        start = ply:GetShootPos(),
        endpos = ply:GetShootPos() + ply:GetAimVector() * 96,
        filter = ply
    })
    suit:SetPos(tr.HitPos)
    suit:Spawn()
    suit.Free = CurTime() + 5
    suit.Owner = ply

    return true
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