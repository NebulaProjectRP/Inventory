if SERVER then return end
local isTesting = false
local PANEL = {}
PANEL.Cards = {}
PANEL.Offset = 0
local lerpVar = 0
PANEL.Velocity = 0
game.AddParticles("particles/nebula.pcf")
PrecacheParticleSystem("fireworks_splash")
PrecacheParticleSystem("suit_deplete_main")

function PANEL:Init()
    NebulaInv.UnboxPanel = self

    if isTesting then
        self:SetSize(ScrW() * 0.6, ScrH() * 0.6)
        self:MakePopup()
        self:Center()
        self.btnMinim:Remove()
        self.btnMaxim:Remove()
        --self:SetPos(-200, -400)
    end

    self.List = vgui.Create("nebula.scroll", self)
    self.List:Dock(RIGHT)
    self.List:SetWide(256)
    self.Spinner = vgui.Create("DPanel", self)
    self.Spinner:SetTall(196)

    self.Spinner.Paint = function(s, w, h)
        self:DrawSpinner(w, h)
    end

    self.Open = vgui.Create("nebula.button", self)
    self.Open:SetSize(228, 72)
    self.Open:SetText("Open Case")
    self.Open:SetFontSize(32)
    self.Cancel = vgui.Create("nebula.button", self)
    self.Cancel:SetSize(228, 72)
    self.Cancel:SetText("Cancel")
    self.Cancel:SetFontSize(32)

    self.Cancel.DoClick = function()
        if self.particleLit then return end

        self:AlphaTo(0, .25, 0, function()
            self:Remove()
        end)
    end

    self.Model = ClientsideModel("models/hunter/blocks/cube025x025x025.mdl")
    self.Model:SetNoDraw(true)

    self.Open.DoClick = function(s, w, h)
        self.SpinUp = true
        self.Progress = 0
        self.Offset = 0
        self.particleLit = false
        lerpVar = 0
        net.Start("Nebula.Inv:OpenCase")
        net.WriteString(self.caseID, 32)
        net.SendToServer()
        self:CreateMoveParticle()
    end

    self.Cards = {}
    self.Offset = 0
    --self:SetCase(8)
    --self:GenerateDummy()

    self.opaint = self.Paint
    self.Paint = function(s, w, h)
        self:opaint(w, h)
        if (self.MoveParticle) then
            local x, y = self:LocalToScreen(0, 0)
            cam.Start3D(Vector(0, -40, 32), Angle(-0, 90, 0), 140, x, y, w, h, 5, self.FarZ)

            DisableClipping(true)
            cam.IgnoreZ(true)
            self.MoveParticle:Render()
            cam.IgnoreZ(false)
            DisableClipping(false)

            cam.End3D()
        end
    end
end

function PANEL:SetCase(id)
    local case = NebulaInv.Items[id].items
    if not case then return end
    self.caseID = id
    self.CaseName = NebulaInv.Items[id].name
    self.Items = table.Copy(case)
    self:GenerateDummy()
    local lbl = Label("Possible rewards:", self.List)
    lbl:Dock(TOP)
    lbl:SetTall(32)
    lbl:DockMargin(4, 4, 0, 0)
    lbl:SetFont(NebulaUI:Font(32))

    for id, _ in pairs(self.Items) do
        local btn = vgui.Create("DPanel", self.List)
        btn:Dock(TOP)
        btn:SetTall(56)
        btn:DockMargin(4, 4, 4, 0)

        btn.owned = LocalPlayer():hasItem(id)
        btn.Paint = function(s, w, h)
            draw.RoundedBox(8, 0, 0, w, h, Color(255, 255, 255, 15))
            draw.RoundedBox(8, 1, 1, w - 2, h - 2, Color(16, 0, 24))

            if NebulaInv.Items[id] then
                draw.SimpleText(NebulaInv.Items[id].name, NebulaUI:Font(20), 58, 4, Color(200, 200, 200))
                if (s.owned) then
                    draw.SimpleText("OWNED", NebulaUI:Font(20), 58, 24, Color(74, 177, 33))
                end
            end
        end

        btn.Item = vgui.Create("nebula.item", btn)
        btn.Item:SetSize(48, 48)
        btn.Item:SetItem(id)
        btn.Item:SetPos(4, 4)
    end
end

function PANEL:OnRemove()
    if IsValid(self.Model) then
        self.Model:Remove()
    end
end

function PANEL:GenerateDummy()
    local offset = 8
    local samples = 64
    local randomItems = {}
    local tries = 0

    for k = 1, samples do
        local chances, id = table.Random(self.Items)

        while tries < 1000 and not NebulaInv.Items[id] do
            chances, id = table.Random(self.Items)
            tries = tries + 1
        end

        table.insert(randomItems, {chances, NebulaInv.Items[id]})
    end

    for k = 1, samples do
        local card = vgui.Create("nebula.item", self.Spinner)
        card:SetSize(96, 96)
        card.Origin = offset

        if k ~= 58 then
            if not randomItems[k][2].id then
                error("Missing item at slot " .. k)
                continue
            end
            card:SetItem(randomItems[k][2].id)
        end

        card:SetBackgroundAlpha(10)
        card:SetPaintedManually(true)
        table.insert(self.Cards, card)
        offset = offset + 112
    end
end

for k = 1, 5 do
    PrecacheParticleSystem("fireworks_" .. k)
end
PrecacheParticleSystem("unbox_drag")
function PANEL:CreateMoveParticle()
    if self.MoveParticle then
        self.MoveParticle:StopEmission(true, true)
        self.MoveParticle = nil
    end

    self.MoveParticle = CreateParticleSystem(self.Model, "unbox_drag", 0, 0, Vector(0, 0, 16))
    self.MoveParticle:SetShouldDraw(false)
end

function PANEL:SpawnParticle(id)
    if self.OpenParticle then
        self.OpenParticle:StopEmission(true, true)
        self.OpenParticle = nil
    end

    surface.PlaySound("ui/achievement_earned.wav")

    if id then
        self.OpenParticle = CreateParticleSystem(self.Model, "fireworks_" .. id - 1, 0, 0, Vector(0, 0, 16))
        self.OpenParticle:SetShouldDraw(false)
    end

    self:AlphaTo(0, .1, id >= 5 and 2.5 or 1.5, function()
        self:Remove()
    end)
end

function PANEL:PaintOver(w, h)
    local x, y = self:LocalToScreen(0, 0)
    local w = self.Spinner:GetWide()
    cam.Start3D(Vector(-40, 0, 4), Angle(-0, 0, 0), 60, x, y, w, h, 5, self.FarZ)

    if IsValid(self.OpenParticle) then
        DisableClipping(true)
        cam.IgnoreZ(true)
        self.OpenParticle:Render()
        cam.IgnoreZ(false)
        DisableClipping(false)
    end

    cam.End3D()
end

local deg = surface.GetTextureID("vgui/gradient-l")
PANEL.LastTick = 0
PANEL.LastOffset = 0
PANEL.TotalOffset = 0

function PANEL:DrawSpinner(w, h)
    draw.RoundedBox(8, 0, 32, w, h - 64, Color(255, 255, 255, 15))
    draw.RoundedBox(8, 1, 33, w - 2, h - 66, Color(16, 0, 24))
    DisableClipping(true)
    draw.SimpleText("Case - " .. self.CaseName, NebulaUI:Font(48), w / 2 - 8, -16, color_white, 1, TEXT_ALIGN_CENTER)

    if self.particleLit then
        draw.SimpleText(self.WinnerName, NebulaUI:Font(24), w / 2, h - 8, NebulaInv.Rarities[self.ParticleID], 1, TEXT_ALIGN_CENTER)
    end

    DisableClipping(false)
    local x, y = self.Spinner:LocalToScreen(0, 32)
    render.SetScissorRect(x + 2, y, x + w - 2, y + h - 64, true)
    local baseOffset = 0
    local w = self.Spinner:GetWide()

    for k, v in pairs(self.Cards) do
        if not IsValid(v) then return end
        local x = v.Origin - self.Offset

        if x > -96 and x < w then
            v:PaintManual()

            if self.particleLit then
                v:SetBackgroundAlpha(v:GetBackgroundAlpha() - FrameTime() * 255)

                if IsValid(v.Icon) and v.Icon:GetColor().a > 0 then
                    v.Icon:SetColor(Color(255, 255, 255, v:GetColor().a - FrameTime() * 255))
                end
            end
        end

        v:SetPos(x, 52)
    end

    render.SetScissorRect(0, 0, 0, 0, false)
    local idealTarget = (self.IdealTarget or 0) - w / 2 + 48

    if self.SpinUp and self.Progress < 1 then
        self.Progress = self.Progress + FrameTime() / 4
        lerpVal = math.ease.InOutCubic(self.Progress)
        self.LastOffset = self.Offset
        self.Offset = lerpVal * idealTarget
        self.TotalOffset = self.TotalOffset + self.Offset - self.LastOffset

        if self.LastTick < self.TotalOffset then
            LocalPlayer():EmitSound("buttons/lightswitch2.wav", 100, 75, .4)
            self.LastTick = self.TotalOffset + 96
        end
    elseif self.SpinUp and self.Progress >= 1 then
        self.Offset = idealTarget

        if not self.particleLit then
            self.particleLit = true
            self:SpawnParticle(self.ParticleID)
        end
    end

    surface.SetDrawColor(16, 0, 24)
    surface.SetTexture(deg)
    surface.DrawTexturedRect(1, 40, 64, h - 80)
    surface.DrawTexturedRectRotated(w - 33, h / 2, 64, h - 80, 180)
end

function PANEL:PerformLayout(w, h)
    if IsValid(self.Spinner) then
        self.Spinner:SetPos(16, h / 2 - self.Spinner:GetTall() / 2)
        self.Spinner:SetWide(w - self.List:GetWide() - 32)
    end

    if IsValid(self.Open) then
        self.Open:SetPos(self.Spinner:GetWide() / 2 - self.Open:GetWide(), h - self.Open:GetTall() - 32)
    end

    if IsValid(self.Cancel) then
        self.Cancel:SetPos(self.Spinner:GetWide() / 2 + 16, h - self.Open:GetTall() - 32)
    end
end

function PANEL:Paint(w, h)
    draw.RoundedBox(8, 0, 0, w, h, Color(25, 25, 25))
end

vgui.Register("nebula.unbox", PANEL, isTesting and "DFrame" or "DPanel")

net.Receive("Nebula.Inv:OpenCase", function()
    local winner = net.ReadString()

    if IsValid(NebulaInv.UnboxPanel) then
        local item = NebulaInv.Items[winner]
        NebulaInv.UnboxPanel.WinnerName = item.name
        NebulaInv.UnboxPanel.ParticleID = item.rarity
        NebulaInv.UnboxPanel.Cards[58]:SetItem(winner)
        NebulaInv.UnboxPanel.Cards[58]:SetBackgroundAlpha(25)
        NebulaInv.UnboxPanel.IdealTarget = NebulaInv.UnboxPanel.Cards[58]:GetX()
    end
end)

if IsValid(NebulaInv.UnboxPanel) then
    NebulaInv.UnboxPanel:Remove()
end
--vgui.Create("nebula.unboxing")