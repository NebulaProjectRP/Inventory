local lan = GetConVar("sv_lan")
local meta = FindMetaTable("Player")

function meta:giveItem(id, am, fields)
    if not NebulaInv.Items[id] then
        MsgN("[Nebula] Item " .. id .. " does not exist!")

        return false
    end

    am = am or 1

    local nextItem = {
        id = id,
        am = am,
        data = fields or {}
    }

    if not self._inventory then
        self._inventory = {}
    end

    local insertAt
    local isAdd = false

    if table.IsEmpty(fields or {}) then
        for k, v in pairs(self._inventory) do
            if v.id == id then
                v.am = v.am + am
                insertAt = k
                isAdd = true
                break
            end
        end
    end

    if not isAdd then
        insertAt = table.insert(self._inventory, nextItem)
    end

    net.Start("Nebula.Inv:AddItem")
    net.WriteUInt(insertAt, 16)
    net.WriteString(id)
    net.WriteUInt(self._inventory[insertAt].am, 16)
    net.WriteUInt(table.Count(self._inventory[insertAt].data), 8)

    for k, v in pairs(self._inventory[insertAt].data) do
        net.WriteString(k)
        net.WriteString(v)
    end

    net.Send(self)
    MsgC(Color(0, 183, 255), "[INV] ", Color(255, 255, 255), self:Nick() .. " have received ", Color(255, 0, 0), am, Color(255, 255, 255), "x ", Color(255, 0, 0), id, "\n")
    self:saveInventory()

    return true
end

meta.addItem = meta.giveItem

function meta:syncInvSlot(slot)
    local item = self:getInventory()[slot]

    if isstring(item.data) then
        self:getInventory()[slot].data = util.JSONToTable(self:getInventory()[slot].data)
    end

    net.Start("Nebula.Inv:SyncItem")
    net.WriteUInt(slot, 16)
    net.WriteUInt(item.am or 0, 16)
    net.WriteString(item.id)
    net.WriteUInt(table.Count(item.data), 8)

    for k, v in pairs(item.data) do
        net.WriteString(k)
        net.WriteString(v)
    end

    net.Send(self)
end

function meta:dropItem(slot, amount)
    local item = self:getInventory()[slot]
    if not item then return end
    local itemRef = NebulaInv.Items[item.id]
    local def = NebulaInv.Types[itemRef.type]
    if not def or not def.DropItem then return end
    local res = def:DropItem(self, itemRef, slot, amount)

    if res then
        self:takeItem(slot, amount)
    end
end

function meta:giftItem(slot, target, amount)
    if target == self then
        DarkRP.notify(self, 1, 5, "You cannot gift items to yourself!")

        return
    end

    local item = self:getInventory()[slot]

    if not item then
        DarkRP.notify(self, 1, 5, "You do not have this item!")

        return
    end

    amount = math.Clamp(amount, 1, item.am)

    if item.am < amount then
        DarkRP.notify(self, 1, 5, "You do not have enough of this item!")

        return
    end

    self:takeItem(slot, amount)
    target:giveItem(item.id, amount, item.data)
    hook.Run("onUnboxGift", self, target, item.id)
end

function meta:takeItem(slot, am)
    if istable(slot) then
        local failed = false

        for _, data in SortedPairs(slot) do
            local temp = table.Copy(self:getInventory()[data[1]])

            if not temp then
                failed = true
                break
            end

            if temp.am < data[2] then
                failed = true
                break
            end

            temp.am = (temp.am or 1) - data[2]

            if temp.am <= 0 then
                self:getInventory()[data[1]].toDeletion = true
            else
                self:getInventory()[data[1]].am = temp.am
            end
        end

        if failed then return false end

        local found = true

        while found do
            found = false

            for k, v in pairs(self:getInventory()) do
                if v.toDeletion then
                    table.remove(self:getInventory(), k)
                    found = true
                end
            end
        end

        self:saveInventory(function()
            self:ConCommand("neb_requestinv")
        end)

        return true
    end

    if isstring(slot) then
        for k, v in pairs(self:getInventory()) do
            if v.id == slot then
                slot = k
                break
            end
        end

        if isstring(slot) then return false end
    end

    local item = self:getInventory()[slot]
    if not item then return false end

    if am == -1 then
        am = item.am
    end

    item.am = (item.am or 1) - am
    self:syncInvSlot(slot)

    if item.am <= 0 then
        table.remove(self._inventory, slot)
    end

    self:saveInventory()

    return true
end

function meta:holsterWeapons()
    for slot, v in pairs(self._loadout) do
        if not string.StartWith(slot, "weapon") then continue end
        local itemId = v.id
        local item = NebulaInv.Items[itemId]
        if not item then continue end
        local newItem = table.Copy(v)
        self._loadout[slot] = nil
        self:networkLoadout(slot, false)
        self:giveItem(itemId, newItem.am or 1, newItem.data)
        if not item.class then continue end
        local wep = self:GetWeapon(item.class)

        if IsValid(wep) then
            self:StripWeapon(item.class)
        end
    end
end

function meta:loadItems(data)
    self._inventory = {}
    self._loadout = {}
    self._decals = {}

    if data and data.items then
        local inv = data.items
        local load = data.loadout
        local decals = data.decals

        if inv then
            self._inventory = util.JSONToTable(inv)
        end

        if decals then
            self._decals = util.JSONToTable(decals)

            if table.IsEmpty(self._decals) then
                self:giveDecals()
            else
                for k, v in pairs(self._decals) do
                    if v then
                        self:SetNWString("DecalName", k)
                        break
                    end
                end
            end
        end

        if load then
            self._loadout = util.JSONToTable(load)
            self:networkLoadout()
        end

        MsgC(Color(100, 255, 200), "[INV]", color_white, " Loaded inventory for " .. self:Nick() .. ":" .. self:SteamID64() .. "\n")
    else
        NebulaDriver:MySQLInsert("inventories", {
            steamid = self:SteamID64(),
            items = util.TableToJSON({}),
            loadout = util.TableToJSON({}),
            decals = util.TableToJSON({}),
        })

        self:giveDecals()
    end
end

function meta:networkLoadout(kind, status)
    local function proccessItem(k, v, isEquip)
        net.Start("Nebula.Inv:EquipItem")
        net.WriteString(k)
        net.WriteBool(isEquip)

        if isEquip then
            net.WriteString(v.id)
            net.WriteUInt(v.am, 16)
            net.WriteTable(v.data)
        end

        net.Send(self)
    end

    if kind then
        proccessItem(kind, self._loadout[kind], status)

        return
    end

    for k, v in pairs(self._loadout or {}) do
        proccessItem(k, v, true)
    end

    for slot, item in pairs(self._loadout) do
        local ref = NebulaInv.Items[item.id]
        local type = NebulaInv.Types[ref.type]

        if type and type.OnEquip then
            type:OnEquip(self, ref, item.id, item)
        end
    end
end

function meta:equipItem(kind, id, status)
    local item = self:getInventory()[id]

    if status then
        if not item then
            DarkRP.notify(self, 1, 4, "You don't have this item!")

            return false
        end

        local exp = string.Explode(":", kind)
        local tempKind = kind

        if #exp == 2 then
            tempKind = exp[1]
        end

        local ref = NebulaInv.Items[item.id]

        if tempKind ~= ref.type then
            MsgN("Wrong slot! ", kind, " on -> ", ref.type)

            return false
        end

        if ref.type == "weapon" and ref.rarity == 6 then return end

        if not self._loadout then
            self._loadout = {}
        end

        if self._loadout[kind] then
            self:giveItem(self._loadout[kind].id, 1, istable(self._loadout[kind].data) and self._loadout[kind].data or nil)
        end

        self._loadout[kind] = table.Copy(item)
        self._loadout[kind].am = 1

        if NebulaInv.Types[ref.type] and NebulaInv.Types[ref.type].OnEquip then
            NebulaInv.Types[ref.type]:OnEquip(self, ref, item.id, item, kind)
        end

        self:takeItem(id, 1)
    else
        if self._loadout[kind] then
            self:giveItem(id, 1, istable(self._loadout[kind]) and self._loadout[kind].data or nil)
            self._loadout[kind] = nil
            local ref = NebulaInv:GetReference(id)

            if NebulaInv.Types[ref.type] and NebulaInv.Types[ref.type].OnEquip then
                NebulaInv.Types[ref.type].OnEquip(self, item, ref)
            end
        end
    end

    self:networkLoadout(kind, status)

    return true
end

function meta:saveDecal()
    NebulaDriver:MySQLUpdate("inventories", {
        decals = util.TableToJSON(self._decals)
    }, "steamid = " .. self:SteamID64(), function()
        MsgN("[INV] Saved decals for " .. self:Nick() .. ":" .. self:SteamID64())
    end)
end

local function savePlayerInventory(ply, cb)
    local nick, sid = ply:Nick(), ply:SteamID64()

    NebulaDriver:MySQLUpdate("inventories", {
        items = util.TableToJSON(ply._inventory),
        loadout = util.TableToJSON(ply._loadout or {})
    }, "steamid = " .. sid, function()
        MsgN("[INV] Saved inventory for " .. nick .. ":" .. sid)

        if cb then
            cb()
        end
    end)
end

hook.Add("PlayerDisconnected", "NebulaSaveItems", savePlayerInventory)

hook.Add("PlayerDeath", "Nebula:RemoveWeapons", function(ply)
    if ply.hasFool then
        ply.hasFool = nil

        return
    end

    for k, v in pairs(ply._loadout) do
        if string.StartWith(k, "weapon") then
            local item = NebulaInv.Items[v.id]
            local wep = ply:GetWeapon(item.class)
            if (wep.livesRemaining and wep.livesRemaining > 1) then
                wep.livesRemaining = wep.livesRemaining - 1
                ply._loadout[k].data.lives = wep.livesRemaining

                local send = "NebulaInv.Loadout['" .. k .. "'].data.lives = " .. wep.livesRemaining
                ply:SendLua(send)
                continue
            end
            if item.rarity >= 6 then continue end
            ply._loadout[k] = nil
            net.Start("Nebula.Inv:RemoveEquipment")
            net.WriteString(k)
            net.Send(ply)
        end
    end

    if (not table.IsEmpty(ply._loadout)) then
        ply:networkLoadout()
    end
end)

hook.Add("canDropWeapon", "Nebula:NODropLoadout", function(ply, wep)
    if not IsValid(wep) then return end
    if wep.cannotDrop then return false end
    local class = wep:GetClass()
    local disallow = false

    for k, v in pairs(ply._loadout) do
        if v.id == "weapon_" .. class then
            disallow = true
            break
        end
    end

    if disallow then
        DarkRP.notify(ply, 1, 4, "You can't drop equipped weapons!")

        return false
    end
end)

hook.Add("PlayerSpawn", "NebulaReturnWeapons", function(ply)
    if (not ply._loadout or table.IsEmpty(ply._loadout)) then
        return
    end

    ply:networkLoadout()
end)

function meta:saveInventory(cb)
    local timerID = self:SteamID64() .. "_inventory_save"

    timer.Create(timerID, cb and 0 or 1, 1, function()
        if not IsValid(self) then return end
        savePlayerInventory(self, cb)
    end)
end