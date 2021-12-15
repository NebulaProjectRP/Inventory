util.AddNetworkString("Nebula.Inv:CreateItem")
util.AddNetworkString("Nebula.Inv:UseItem")
util.AddNetworkString("Nebula.Inv:DropItem")
util.AddNetworkString("Nebula.Inv:RemoveItem")

hook.Add("DatabaseCreateTables", "NebulaInventory", function()
    NebulaDriver:MySQLCreateTable("inventories", {
        items = "TEXT DEFAULT '{}' NOT NULL",
        loadout = "TEXT DEFAULT '{}' NOT NULL",
        steamid = "VARCHAR(22)"
    }, "steamid")

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

