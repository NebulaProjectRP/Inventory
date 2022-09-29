local PANEL = {}
local decalCache = {}
local ShowMode = {}

local SortModes = {
    ["None"] = function(a, b) return ((a or {}).id or "") < ((b or {}).id or "") end,
    ["Name"] = function(a, b) return ((a or {}).name or "") < ((b or {}).name or "") end,
    ["Rarity"] = function(a, b) return ((a or {}).rarity or 1) > ((b or {}).rarity or 1) end,
    ["Amount"] = function(a, b, c, d) return c == d and ((a or {}).name or "") < ((b or {}).name or "") or ((c or {}).am or 0) > ((d or {}).am or 0) end,
}

PANEL.Slots = {}

function PANEL:Init()
    ShowMode["All"] = function() return true end
    NebulaInv.Panel = self
    self:Dock(FILL)
    self:InvalidateLayout(true)
    self.Preview = vgui.Create("Panel", self)
    self.Preview:Dock(RIGHT)
    self.Preview:SetWide(352)
    self:CreateHeader()
    self.LastPaint = SysTime()
    self.Model = vgui.Create("DModelPanel", self.Preview)
    self.Model:Dock(FILL)
    self.Model:SetModel(LocalPlayer():GetModel())
    self.Model:GetEntity():ResetSequence("menu_combine")
    self.Model:SetFOV(30)

    self.Model.PreDrawModel = function(s, ent)
        if self:GetAlpha() ~= 255 then return false end
    end

    self.Model.LayoutEntity = function(s, ent)
        ent:FrameAdvance(RealTime() - self.LastPaint)
        self:ManipulateModel(ent)
    end

    local ent = self.Model:GetEntity()
    local att = ent:LookupAttachment("eyes")

    if att then
        local attach = ent:GetAttachment(att)

        if attach then
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
    self.Layout:Dock(FILL)
    self.ItemSpawned = {}
    self:PopulateItems()
end

function PANEL:CreateHeader()
    self.Header = vgui.Create("Panel", self)
    self.Header:Dock(TOP)
    self.Header:SetTall(32)
    self.Header:DockMargin(0, 0, 16, 16)
    self.OrderBy = vgui.Create("nebula.combobox", self.Header)
    self.OrderBy:Dock(RIGHT)
    self.OrderBy:SetText("Rarity")
    self.OrderBy:SetWide(128)

    self.OrderBy.OnSelect = function(s, index, value)
        self:PopulateItems()
    end

    for k, v in pairs(SortModes) do
        self.OrderBy:AddChoice(k)
    end

    self.TradeButton = vgui.Create("nebula.button", self.Header)
    self.TradeButton:Dock(RIGHT)
    self.TradeButton:DockMargin(0, 0, 16, 0)
    self.TradeButton:SetWide(128)
    self.TradeButton:SetText("Trade")

    self.TradeButton.DoClick = function()
        local selector = PlayerSelector()

        selector.OnSelect = function(s, ply)
            net.Start("NebulaInv.Trade:SendInvitation")
            net.WriteEntity(ply)
            net.SendToServer()
        end

        selector:Open()
    end

    self.Search = vgui.Create("nebula.textentry", self.Header)
    self.Search:Dock(FILL)
    self.Search:DockMargin(0, 0, 16, 0)
    self.Search:SetPlaceholderText("Search...")
    self.Search:SetUpdateOnType(true)

    self.Search.OnValueChange = function(s)
        self:PopulateItems()
    end
end

function PANEL:ManipulateModel(ent)
    local my = -.4 + gui.MouseY() / ScrH()
    local mx = -.5 + gui.MouseX() / ScrW()
    ent:SetEyeTarget(Vector(0, 0, 60 - my * 40))
    local boneID = ent:LookupBone("ValveBiped.Bip01_Head1")
    ent:ManipulateBoneAngles(boneID, Angle(0, -20 - my * 20, -25 + mx * 20))
end

PANEL.Categories = {}

function PANEL:PopulateItems()
    local inv = LocalPlayer():getInventory()
    local orderBy = SortModes[self.OrderBy:GetText() or "None"]

    if self.OrderBy:GetText() == "None" then
        orderBy = nil
    end

    local search = string.lower(self.Search:GetText())

    for k, v in pairs(self.Categories) do
        if IsValid(v) then
            v:Remove()
        end
    end

    self.ItemSpawned = {}
    local invData = {}
    local typesFound = 0

    for k = 1, table.Count(inv) do
        local v = inv[k] or {}
        local item = NebulaInv.Items[v.id]
        if not item then continue end

        if not invData[item.type] then
            typesFound = typesFound + 1

            invData[item.type] = {
                Definition = NebulaInv.Types[item.type],
                Items = {},
                Index = cookie.GetNumber("NebulaInv.SortIndex." .. item.type, typesFound),
            }
        end

        if item and not item.name then
            PrintTable(item)
        end

        if filter and not filter(item) or (search ~= "" and not string.find(string.lower(item.name), search, 0, true)) then continue end

        if not IsValid(self.Categories[item.type]) then
            self.Categories[item.type] = vgui.Create("nebula.f4.inventory.kind", self.Layout)
            self.Categories[item.type]:Dock(TOP)
            self.Categories[item.type]:Setup(NebulaInv.Types[item.type])
            self.Categories[item.type].Type = item.type
            self.Categories[item.type].Index = invData[item.type].Index
        end

        table.insert(invData[item.type].Items, {
            am = v.am or 1,
            id = v.id,
            slot = k,
            fav = v.fav,
            type = item.type,
            data = v.data
        })
    end

    for kind, inv in SortedPairsByMemberValue(invData, "Index") do
        if orderBy then
            table.sort(inv.Items, function(a, b)
                local state = orderBy(NebulaInv.Items[(a or {}).id or ""], NebulaInv.Items[(b or {}).id or ""], a, b)

                return state
            end)
        else
            table.sort(inv.Items, function(a, b)
                local aref, bref = NebulaInv.Items[a.id], NebulaInv.Items[b.id]
                local ca, cb = table.Count(a.data), table.Count(b.data)
                local generic = nil

                if a.fav ~= b.fav then
                    generic = a.fav ~= nil
                elseif bref.rarity == 6 or aref.rarity == 6 then
                    generic = bref.rarity < aref.rarity
                elseif ca ~= cb then
                    generic = ca > cb
                elseif bref.rarity ~= aref.rarity then
                    generic = bref.rarity < aref.rarity
                elseif aref.name ~= bref.name then
                    generic = bref.name > aref.name
                else
                    generic = a.slot < b.slot
                end

                return generic
            end)
        end

        for k, v in pairs(inv.Items) do
            local btn = vgui.Create("nebula.item", self.Categories[kind])
            local res = btn:SetItem(v.id, v.slot)

            if not res then
                btn:Remove()
                continue
            end

            btn:SetSize(112, 112)
            btn:Droppable("Receiver." .. v.type)
            btn.Slot = v.slot

            btn.DoClick = function(s)
                local menu = DermaMenu()

                if NebulaInv.Types[v.type].OpenMenu then
                    NebulaInv.Types[v.type]:OpenMenu(menu, v, s.Slot)
                end

                menu:AddSpacer()

                menu:AddOption((LocalPlayer():getInventory()[v.slot].fav and "UnMark" or "Mark") .. " Favorite", function()
                    net.Start("Nebula.Inv:ToggleFavorite")
                    net.WriteUInt(v.slot, 16)
                    net.SendToServer()

                    if (LocalPlayer():getInventory()[v.slot] or {}).fav then
                        LocalPlayer():getInventory()[v.slot].fav = nil
                    else
                        LocalPlayer():getInventory()[v.slot].fav = true
                    end

                    s.isFavorite = LocalPlayer():getInventory()[v.slot].fav
                end)

                menu:AddSpacer()

                menu:AddOption("Gift Item", function()
                    local selector = PlayerSelector()

                    selector.OnSelect = function(s, ply)
                        if v.am == 1 then
                            net.Start("Nebula.Inv:GiftItem")
                            net.WriteUInt(v.slot, 16)
                            net.WriteEntity(ply)
                            net.WriteUInt(1, 16)
                            net.SendToServer()
                            return
                        end
                        Derma_StringRequest("Gift", "How many do you want to send", "1", function(text)
                            local amount = tonumber(text)

                            if amount and amount > 0 and amount <= v.am then
                                net.Start("Nebula.Inv:GiftItem")
                                net.WriteUInt(v.slot, 16)
                                net.WriteEntity(ply)
                                net.WriteUInt(amount, 16)
                                net.SendToServer()
                                return
                            end
                            Derma_Message("Invalid amount.", "Error", "OK")

                        end)
                    end

                    selector:Open()
                end)

                menu:AddOption("Sell Item", function()
                    Derma_StringRequest("For how much do you want to sell this item", "Marketplace", "100", function(val)
                        local amount = tonumber(val)
                        if not amount then return end
                        net.Start("NebulaMarket:AddItem")
                        net.WriteUInt(s.Slot, 16)
                        net.WriteUInt(amount, 32)
                        net.SendToServer()
                    end)
                end)

                menu:AddSpacer()

                menu:AddOption("Deconstruct Item", function()
                    local amount = NebulaInv.Items[v.id].rarity * 25

                    Derma_Query("Are you sure do you want to decontruct this item? You will get x" .. amount .. " gobblegum credits for each item", "Delete Item", "Yes", function()
                        net.Start("Nebula.Inv:DeleteItem")
                        net.WriteUInt(s.Slot, 16)
                        net.WriteBool(false)
                        net.SendToServer()
                    end, "Delete some", function()
                        if v.am > 1 then
                            Derma_StringRequest("Delete amount", "How many do you want to delete (Max " .. v.am .. ")", "1", function(text)
                                local amount = tonumber(text)

                                if amount and amount > 0 and amount <= v.am then
                                    net.Start("Nebula.Inv:DeleteItem")
                                    net.WriteUInt(s.Slot, 16)
                                    net.WriteBool(true)
                                    net.WriteUInt(amount, 16)
                                    net.SendToServer()
                                else
                                    Derma_Message("Invalid amount.", "Error", "OK")
                                end
                            end)

                            return
                        end

                        net.Start("Nebula.Inv:DeleteItem")
                        net.WriteUInt(s.Slot, 16)
                        net.WriteBool(true)
                        net.WriteUInt(0, 16)
                        net.SendToServer()
                    end, "No", function() end)
                end)

                if LocalPlayer():IsAdmin() then
                    menu:AddOption("Copy ItemID", function()
                        SetClipboardText(v.id)
                    end)
                end

                menu:AddOption("Cancel")
                menu:Open()
            end

            table.insert(self.ItemSpawned, btn)
        end
    end
end

local off = Color(255, 255, 255, 25)

function PANEL:CreateSlots()
    local default = NebulaRanks.Ranks.Default
    local rankData = NebulaRanks.Ranks[LocalPlayer():getTitle()] or default
    local titles = vgui.Create("Panel", self.Model)
    titles:Dock(TOP)
    titles:SetTall(32)
    local cosmeticButton = vgui.Create("nebula.button", titles)
    cosmeticButton:SetText("Edit Title")
    cosmeticButton:Dock(FILL)
    cosmeticButton:SetWide(72)

    cosmeticButton.DoClick = function()
        vgui.Create("nebula.cosmeticTitle")
    end
/*
    self.Titles = vgui.Create("nebula.combobox", titles)
    self.Titles:Dock(FILL)
    self.Titles:DockMargin(0, 0, 16, 0)
    self.Titles:SetText(rankData.Name)

    for k, v in pairs(LocalPlayer():getTitles()) do
        local subRank = NebulaRanks.Ranks[v] or default
        self.Titles:AddChoice(subRank.Name, v)
    end

    self.Titles.OnSelect = function(s, id, a, b)
        Derma_Query("Do you want to update your cosmetic title to " .. a .. "?", "Update Title", "Yes", function()
            net.Start("NebulaRP.Credits:ChangeTitle")
            net.WriteString(b)
            net.WriteBool(true)
            net.SendToServer()
        end, "No", function()
            net.Start("NebulaRP.Credits:ChangeTitle")
            net.WriteString(b)
            net.WriteBool(true)
            net.SendToServer()
        end)
    end
*/
    local header = vgui.Create("Panel", self.Model)
    header:Dock(BOTTOM)
    header:SetTall(64)
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
        btn.IsSlot = "weapon:" .. k
        btn:SetDrawOnTop(true)

        btn.Think = function(s)
            s:SetDrawOnTop(s:IsHovered())
        end

        self.Slots["weapon:" .. k] = btn
        table.insert(self.WeaponSlots, btn)
    end

    self.HolsterSuit = vgui.Create("nebula.button", header)
    self.HolsterSuit:Dock(BOTTOM)
    self.HolsterSuit:SetTall(32)
    self.HolsterSuit:SetTooltip("Start holstering your suit to your inventory")
    self.HolsterSuit:SetText("Return your suit")

    self.HolsterSuit.DoClick = function()
        if not LocalPlayer():hasSuit() then return end
        net.Start("Nebula.Inv:PickupSuit")
        net.SendToServer()
    end

    --RunConsoleCommand("say", "!dropsuit")
    self.Holster = vgui.Create("nebula.button", header)
    self.Holster:Dock(BOTTOM)
    self.Holster:SetTall(32)
    self.Holster:SetText("Return Weapons to inventory")
    local modify = false

    self.Holster.Think = function(s)
        local cooldown = LocalPlayer():GetNWFloat("ReturnCooldown", 0)

        if cooldown > CurTime() then
            modify = true
            s:SetText("You have to wait " .. math.Round(cooldown - CurTime(), 1))
        elseif modify then
            s:SetText("Return Weapons to inventory")
        end
    end

    self.Holster.DoClick = function()
        local cooldown = LocalPlayer():GetNWFloat("ReturnCooldown", 0)
        if cooldown > CurTime() then return end
        net.Start("Nebula.Inv:HolsterEquipment")
        net.SendToServer()

        for k = 1, 3 do
            NebulaInv.Loadout["weapon:" .. k] = nil
            self.WeaponSlots[k]:SetItem(nil)
            --self.Slots["weapon:" .. k]:SetItem(nil)
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
        menu.GetDeleteSelf = function() return true end
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
        if decal == "" then return end

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
    self.PlayerSlot:Allow("accessory", true)
    self.Slots["accessory"] = self.PlayerSlot

    self.PlayerSlot.DoClick = function(s)
        if not s.ID then return end
        local menu = DermaMenu()

        menu:AddOption("Remove", function()
            net.Start("Nebula.Inv:RemoveSlot")
            net.WriteString("accessory")
            net.SendToServer()
            s:SetItem(nil)
            NebulaInv.Loadout["accessory"] = nil
        end)

        menu:AddOption("Cancel")
        menu:Open()
    end

    self.HitSound = vgui.Create("nebula.item", side)
    self.HitSound:SetSize(72, 72)
    self.HitSound:Dock(BOTTOM)
    self.HitSound:DockMargin(0, 8, 0, 8)
    self.HitSound:Allow("hitmark", true)
    self.Slots["hitmark"] = self.HitSound

    self.HitSound.DoClick = function(s)
        if not s.Item then return end
        local menu = DermaMenu()

        menu:AddOption("Remove", function()
            net.Start("Nebula.Inv:RemoveSlot")
            net.WriteString("hitmark")
            net.SendToServer()
            s:SetItem(nil)
            NebulaInv.Loadout["hitmark"] = nil
        end)

        menu:AddOption("Cancel")
        menu:Open()
    end

    self.VOX = vgui.Create("nebula.item", side)
    self.VOX:SetSize(72, 72)
    self.VOX:Dock(BOTTOM)
    self.VOX:Allow("vox", true)
    self.Slots["vox"] = self.VOX

    self.VOX.OnMousePressed = function(s)
        if not s.Reference then return end
        local menu = DermaMenu()

        menu:AddOption("Remove", function()
            net.Start("Nebula.Inv:RemoveSlot")
            net.WriteString("vox")
            net.SendToServer()
            s:SetItem(nil)
            NebulaInv.Loadout["vox"] = nil
        end)

        menu:AddOption("Cancel")
        menu:Open()
    end

    local loadout = NebulaInv.Loadout
    if not loadout then return end

    if loadout.accessory then
        self.PlayerSlot:SetItem(istable(loadout.accessory) and loadout.accessory.id or loadout.accessory)
    end

    if loadout.hitmark then
        self.HitSound:SetItem(istable(loadout.hitmark) and loadout.hitmark.id or loadout.hitmark)
    end

    if loadout.vox then
        self.VOX:SetItem(istable(loadout.vox) and loadout.vox.id or loadout.vox)
    end

    for k = 1, 3 do
        local ld = loadout["weapon:" .. k]
        if not ld then continue end
        self.WeaponSlots[k]:SetItem(istable(ld) and ld.id or ld)
    end
end

vgui.Register("nebula.f4.inventory", PANEL, "Panel")
local KIND = {}
KIND.CanAdd = false
KIND.Items = {}

function KIND:Init()
    self:SetTall(148)
    self.CanAdd = false
    self.Label = Label("", self)
    self.Label:SetFont(NebulaUI:Font(24))
    self.Label:Dock(TOP)
    self.Label:SetTall(24)
    self.Label:SetTextColor(color_white)
    self.Label:SetMouseInputEnabled(true)
    self.Label:DockMargin(0, 0, 0, 16)
    self.Items = {}
end

function KIND:OnChildAdded(child)
    table.insert(self.Items, child)
end

KIND.NoReloop = false

function KIND:PerformLayout(w, h)
    if self.NoReloop then return end
    local x, y = 4, 32
    local largestH = 0
    local totalHeight = 0

    for i, child in pairs(self.Items) do
        if not IsValid(child) then
            table.remove(self.Items, i)
            continue
        end

        largestH = math.max(largestH, child:GetTall())
        child:SetPos(x, y)
        x = x + child:GetWide() + 8

        if x + child:GetWide() > w then
            x = 4
            y = y + largestH + 8
            totalHeight = totalHeight + largestH + 8
            largestH = 0
        end
    end

    self.NoReloop = true
    self:SetTall(totalHeight + 156)
    self:InvalidateParent(true)
    self.NoReloop = false
end

function KIND:Setup(ref)
    self.Label:SetText(ref.Name)
    self.Help = ref.Help
end

function KIND:Paint(w, h)
    surface.SetDrawColor(255, 255, 255, 75)
    surface.DrawRect(0, 26, w - 4, 1)

    if self.Help then
        draw.SimpleText(self.Help, NebulaUI:Font(18), w - 8, 14, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end
end

vgui.Register("nebula.f4.inventory.kind", KIND, "Panel")

net.Receive("Nebula.Inv:SyncItem", function()
    local slot = net.ReadUInt(16)
    local am = net.ReadUInt(16)
    local id = net.ReadString()

    local entry = {
        id = id,
        am = am,
        data = {}
    }

    for k = 1, net.ReadUInt(8) do
        entry.data[net.ReadString()] = net.ReadString()
    end

    if am > 0 then
        if NebulaInv.Inventory[slot] and NebulaInv.Inventory[slot].id == id then
            NebulaInv.Inventory[slot].am = am
            NebulaInv.Inventory[slot].data = entry.data
        else
            local found = false

            for k, v in pairs(NebulaInv.Inventory) do
                if v.id == id then
                    for a, b in pairs(v.data) do
                        if entry[a] == v.data[a] then
                            NebulaInv.Inventory[k].am = am
                            found = true
                            break
                        end
                    end
                end
            end

            if not found then
                table.insert(NebulaInv.Inventory, slot, entry)
            end
        end
    else
        table.remove(NebulaInv.Inventory, slot)
    end

    if IsValid(NebulaInv.Panel) then
        NebulaInv.Panel:PopulateItems()
    end
end)

net.Receive("Nebula.Inv:RemoveEquipment", function(l, ply)
    local empty = net.ReadString()

    for k, v in pairs(NebulaInv.Loadout or {}) do
        if empty ~= k and not string.StartWith(k, "weapon:") then continue end
        local item = NebulaInv.Items[v.id]
        if item.rarity >= 6 then continue end
        NebulaInv.Loadout[k] = nil
    end
end)

net.Receive("Nebula.Inv:EquipItem", function()
    local kind = net.ReadString()
    local isEquip = net.ReadBool()

    if not NebulaInv.Loadout then
        NebulaInv.Loadout = {
            [kind] = {}
        }
    end

    if isEquip then
        NebulaInv.Loadout[kind] = {
            id = net.ReadString(),
            am = net.ReadUInt(16),
            data = net.ReadTable()
        }
    else
        NebulaInv.Loadout[kind] = nil
    end

    local pnl = NebulaInv.Panel

    if IsValid(pnl) and pnl.Slots[kind] then
        pnl.Slots[kind]:SetItem(isEquip and NebulaInv.Loadout[kind].id or nil)
    end
end)