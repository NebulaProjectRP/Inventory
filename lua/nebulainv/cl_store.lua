local PANEL = {}

local storeTitle = "Nebula Store"
local lwhite = Color(255, 255, 255, 100)

local nebux = Material("nebularp/ui/nebux")
local vaultback = Color(151, 62, 173)

surface.CreateFont("vault_strobble", {
    font = "ONE DAY",
    size = 36,
    blursize = 4
})
function PANEL:Init()
    StorePanel = self
    self.Categories = {}

    if self.NoFrame then
        self:DockPadding(8, 8, 8, 8)
        self:Dock(FILL)
    else
        self:SetTitle("Store!")
        self:SetSize(ScrW() * .8, ScrH() * .8)
        self:Center()
        self:MakePopup()
    end

    //God please forgive me for this
    self:GetParent():InvalidateParent(true)
    self:InvalidateParent(true)
    self:InvalidateLayout(true)


    self.Packages = vgui.Create("nebula.grid", self)

    self.Packages:Dock(FILL)
    self.Packages:SetGrid(12, 1)
    self.Packages:DockMargin(0, 0, 8, 0)

    self.Season = vgui.Create("nebula.grid", self.Packages)
    self.Season:SetPosGrid(0, 0, 3, 1)
    self.Season:SetGrid(1, 8)
    self.Season:DockMargin(0, 72, 8, 0)

    self.Deals = vgui.Create("nebula.grid", self.Packages)
    self.Deals:SetPosGrid(3, 0, 7, 1)
    self.Deals:SetGrid(2, 8)
    self.Deals:DockMargin(16, 84, 24, 0)
    self.Deals:SetWide(400)
    self.Deals.Paint = function(s, w, h)
        local twide = 256
        local vaultback = HSVToColor((300 + math.cos(RealTime() * 2) * 30) % 360, 1, .5)
        local desync = HSVToColor((380 + math.cos(RealTime() * 2) * 30) % 360, .4, 1)
        draw.RoundedBox(8, w / 2 - twide / 2, 16, twide, 48, vaultback)
        
        draw.SimpleText("THE VAULT", "vault_strobble", w / 2, h * .05 + 8, ColorAlpha(desync, 100 + math.tan(RealTime() * 8) * 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("THE VAULT", NebulaUI:Font(36, true), w / 2, h * .05 + 8, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local fontSize = 64
    surface.SetFont(NebulaUI:Font(fontSize))
    local textwide, _ = surface.GetTextSize(storeTitle)
    self.Packages.Paint = function(s, w, h)
        local posx = 0
        for k = 1, #storeTitle do
            local jump = math.cos(RealTime() * 8 + k * 1) * 3
            local clr = HSVToColor((RealTime() * 100 + k * 10) % 360, 1, 1)
            local letter, _ = draw.SimpleText(storeTitle[k], NebulaUI:Font(fontSize), w / 2 - textwide / 2 + posx + 2, -16 + jump, lwhite, TEXT_ALIGN_LEFT, 0)
            draw.SimpleText(storeTitle[k], NebulaUI:Font(fontSize), w / 2 - textwide / 2 + posx, jump - 14, clr, TEXT_ALIGN_LEFT, 0)
            posx = posx + letter
        end

        surface.SetDrawColor(255, 255, 255, 25)
        surface.DrawRect(0, 60, w, 1)
    end

    self:InvalidateLayout(true)

    self.Nebux = vgui.Create("nebula.button", self.Packages)
    self.Nebux:SetSize(74, 48)
    self.Nebux:AlignRight(8)
    self.Nebux:AlignTop(0)
    self.Nebux:SetText("")
    self.Nebux:SetTooltip("Visit our store!")
    self.Nebux.DoClick = function(s)
        gui.OpenURL("https://nebularp.tebex.io/")
    end
    self.Nebux.Credits = 516800
    self.Nebux.PaintOver = function(s, w, h)
        local credits = string.Comma(LocalPlayer():getCredits())

        surface.SetMaterial(nebux)
        surface.SetDrawColor(color_white)
        local tx, _  = draw.SimpleText(credits, NebulaUI:Font(32), w - 16, h / 2 - 2, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        surface.DrawTexturedRect(w - 24 - tx - 32, 8, 32, 32)
        if s.Credits != LocalPlayer():getCredits() then
            s.Credits = LocalPlayer():getCredits()
            surface.SetFont(NebulaUI:Font(32))
            local tx, _ = surface.GetTextSize(credits)
            s.Size = 48 + tx + 20
            s:SizeTo(s.Size, 48, .1, 0, 1)
            s:MoveTo(self.Packages:GetWide() - s.Size, 0, .3, 0, 0)
        end
    end

    self.Help = vgui.Create("nebula.button", self)
    self.Help:SetSize(156, 48)
    self.Help:SetPos(16, self.NoFrame and 8 or 48)
    self.Help:SetText("What's NebulaRP?")
    self.Help.DoClick = function()
        local frame = vgui.Create("nebula.frame")
        frame:SetTitle("About")
        frame:SetSize(560, 410)
        frame:MakePopup()
        frame:SetBackgroundBlur(true)
        frame:SetAlpha(0)
        frame:AlphaTo(255, .25, 0)
        frame:Center()
        frame.Markup = markup.Parse("<font=" .. NebulaUI:Font(20) .. [[>
What's NebulaRP?
NebulaRP in simple words, is a roleplay game where you have the freedom to build your own base and invade other players bases!
It's intended to be played in cooperative along other people, but you can also play it alone if you want to.

What's the goal of the game?
Do different activities to gain virtual money and spend it to upgrade your equipment and progress

Do I need to pay to play?
No! NebulaRP it's TOTALLY free, you can play it without paying a single penny!
Although working on this game, it's a hard task, so if you want to support us, you can buy some items in our store!

Your information will never be shared with anyone, and we will never ask you for your password or anything sensible.
        </font>]], frame:GetWide() - 16)
        frame.PaintOver = function(s, w, h)
            s.Markup:Draw(8, 40, w - 16, h - 16, 150, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end
    end

    self.Main = vgui.Create("Panel", self.Packages)
    self.Main:SetPosGrid(7, 0, 12, 1)
    self.Main:DockMargin(0, 72, 0, 0)

    self:InvalidateChildren(true)

    self:InitSeason()
    self:InitStore()
end

function PANEL:InitSeason()

    local season = self.Season

    season.Top = vgui.Create("DPanel", season)
    season.Top:SetPosGrid(0, 0, 1, 7)
    season.Top.Paint = function(s, w, h)
        draw.RoundedBox(8, 0, 0, w, h, color_black)
    end

    season.Top.PaintOver = function(s, w, h)
        draw.SimpleText(NebulaStore.SeasonPass.name, NebulaUI:Font(42), w / 2, h - 32 - 16, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
        draw.SimpleText(NebulaStore.SeasonPass.description, NebulaUI:Font(16), w / 2, h - 32, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        if not NebulaStore.SeasonPass.enabled then
            draw.SimpleText("-COMING SOON-", NebulaUI:Font(32, true), w / 2, h / 2 - 32, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end
    season.Top.Imgur = vgui.Create("nebula.imgur", season.Top)

    season.Top.Imgur:Dock(FILL)
    //season.Top.Imgur:SetImage(NebulaStore.SeasonPass.imgur)
    //season.Top.PaintOver = function(s, w, h)
    //end

    season.Buy = vgui.Create("nebula.button", season)
    season.Buy:SetTall(48)
    season.Buy:SetPosGrid(0, 7, 1, 8)
    season.Buy:SetText("")
    season.Buy:SetTooltip(NebulaStore.SeasonPass.description)
    season.Buy.DoClick = function(s)
        if (not NebulaStore.SeasonPass.enabled) then
            Derma_Message("Slow down space cowboy, the season pass is not enabled yet!", "NebulaRP", "OK")
            return
        end
        if (LocalPlayer():getCredits() >= NebulaStore.SeasonPass.credits) then
            RunConsoleCommand("nebula_buy", 1)
        else
            Derma_Message("You cannot afford the season pass!")
        end
    end
    season.Buy.PaintOver = function(s, w, h)
        local tx, _ = draw.SimpleText(NebulaStore.SeasonPass.credits, NebulaUI:Font(32), w / 2 + 16, h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        surface.SetMaterial(nebux)
        surface.SetDrawColor(color_white)
        surface.DrawTexturedRect(w / 2 - tx / 2 - 24, h / 2 - 16, 32, 32)
    end

    for y = 1, 2 do
        for x = 1, 2 do
            local index = (y - 1) * 2 + x
            local itemData = NebulaStore.QueueItems[index]
            if not itemData then
                continue
            end
            local item = vgui.Create("nebula.grid", self.Deals)
            item:SetPosGrid(x - 1, 1 + (y - 1) * 3, x, 1 + (y - 1) * 3 + 3)
            item:SetWide(64)
            item:SetGrid(1, 4)
            item:SetText((y - 1) * 2 + x)
            item.Buy = vgui.Create("nebula.button", item)
            item.Buy:SetPosGrid(0, 3, 1, 4)
            item.Buy:SetText("")
            item.DoClick = function()
                if (itemData.credits or 0) > LocalPlayer():getCredits() then
                    Derma_Message("You cannot afford this item!", "NebulaRP", "OK")
                    return
                end
                RunConsoleCommand("nebula_buy", 2, index)
            end
            item.Buy.PaintOver = function(s, w, h)
                local tx, _ = draw.SimpleText(NebulaStore.QueueItems[index].credits, NebulaUI:Font(24), w / 2 + 16, h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                surface.SetMaterial(nebux)
                surface.SetDrawColor(color_white)
                surface.DrawTexturedRect(w / 2 - tx / 2 - 14, h / 2 - 12, 24, 24)
            end
            item.Image = vgui.Create("nebula.item", item)
            item.Image:SetPosGrid(0, 0, 1, 3)
            item.Image:SetItem(itemData.itemID)
            item.Image.Icon:SetFitMode(FIT_ASPECT_W)
        end
    end

end

PANEL.Categories = {}
function PANEL:InitStore()

    self.Market = vgui.Create("DMarket.Shop", self.Main)
    self.Market:Dock(FILL)
    self.Market:DockMargin(0, 0, 8, 0)

    if true then return end
    for k, v in pairs(NebulaStore.Shop) do
        if not IsValid(self.Categories[k]) then
            local cat = vgui.Create("nebula.f4.category", self.Main)
            cat:SetText(k)
            cat:SetHeaderColor(v.Color)
            cat:SetColumns(math.Round(self.Main:GetWide() / 128) - 1)
            cat:Dock(TOP)
            cat:DockMargin(0, 0, 0, 8)
            self.Categories[k] = cat
        end

        for i, it in pairs(v.Items) do
            local item = vgui.Create("Panel", self.Categories[k])
            item:SetTall(128 + 32)
            item:DockMargin(0, 4, 0, 0)
            item.Icon = vgui.Create("nebula.item", item)
            item.Icon:Dock(TOP)
            item.Icon:SetTall(128)
            item.Icon:SetItem(it.itemID)

            item.buy = vgui.Create("nebula.button", item)
            item.buy:Dock(FILL)
            item.buy:DockMargin(0, 4, 0, 0)
            if (it.money) then
                item.buy:SetText(DarkRP.formatMoney(it.money))
            else
                item.buy:SetText("")
                item.buy.PaintOver = function(s, w, h)
                    local tx, _ = draw.SimpleText(it.credits, NebulaUI:Font(24), w / 2 + 16, h - 32 - 16, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
                    surface.SetMaterial(nebux)
                    surface.SetDrawColor(color_white)
                    surface.DrawTexturedRect(w / 2 - tx / 2 - 8, h / 2 - 16, 32, 32)
                end
            end
            item.ItemData = it
            item.CategoryName = k
            item.buy.DoClick = function(s)
                if (item.ItemData.credits and (LocalPlayer():getCredits() >= item.ItemData.credits) or LocalPlayer():canAfford(item.ItemData.money)) then
                    RunConsoleCommand("nebula_buy", 3, item.CategoryName, i, item.ItemData.itemID)
                else
                    Derma_Message("You do not have enough " .. (item.ItemData.credits and "credits" or "money") .. " to buy this item.", "Nebula", "OK")
                    return
                end
            end
        end

        self:InvalidateLayout(true)
        for _, cat in pairs(self.Categories) do
            if not IsValid(cat) then return end
            cat:UpdateLayout(true)
        end
        
    end
end

vgui.Register("nebula.store", PANEL, "nebula.frame")
local newPanel = table.Copy(PANEL)
newPanel.NoFrame = true
vgui.Register("nebula.storef4", newPanel, "Panel")

hook.Add("OnF4MenuCreated", "NebulaRP.CreateStoreTab", function(pnl)
    pnl.Tabs:AddTab("Store", "nebula.storef4", true):SetIcon(NebulaUI.Derma.F4[3]):SetColor(Color(255, 238, 0))
end)

concommand.Add("neb_store", function()
    if IsValid(StorePanel) then
        StorePanel:Remove()
    end
    
    StorePanel = vgui.Create("nebula.store")
end)

//RunConsoleCommand("neb_store")