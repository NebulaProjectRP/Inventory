local PANEL = {}
local slotSize = 64
PANEL.Slots = {}

function PANEL:Init()
    self:SetSize((slotSize + 4) * 12 + 8, (slotSize + 4) * 2 + 6)
    self:SetPos(ScrW() / 2 - self:GetWide() / 2, ScrH() - self:GetTall() - 48)
    self:SetMouseInputEnabled(true)
    self:PrepareSlots()
end

local possible = {
    weapon = true,
    suit = true
}
function PANEL:PrepareSlots()
    local ply = LocalPlayer()
    local items = {}
    local total = 0
    for k, v in pairs(ply:getInventory()) do
        local item = NebulaInv.Items[v.id]
        if (v.fav and possible[item.type]) then
            table.insert(items, {
                amount = v.amount,
                id = v.id,
                slot = k
            })
            total = total + 1
            if (total > 23) then break end
        end
    end
    table.sort(items, function(a, b)
        local item_a = NebulaInv.Items[a.id]
        local item_b = NebulaInv.Items[b.id]
        if (item_a.rarity == item_b.rarity) then
            return item_a.name > item_b.name
        else
            return item_a.rarity > item_b.rarity
        end
    end)

    for k, v in pairs(self.Slots) do
        v:Remove()
    end

    self.Slots = {}

    for k = 0, 23 do
        local item_slot = items[k + 1]
        local slot = vgui.Create("DButton", self)
        slot:SetSize(slotSize, slotSize)
        slot:SetText("")
        slot:SetPos(6 + (k % 12) * (slotSize + 4), 6 + math.ceil((k + 1) / 12) * (slotSize + 4) - slotSize - 4)

        slot.Paint = function(s, w, h)
            if not NebulaInv.Items[s.ID] then
                surface.SetDrawColor(255, 255, 255, 5)
                surface.DrawOutlinedRect(0, 0, w, h)

                return
            end

            if s.ID and NebulaInv.Items[s.ID] then
                local borderColor = NebulaInv.Items[s.ID].rarity or 1
                local borderColorRGB = NebulaInv.Rarities[borderColor]
                draw.RoundedBox(16, 0, 0, w, h, borderColorRGB)
            else
                draw.RoundedBox(16, 0, 0, w, h, Color(66, 66, 66))
            end

            draw.RoundedBox(16, 1, 1, w - 2, h - 2, Color(36, 36, 36))
            draw.SimpleText(k + 1, NebulaUI:Font(24), w - 8, h - 8, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
            if s.Slot and not LocalPlayer():getInventory()[s.Slot] then
                s:Set(nil)
            end
        end

        slot.PaintOver = function(s, w, h)
            if s.ID and LocalPlayer():getInventory()[s.Slot] then
                draw.SimpleText("x" .. LocalPlayer():getInventory()[s.Slot].am, NebulaUI:Font(24), w - 5, h - 3, color_black, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
                draw.SimpleText("x" .. LocalPlayer():getInventory()[s.Slot].am, NebulaUI:Font(24), w - 4, h - 2, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
            end
        end

        slot.DoClick = function(s)
            if s.Item.type == "suit" and LocalPlayer():hasSuit() then return end
            local menu = DermaMenu()

            if NebulaInv.Types[s.Item.type].OpenMenu then
                NebulaInv.Types[s.Item.type]:OpenMenu(menu, s.Item, s.Slot)
            end
            menu:AddOption("Cancel")
            menu:Open()
        end

        slot.Set = function(s, slot, item, ignore)
            if IsValid(s.Content) then
                s.Content:Remove()
            end

            s:SetMouseInputEnabled(item ~= nil)

            if not slot then
                s.ID = nil
                s.Item = nil
                s.Slot = nil
                return
            end
            s.ID = slot.id
            s.Item = item
            s.Slot = slot.slot

            if slot then
                local iconPreview = vgui.Create("nebula.item", s)
                iconPreview:SetItem(slot.id)
                iconPreview:Dock(FILL)
                iconPreview.zoom = item.zoom
                iconPreview:SetMouseInputEnabled(false)
                s.Content = iconPreview
                s:SetTooltip(item.name)
            else
                s:SetTooltip(nil)
            end
        end

        slot:SetMouseInputEnabled(false)
        k = k + 1

        if item_slot then
            slot:Set(item_slot, NebulaInv.Items[item_slot.id])
        end

        k = k - 1
        table.insert(self.Slots, slot)
    end
end

function PANEL:Paint(w, h)
    draw.RoundedBox(8, 0, 0, w, h, Color(255, 255, 255, 5))
    draw.RoundedBox(8, 1, 1, w - 2, h - 2, Color(16, 0, 26, 200))
end

vgui.Register("Inventory.QuickMenu", PANEL, "DPanel")

if IsValid(QUICK_INV) then
    QUICK_INV:Remove(true)
end

hook.Add("OnContextMenuOpen", "OpenInvMenu", function()
    if LocalPlayer():InArena() then return end

    if IsValid(QUICK_INV) then
        QUICK_INV:SetVisible(true)
        QUICK_INV:PrepareSlots()
    else
        QUICK_INV = vgui.Create("Inventory.QuickMenu", g_ContextMenu)
    end
    QUICK_INV:SetMouseInputEnabled(true)
end)

hook.Add("OnContextMenuClose", "OpenInvMenu", function()
    if IsValid(QUICK_INV) then
        QUICK_INV:SetVisible(false)
    end
end)