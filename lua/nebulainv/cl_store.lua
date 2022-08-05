local PANEL = {}

local storeTitle = "Nebula Store"
local lwhite = Color(255, 255, 255, 100)

local nebux = Material("nebularp/ui/nebux")

function PANEL:Init()
    StorePanel = self

    if self.NoFrame then
        self:DockPadding(8, 8, 8, 8)
        self:Dock(FILL)
    else
        self:SetTitle("Store!")
        self:SetSize(ScrW() * .7, ScrH() * .7)
        self:Center()
        self:MakePopup()
    end

    self.Packages = vgui.Create("DPanel", self)

    self.Packages:Dock(FILL)
    self.Packages:DockMargin(0, 0, 8, 0)
    
    self.Season = vgui.Create("nebula.grid", self.Packages)
    self.Season:Dock(LEFT)
    self.Season:SetWide(400)
    self.Season:SetGrid(2, 4)
    self.Season:DockMargin(0, 72, 8, 0)

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
        surface.DrawTexturedRect(8, 8, 32, 32)
        draw.SimpleText(credits, NebulaUI:Font(32), 48, h / 2 - 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        if s.Credits != LocalPlayer():getCredits() then
            s.Credits = LocalPlayer():getCredits()
            surface.SetFont(NebulaUI:Font(32))
            local tx, _ = surface.GetTextureSize(credits)
            s.Size = 48 + tx + 26
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

    self.Main = vgui.Create("nebula.scroll", self.Packages)
    self.Main:Dock(FILL)
    self.Main:DockMargin(0, 72, 0, 0)

    self:InitSeason()
end

function PANEL:InitSeason()
    local season = self.Season

    season.Top = vgui.Create("DPanel", season)
    season.Top:SetPosGrid(0, 0, 2, 2)
    season.Top.Paint = function(s, w, h)
        draw.RoundedBox(8, 0, 0, w, h, color_black)
    end

    season.Top.Buy = vgui.Create("nebula.button", season.Top)
    season.Top.Buy:Dock(BOTTOM)
    season.Top.Buy:SetTall(32)
    season.Top.Buy:SetText("Coming soon...")
    season.Top.Buy:DockMargin(8, 0, 8, 8)

    for y = 1, 2 do
        for x = 1, 2 do
            local item = vgui.Create("nebula.grid", season)
            item:SetPosGrid(x - 1, 2 + y - 1, x, 2 + y)
            item:SetWide(64)
            item:SetGrid(1, 4)
            item:SetText((y - 1) * 2 + x)
            item.Buy = vgui.Create("nebula.button", item)
            item.Buy:SetPosGrid(0, 3, 1, 4)
            item.Buy:SetText("Buy")
            item.Image = vgui.Create("nebula.item", item)
            item.Image:SetItem("weapon_paladin_1")
            item.Image:SetPosGrid(0, 0, 1, 3)
            item.Image.Icon:SetFitMode(FIT_ASPECT_W)
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