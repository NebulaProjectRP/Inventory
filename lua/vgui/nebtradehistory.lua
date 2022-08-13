NebulaInv.Trade = {
    Sessions = {}
}

local PANEL = {}
PANEL.Selected = nil

function PANEL:Init()
    self:SetSize(700, 600)
    self:Center()
    self:SetTitle("Trade History")
    self:MakePopup()
    self:SetBackgroundBlur(true)
    self.Search = vgui.Create("nebula.textentry", self)
    self.Search:Dock(TOP)
    self.Search:SetPlaceholder("Search SteamID64...")
    self.Search:DockMargin(self:GetWide() * .6, 16, 16, 16)
    self.Search:SetUpdateOnType(true)

    self.Search.OnValueChange = function(s)
        self:LoadData()
    end

    self.Content = vgui.Create("nebula.scroll", self)
    self.Content:Dock(FILL)
    self.Content:DockMargin(16, 0, 16, 16)

    self.Content.Paint = function(s, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(16, 16, 16))
    end

    self:LoadData()
end

function PANEL:LoadData()
    for k, v in pairs(self.Content:GetCanvas():GetChildren()) do
        v:Remove()
    end

    local filter = self.Search:GetText() or ""

    http.Fetch(NebulaAPI.HOST .. "trade/get?steamid=" .. LocalPlayer():SteamID64(), function(body)
        if not IsValid(self) then return end
        if not IsValid(self.Content) then return end
        local data = util.JSONToTable(body)
        table.sort(data, function(a, b) return tonumber(a.date or 0) > tonumber(b.date or 0) end)

        for id, trade in SortedPairs(data, true) do
            if (filter ~= "" and not (filter == trade.player_a or filter == trade.player_b)) then continue end
            local btn = vgui.Create("nebula.button", self.Content)
            local plya = IsValid(player.GetBySteamID64(trade.player_a)) and player.GetBySteamID64(trade.player_a) or nil
            local plyb = IsValid(player.GetBySteamID64(trade.player_b)) and player.GetBySteamID64(trade.player_b) or nil
            btn:Dock(TOP)
            btn:SetTall(32)
            btn:SetText("")
            btn:DockMargin(4, 4, 4, 0)

            btn.Paint = function(s, w, h)
                local ind = s:IsHovered() and 46 or 36
                draw.RoundedBox(4, 0, 0, w, h, Color(ind, ind, ind))
            end

            btn.avatar_a = vgui.Create("AvatarImage", btn)
            btn.avatar_a:Dock(LEFT)
            btn.avatar_a:SetWide(24)
            btn.avatar_a:DockMargin(4, 4, 8, 4)

            if plya then
                btn.avatar_a:SetPlayer(plya, 32)
            else
                btn.avatar_a:SetSteamID(trade.player_a, 32)
            end

            btn.name_a = Label(plya and plya:Nick() or "Loading...", btn)
            btn.name_a:SetFont(NebulaUI:Font(18))
            btn.name_a:Dock(LEFT)
            btn.name_a:SizeToContents()
            btn.name_a:SetTextColor(Color(255, 138, 0))

            if (not plya) then
                steamworks.RequestPlayerInfo(trade.player_a, function(name)
                    btn.name_a:SetText(name)
                    btn.name_a:SizeToContents()
                end)
            end

            local lbl = Label(" traded with ", btn)
            lbl:SetFont(NebulaUI:Font(18))
            lbl:Dock(LEFT)
            lbl:SizeToContents()
            btn.avatar_b = vgui.Create("AvatarImage", btn)
            btn.avatar_b:Dock(LEFT)
            btn.avatar_b:SetWide(24)
            btn.avatar_b:DockMargin(4, 4, 8, 4)

            if plyb then
                btn.avatar_b:SetPlayer(plyb, 32)
            else
                btn.avatar_b:SetSteamID(trade.player_b, 32)
            end

            btn.name_b = Label(plyb and plyb:Nick() or "Loading...", btn)
            btn.name_b:SetFont(NebulaUI:Font(18))
            btn.name_b:Dock(LEFT)
            btn.name_b:SizeToContents()
            btn.name_b:SetTextColor(Color(0, 186, 255))

            if (not plyb) then
                steamworks.RequestPlayerInfo(trade.player_b, function(name)
                    btn.name_b:SetText(name)
                    btn.name_b:SizeToContents()
                end)
            end

            lbl = Label(string.NiceTime(os.time() - trade.date), btn)
            lbl:Dock(RIGHT)
            lbl:DockMargin(0, 0, 8, 0)
            lbl:SetContentAlignment(6)
            lbl:SetFont(NebulaUI:Font(18))
            lbl:SizeToContents()

            btn.DoClick = function(s)
                self:Remove()

                http.Fetch(NebulaAPI.HOST .. "trade/get?steamid=" .. trade.player_a .. "&id=" .. id, function(body)
                    local tradeData = util.JSONToTable(body)

                    if IsValid(GTRADE) then
                        GTRADE:Remove()
                    end

                    GTRADE = vgui.Create("Trade:Main")

                    if IsValid(GTRADE) and GTRADE.MakeHistory then
                        GTRADE:MakeHistory(id, tradeData)
                    end
                end)
            end
        end
    end)
end

vgui.Register("Trade.History", PANEL, "nebula.frame")