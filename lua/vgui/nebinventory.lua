local PANEL = {}
local decalCache = {}

local ShowMode = {
    ["Case"] = function(item)
        return item.type == "case"
    end,
    ["Weapon"] = function(item)
        return item.type == "weapon"
    end,
    ["Suit"] = function(item)
        return item.type == "suit"
    end,
    ["Ammo"] = function(item)
        return item.type == "ammo"
    end,
    ["Tool"] = function(item)
        return item.type == "tool"
    end,
    ["Gobblegum"] = function(item)
        return item.type == "food"
    end,
    ["Drug"] = function(item)
        return item.type == "drug"
    end,
    ["Material"] = function(item)
        return item.type == "material"
    end,
    ["Other"] = function(item)
        return item.type == "other"
    end,
    ["All"] = function()
        return true
    end
}

local SortModes = {
    ["None"] = function(a, b)
        return a.id < b.id
    end,
    ["Name"] = function(a, b)
        return a.name < b.name
    end,
    ["Type"] = function(a, b)
        return a.type < b.type
    end,
    ["Rarity"] = function(a, b)
        return a.rarity < b.rarity
    end,
    ["Amount"] = function(a, b, c, d)
        return c == d and a.name < b.name or c > d
    end,
}

function PANEL:Init()
    NebulaInv.Panel = self
    self:Dock(FILL)
    self:InvalidateLayout(true)

    self.Preview = vgui.Create("Panel", self)
    self.Preview:Dock(RIGHT)
    self.Preview:SetWide(352)

    self.Header = vgui.Create("Panel", self)
    self.Header:Dock(TOP)
    self.Header:SetTall(32)
    self.Header:DockMargin(0, 0, 16, 16)

    self.ShowOnly = vgui.Create("nebula.combobox", self.Header)
    self.ShowOnly:Dock(LEFT)
    self.ShowOnly:SetWide(128)
    self.ShowOnly:SetText("Show only:")
    self.ShowOnly.OnSelect = function(s, index, value)
        self:PopulateItems()
    end
    for k, v in pairs(ShowMode) do
        self.ShowOnly:AddChoice(k)
    end

    self.OrderBy = vgui.Create("nebula.combobox", self.Header)
    self.OrderBy:Dock(RIGHT)
    self.OrderBy:SetText("Sort by:")
    self.OrderBy:SetWide(128)
    self.OrderBy.OnSelect = function(s, index, value)
        self:PopulateItems()
    end
    for k, v in pairs(SortModes) do
        self.OrderBy:AddChoice(k)
    end

    self.Search = vgui.Create("nebula.textentry", self.Header)
    self.Search:Dock(FILL)
    self.Search:DockMargin(16, 0, 16, 0)
    self.Search:SetPlaceholderText("Search...")
    self.Search:SetUpdateOnType(true)
    self.Search.OnValueChange = function(s)
        self:PopulateItems()
    end

    self.LastPaint = SysTime()
    self.Model = vgui.Create("DModelPanel", self.Preview)
    self.Model:Dock(FILL)
    self.Model:SetModel(LocalPlayer():GetModel())
    self.Model:GetEntity():ResetSequence("menu_combine")
    self.Model:SetFOV(35)
    self.Model.PreDrawModel = function(s, ent)
        if (self:GetAlpha() != 255) then
            return false
        end
    end
    self.Model.LayoutEntity = function(s, ent)
        ent:FrameAdvance( RealTime() - self.LastPaint )
        self:ManipulateModel(ent)
    end

    local ent = self.Model:GetEntity()
    local att = ent:LookupAttachment("eyes")
    if (att) then
        local attach = ent:GetAttachment(att)
        if (attach) then
            local ang = attach.Ang
            local targetZ = attach.Pos.z / 1.5
            self.Model:SetCamPos(attach.Pos + ang:Forward() * 65 + ang:Right() * -24 - Vector(0, 0, targetZ / 2))
            self.Model:SetLookAt(Vector(attach.Pos.x, attach.Pos.y, targetZ * .8))
        end
    end

    self:CreateSlots()

    self.Content = vgui.Create("nebula.scroll", self)
    self.Content:Dock(FILL)
    self.Content:DockMargin(0, 0, 16, 0)
    self.Content:GetCanvas():DockPadding(8, 8, 8, 8)
    self.Content.PaintOver = function(s, w, h)
        local childCount = #self.Layout:GetChildren()
        if childCount == 0 then
            draw.SimpleText("No items found.", NebulaUI:Font(30), w / 2, h / 2, Color(255, 255, 255, 73), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end

    self.Layout = vgui.Create("DIconLayout", self.Content)
    self.Layout:SetSpaceX(8)
    self.Layout:SetSpaceY(8)
    self.Layout:Dock(FILL)

    self.ItemSpawned = {}
    self:PopulateItems()
end

function PANEL:ManipulateModel(ent)
    local my = -.4 + gui.MouseY() / ScrH()
    local mx = -.5 + gui.MouseX() / ScrW()
    ent:SetEyeTarget(Vector(0, 0, 60 - my * 40))

    local boneID = ent:LookupBone("ValveBiped.Bip01_Head1")
    ent:ManipulateBoneAngles(boneID, Angle(0, -20 -my * 20, -25 + mx * 20))
end

function PANEL:PopulateItems()
    local inv = LocalPlayer():getInventory() or {}
    local filter = ShowMode[self.ShowOnly:GetText() or "All"]
    local orderBy = SortModes[self.OrderBy:GetText() or "None"]
    local search = string.lower(self.Search:GetText())

    for k, v in pairs(self.ItemSpawned) do
        v:Remove()
    end

    self.ItemSpawned = {}

    local invData = {}
    for k, v in pairs(inv) do
        local item = NebulaInv.Items[v.id]
        if not item then
            continue
        end
        if filter and not filter(item) or (search != "" and not string.find(string.lower(item.name), search, 0, true)) then
            continue
        end
        table.insert(invData, {
            am = v.am or 1,
            id = v.id,
            slot = k,
            type = item.type
        })
    end

    table.sort(invData, function(a, b)
        if orderBy then
            return orderBy(NebulaInv.Items[a.id], NebulaInv.Items[b.id], a.amount, b.amount)
        end
    end)

    for k, v in pairs(invData) do
        local btn = vgui.Create("nebula.item", self.Layout)
        local res = btn:SetItem(v.id, true)
        if (not res) then
            btn:Remove()
            continue
        end
        btn:SetSize(96, 96)
        btn:Droppable("Receiver." .. v.type)
        btn.Slot = v.slot
        btn.DoClick = function(s)

            local menu = DermaMenu()

            if (NebulaInv.Types[v.type].OpenMenu) then
                NebulaInv.Types[v.type]:OpenMenu(menu, v)
            end

            menu:AddOption("Delete Item", function()
                net.Start("Nebula.Inv:DeleteItem")
                net.WriteString(v.id)
                net.SendToServer()
            end)
            menu:AddOption("Sell Item", function()
                net.Start("Nebula.Inv:SellItem")
                net.WriteString(v.id)
                net.SendToServer()
            end)
            menu:AddOption("Cancel")
            menu:Open()
        end
        table.insert(self.ItemSpawned, btn)
    end
end

local off = Color(255, 255, 255, 25)
function PANEL:CreateSlots()

    local header = vgui.Create("Panel", self.Model)
    header:Dock(BOTTOM)
    header:SetTall(32)
    header:DockMargin(0, 8, 0, 0)

    local slots = vgui.Create("DIconLayout", self.Model)
    slots:Dock(BOTTOM)
    local size = (352 - 16) / 3
    slots:SetTall(size + 16)
    slots:SetSpaceX(8)
    slots:SetSpaceY(8)
    self.WeaponSlots = {}

    local lbl = Label("Equipped Weapons:", self.Model)
    lbl:Dock(BOTTOM)
    lbl:DockMargin(0, 4, 0, 4)
    lbl:SetFont(NebulaUI:Font(16))

    for k = 1, 3 do
        local btn = vgui.Create("nebula.item", slots)
        btn:SetSize(size, size)
        btn:Allow("weapon", true, self.WeaponSlots)
        btn.subslot = k
        table.insert(self.WeaponSlots, btn)
    end

    self.Holster = vgui.Create("nebula.button", header)
    self.Holster:Dock(FILL)
    self.Holster:SetText("Return Weapons to inventory")
    self.Holster.DoClick = function()
        net.Start("Nebula.Inv:HolsterEquipment")
        net.SendToServer()
        for k = 1, 3 do
            NebulaInv.Loadout = {}
            self.WeaponSlots[k]:SetItem(nil)
        end
    end

    local left = vgui.Create("Panel", self.Model)
    left:Dock(LEFT)
    left:SetWide(72)

    self.Decals = vgui.Create("nebula.button", left)
    self.Decals:Dock(BOTTOM)
    self.Decals:SetTall(72)
    self.Decals:SetText("")
    self.Decals.DoClick = function(s)
        local count = table.Count(NebulaInv.Decals or {})
        local menu = vgui.Create("nebula.scroll")
        local rows = math.Clamp(math.ceil(count / 4), 1, 5)
        menu:SetSize(76 * 4 + (rows > 1 and 24 or 12), rows * 76 + 8)
        menu:GetCanvas():DockPadding(8, 8, 4, 4)
        menu.GetDeleteSelf = function()
            return true
        end
        menu:SetDrawOnTop(true)
        menu:SetMouseInputEnabled(true)
        menu:MakePopup()
        menu:RequestFocus()
        menu.m_bIsMenuComponent = true
        RegisterDermaMenuForClose(menu)
        local icons = vgui.Create("DIconLayout", menu)
        icons:Dock(FILL)
        icons:SetSpaceX(4)
        icons:SetSpaceY(4)

        for k, v in pairs(NebulaInv.Decals or {}) do
            local btn = vgui.Create("nebula.button", icons)
            btn:SetSize(72, 72)
            btn:SetText("")
            btn.DoClick = function()
                LocalPlayer():setDeathDecal(k)
            end
            btn.PaintOver = function(s, w, h)
                if not decalCache[k] then
                    decalCache[k] = Material("nebularp/decals/" .. k)
                else
                    surface.SetMaterial(decalCache[k])
                    surface.SetDrawColor(color_white)
                    surface.DrawTexturedRect(8, 8, w - 16, h - 16)
                end
            end
        end
        local x, y = s:LocalToScreen(s:GetWide(), 0)
        menu:SetPos(x - menu:GetWide(), y - menu:GetTall() - 8)
    end
    self.Decals.PaintOver = function(s, w, h)
        local decal = LocalPlayer():GetNWString("DecalName")
        if (decal == "") then
            return
        end

        if not decalCache[decal] then
            decalCache[decal] = Material("nebularp/decals/" .. decal)
        else
            surface.SetMaterial(decalCache[decal])
            surface.SetDrawColor(color_white)
            surface.DrawTexturedRect(8, 8, w - 16, h - 16)
        end
    end

    self.Tarot = vgui.Create("nebula.button", left)
    self.Tarot:Dock(BOTTOM)
    self.Tarot:DockMargin(0, 0, 0, 8)
    self.Tarot:SetTall(48)
    self.Tarot:SetText("")
    self.Tarot.DoClick = function(s)
        if IsValid(NebulaTarot.Store) then
            NebulaTarot.Store:Remove()
        end

        NebulaTarot.Store = vgui.Create("nebulaui.tarot.store")
    end
    self.Tarot.PaintOver = function(s, w, h)
        local inv = NebulaTarot.Favorites
        if not inv then
            NebulaTarot.Favorites = util.JSONToTable(cookie.GetString("cards_equipped", "[]"))
            return
        end
        NebulaUI.Derma.Inventory[7](w / 2 - 12 - 20, h / 2 - 12, 24, 24, inv[1] and color_white or off)
        NebulaUI.Derma.Inventory[7](w / 2 - 12, h / 2 - 12, 24, 24, inv[2] and color_white or off)
        NebulaUI.Derma.Inventory[7](w / 2 - 12 + 20, h / 2 - 12, 24, 24, inv[3] and color_white or off)
    end

    local side = vgui.Create("Panel", self.Model)
    side:Dock(RIGHT)
    side:SetWide(72)

    self.PlayerSlot = vgui.Create("nebula.item", side)
    self.PlayerSlot:SetSize(72, 72)
    self.PlayerSlot:Dock(BOTTOM)
    self.PlayerSlot:Allow("model", true)

    self.HitSound = vgui.Create("nebula.item", side)
    self.HitSound:SetSize(72, 72)
    self.HitSound:Dock(BOTTOM)
    self.HitSound:DockMargin(0, 8, 0, 8)
    self.HitSound:Allow("hitmark", true)

    self.VOX = vgui.Create("nebula.item", side)
    self.VOX:SetSize(72, 72)
    self.VOX:Dock(BOTTOM)
    self.VOX:Allow("vox", true)

    local loadout = NebulaInv.Loadout
    if not loadout then return end

    if (loadout.model) then
        self.PlayerSlot:SetItem(istable(loadout.model) and loadout.model.id or loadout.model)
    end

    if (loadout.hitmark) then
        self.HitSound:SetItem(istable(loadout.hitmark) and loadout.hitmark.id or loadout.hitmark)
    end

    if (loadout.vox) then
        self.VOX:SetItem(istable(loadout.vox) and loadout.vox.id or loadout.vox)
    end

    for k = 1, 3 do
        local ld = loadout["weapon:" .. k]
        if (!ld) then continue end
        self.WeaponSlots[k]:SetItem(istable(ld) and ld.id or ld)
    end
end

function PANEL:PerformLayout(w, h)

end

vgui.Register("nebula.f4.inventory", PANEL, "Panel")

net.Receive("Nebula.Inv:SyncItem", function()
    local slot = net.ReadUInt(16)
    local am = net.ReadUInt(8)
    local id = net.ReadString()
    local entry = {
        id = id,
        amount = am,
        data = {}
    }

    for k = 1, net.ReadUInt(8) do
        entry[net.ReadString()] = net.ReadString()
    end
    
    if (am > 0) then
        NebulaInv.Inventory[slot] = entry
    else
        table.remove(NebulaInv.Inventory, slot)
    end

    if IsValid(NebulaInv.Panel) then
        NebulaInv.Panel:PopulateItems()
    end
end)


net.Receive("Nebula.Inv:EquipItem", function()
    local kind = net.ReadString()
    local isEquip = net.ReadBool()
    local isCustom = net.ReadBool()

    if not NebulaInv.Loadout then
        NebulaInv.Loadout = {
            [kind] = {}
        }
    end

    if (isCustom) then
        NebulaInv.Loadout[kind] = {
            id = net.ReadString(),
            am = net.ReadUInt(16),
            data = net.ReadTable()
        }
    else
        NebulaInv.Loadout[kind] = net.ReadUInt(32)
    end

    if IsValid(NebulaInv.Panel) then
        NebulaInv.Panel:PopulateItems()
    end
end)