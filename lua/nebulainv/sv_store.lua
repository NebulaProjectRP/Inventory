
concommand.Add("nebula_buy", function(ply, cmd, args)
    local kind = tonumber(args[1])
    local store = NebulaStore
    if (kind == 1) then
        if (not store.SeasonPass.enabled) then
            return
        end

        if (ply:getCredits() >= store.SeasonPass.credits) then
        end
    elseif (kind == 2) then
        local id = args[2]
        if (store.QueueItems[id] and ply:getCredits() >= store.QueueItems[id].credits) then
        end
    elseif (kind == 3) then
        local category = args[2]
        local itemid = tonumber(args[3])
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