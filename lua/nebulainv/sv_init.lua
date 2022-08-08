util.AddNetworkString("Nebula.Inv:CreateItem")
util.AddNetworkString("Nebula.Inv:NetworkItem")
util.AddNetworkString("Nebula.Inv:UseItem")
util.AddNetworkString("Nebula.Inv:DeleteItem")
util.AddNetworkString("Nebula.Inv:ClearSlot")
util.AddNetworkString("Nebula.Inv:SellItem")
util.AddNetworkString("Nebula.Inv:RemoveItem")
util.AddNetworkString("Nebula.Inv:AddItem")
util.AddNetworkString("Nebula.Inv:SyncItem")
util.AddNetworkString("Nebula.Inv:EquipItem")
util.AddNetworkString("Nebula.Inv:EquipResult")
util.AddNetworkString("Nebula.Inv:HolsterEquipment")
util.AddNetworkString("Nebula.Inv:OpenCase")
util.AddNetworkString("Nebula.Inv:DropItem")
util.AddNetworkString("Nebula.Inv:RemoveEquipment")
util.AddNetworkString("Nebula.Inv:RemoveSlot")

hook.Add("DatabaseCreateTables", "NebulaInventory", function()
    NebulaDriver:MySQLCreateTable("inventories", {
        items = "TEXT NOT NULL",
        decals = "TEXT NOT NULL",
        loadout = "TEXT NOT NULL",
        steamid = "VARCHAR(22)"
    }, "steamid", function()
        NebulaDriver:MySQLQuery("SELECT * FROM items;", function(data)
            NebulaInv.Items = data
        end)
    end)

    NebulaDriver:MySQLCreateTable("items", {
        id = "INT NOT NULL AUTO_INCREMENT",
        name = "VARCHAR(32)",
        icon = "VARCHAR(128)",
        rarity = "TINYINT DEFAULT 1 NOT NULL",
        type = "VARCHAR(16) DEFAULT 'suits' NOT NULL",
        class = "VARCHAR(32)",
        extraData = "TEXT NOT NULL",
        perm = "INT DEFAULT 0 NOT NULL"
    }, "id")

    NebulaDriver:MySQLHook("inventories", function(ply, data)
        ply:loadItems(data)
    end)
end)

function NebulaInv:NetworkItem(id)
    local item = self.Items[id]
    net.Start("Nebula.Inv:NetworkItem")
    net.WriteUInt(id, 32)
    net.WriteString(item.name)
    net.WriteString(item.icon)
    net.WriteUInt(item.rarity, 3)
    net.WriteString(item.class)
    net.WriteString(item.type)
    net.WriteBool(item.perm == 1)
    net.WriteTable(item.extraData)
    net.Broadcast()
end

function NebulaInv:CreateItem(owner, isEdit, editID, itemName, itemIcon, itemRarity, itemType, itemClass, extraData)
    local item = {
        name = itemName,
        icon = itemIcon,
        rarity = itemRarity,
        type = itemType,
        class = itemClass,
        perm = itemRarity == 6 and 1 or 0,
        extraData = extraData
    }

    if isEdit then
        NebulaInv.Items[editID] = item
        self:NetworkItem(editID)
        NebulaDriver:MySQLUpdate("items", {
            name = itemName,
            icon = itemIcon,
            rarity = itemRarity,
            type = itemType,
            class = itemClass,
            perm = itemRarity == 6 and 1 or 0,
            extraData = util.TableToJSON(extraData)
        }, "id = " .. editID, function()
            owner:SendLua("Derma_Message('Item with id " .. editID .. " has been updated!', 'Nebula Inventory', 'OK')")
            BroadcastLua("NebulaInv:LoadItems()")
            http.Post(NebulaAPI.HOST .. "items/update", nil, nil, {
                authorization = NebulaAPI.API_KEY
            })
        end)
    else
        local safeCopy = table.Copy(item)
        safeCopy.extraData = util.TableToJSON(safeCopy.extraData)
        NebulaDriver:MySQLInsert("items", safeCopy, function()
            NebulaDriver:MySQLQuery("SELECT LAST_INSERT_ID() AS lastid", function(data)
                item.id = data[1].lastid
                NebulaInv.Items[data[1].lastid] = item
                self:NetworkItem(item.id)
                owner:SendLua("Derma_Message('Item has been created with id " .. item.id .. "!', 'Nebula Inventory', 'OK')")

                http.Post(NebulaAPI.HOST .. "items/update", nil, nil, {
                    authorization = NebulaAPI.API_KEY
                })
            end)
        end)
    end
end

function NebulaInv:LoadItems()
    MsgC(Color(200, 200, 0), "[Nebula] Loading items...\n")
    NebulaDriver:MySQLSelect("items", nil, function(data)
        self.Cases = {}
        local tempCases = {}
        for k, v in pairs(data) do
            self.Items[v.id] = v
            if (v.type == "case") then
                local data = util.JSONToTable(v.extraData)
                tempCases[v.id] = v
            end
        end

        for k, v in pairs(tempCases) do
            local item = self.Items[k]
            table.insert(self.Cases, {
                rarity = item.rarity,
                chances = v.chances,
                content = v.content
            })
        end

        MsgC(Color(0, 200, 0), "[Nebula] Items loaded succesfully!\n")
    end)
end

if (NebulaDriver) then
    NebulaInv:LoadItems()
end

net.Receive("Nebula.Inv:CreateItem", function(l, ply)
    if (not ply:IsAdmin()) then return end

    local isEdit = net.ReadBool()
    local editID = net.ReadUInt(32)
    local itemName = net.ReadString()
    local itemIcon = net.ReadString()
    local itemRarity = net.ReadUInt(3)
    local itemType = net.ReadString()
    local itemClass = net.ReadString()
    local itemExtraData = net.ReadTable()

    NebulaInv:CreateItem(ply, isEdit, editID, itemName, itemIcon, itemRarity, itemType, itemClass, itemExtraData)
end)

net.Receive("Nebula.Inv:UseItem", function(l, ply)
    local slot = net.ReadUInt(16)
    local item = ply:getInventory()[slot]
    local id = item.id

    local ref = NebulaInv.Items[id]

    if not item then
        DarkRP.notify(ply, 1, 4, "This item not longer exists!")
        return
    end
    local resolver = NebulaInv.Types[ref.type]
    if (not resolver) then
        DarkRP.notify(ply, 1, 4, "This item is not usable!")
        return
    end

    local result = resolver:OnUse(ply, ref, id, item)
    if (result == true) then
        ply:takeItem(slot, 1)
    end
end)

net.Receive("Nebula.Inv:EquipItem", function(l, ply)
    local kind = net.ReadString()
    local id = net.ReadUInt(16)
    local status = net.ReadBool()

    ply:equipItem(kind, id, status)
end)

net.Receive("Nebula.Inv:HolsterEquipment", function(l, ply)
    if (ply:GetNWFloat("ReturnCooldown", 0) > CurTime()) then
        DarkRP.notify(ply, 1, 4, "You can't return your equipment yet!")
        return
    end
    ply:SetNWFloat("ReturnCooldown", CurTime() + 30)
    ply:holsterWeapons()
end)

net.Receive("Nebula.Inv:DeleteItem", function(l, ply)
    local slot = net.ReadUInt(16)
    ply:takeItem(slot, 1)
end)

net.Receive("Nebula.Inv:DropItem", function(l, ply)
    local slot = net.ReadUInt(16)
    ply:dropItem(slot, 1)
end)

net.Receive("Nebula.Inv:RemoveSlot", function(l, ply)
    local slot = net.ReadString()
    if (not ply._loadout or not ply._loadout[slot]) then return end

    ply:giveItem(ply._loadout[slot].id, 1, ply._loadout.data or {})
    ply._loadout[slot] = nil

end)

net.Receive("Nebula.Inv:OpenCase", function(l, ply)
    local caseID = net.ReadString(32)
    local slot
    for k, v in pairs(ply:getInventory()) do
        if (v.id == caseID) then
            slot = k
            break
        end
    end
    if not slot then return end
    local winner, _, _ = NebulaInv:Unbox(ply, caseID)
    net.Start("Nebula.Inv:OpenCase")
    net.WriteString(winner)
    net.Send(ply)

    if (winner) then
        ply:takeItem(slot, 1)
    end
end)