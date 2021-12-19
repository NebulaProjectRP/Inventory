util.AddNetworkString("Nebula.Inv:CreateItem")
util.AddNetworkString("Nebula.Inv:NetworkItem")
util.AddNetworkString("Nebula.Inv:UseItem")
util.AddNetworkString("Nebula.Inv:DropItem")
util.AddNetworkString("Nebula.Inv:RemoveItem")
util.AddNetworkString("Nebula.Inv:AddItem")

hook.Add("DatabaseCreateTables", "NebulaInventory", function()
    NebulaDriver:MySQLCreateTable("inventories", {
        items = "TEXT DEFAULT '{}' NOT NULL",
        loadout = "TEXT DEFAULT '{}' NOT NULL",
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
    net.Broadcast()
end

function NebulaInv:CreateItem(owner, isEdit, editID, itemName, itemIcon, itemRarity, itemType, itemClass)
    local item = {
        name = itemName,
        icon = itemIcon,
        rarity = itemRarity,
        type = itemType,
        class = itemClass,
        perm = itemRarity == 6 and 1 or 0
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
            perm = itemRarity == 6 and 1 or 0
        }, "id = " .. editID, function()
            owner:SendLua("Derma_Message('Item with id " .. editID .. " has been updated!', 'Nebula Inventory', 'OK')")
        end)
    else
        NebulaDriver:MySQLInsert("items", item, function()
            NebulaDriver:MySQLQuery("SELECT LAST_INSERT_ID() AS lastid", function(data)
                item.id = data[1].lastid
                NebulaInv.Items[data[1].lastid] = item
                self:NetworkItem(item.id)
                owner:SendLua("Derma_Message('Item has been created with id " .. item.id .. "!', 'Nebula Inventory', 'OK')")
            end)            
        end)
    end
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

    NebulaInv:CreateItem(ply, isEdit, editID, itemName, itemIcon, itemRarity, itemType, itemClass)
end)