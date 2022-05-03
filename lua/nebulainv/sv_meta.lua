local meta = FindMetaTable("Player")

function meta:giveItem(id, am, fields)

    if (!NebulaInv.Items[id]) then
        MsgN("[NebulaInv] Item "..id.." does not exist!")
        return false
    end
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

    MsgC(Color(0, 183, 255), "[INV] ", Color(255, 255, 255), self:Nick() .. " have received ", Color(255, 0, 0), am, Color(255, 255, 255), "x ", Color(255, 0, 0), id, "\n")
    self:saveInventory()

    return true
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
        net.WriteUInt(self._inventory[id] or 0, 32)
        net.Send(self)
    elseif (self._inventory[id]) then
        self._inventory[id].amount = self._inventory[id].amount - am
        if (self._inventory[id].amount <= 0) then
            self._inventory[id] = nil
        end
        net.Start("Nebula.Inv:SyncItem")
        net.WriteBool(true)
        net.WriteString(id)
        net.WriteUInt(self._inventory[id] and self._inventory[id].amount or 0, 16)
        net.WriteTable({})
        net.Send(self)
    end
    self:saveInventory()
end

function meta:holsterWeapons()
    for slot, v in pairs(self._loadout) do
        local itemId = istable(v) and v.id or v
        local item = NebulaInv.Items[itemId]
        if not item then continue end

        self:giveItem(itemId, istable(v) and v.amount or 1, istable(v) and v or nil)
        self:StripWeapon(item.class)
        self._loadout[slot] = nil
    end

    self:networkLoadout()
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
            self:networkLoadout()
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

function meta:networkLoadout(kind, status)
    local function proccessItem(k, v)
        net.Start("Nebula.Inv:EquipItem")
        net.WriteString(k)
        if (status) then
            net.WriteBool(true)
            local iscustom = istable(v)
            net.WriteBool(iscustom)
            if (iscustom) then
                net.WriteString(v.id)
                net.WriteUInt(v.amount, 16)
                net.WriteTable(v.data)
            else
                net.WriteUInt(v, 32)
            end
        else
            net.WriteBool(false)
        end
        net.Send(self)
    end

    if (kind) then
        proccessItem(kind, self._loadout[kind], status)
        return
    end

    for k, v in pairs(self._loadout or {}) do
        proccessItem(k, v, true)
    end
end

function meta:dropItem(id)
    self:saveInventory()
end

function meta:equipItem(kind, id, status)
    local slot
    if (status) then
        if (tonumber(id)) then
            id = tonumber(id)
        else
            local exp = string.Explode(":", id)
            if (#exp > 0) then
                id = tonumber(exp[1])
                slot = exp[2]
            end
        end

        local item = self._inventory[id]
        if (!item) then
            DarkRP.notify(self, 1, 4, "You don't have this item!")
            return
        end

        local ref = NebulaInv:GetReference(id)

        if (slot) then
            kind = kind .. ":" .. slot
        end
        
        if not self._loadout then
            self._loadout = {
                [kind] = {}
            }
        end

        if (istable(item)) then
            self._loadout[kind] = table.Copy(item)
            self._loadout[kind].id = id
            self._loadout[kind].amount = 1
        else
            self._loadout[kind] = id
        end

        if (NebulaInv.Types[ref.type] and NebulaInv.Types[ref.type].OnEquip) then
            NebulaInv.Types[ref.type]:OnEquip(self, ref)
        end

        self:takeItem(id, 1)
    else
        if (self._loadout[kind]) then
            self:giveItem(id, 1, istable(self._loadout[kind]) and self._loadout[kind].data or nil)
            self._loadout[kind] = nil

            local ref = NebulaInv:GetReference(id)
            if (NebulaInv.Types[ref.type] and NebulaInv.Types[ref.type].OnEquip) then
                NebulaInv.Types[ref.type].OnEquip(self, item, ref)
            end
        end
    end

    self:networkLoadout(kind, status)
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
