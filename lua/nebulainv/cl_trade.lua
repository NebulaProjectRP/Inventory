local PANEL = {}
PANEL.ImTrading = {}
PANEL.IsTrading = {}
PANEL.TradeCredits = 0

function PANEL:Init()
    GTRADE = self
    self.ImTrading = {}
    self.IsTrading = {}
    if LocalPlayer():GetNWBool("Trade.Voice", false) then
        RunConsoleCommand("+voicerecord")
    end

    self:SetSize(ScrW(), ScrH())
    self:Center()
    self:SetTitle("")
    self:MakePopup()
    self:ShowCloseButton(false)
    self._start = SysTime()
    self.Left = vgui.Create("Panel", self)
    self.Left:Dock(LEFT)
    self.Left:SetWide(self:GetWide() / 2)
    self.Left:DockPadding(ScrW() * .05, 32, ScrW() * .05, 32)
    self.Right = vgui.Create("Panel", self)
    self.Right:Dock(FILL)
    self.Right:DockPadding(0, 32, ScrW() * .05, 32)
    self.Inventory = vgui.Create("DPanel", self.Left)
    self.Inventory:Dock(TOP)
    self.Inventory:DockPadding(8, 54, 8, 8)
    self.Inventory:SetTall(self:GetTall() / 2)

    self.Inventory.Paint = function(s, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(26, 26, 26, 200))
        draw.RoundedBoxEx(4, 0, 0, w, 48, Color(16, 16, 16), true, true, false, false)
        draw.SimpleText("Inventory", NebulaUI:Font(18), 16, 16, color_white)
    end

    self.Chat = vgui.Create("DPanel", self.Left)
    self.Chat:DockMargin(0, 16, 0, 0)
    self.Chat:DockPadding(8, 38, 8, 8)
    self.Chat:Dock(FILL)

    self.Chat.Paint = function(s, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(26, 26, 26, 200))
        draw.RoundedBoxEx(4, 0, 0, w, 32, Color(16, 16, 16), true, true, false, false)
        draw.SimpleText("Chat", NebulaUI:Font(16), 8, 8, color_white)
    end

    self:SetupChat()
    self:InvalidateLayout(true)
    self:SetupViews()
end

function PANEL:SetupChat()
    self.chatText = vgui.Create("nebula.textentry", self.Chat)
    self.chatText:Dock(BOTTOM)
    self.chatText:SetPlaceholder("Insert a message")
    self.chatText:SetTall(32)

    self.chatText.OnEnter = function(s)
        if (self.IsHistory) then return end
        net.Start("NebulaInv.Trade:SendMessage")
        net.WriteString(s:GetText())
        net.SendToServer()
        self.chatBox:InsertColorChange(100, 100, 100, 255)
        self.chatBox:AppendText("You: ")
        self.chatBox:InsertColorChange(235, 235, 235, 255)
        self.chatBox:AppendText(s:GetText() .. "\n")
        s:SetText("")
        s.textentry:RequestFocus()
    end

    self.chatBox = vgui.Create("RichText", self.Chat)
    self.chatBox:DockMargin(0, 0, 0, 8)
    self.chatBox:Dock(FILL)

    self.chatBox.Think = function(s)
        s:SetFontInternal(NebulaUI:Font(18))
    end

    self.chatBox.oPaint = self.chatBox.Paint

    self.chatBox.Paint = function(s, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(16, 16, 16, 200))
    end
end


function PANEL:SetupViews()
    self.LocalContainer = vgui.Create("DPanel", self.Right)
    self.LocalContainer:Dock(TOP)
    self.LocalContainer:SetTall(self:GetTall() / 2 - 128)

    self.LocalContainer.Paint = function(s, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(26, 26, 26, 200))
        draw.RoundedBoxEx(4, 0, 0, w, 38, Color(16, 16, 16), true, true, false, false)
        draw.SimpleText(self.LocalName and self.LocalName .. " Offer" or "Your Offer", NebulaUI:Font(18), 8, 8, color_white)
    end

    local bottom = vgui.Create("Panel", self.LocalContainer)
    bottom:Dock(BOTTOM)
    bottom:SetTall(32)
    bottom:DockMargin(16, 0, 16, 16)
    bottom.Money = vgui.Create("nebula.textentry", bottom)
    bottom.Money:Dock(LEFT)
    bottom.Money:SetWide(196)
    bottom.Money:DockMargin(0, 0, 16, 0)
    bottom.Money:SetNumeric(true)
    bottom.Money:SetPlaceholder("Insert money...")

    self.LocalMoney = bottom.Money

    bottom.Money.OnEnter = function(s)
        local val = tonumber(s:GetText())
        if not val then return end

        if (val < 0) then
            s:SetText("0")
        end

        if (not LocalPlayer():canAfford(val)) then
            s:SetText(LocalPlayer():getDarkRPVar("money", 0))
        end

        net.Start("NebulaInv.Trade:SetMoney")
        net.WriteUInt(tonumber(s:GetText()), 32)
        net.SendToServer()
    end

    bottom.Credits = vgui.Create("nebula.textentry", bottom)
    bottom.Credits:Dock(LEFT)
    bottom.Credits:SetWide(196)
    bottom.Credits:SetNumeric(true)
    bottom.Credits:SetPlaceholder("Insert Credits...")

    self.LocalCredits = bottom.Credits

    bottom.Credits.OnEnter = function(s)
        local val = tonumber(s:GetText())
        if not val then return end

        if (val < 0) then
            s:SetText("0")
        end

        if (val < 600) then
            Derma_Message("You cannot send below 600")
            s:SetText("0")

            return
        end

        if (math.Round(val / 100) ~= val / 100) then
            local fml = math.ceil(val / 100 - 1) * 100
            Derma_Message("You've introduce an invalid amount\nNearest valid value is " .. fml .. " or " .. (fml + 100), "Error")
            s:SetText("0")

            return
        end

        if (val > (LocalPlayer():getCredits() - (LocalPlayer()._oldCredits or 0))) then
            Derma_Message("You don't have that many tradable credits", "Error")

            return
        end

        if (LocalPlayer():getCredits() < val) then
            s:SetText(LocalPlayer():getCredits())

            return
        end

        net.Start("NebulaInv.Trade:SetCredits")
        net.WriteInt(tonumber(s:GetText()), 32)
        net.SendToServer()
    end

    bottom.Status = vgui.Create("nebula.button", bottom)
    bottom.Status:Dock(RIGHT)
    bottom.Status:SetText("Set ready")
    bottom.Status:SetWide(self.Right:GetWide() * .225)

    bottom.Status.Think = function(s)
        if (self.IsHistory) then
            s:SetText("Ready")
            s:SetColor(Color(73, 145, 45, 150))
            return
        end
        local isReady = LocalPlayer():GetNWBool("Trade.Ready")
        s:SetText(isReady and "You're Ready" or "You're not ready")
        s:SetColor(isReady and Color(56, 162, 51, 150) or Color(75, 75, 75, 150))
    end

    bottom.Status.DoClick = function()
        net.Start("NebulaInv.Trade:ChangeStatus")
        net.WriteBool(not LocalPlayer():GetNWBool("Trade.Ready", false))
        net.SendToServer()
    end

    local scroll = vgui.Create("nebula.scroll", self.LocalContainer)
    scroll:Dock(FILL)
    scroll:DockMargin(8, 42, 8, 8)

    scroll.Paint = function(s, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(26, 26, 26))
    end

    scroll:Receiver("tradeTarget", function(slf, tbl, dropped)
        if (self.IsHistory) then return end
        if (dropped) then
            local slot = tbl[1]

            if (slot.Amount > 1) then
                Derma_StringRequest("How many items do you want to trade", "Trade", slot.Amount, function(val)
                    if (tonumber(val) and slot.Amount >= tonumber(val)) then
                        if (IsValid(self.ImTrading[slot.Slot])) then
                            self.ImTrading[slot.Slot].Amount = tonumber(val)
                            net.Start("NebulaInv.Trade:InsertItem")
                            net.WriteUInt(slot.Slot, 16)
                            net.WriteUInt(tonumber(val), 16)
                            net.SendToServer()
                        else
                            local toSend = table.Copy(slot.InvSlot)
                            toSend.am = tonumber(val)
                            local size = (self.LocaliconLayout:GetWide() - 12) / 6 - 4

                            local p = self:CreateItemSlot(toSend, self.LocaliconLayout, size, slot.Slot)
                            p.IsTrade = true
                            self.ImTrading[slot.Slot] = p
                            net.Start("NebulaInv.Trade:InsertItem")
                            net.WriteUInt(slot.Slot, 16)
                            net.WriteUInt(tonumber(val), 16)
                            net.SendToServer()
                        end
                    end
                end)
            elseif (self.ImTrading[slot.Slot]) then
                return
            else
                local size = (self.LocaliconLayout:GetWide() - 12) / 6 - 4
                local p = self:CreateItemSlot(slot.InvSlot, self.LocaliconLayout, size)
                p.IsTrade = true
                self.ImTrading[slot.Slot] = p
                net.Start("NebulaInv.Trade:InsertItem")
                net.WriteInt(slot.Slot, 16)
                net.WriteInt(1, 16)
                net.SendToServer()
            end
        end
    end)

    self.LocaliconLayout = vgui.Create("DIconLayout", scroll)
    self.LocaliconLayout:Dock(TOP)
    self.LocaliconLayout:SetSpaceX(4)
    self.LocaliconLayout:SetSpaceY(4)
    self.FooterContainer = vgui.Create("Panel", self.Right)
    self.FooterContainer:Dock(BOTTOM)
    self.FooterContainer:SetTall(96)
    self.FooterContainer:DockMargin(0, 32, 0, 0)
    self.FooterContainer.Cancel = vgui.Create("nebula.button", self.FooterContainer)
    self.FooterContainer.Cancel:Dock(LEFT)
    self.FooterContainer.Cancel:DockMargin(16, 16, 16, 16)
    self.FooterContainer.Cancel:SetWide(self:GetWide() * .2)
    self.FooterContainer.Cancel:SetText("Cancel Trade")

    self.FooterContainer.Cancel.DoClick = function(s)
        self:Remove()
    end

    self.FooterContainer.Accept = vgui.Create("nebula.button", self.FooterContainer)
    self.FooterContainer.Accept:Dock(FILL)
    self.FooterContainer.Accept:DockMargin(16, 16, 16, 16)
    self.FooterContainer.Accept:SetText("Accept Trade")
    self.FooterContainer.Accept.DoClick = function()
        if (self.IsHistory) then
            self:Remove()
        end
        if not IsValid(self.Target) then return end
        if (not self.Target:GetNWBool("Trade.Ready") or not LocalPlayer():GetNWBool("Trade.Ready")) then
            Derma_Message("Both players need to set ready in order to finish the trade")

            return
        end

        if (not self.Dispatched) then
            self.Dispatched = true
        else
            return
        end

        net.Start("NebulaInv.Trade:Finish")
        net.SendToServer()
    end

    self.LocalInfo = vgui.Create("DPanel", self.Right)
    self.LocalInfo:Dock(TOP)
    self.LocalInfo:SetTall(32)
    self.LocalInfo:DockMargin(0, 16, 0, 16)

    self.LocalInfo.Paint = function(s, w, h)
        local tx, _ = draw.SimpleText("Money: " .. DarkRP.formatMoney(LocalPlayer():getDarkRPVar("money")), NebulaUI:Font(18), 0, h / 2, Color(114, 197, 40), 0, TEXT_ALIGN_CENTER)
        local credits = LocalPlayer():getCredits() .. ((LocalPlayer()._oldCredits and LocalPlayer()._oldCredits > 0) and " (" .. LocalPlayer()._oldCredits .. ")" or "")
        draw.SimpleText("Credits: " .. credits, NebulaUI:Font(18), tx + 32, h / 2, Color(0, 198, 255), 0, TEXT_ALIGN_CENTER)
    end

    self.Voice = vgui.Create("nebula.button", self.LocalInfo)
    self.Voice:Dock(RIGHT)
    self.Voice:SetText("")
    self.Voice:SetWide(192)

    self.Voice.Think = function(s)
        local voiceOn = LocalPlayer():GetNWBool("Trade.Voice")
        s:SetText(voiceOn and "Disable Voicechat" or "Enable Voicechat")

        if (voiceOn) then
            local vol = self.Target:VoiceVolume()
            s:SetColor(Color(36 + vol * 100, 36 + 150 * vol, 36 + 16 * vol))
        end
    end

    self.Voice.DoClick = function(s)
        if (self.IsHistory) then return end
        local onVoice = not LocalPlayer():GetNWBool("Trade.Voice")
        net.Start("ASAP.Trade:ToggleVoiceChat")
        net.WriteBool(onVoice)
        net.SendToServer()
        RunConsoleCommand(onVoice and "+voicerecord" or "-voicerecord")
    end

    self.TradeContainer = vgui.Create("DPanel", self.Right)
    self.TradeContainer:Dock(FILL)
    self.TradeContainer:DockMargin(0, 0, 0, 0)

    self.TradeContainer.Paint = function(s, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(26, 26, 26, 200))
        draw.RoundedBoxEx(4, 0, 0, w, 38, Color(16, 16, 16), true, true, false, false)
        draw.SimpleText((self.TraderName or "Their") .. "'s Offer", NebulaUI:Font(18), 8, 8, color_white)
    end

    bottom = vgui.Create("Panel", self.TradeContainer)
    bottom:Dock(BOTTOM)
    bottom:SetTall(32)
    bottom:DockMargin(16, 0, 16, 16)
    bottom.Money = vgui.Create("DLabel", bottom)
    bottom.Money:Dock(LEFT)
    bottom.Money:SetWide(self.Right:GetWide() * .6)
    bottom.Money:SetFont(NebulaUI:Font(18))

    bottom.Money.Think = function(s)
        s:SetText("Money: " .. DarkRP.formatMoney(self.TradeMoney or 0) .. (self.TradeCredits > 0 and (" - Credits: " .. self.TradeCredits) or ""))
    end

    bottom.Money.OnEnter = function(s)
        local val = tonumber(s:GetText())
        if not val then return end

        if (val < 0) then
            s:SetText("0")
        end

        if (not LocalPlayer():canAfford(val)) then
            s:SetText(LocalPlayer():getDarkRPVar("money", 0))
        end

        net.Start("NebulaInv.Trade:SetMoney")
        net.WriteUInt(tonumber(s:GetText()), 32)
        net.SendToServer()
    end

    bottom.Status = vgui.Create("nebula.button", bottom)
    bottom.Status:Dock(RIGHT)
    bottom.Status:SetText("Set ready")
    bottom.Status:SetWide(self.Right:GetWide() * .2)

    bottom.Status.Think = function(s)
        if (self.IsHistory) then
            s:SetText("Ready")
            s:SetColor(Color(73, 145, 45, 150))
            return
        end
        local isReady = (self.Target or LocalPlayer()):GetNWBool("Trade.Ready")
        s:SetText(isReady and "Is Ready" or "Waiting")
        s:SetColor(isReady and Color(73, 145, 45, 150) or Color(193, 119, 60, 150))
    end

    scroll = vgui.Create("nebula.scroll", self.TradeContainer)
    scroll:Dock(FILL)
    scroll:DockMargin(8, 42, 8, 8)

    scroll.Paint = function(s, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(26, 26, 26))
    end

    self.OthericonLayout = vgui.Create("DIconLayout", scroll)
    self.OthericonLayout:Dock(TOP)
    self.OthericonLayout:SetSpaceX(4)
    self.OthericonLayout:SetSpaceY(4)
    self:LoadInventory()
end

function PANEL:OnRemove()
    if (self.IsHistory) then return end
    if (not self._dismiss) then
        net.Start("NebulaInv.Trade:Quit")
        net.SendToServer()
    end
    if LocalPlayer():GetNWBool("Trade.Voice", false) then
        RunConsoleCommand("-voicerecord")
    end
end

function PANEL:LoadInventory()
    self.searchInv = vgui.Create("nebula.textentry", self.Inventory)
    self.searchInv:Dock(TOP)
    self.searchInv:SetPlaceholder("Search an item...")
    self.searchInv:SetUpdateOnType(true)

    self.searchInv.OnValueChange = function()
        self:PopulateItems()
    end

    self.ItemsContainer = vgui.Create("nebula.scroll", self.Inventory)
    self.ItemsContainer:Dock(FILL)
    self.ItemsContainer:DockMargin(0, 8, 0, 0)

    self.ItemsContainer.Paint = function(s, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(26, 26, 26))
    end

    self.ItemsLayout = vgui.Create("DIconLayout", self.ItemsContainer)
    self.ItemsLayout:SetSpaceX(4)
    self.ItemsLayout:DockPadding(4, 4, 0, 0)
    self.ItemsLayout:SetSpaceY(4)
    self.ItemsLayout:Dock(FILL)
    self.Left:InvalidateLayout(true)
    self.Inventory:InvalidateLayout(true)
    self:PopulateItems()
end

function PANEL:PopulateItems()
    local filter = string.lower(self.searchInv:GetText() or "")
    local itemTable = LocalPlayer():getInventory()

    for _, v in pairs(self.ItemsLayout:GetChildren()) do
        v:Remove()
    end

    local totalWide = (self.ItemsContainer:GetWide() - 16) / 8 - 4

    for slot, data in pairs(itemTable) do
        local item = NebulaInv.Items[data.id]

        if (string.find(string.lower(item.name), filter, 1, true)) then
            self:CreateItemSlot(data, self.ItemsLayout, totalWide, slot)
        end
    end
end

function PANEL:CreateItemSlot(data, parent, totalWide, slot, position)
    local item = NebulaInv.Items[data.id]
    local it = vgui.Create("DButton", parent)
    it:SetSize(totalWide, totalWide)
    it:SetText("")

    it:Droppable("tradeTarget")

    it.Item = item
    it.ID = data.id
    it.Amount = data.am
    it.InvSlot = data
    it.Slot = slot
    it.Color = NebulaInv.Rarities[item.rarity]
    it:SetTooltip(item.name)

    it.DoClick = function(s)

        if (item.perm && LocalPlayer():HasWeapon(item.class)) then
            Derma_Message("You cannot trade an item that you have equipped!")
            return
        end

        local menu = DermaMenu()

        menu:AddOption("See Price", function()
            if IsValid(REQ_DIALOG) then
                REQ_DIALOG:Remove()
            end
            REQ_DIALOG = vgui.Create("DMarket.Stat")
            REQ_DIALOG:Request(s.ID)
        end)

        if (s.IsTrade) then
            menu:AddOption("Retrieve", function()
                self.ImTrading[s.Slot] = nil
                net.Start("NebulaInv.Trade:InsertItem")
                net.WriteUInt(slot, 16)
                net.WriteInt(0, 16)
                net.SendToServer()
                s:Remove()
            end)
        end

        menu:AddOption("Cancel")
        menu:Open()
    end

    it.Paint = function(s, w, h)
        draw.RoundedBox(4, 0, 0, w, h, ColorAlpha(s.Color or color_white, s:IsHovered() and 200 or 50))
        draw.RoundedBox(4, 1, 1, w - 2, h - 2, Color(26, 26, 26))

        if (not s.InitPreview) then
            s.InitPreview = true
            local iconPreview = vgui.Create("nebula.item", s)
            iconPreview:SetItem(item.id)

            iconPreview:Dock(FILL)
            iconPreview:DockMargin(2, 2, 2, 2)
            iconPreview:SetMouseInputEnabled(false)
            s.Content = iconPreview
            s.IsModel = item.iconIsModel
        end
    end

    it.PaintOver = function(s, w, h)
        if (s.Amount > 1) then
            draw.SimpleText("x" .. s.Amount, NebulaUI:Font(18), w - 6, h - 4, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
        end
    end

    parent:Add(it)

    return it
end

function PANEL:MakeHistory(id, data)
    self.TradeID = id
    self.IsHistory = true
    local tradeInfo = data.tradeinfo
    local size = (self.OthericonLayout:GetWide() - 12) / 6 - 4
    for key, lam in pairs(tradeInfo.Items[1]) do
        self:CreateItemSlot(key, lam, self.LocaliconLayout, size)
    end
    for key, lam in pairs(tradeInfo.Items[2]) do
        self:CreateItemSlot(key, lam, self.OthericonLayout, size)
    end

    steamworks.RequestPlayerInfo(data.player_a, function(name)
        self.LocalName = name
        if (self.TraderName) then
            self:SetChatlog(tradeInfo.ChatLog)
        end
    end)

    steamworks.RequestPlayerInfo(data.player_b, function(name)
        self.TraderName = name
        if (self.LocalName) then
            self:SetChatlog(tradeInfo.ChatLog)
        end
    end)

    self.TradeMoney = tradeInfo.Money[2]
    self.TradeCredits = tradeInfo.Credits[2]

    self.LocalMoney:SetText(tradeInfo.Money[1])
    self.LocalMoney.textentry:SetEditable(false)
    self.LocalCredits:SetText(tradeInfo.Credits[1])
    self.LocalCredits.textentry:SetEditable(false)

    self.FooterContainer.Accept:SetVisible(false)
end

function PANEL:SetChatlog(data)
    self.chatBox:SetText("")
    for k, v in pairs(data or {}) do
        if (tonumber(v.Owner) == 1) then
            self.chatBox:InsertColorChange(255, 138, 0, 255)
            self.chatBox:AppendText(self.LocalName .. ": ")
        else
            self.chatBox:InsertColorChange(0, 186, 255, 255)
            self.chatBox:AppendText(self.TraderName .. ": ")
        end

        self.chatBox:InsertColorChange(235, 235, 235, 255)
        self.chatBox:AppendText(v.Message .. "\n")
    end
end
PANEL.PaintedFrames = 0
function PANEL:Paint(w, h)
    surface.SetDrawColor(0, 0, 0, 150)
    surface.DrawRect(0, 0, w, h)
    Derma_DrawBackgroundBlur(self, self._start)
    if self.PaintedFrames < 8 then
        self.PaintedFrames = self.PaintedFrames + 1
        return
    end
    if not self.IsHistory and not IsValid(self.Target) then
        self:Remove()
    end
end

function PANEL:SetPlayers(a, b)
    self.Target = a == LocalPlayer() and b or a
end

function PANEL:Update(data)
    local ourID = data.Players[1] == LocalPlayer() and 1 or 2
    local otherID = ourID == 1 and 2 or 1

    for k, v in pairs(self.OthericonLayout:GetChildren()) do
        v:Remove()
    end

    local size = (self.OthericonLayout:GetWide() - 12) / 6 - 4

    for slot, item in pairs(data.Items[otherID]) do
        self:CreateItemSlot(item, self.OthericonLayout, size, slot)
    end

    self.TradeMoney = data.Money[otherID]
    self.TradeCredits = data.Credits[otherID]
end

vgui.Register("Trade:Main", PANEL, "DFrame")

local INV = {}

function INV:Init()
    self:SetSize(320, 132)
    self:SetPos(ScrW() - self:GetWide(), ScrH() / 2 - self:GetTall() / 2)
    self:SetTitle("Trade Invitation")
    self.Bottom = vgui.Create("Panel", self)
    self.Bottom:Dock(BOTTOM)
    self.Bottom:SetTall(32)
    self.Bottom:DockMargin(8, 8, 8, 8)

    self.Bottom.Yes = vgui.Create("nebula.button", self.Bottom)
    self.Bottom.Yes:Dock(LEFT)
    self.Bottom.Yes:SetColor(Color(16, 16, 16))
    self.Bottom.Yes:DockMargin(0, 0, 4, 0)
    self.Bottom.Yes:SetText("Accept")
    self.Bottom.Yes:SetWide(self:GetWide() / 2)
    self.Bottom.Yes.DoClick = function()
        net.Start("NebulaInv.Trade:SendResponse")
        net.WriteBool(true)
        net.SendToServer()
        self:Remove()
    end

    self.Bottom.No = vgui.Create("nebula.button", self.Bottom)
    self.Bottom.No:Dock(FILL)
    self.Bottom.No:SetColor(Color(16, 16, 16))
    self.Bottom.No:DockMargin(4, 0, 0, 0)
    self.Bottom.No:SetText("Decline")
    self.Bottom.No:SetWide(self:GetWide() / 2)
    self.Bottom.No.DoClick = function()
        net.Start("NebulaInv.Trade:SendResponse")
        net.WriteBool(false)
        net.SendToServer()
        self:Remove()
    end
end

function INV:PaintOver(w,h)
    draw.SimpleText(self.TraderName or "", NebulaUI:Font(20), 12, 48, color_white)
end

vgui.Register("Trade:Invite", INV, "nebula.frame")

net.Receive("NebulaInv.Trade:SendInvitation", function(l)
    local invite = net.ReadEntity()
    local trade = vgui.Create("Trade:Invite")
    trade.TraderName = invite:Nick()
end)

net.Receive("NebulaInv.Trade:Start", function(l)
    if IsValid(GTRADE) then
        GTRADE:Remove()
    end

    local participants = net.ReadTable()
    local trade = vgui.Create("Trade:Main")
    trade:SetPlayers(participants[1], participants[2])
end)

net.Receive("NebulaInv.Trade:SendMessage", function(l)
    local msg = net.ReadString()

    if IsValid(GTRADE) then
        GTRADE.chatBox:InsertColorChange(216, 137, 44, 255)
        GTRADE.chatBox:AppendText(GTRADE.Target:Nick() .. ": ")
        GTRADE.chatBox:InsertColorChange(235, 235, 235, 255)
        GTRADE.chatBox:AppendText(msg .. "\n")
    end
end)

net.Receive("NebulaInv.Trade:UpdateInfo", function(l)
    local isItem = net.ReadBool()
    local owner = net.ReadEntity()
    local toAdd
    
    local isTake = net.ReadBool()

    if (isItem) then
        toAdd = net.ReadTable()
    else
        toAdd = net.ReadUInt(32)
    end

    if IsValid(GTRADE) then
        GTRADE.chatBox:InsertColorChange(100, 100, 100, 255)
        local str

        if (isTake) then
            if (isItem) then
                str = NebulaInv.Items[toAdd.id].name
            else
                str = DarkRP.formatMoney(toAdd)
            end
        end

        GTRADE.chatBox:AppendText((owner == LocalPlayer() and "You've" or owner:Nick()) .. " " .. (not isTake and "took an item" or "added " .. str))
        GTRADE.chatBox:AppendText("\n")
    end
end)

net.Receive("NebulaInv.Trade:UpdateInfoCredits", function(l)
    local owner = net.ReadEntity()
    local amount = net.ReadInt(32)

    if IsValid(GTRADE) then
        GTRADE.chatBox:InsertColorChange(100, 100, 100, 255)
        GTRADE.chatBox:AppendText((owner == LocalPlayer() and "You've" or owner:Nick()) .. " put " .. amount .. " credits")
        GTRADE.chatBox:AppendText("\n")
    end
end)

net.Receive("NebulaInv.Trade:Finish", function(l, ply)
    local status = net.ReadInt(4) or 0

    if (status == 1) then
        chat.AddText(Color(52, 216, 44), "[TRADE] ", color_white, "Trade has successfully ended!")
    end

    if IsValid(GTRADE) then
        GTRADE:Remove()
    end
end)

net.Receive("NebulaInv.Trade:SyncStuff", function()
    local data = net.ReadTable()
    if IsValid(GTRADE) then
        GTRADE:Update(data)
    end
end)

net.Receive("NebulaInv.Trade:Quit", function()
    if IsValid(GTRADE) then
        GTRADE._dismiss = true
        GTRADE:Remove()
    end
end)

--vgui.Create("Trade:Main")