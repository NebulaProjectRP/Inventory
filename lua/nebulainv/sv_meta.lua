local meta = FindMetaTable("Player")

function meta:giveItem(id, am, fields)
    am = am or 1
    local isUnique = fields != nil
    if not isUnique then
        if (self._inventory[id]) then
            self._inventory[id] = self._inventory[id] + am
        else
            self._inventory[id] = am
        end

        net.Start("Nebula.Inv:AddItem")
        net.WriteBool(false)
        net.WriteUInt(id, 32)
        net.WriteUInt(self._inventory[id], 32)
        net.Send(self)
    else
        local hash = util.MD5(util.TableToJSON(fields))
        local name = "unique_" .. id .. "_" .. hash
        if (self._inventory[name]) then
            self._inventory[name].amount = self._inventory[name].amount + am
        else
            self._inventory[name] = {
                amount = am,
                data = fields
            }
        end
        
        net.Start("Nebula.Inv:AddItem")
        net.WriteBool(true)
        net.WriteString(name)
        net.WriteUInt(self._inventory[name].amount, 16)
        net.WriteTable(fields)
        net.Send(self)
    end
    MsgN("Added item")
    self:saveInventory()
end
meta.addItem = meta.giveItem

function meta:takeItem(id, am)
    local isUnique = isstring(id)
    if not isUnique then
        self._inventory[id] = self._inventory[id] - am
        if (self._inventory[id] <= 0) then
            self._inventory[id] = nil
        end

        net.Start("Nebula.Inv:SyncItem")
        net.WriteBool(false)
        net.WriteUInt(id, 32)
        net.WriteUInt(self._inventory[id], 32)
        net.Send(self)
    else
        self._inventory[id].amount = self._inventory[id].amount - am
        if (self._inventory[id].amount <= 0) then
            self._inventory[id] = nil
        end
        net.Start("Nebula.Inv:SyncItem")
        net.WriteBool(true)
        net.WriteString(name)
        net.WriteUInt(self._inventory[name].amount, 16)
        net.WriteTable({})
        net.Send(self)
    end
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
        savePlayerInventory(self)
    end)
end
