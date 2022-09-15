util.AddNetworkString("Nebula.Inv:CreateItem")
util.AddNetworkString("Nebula.Inv:NetworkItem")
util.AddNetworkString("Nebula.Inv:UseItem")
util.AddNetworkString("Nebula.Inv:DeleteItem")
util.AddNetworkString("Nebula.Inv:GiftItem")
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
util.AddNetworkString("NebulaInv:SendMoney")
util.AddNetworkString("Nebula.Inv:ToggleFavorite")
util.AddNetworkString("Nebula.Inv:PickupSuit")
util.AddNetworkString("Nebula.Inv:UnboxGobblegums")


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
    if (not ply:IsSuperAdmin()) then return end

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
    local isAll = net.ReadBool()
    local amount = net.ReadUInt(16)
    local total = isAll and (amount > 0 and amount or -1) or 1

    if (ply:getInventory()[slot]) then
        local lam = total == -1 and ply:getInventory()[slot].am or total
        if (ply:getInventory()[slot].am < lam) then
            return
        end
        local rarity = NebulaInv.Items[ply:getInventory()[slot].id].rarity
        local credits = lam * rarity
        ply:GiveCredits(credits * 25)
        ply:AddXP(credits * 10, "<rainbow=4>+" .. (credits * 25) .. "</rainbow> credits.")
    end

    ply:takeItem(slot, total, true)
end)

net.Receive("Nebula.Inv:GiftItem", function(l, ply)
    local slot = net.ReadUInt(16)
    local target = net.ReadEntity()
    local amount = net.ReadUInt(16)
    ply:giftItem(slot, target, amount)
end)

net.Receive("Nebula.Inv:DropItem", function(l, ply)
    local slot = net.ReadUInt(16)
    ply:dropItem(slot, 1)
end)

net.Receive("Nebula.Inv:RemoveSlot", function(l, ply)
    local slot = net.ReadString()
    if (not ply._loadout or not ply._loadout[slot]) then return end
    local item = ply._loadout[slot]
    local ref = NebulaInv.Items[item.id]
    local type = NebulaInv.Types[ref.type]
    if (type.OnUnequip) then
        type:OnUnequip(ply, ref, item.id, item)
    end
    ply:giveItem(item.id, 1, item.data or {})
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

net.Receive("NebulaInv:SendMoney", function(l, ply)
    local target = net.ReadEntity()
    local amount = net.ReadUInt(32)

    if (ply == target) then return end
    if (not ply:canAfford(amount)) then return end

    ply:addMoney(-amount)
    target:addMoney(amount)

    hook.Run("playerGaveMoney", ply, target, amount)
end)

net.Receive("Nebula.Inv:ToggleFavorite", function(l, ply)
    local slot = net.ReadUInt(16)
    local inv = ply:getInventory()
    if (not inv[slot]) then return end

    if (inv[slot].fav) then
        inv[slot].fav = nil
    else
        inv[slot].fav = true
    end

    ply:saveInventory()
end)

net.Receive("Nebula.Inv:UnboxGobblegums", function(len, ply)
    local slot = net.ReadUInt(16)
    local item = ply:getInventory()[slot]
    if not slot then return end

    local amount = 4

    local ref = NebulaInv.Items[item.id]
    if (ref.type ~= "case") then return end

    local gobbles = NebulaInv:UnboxGobble(amount)
    if not gobbles then return end

    net.Start("Nebula.Inv:UnboxGobblegums")
    net.WriteUInt(amount, 6)
    for k ,v in pairs(gobbles) do
        net.WriteUInt(v, 6)
    end
    net.Send(ply)

    ply:takeItem(slot, 1)
end)

// Concommands

concommand.Add("neb_giveall", function(ply, cmd, args)
    if (not ply:IsSuperAdmin()) then return end
    local target = p(1)

    for id, data in pairs(NebulaInv.Items) do
        target:giveItem(id, 1)
    end
end)

concommand.Add("neb_giveitem", function(ply, cmd, args)
    if IsValid(ply) then return end

    local target = player.GetBySteamID64(args[1])

    if not IsValid(target) then return end
    
    local id = args[2]
    local am = tonumber(args[3])
    
    if not (id or am) then return end

    if NebulaInv.Items[id] then
        target:giveItem(id, am)
        MsgN("[Nebula] " .. target:SteamID64() .. " has been given " .. am .. " " .. id .. ".")
    end
end, nil, "Usage: neb_giveitem <steamid64> <id> <amount>")