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
    self._loadout = {}

    NebulaDriver:MySQLSelect("inventories", "steamid=" .. self:SteamID64(), function(data)
        if not IsValid(self) then return end
        if (data and data[1]) then
            local inv = data[1].inventory
            local load = data[1].loadout

            if (inv) then
                self._inventory = util.JSONToTable(inv)
            end

            if (load) then
                self._loadout = util.JSONToTable(load)
            end

            MsgN("[INV] Loaded inventory for " .. self:Nick() .. ":" .. self:SteamID64())
        end
    end)
end

function meta:useItem(id)
    self:saveInventory()
end

function meta:dropItem(id)
    self:saveInventory()
end

local function savePlayerInventory(ply)
    NebulaDriver:MySQLUpdate("inventories", {
        items = util.TableToJSON(ply._inventory),
        loadout = util.TableToJSON(ply._loadout or {})
    }, "steamid = " .. ply:SteamID64(), function()
        MsgN("[INV] Saved inventory for " .. ply:Nick() .. ":" .. ply:SteamID64())
    end)
end

function meta:saveInventory()
    local timerID = self:SteamID64() .. "_inventory_save"
    timer.Create(timerID, 5, 1, function()
        if not IsValid(self) then return end
    end)
end
