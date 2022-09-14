local DEF = {}

DEF.Name = "Case"
DEF.Help = "Used to unbox items to use in your inventory"
DEF.Icon = 3

function DEF:OnUse(ply, item)
    local b = NebulaInv:Unbox(ply, item.class, ply.luckValue)
    return b
end

function DEF:OpenMenu(menu, item)
    menu:AddOption("Open case", function()
        local ref = NebulaInv.Items[item.id]
        if (ref.onOpen) then
            ref.onOpen(item, item.slot)
            return
        end
        if IsValid(NebulaInv.Panel) then
            local w, h = NebulaInv.Panel:GetSize()
            local fit = vgui.Create("nebula.unbox", NebulaInv.Panel)
            fit:SetSize(w, h)
            fit:SetCase(item.id)
        end
    end)
end

if CLIENT then
    
local PANEL = {}
PANEL.Balls = {}
local gobbles = 4
function PANEL:Init()
    self:SetSize(ScrW(), ScrH())
    self:MakePopup()
    self:SetTitle("")
    self:ShowCloseButton(false)
    self:DockPadding(0, 0, 0, 0)

    local mx, my = ScrW() * .15, ScrH() * .15
    local cl = vgui.Create("nebula.close", self)
    cl:AlignRight(mx)
    cl:AlignTop(my)

    self.Grid = vgui.Create("nebula.grid", self)
    self.Grid:Dock(FILL)
    self.Grid:SetGrid(gobbles + 2, 4)

    self.Balls = {}
    for k = 0, gobbles - 1 do
        timer.Simple(k * .5, function()
            LocalPlayer():EmitSound("physics/metal/metal_computer_impact_soft2.wav", 100, 90 + 4 * k)
        end)
        local pnl = vgui.Create("DPanel", self.Grid)
        pnl:SetPosGrid(1 + k, 0, 2 + k, 3)
        pnl:SetAlpha(0)
        pnl:AlphaTo(255, 1, .5 * k, function()
            pnl:AlphaTo(0, 1, 1, function()
                self:Dispatch()
            end)
        end)
        pnl.extra = math.cos(-math.pi / 2 + ((k + 1) / (gobbles + 1)) * math.pi)
        pnl.Progress = 0
        pnl.name = ""
        pnl.Model = ClientsideModel("models/props_junk/cardboard_box003a.mdl")
        pnl.Model:SetNoDraw(true)

        pnl.OnRemove = function(s)
            SafeRemoveEntity(s.Model)
            if s.OpenParticle then
                s.OpenParticle:StopEmission(true, true)
                s.OpenParticle = nil
            end
        end
        pnl.SpawnParticle = function(s, id)
            if s.OpenParticle then
                s.OpenParticle:StopEmission(true, true)
                s.OpenParticle = nil
            end
        
            if id and id >= 3 then
                s.OpenParticle = CreateParticleSystem(s.Model, "fireworks_" .. id - 1, 0, 0, Vector(0, 0, 16))
                s.OpenParticle:SetShouldDraw(false)
            end
        end
        pnl.Paint = function(s, w, h)
            if not s.icon then return end
            if s:GetAlpha() == 0 then return end
            s.Progress = math.min(s.Progress + FrameTime() * 2, 1)
            local p = math.ease.OutBounce(s.Progress)
            surface.SetMaterial(s.icon)
            surface.SetDrawColor(color_white)
            surface.DrawTexturedRectRotated(w / 2, (h / 3) * p + h * .1 + s.extra * h / 4, 128, 128, p * 360)

            if (s.OpenParticle) then
                s.Model:DrawModel()
                s.OpenParticle:Render()
            end

            DisableClipping(true)
            draw.SimpleText(s.name, NebulaUI:Font(48), w / 2, h * .1 + h * .5 + s.extra * h / 4, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            DisableClipping(false)
        end
        pnl.PaintOver = function(s, w, h)
            local x, y = s:LocalToScreen(0, 0)
            cam.Start3D(Vector(-40, 0, s.extra * 12), Angle(-0, 0, 0), 20, x, y, w, h, 5, s.FarZ)
        
            if IsValid(s.OpenParticle) then
                DisableClipping(true)
                cam.IgnoreZ(true)
                s.OpenParticle:Render()
                cam.IgnoreZ(false)
                DisableClipping(false)
            end
        
            cam.End3D()
        end

        table.insert(self.Balls, pnl)
    end
end

function PANEL:Dispatch()
    if (self.Dispatched) then return end
    self.Dispatched = true

    self:AlphaTo(0, .5, 0, function()
        self:Remove()
    end)
end

function PANEL:SetGobblegums(gb)
    for k = 1, 4 do
        local gumball = ASAP_GOBBLEGUMS.Gumballs[gb[k]]
        if not gumball then
            continue
        end
        self.Balls[k].icon = gumball.icon
        self.Balls[k].name = gumball.name
        timer.Simple(k / 4, function()
            if IsValid(self) and IsValid(self.Balls[k]) then
                self.Balls[k]:SpawnParticle(gumball.type)
            end
        end)
    end
end

function PANEL:Paint(w, h)
    surface.SetDrawColor(0, 0, 0, 200)
    surface.DrawRect(0, 0, w, h)
    XeninUI:DrawBlur(self, 3)
end

vgui.Register("nebula.unboxgobblegums", PANEL, "DFrame")

net.Receive("Nebula.Inv:UnboxGobblegums", function()
    local am = net.ReadUInt(6)
    local tbl = {}
    for k = 1, am do
        table.insert(tbl, net.ReadUInt(6))
    end

    if IsValid(NebulaInv.GobblePanel) then
        NebulaInv.GobblePanel:Remove()
    end

    NebulaInv.GobblePanel = vgui.Create("nebula.unboxgobblegums")
    NebulaInv.GobblePanel:SetGobblegums(tbl)
end)

end

function DEF:CreateEditor(panel, container, data)
    local top = panel:AddControl("DLabel", {
        Text = "Item Pool",
        Font = NebulaUI:Font(20),
        TextColor = color_white,
        Tall = 20,
    })
    
    local body = panel:AddControl("DListView", {
        Tall = 178,
    })


    body:AddColumn("Name", 1):SetWidth(200)
    body:AddColumn("Odds", 2)

    if not data.cases then
        data.cases = {}
    end

    body:Receiver("nebula.item.reference", function(s, items, drop, mnx)
        if not drop then return end
        local id = items[1].ID
        for k, v in pairs(s:GetLines()) do
            if (v:GetColumnText(1) == items[1]:GetText()) then
                v:SetColumnText(2, tonumber(v:GetColumnText(2)) + 1)
                return
            end
        end
        local line = body:AddLine(items[1]:GetText(), 1)
        data.cases[id] = 1
        line.OnRightClick = function()
            local menu = DermaMenu()
            menu:AddOption("Set odds", function()
                Derma_StringRequest("Odds", "Set the odds of this item being selected", line:GetColumnText(2), function(text)
                    if (tonumber(text) == nil) then return end
                    line:SetColumnText(2, text)
                    data.cases[id] = tonumber(text)
                end)
            end)
            menu:AddOption("Remove", function()
                data.cases[id] = nil
                body:RemoveLine(line:GetID())
            end)
            menu:AddOption("Cancel")
            menu:Open()
        end
    end)

    for k, v in pairs(data.cases) do
        body:AddLine(k, v)
    end
end

function DEF:Build(data, id)
    local items = data.items
    if (data.generate) then
        local main = NebulaInv.Items
        for k, _ in pairs(items) do
            local found = false
            for itemid, info in pairs(main) do
                if (not string.StartWith(itemid, "weapon_")) then continue end
                if (itemid == "weapon_" .. k) then
                    found = true
                    break
                end
            end

            if (not found) then        
                local chances = {}
                for _, v in pairs(items) do
                    if (table.HasValue(chances, v)) then continue end
                    table.insert(chances, v)
                end

                while (#chances > 5) do
                    table.remove(chances, 2)
                end

                local icon = ""
                local rarity = 1
                //local wepData = weapons.GetStored(data.classname)
                local filePath = "materials/entities/" .. k .. ".png"
                if (file.Exists(filePath, "GAME")) then
                    icon = "entities/" .. k .. ".png"
                end

                for i = 1, 5 do
                    if (chances[i] <= items[k]) then
                        rarity = i
                        break
                    end
                end

                MsgN("NebulaInv:RegisterItem('weapon', '" .. k .. "', {\n\tclassname = '" .. k .. "',\n\trarity = " .. rarity .. ",\n\ticon = '" .. icon .. "'\n})")
            end
        end
    end

    return data
end

NebulaInv:RegisterType("case", DEF)