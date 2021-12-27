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
    self:Dock(FILL)
    self:InvalidateLayout(true)

    self.Header = vgui.Create("DPanel", self)
    self.Header:Dock(TOP)
    self.Header:SetTall(48)

    self.ShowOnly = vgui.Create("nebula.combobox", self.Header)
    self.ShowOnly:Dock(LEFT)
    self.ShowOnly:SetWide(128)
    self.ShowOnly:SetText("All")
    self.ShowOnly.OnSelect = function(s, index, value)
        self:PopulateInventory()
    end
    for k, v in pairs(ShowMode) do
        self.ShowOnly:AddChoice(k)
    end

    self.OrderBy = vgui.Create("nebula.combobox", self.Header)
    self.OrderBy:Dock(RIGHT)
    self.OrderBy:SetWide(128)
    self.OrderBy.OnSelect = function(s, index, value)
        self:PopulateInventory()
    end
    for k, v in pairs(SortMode) do
        self.OrderBy:AddChoice(k)
    end

    self.Search = vgui.Create("nebula.textentry", self.Header)
    self.Search:Dock(FILL)
    self.Search:DockMargin(8, 0, 8, 0)
    self.Search:SetPlaceholderText("Search...")
    self.Search.OnEnter = function(s)
        self:PopulateInventory()
    end

    self.Preview = vgui.Create("DPanel", self)
    self.Preview:Dock(RIGHT)
    self.Preview:SetWide(172)

    self.Model = vgui.Create("DModelPanel", self.Preview)
    self.Model:Dock(FILL)
    self.Model:SetModel(LocalPlayer():GetModel())
    self.Model:GetEntity():ResetSequence("menu_combine")
    self.Model:SetFOV(45)
    self.Model:SetCamPos(Vector(0, 45, 50))
    self.Model:SetLookAt(Vector(0, 0, 45))

    self:CreateSlots()

    self.Content = vgui.Create("nebula.scroll", self)
    self.Content:Dock(FILL)
    self.Content:DockMargin(0, 8, 8, 0)

    self.Layout = vgui.Create("DIconLayout", self.Content)
    self.Layout:SetSpaceX(4)
    self.Layout:SetSpaceY(4)
    self.Layout:Dock(FILL)

    self.ItemSpawned = {}
    self:PopulateItems()
end

function PANEL:MakeGrid()
    local inv = LocalPlayer():getInventory()
    local filter = ShowMode[self.ShowOnly:GetText() or "All"]
    local orderBy = SortModes[self.OrderBy:GetText() or "None"]
    local search = string.lower(self.Search:GetText())

    for k, v in pairs(self.ItemSpawned) do
        v:Remove()
    end

    self.ItemSpawned = {}

    local invData = {}
    for k, v in pairs(inv) do
        if not filter(v) or (search != "" and not string.find(string.lower(NebulaInv.Items[v.name]), search)) then
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
        btn:SetItem(v.id)
        btn:SetSize(64, 64)
        table.insert(self.ItemSpawned, btn)
    end
end

function PANEL:CreateSlots()
    local slots = vgui.Create("DIconLayout", self.Preview)
    slots:Dock(BOTTOM)
    slots:SetTall(172)
    slots:SetSpaceX(8)
    slots:SetSpaceY(8)
    local size = (172 - 16) / 2
    for k = 1, 4 do
        local btn = vgui.Create("nebula.button", slots)
        btn:SetSize(size, size)
    end

    self.PlayerSlot = vgui.Create("nebula.item", self.Preview)
    self.PlayerSlot:Dock(BOTTOM)
    self.PlayerSlot:SetTall(128)
    self.PlayerSlot:Allows("model")
    self.PlayerSlotDockMargin(100, 0, 8, 8)
end

vgui.Register("nebula.inv.main", PANEL, "Panel")