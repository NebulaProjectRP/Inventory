local DEF = {}
DEF.Name = "Case"
DEF.Help = "Used to unbox items to use in your inventory"
DEF.Icon = 3
function DEF:OnUse(ply, item)
    local b = NebulaInv:Unbox(ply, item.class, ply.luckValue)
    return b
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

NebulaInv:RegisterType("case", DEF)