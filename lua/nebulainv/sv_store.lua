util.AddNetworkString("NebulaRP.StoreBuy")

net.Receive("NebulaRP.StoreBuy", function(l, ply)
    local kind = net.ReadUInt(3)
    local store = NebulaStore
    if (kind == 1) then
        if (not store.SeasonPass.enabled) then
            return
        end

        if (ply:getCredits() >= store.SeasonPass.credits) then
        end
    elseif (kind == 2) then
        local id = net.ReadUInt(8)
        if (store.QueueItems[id] and ply:getCredits() >= store.QueueItems[id].credits) then
            local data = NebulaInv.Types.weapon:Generate(store.QueueItems[id].itemID)
            data.lives = NebulaInv.Mutators["lives"]:SetValue(math.random(1, 5))
            ply:giveItem(store.QueueItems[id].itemID, 1, data)
            ply:addCredits(-store.QueueItems[id].credits, "Item store purchase")
        end
    elseif (kind == 3) then
        local category = net.ReadUInt(8)
        local itemid = net.ReadUInt(8)
        local item = store.Shop[category].Items[itemid]
        if not item then return end
        if (item.credits and ply:getCredits() >= item.credits or ply:canAfford(item.money)) then
            local ref = NebulaInv.Items[item.itemID]
            ply:addItem(item.itemID, 1)
            ply:addMoney(-item.money)
            DarkRP.notify(ply, 0, 4, "You have purchased " .. ref.name .. " for " .. DarkRP.formatMoney(item.money) .. ".")
        end
    end
end)