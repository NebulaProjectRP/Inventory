local PANEL = {}

local ShowMode = {
    ["Case"] = function(item)
        return item.type == "case"
    end,
    ["Weapon"] = function(item)
        return item.type == "weapon"
    end,
    ["Suit"] = function(item)
        return item.type == "weapon"
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
        return c == d and a.name < b.name or c < d
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
        self:PopulateInventory()
    end
    for k, v in pairs(ShowMode) do
        self.ShowOnly:AddChoice(k)
    end

    self.OrderBy = vgui.Create("nebula.combobox", self.Header)
    self.OrderBy:Dock(RIGHT)
    self.OrderBy:SetText("Sort by:")
    self.OrderBy:SetWide(128)
    self.OrderBy.OnSelect = function(s, index, value)
        self:PopulateInventory()
    end
    for k, v in pairs(SortModes) do
        self.OrderBy:AddChoice(k)
    end

    self.Search = vgui.Create("nebula.textentry", self.Header)
    self.Search:Dock(FILL)
    self.Search:DockMargin(16, 0, 16, 0)
    self.Search:SetPlaceholderText("Search...")
    self.Search.OnEnter = function(s)
        self:PopulateInventory()
    end

    self.LastPaint = SysTime()
    self.Model = vgui.Create("DModelPanel", self.Preview)
    self.Model:Dock(FILL)
    self.Model:SetModel(LocalPlayer():GetModel())
    self.Model:GetEntity():ResetSequence("menu_combine")
    self.Model:SetFOV(35)
    self.Model.LayoutEntity = function(s, ent)
        ent:FrameAdvance( ( RealTime() - self.LastPaint ) )
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
    self.Content.PaintOver = function(s, w, h)
        local childCount = #self.Layout:GetChildren()
        if childCount == 0 then
            draw.SimpleText("No items found.", NebulaUI:Font(30), w / 2, h / 2, Color(255, 255, 255, 73), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)    
        end
    end

    self.Layout = vgui.Create("DIconLayout", self.Content)
    self.Layout:SetSpaceX(4)
    self.Layout:SetSpaceY(4)
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
        if filter and not filter(v) or (search != "" and not string.find(string.lower(NebulaInv.Items[v.name]), search)) then
            continue
        end
        table.insert(invData, {
            amount = istable(v) and v.amount or v,
            id = k
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
        btn:SetSize(64, 64)
        btn.DoClick = function(s)
            local menu = DermaMenu()
            menu:AddOption("Use Item", function()
                net.Start("Nebula.Inv:UseItem")
                net.WriteString(v.id)
                net.SendToServer()
            end)
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

function PANEL:CreateSlots()
    local slots = vgui.Create("DIconLayout", self.Model)
    slots:Dock(BOTTOM)
    local size = (352 - 16) / 3
    slots:SetTall(size + 16)
    slots:SetSpaceX(8)
    slots:SetSpaceY(8)
    for k = 1, 3 do
        local btn = vgui.Create("nebula.item", slots)
        btn:SetSize(size, size)
        btn:Allow("weapon", true)
    end

    local header = vgui.Create("Panel", self.Model)
    header:Dock(BOTTOM)
    header:SetTall(32)
    header:DockMargin(0, 0, 0, 8)

    local lbl = Label("Weapon loadouts", self.Model)
    lbl:Dock(BOTTOM)
    lbl:DockMargin(0, 0, 0, 4)
    lbl:SetFont(NebulaUI:Font(16))

    self.Equip = vgui.Create("nebula.button", header)
    self.Equip:Dock(RIGHT)
    self.Equip:SetWide(72)
    self.Equip:SetText("Equip")
    self.Equip.DoClick = function()
    end

    self.Save = vgui.Create("nebula.button", header)
    self.Save:Dock(RIGHT)
    self.Save:SetWide(72)
    self.Save:SetText("Save")
    self.Save:DockMargin(4, 0, 4, 0)
    self.Save.DoClick = function()
    end

    self.Combo = vgui.Create("nebula.combobox", header)
    self.Combo:Dock(FILL)

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
end

function PANEL:PerformLayout(w, h)

end

vgui.Register("nebula.f4.inventory", PANEL, "Panel")

net.Receive("Nebula.Inv:SyncItem", function()
    local isUnique = net.ReadBool()
    if (isUnique) then
        local item = net.ReadString()
        local amount = net.ReadUInt(16)
        local data = net.ReadTable()
        NebulaInv.Inventory[id] = amount > 0 and {
            amount = amount,
            data = data
        } or nil
    else
        local id = net.ReadUInt(32)
        local amount = net.ReadUInt(16)
        NebulaInv.Inventory[id] = amount > 0 and amount or nil
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
            amount = net.ReadUInt(16),
            data = net.ReadTable()
        }
    else
        NebulaInv.Loadout[kind] = net.ReadUInt(32)
    end

    if IsValid(NebulaInv.Panel) then
        NebulaInv.Panel:PopulateItems()
    end
end)