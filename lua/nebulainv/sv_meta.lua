local meta = FindMetaTable("Player")

function meta:giveItem(id, am, fields)
    self:saveInventory()
end
meta.addItem = meta.giveItem

function meta:takeItem(id, am)
    self:saveInventory()
end

function meta:loadItems()
    self._inventory = {}
end

function meta:useItem(id)
    self:saveInventory()
end

function meta:dropItem(id)
    self:saveInventory()
end

local function savePlayerInventory(ply)
    
end

function meta:saveInventory()
    local timerID = self:SteamID64() .. "_inventory_save"
    timer.Create(timerID, 5, 1, function()
        if not IsValid(self) then return end
    end)
end
