util.AddNetworkString("NebulaInv.RequestAlchemy")

net.Receive("NebulaInv.RequestAlchemy", function(l, ply)
    --Item we want to transmutate
    local slot = net.ReadUInt(16)
    local itemOG = ply:getInventory()[slot]

    if not itemOG then
        MsgN("[Transmutator] Invalid slot")

        return
    end

    local mut = net.ReadString()

    if not itemOG.data[mut] then
        MsgN("[Transmutator] Item doesn't have mutator ", mut)

        return
    end

    local ref = NebulaInv.Items[itemOG.id]

    --Reject monkey
    if not ref or ref.type ~= "weapon" then
        MsgN("[Transmutator] Item is not a weapon")

        return
    end

    local baseLevel = itemOG.data[mut]
    local itemCount = net.ReadUInt(3)
    local couldTransform = baseLevel
    local bagItems = {}

    for k = 1, itemCount do
        local nslot = net.ReadUInt(16)

        if slot == nslot then
            MsgN("[Transmutator] Trying to use the weapon as ingredient")

            return
        end

        if table.HasValue(bagItems, nslot) then
            MsgN("[Transmutator] Trying to use an item twice")

            return
        end

        local bitem = ply:getInventory()[nslot]
        if not bitem then return end

        --If items are different we can't transform
        if not bitem.data[mut] or bitem.data[mut] ~= baseLevel then
            MsgN("[Transmutator] Items are not same level, hence cannot mutate")

            return
        end

        couldTransform = couldTransform - 1
        table.insert(bagItems, {nslot, 1})
    end

    if couldTransform <= 0 then
        --Level up the weapon and copy of it for networking purposes, RIP original bytes
        itemOG.data[mut] = itemOG.data[mut] + 1
        local newItem = table.Copy(itemOG)
        table.insert(bagItems, {slot, 1})
        --We send a list of items since it would affect ordering
        ply:takeItem(bagItems)
        --We give the same old weapon but with a new mutator
        ply:giveItem(newItem.id, newItem.amount or 1, newItem.data)
    end
end)