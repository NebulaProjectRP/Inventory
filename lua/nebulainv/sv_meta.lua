local meta = FindMetaTable("Player")

function meta:giveItem(id, am, fields)
    self:saveInventory()
end
meta.addItem = meta.giveItem

function meta:takeItem(id, am)
    self:saveInventory()
end

function meta:loadItems(data)
    self._inventory = {}
    self._loadout = {}

    if (data and data.items) then
        local inv = data.items
        local load = data.loadout

        if (inv) then
            self._inventory = util.JSONToTable(inv)
        end

        if (load) then
            self._loadout = util.JSONToTable(load)
        end

        MsgC(Color(100, 255, 200),"[INV]", color_white, " Loaded inventory for " .. self:Nick() .. ":" .. self:SteamID64() .. "\n")
    else
        NebulaDriver:MySQLInsert("inventories", {
            steamid = self:SteamID64(),
            items = util.TableToJSON({}),
            loadout = util.TableToJSON({})
        })
    end
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
