local PANEL = {}

function PANEL:Init()
    CR = self
    self:SetSize(720, 450)
    self:MakePopup()
    self:SetTitle("Item Creator")
    self:Center()

    self:SetGrid(100, 100)

    self.Search = vgui.Create("nebula.textentry", self)
    self.Search:SetPosGrid(0, 0, 32, 9)
    self.Search:SetPlaceholderText("Search...")

    self.List = vgui.Create("nebula.scroll", self)
    self.List:SetPosGrid(0, 10, 32, 88)

    self.Create = vgui.Create("nebula.button", self)
    self.Create:SetPosGrid(0, 90, 32, 100)
    self.Create:SetText("Create new item")
    self.Create.DoClick = function(s)
        self.IsEditing = false
        self.ItemID = nil
        self.Name:SetText("")
        self.URL:SetText("")
        self.Quality = 1
        self.QualityButtons[1]:DoClick()
        self.ClassName:SetText("")
        self.ItemType:SetText("")
    end

    self.Container = vgui.Create("Panel", self)
    self.Container:SetPosGrid(34, 0, 100, 100)

    self:AddLabel("Item Name:")
    self.Name = vgui.Create("nebula.textentry", self.Container)
    self.Name:Dock(TOP)
    self.Name:SetTall(28)

    local pnl = vgui.Create("Panel", self.Container)
    pnl:Dock(TOP)
    pnl:DockMargin(0, 8, 0, 0)
    pnl:SetTall(96)

    self.Image = vgui.Create("nebula.imgur", pnl)
    self.Image:Dock(RIGHT)
    self.Image:SetWide(96)

    pnl.Text = Label("Insert an Imgur link (Can be an id or the whole link)", pnl)
    pnl.Text:Dock(TOP)
    pnl.Text:SetFont(NebulaUI:Font(16))
    pnl.Text:DockMargin(0, 0, 0, 4)

    self.URL = vgui.Create("nebula.textentry", pnl)
    self.URL:Dock(TOP)
    self.URL:SetTall(28)
    self.URL:DockMargin(0, 0, 8, 0)

    self.URLButton = vgui.Create("nebula.button", pnl)
    self.URLButton:Dock(FILL)
    self.URLButton:SetText("Update Icon")
    self.URLButton:DockMargin(0, 8, 8, 0)
    self.URLButton.DoClick = function()
        self.Image:SetImage(self.URL:GetText())
    end

    self:AddLabel("Quality:"):DockMargin(0, 8, 0, 0)
    local qly = vgui.Create("nebula.grid", self.Container)
    
    qly:Dock(TOP)
    qly:SetTall(32)
    qly:DockMargin(0, 4, 0, 0)
    qly:SetGrid(6, 1)
    self.QualityButtons = {}
    for k = 1, 6 do
        local btn = vgui.Create("nebula.button", qly)
        btn:Dock(LEFT)
        btn:SetText(k)
        btn:SetColor(NebulaInv.Rarities[k])
        btn:SetPosGrid(k, 0, k + 1, 1)
        btn.DoClick = function(s)
            self.Quality = k
            if (IsValid(self.SelectedQuality)) then
                self.SelectedQuality.HighLight = false
            end
            self.SelectedQuality = s
            s.HighLight = true
        end
        if (k == 1) then
            btn:DoClick()
        end
        table.insert(self.QualityButtons, btn)
    end

    self:AddLabel("Item Type:"):DockMargin(0, 8, 0, 0)
    self.ItemType = vgui.Create("nebula.textentry", self.Container)
    self.ItemType:SetPlaceholderText("suit/weapon")
    self.ItemType:Dock(TOP)
    self.ItemType:SetTall(28)
    self.ItemType:DockMargin(0, 4, 0, 0)

    self:AddLabel("Class Name:"):DockMargin(0, 8, 0, 0)
    self.ClassName = vgui.Create("nebula.textentry", self.Container)
    self.ClassName:SetPlaceholderText("Test suit/weapon_physgun")
    self.ClassName:Dock(TOP)
    self.ClassName:SetTall(28)
    self.ClassName:DockMargin(0, 4, 0, 0)

    self.Update = vgui.Create("nebula.button", self.Container)
    self.Update:Dock(FILL)
    self.Update:DockMargin(0, 16, 0, 0)
    self.Update:SetTall(32)
    self.Update:SetText("Create/Update Item")
    self.Update.DoClick = function()
        self:SendItem()
    end

    self:LoadItems()
end

function PANEL:LoadItems()
    for id, v in pairs(NebulaInv.Items) do
        local btn = vgui.Create("nebula.button", self.List)
        btn:Dock(TOP)
        btn:SetText(id .. "#" .. v.name)
        btn:SetTall(28)
        btn:SetContentAlignment(4)
        btn:SetTextInset(8, 0)
        btn.DoClick = function()
            self.IsEditing = true
            self.ItemID = id
            self.Name:SetText(v.name)
            self.ItemType:SetText(v.type)
            self.ClassName:SetText(v.class)
            self.Quality = v.rarity
            self.QualityButtons[v.rarity]:DoClick()
            self.URL:SetText(v.icon)
            self.URLButton:DoClick()
        end
    end
end

function PANEL:SendItem()
    local name = self.Name:GetText()
    if (#name == 0) then
        Derma_Message("You must enter a name for the item!", "Error", "OK")
        return
    end

    local url = self.URL:GetText()
    if (#url == 0) then
        Derma_Message("The icon it's empty", "Error", "OK")
        return
    end

    local type = self.ItemType:GetText()
    if (type == "") then
        Derma_Message("You must enter a type for the item!", "Error", "OK")
        return
    end

    local class = self.ClassName:GetText()
    if (type == "") then
        Derma_Message("You must enter a classname for the item!", "Error", "OK")
        return
    end

    net.Start("Nebula.Inv:CreateItem")
    net.WriteBool(self.IsEditing)
    net.WriteUInt(self.ItemID or 0, 32)
    net.WriteString(name)
    net.WriteString(url)
    net.WriteUInt(self.Quality, 3)
    net.WriteString(type)
    net.WriteString(class)
    net.SendToServer()
end

function PANEL:AddLabel(name)
    local lbl = Label(name, self.Container)
    lbl:Dock(TOP)
    lbl:SetFont(NebulaUI:Font(18))
    lbl:SetTall(18)
    lbl:DockMargin(0, 0, 0, 4)
    return lbl
end

vgui.Register("nebula.inventory.creator", PANEL, "nebula.frame")

if IsValid(CR) then
    CR:Remove()
end

//CR = vgui.Create("nebula.inventory.creator")

concommand.Add("nebula_itemcreator", function()
    vgui.Create("nebula.inventory.creator")
end)