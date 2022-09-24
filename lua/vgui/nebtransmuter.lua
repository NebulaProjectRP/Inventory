local PANEL = {}

function PANEL:Init()
    self:SetTitle("Transmutator")
    self:SetSize(320, 508)
    self:Center()
    self:MakePopup()

    local label = Label("Improve your weapon stats", self)
    label:Dock(TOP)
    label:SetTall(20)
    label:SetFont(NebulaUI:Font(20))
    label:SetContentAlignment(5)
    label:SetTextColor(color_white)

    local mx = (self:GetWide() - 128 - 32) / 2
    self.Local = vgui.Create("nebula.item", self)
    self.Local:Dock(TOP)
    self.Local:SetTall(128)
    self.Local:DockMargin(mx, 16, mx, 16)
    self.Slots = vgui.Create("nebula.combobox", self)
    self.Slots:Dock(TOP)
    self.Slots:SetTall(32)
    self.Slots:SetText("NONE")
    self.Slots:DockMargin(16, 0, 16, 16)
    self.Slots.OnSelect = function(s, index, value, data)
        self.ItemLevel = data.level
        self.SelectedMutator = data.id
        self.Selected = {}
        for k, v in pairs(self.Ingredients) do
            v:SetItem(nil)
        end
    end
    local container = vgui.Create("nebula.grid", self)
    container:Dock(TOP)
    container:SetTall(192 - 32)
    container:SetGrid(3, 2)
    container:DockMargin(16, 0, 16, 16)

    self.Send = vgui.Create("nebula.button", self)
    self.Send:Dock(TOP)
    self.Send:SetTall(32)
    self.Send:SetText("Transmutate")
    self.Send:DockMargin(16, 0, 16, 0)
    self.Send.DoClick = function(s)
        Derma_Query("Are you sure do you want to transmutate this item? Your other items will get consumed", "Transmutate", "Yes", function()
            net.Start("NebulaInv.RequestAlchemy")
            net.WriteUInt(self.SlotSelected, 16)
            net.WriteString(self.SelectedMutator)
            net.WriteUInt(table.Count(self.Selected), 3)
            for k, v in pairs(self.Selected) do
                net.WriteUInt(v, 16)
            end
            net.SendToServer()
        end, "Cancel")
    end

    self.Selected = {}
    self.Ingredients = {}

    for k = 1, 5 do
        local slot = vgui.Create("nebula.item", container)
        slot.id = k

        slot.DoClick = function(s)
            if self.ItemLevel < s.id then return end
            if s.id > 1 and not self.Selected[s.id - 1] then return end
            local picker = ItemPicker()

            picker.Filter = function(s, item, islot)
                if (islot == self.SlotSelected) then return false end
                for i = 1, 5 do
                    if (self.Selected[i] == islot) then
                        return false
                    end
                end
                local _it = LocalPlayer():getInventory()[islot]
                local itemLevel = _it.data[self.SelectedMutator]
                if not itemLevel or itemLevel ~= self.ItemLevel then return false end

                return true
            end

            picker.OnItemSelected = function(s, id, item, islot)
                self.Selected[k] = islot
                self.Ingredients[k]:SetItem(item and item.id or nil, islot)
            end
            picker:Populate()
        end

        table.insert(self.Ingredients, slot)

        local x, y = (k - 1) % 3, math.ceil(k / 3) - 1
        slot:SetPosGrid(x, y, x + 1, y + 1)
    end
end

function PANEL:SetItem(slot)
    local item = LocalPlayer():getInventory()[slot]
    self.SlotSelected = slot
    self.Local:SetItem(item.id, slot)
    self.Slots:Clear()
    local shouldApply = true
    for k, v in pairs(item.data) do
        if (k == "kills" or k == "lives") then
            continue
        end
        local mut = NebulaInv.Mutators[k]
        self.Slots:AddChoice(mut.Name .. " Level: " .. v, {
            id = k,
            level = v,
        }, shouldApply)
        shouldApply = false
    end

end

vgui.Register("nebula.transmutator", PANEL, "nebula.frame")