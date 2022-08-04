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
            http.Post(NebulaAPI.HOST .. "items/update", {
                key = NebulaAPI.API_KEY
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

                http.Post(NebulaAPI.HOST .. "items/update", {
                    key = NebulaAPI.API_KEY
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
    if (!ply:IsAdmin()) then return end

    local isEdit = net.ReadBool()
    local editID = net.ReadUInt(32)
    local itemName = net.ReadString()
    local itemIcon = net.ReadString()
    local itemRarity = net.ReadUInt(3)
    local itemType = net.ReadString()
    local itemClass = net.ReadString()
    local itemExtraData = net.ReadTable()

    MsgN("Hello?")
    NebulaInv:CreateItem(ply, isEdit, editID, itemName, itemIcon, itemRarity, itemType, itemClass, itemExtraData)
end)

net.Receive("Nebula.Inv:UseItem", function(l, ply)
    local itemID = net.ReadString()
    local id
    if (string.StartWith(itemID, "unique")) then
        id = tonumber(string.Explode("_", itemID, false)[2])
        if (not ply._inventory[itemID]) then
            DarkRP.notify(ply, 1, 4, "You don't have this item!")
            return
        end
    else
        if (not ply._inventory[tonumber(itemID)]) then
            DarkRP.notify(ply, 1, 4, "You don't have this item!")
            return
        end
        id = tonumber(itemID)
    end

    local item = NebulaInv.Items[id]
    
    if not item then
        DarkRP.notify(ply, 1, 4, "This item not longer exists!")
        return
    end
    local resolver = NebulaInv.Types[NebulaInv.Items[id].type]
    if (!resolver) then
        DarkRP.notify(ply, 1, 4, "This item is not usable!")
        return
    end

    local result = resolver:OnUse(ply, item)
    if (result == true) then
        ply:takeItem(tonumber(itemID) and tonumber(itemID) or itemID, 1)
    end
end)

net.Receive("Nebula.Inv:EquipItem", function(l, ply)
    local kind = net.ReadString()
    local id = net.ReadUInt(16)
    local status = net.ReadBool()

    local result = ply:equipItem(kind, id, status)

    net.Start("Nebula.Inv:EquipResult")
    net.WriteBool(result)
    net.Send(ply)
end)

net.Receive("Nebula.Inv:HolsterEquipment", function(l, ply)
    ply:holsterWeapons()
end)

net.Receive("Nebula.Inv:OpenCase", function(l, ply)
    local caseID = net.ReadUInt(32)
    local winner, ran, cache = NebulaInv:Unbox(ply, caseID)
    net.Start("Nebula.Inv:OpenCase")
    net.WriteUInt(winner, 32)
    net.Send(ply)
end)