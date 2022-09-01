util.AddNetworkString("NebulaInv.Trade:SendInvitation")
util.AddNetworkString("NebulaInv.Trade:SendResponse")
util.AddNetworkString("NebulaInv.Trade:InsertItem")
util.AddNetworkString("NebulaInv.Trade:SetMoney")
util.AddNetworkString("NebulaInv.Trade:SetCredits")
util.AddNetworkString("NebulaInv.Trade:ChangeStatus")
util.AddNetworkString("NebulaInv.Trade:Start")
util.AddNetworkString("NebulaInv.Trade:Finish")
util.AddNetworkString("NebulaInv.Trade:SendMessage")
util.AddNetworkString("NebulaInv.Trade:SyncStuff")
util.AddNetworkString("NebulaInv.Trade:UpdateInfo")
util.AddNetworkString("ASAP.Trade:ToggleVoiceChat")
util.AddNetworkString("NebulaInv.Trade:Quit")
util.AddNetworkString("NebulaInv.Trade:UpdateInfoCredits")

NebulaInv.Trade = {
    Sessions = {}
}

function NebulaInv.Trade:StartTrade(ply, target)
    --I normally just know how to make things works instantly, always with creative solutions
    --This time i was facing this awful issue, for trade ids, i use os.time(), that returns time
    --in epoch on seconds, that means it only changes every second, so if 2 trades happens at the
    --same second, shit gets real and even me have no idea how broken that would be
    --How did i solve it? I just add seconds until nobody has this id, it would fix the issue
    --and the only drawback it's that the date will be innacurate just by few seconds
    local id = os.time()

    while self.Sessions[id] do
        id = id + 1
    end

    ply._tradeID = id
    ply._tradeSlot = 1
    target._tradeID = id
    target._tradeSlot = 2
    ply:SetNWBool("Trade.Ready", false)
    target:SetNWBool("Trade.Ready", false)
    ply._tradeHasInvite = nil
    target._tradeHasInvite = nil

    self.Sessions[id] = {
        Items = {{}, {}},
        Money = {0, 0},
        Credits = {0, 0},
        Players = {ply, target},
        ChatLog = {}
    }

    local targets = {ply, target}

    net.Start("NebulaInv.Trade:Start")
    net.WriteTable(targets)
    net.Send(targets)

    hook.Add("PlayerCanHearPlayersVoice", ply, function(_, list, talk)
        if not ply:GetNWBool("Trade.Voice") or not target:GetNWBool("Trade.Voice") then return end
        if (list == ply or list == target) and (talk == ply or talk == target) then return true end
    end)
end

function NebulaInv.Trade:FinishTrade(ply)
    local session = self.Sessions[ply._tradeID]

    if not session then
        ply._tradeID = nil
        net.Start("NebulaInv.Trade:Quit")
        net.Send(ply)

        return
    end

    if session.Players[1]:GetNWBool("Trade.Ready", false) and session.Players[2]:GetNWBool("Trade.Ready", false) then
        session.Players[1]:SetNWBool("Trade.Ready", false)
        session.Players[2]:SetNWBool("Trade.Ready", false)

        for id = 1, 2 do
            local buildList = {}

            for k, v in pairs(session.Items[id]) do
                table.insert(buildList, {k, v.am})
            end

            local could = session.Players[id]:takeItem(buildList)

            if not could then
                DarkRP.notify(session.Players[id], 1, 4, "An error occurred while resolving the trade, items won't be modified.")
                break
            end
        end

        for id = 1, 2 do
            for k, v in pairs(session.Items[id]) do
                local target = session.Players[id == 1 and 2 or 1]
                target:giveItem(v.id, v.am, v.data)
            end

            local moneyAmount = session.Money[id]

            if moneyAmount > 0 then
                local target = session.Players[id == 1 and 2 or 1]
                if (session.Players[id]:canAfford(moneyAmount)) then
                    session.Players[id]:addMoney(-moneyAmount)
                    target:addMoney(moneyAmount)
                else
                    DarkRP.notify(session.Players[id], 1, 4, "An error occurred while resolving the trade, money won't be modified.")
                end
            end

            local creditsAmount = session.Credits[id]

            if creditsAmount > 0 then
                local target = session.Players[id == 1 and 2 or 1]
                if (session.Players[id]:getCredits() >= creditsAmount) then
                    session.Players[id]:addCredits(-creditsAmount, "Trade with " .. target:Nick())
                    target:addCredits(creditsAmount, "Trade with " .. session.Players[id]:Nick())
                else
                    DarkRP.notify(session.Players[id], 1, 4, "An error occurred while resolving the trade, credits won't be modified.")
                end
            end
        end

        local a, b = session.Players[1], session.Players[2]
        net.Start("NebulaInv.Trade:Finish")
        net.WriteInt(1, 4)

        net.Send({a, b})

        local chatlog = {}

        for k, v in pairs(session.ChatLog) do
            table.insert(chatlog, {
                Owner = a == v.Owner and 1 or 2,
                Message = sql.SQLStr(v.Message, true)
            })
        end

        local data = {
            key = "gonzo_built_it",
            a = tostring(a:SteamID64()),
            b = tostring(b:SteamID64()),
            id = tostring(ply._tradeID),
            date = tostring(os.time()),
            tradeinfo = util.TableToJSON({
                Items = table.Copy(session.Items),
                Money = session.Money,
                Credits = session.Credits,
                ChatLog = chatlog
            })
        }

        NebulaLogs:add("Trade", a, b, data.id)
        net.Start("NebulaInv.Trade:Quit")

        net.Send({a, b})

        http.Post(NebulaAPI.HOST .. "trade/upload", data)
        self.Sessions[a._tradeID] = nil
        a._tradeID = nil
        b._tradeID = nil
        a._tradeHasInvite = nil
        b._tradeHasInvite = nil
        ply._tradeID = nil
    end
end

net.Receive("NebulaInv.Trade:InsertItem", function(l, ply)
    local slot = net.ReadUInt(16)
    local amount = net.ReadUInt(16)

    if ply:getInventory()[slot] and ply:getInventory()[slot].am >= amount then
        local tradeSession = NebulaInv.Trade.Sessions[ply._tradeID]

        if not tradeSession then
            ply._tradeID = nil
            net.Start("NebulaInv.Trade:Quit")
            net.Send(ply)

            return
        end

        tradeSession.Items[ply._tradeSlot][slot] = amount > 0 and table.Copy(ply:getInventory()[slot]) or nil

        if amount > 0 then
            tradeSession.Items[ply._tradeSlot][slot].am = amount
        end

        net.Start("NebulaInv.Trade:SyncStuff")
        net.WriteTable(tradeSession)
        net.Send(tradeSession.Players)
        tradeSession.Players[1]:SetNWBool("Trade.Ready", false)
        tradeSession.Players[2]:SetNWBool("Trade.Ready", false)
        net.Start("NebulaInv.Trade:UpdateInfo")
        net.WriteBool(true)
        net.WriteEntity(ply)
        net.WriteBool(tradeSession.Items[ply._tradeSlot][slot] ~= nil)
        net.WriteTable(tradeSession.Items[ply._tradeSlot][slot] or {})
        net.Send(tradeSession.Players)
    end
end)

net.Receive("NebulaInv.Trade:ChangeStatus", function(l, ply)
    local state = net.ReadBool()
    ply:SetNWBool("Trade.Ready", state)
end)

net.Receive("NebulaInv.Trade:Finish", function(l, ply)
    NebulaInv.Trade:FinishTrade(ply)
end)

net.Receive("NebulaInv.Trade:SetMoney", function(l, ply)
    local amount = net.ReadUInt(32)
    if amount < 0 then return end

    if ply:canAfford(amount) then
        local tradeSession = NebulaInv.Trade.Sessions[ply._tradeID]
        tradeSession.Money[ply._tradeSlot] = amount
        net.Start("NebulaInv.Trade:SyncStuff")
        net.WriteTable(tradeSession)
        net.Send(tradeSession.Players)
        tradeSession.Players[1]:SetNWBool("Trade.Ready", false)
        tradeSession.Players[2]:SetNWBool("Trade.Ready", false)
        net.Start("NebulaInv.Trade:UpdateInfo")
        net.WriteBool(false)
        net.WriteEntity(ply)
        net.WriteUInt(amount, 32)
        net.WriteBool(true)
        net.Send(tradeSession.Players)
    end
end)

net.Receive("NebulaInv.Trade:SetCredits", function(l, ply)
    local amount = net.ReadInt(32)
    if amount < 0 then return end

    if ply:getCredits() >= amount then
        local tradeSession = NebulaInv.Trade.Sessions[ply._tradeID]
        tradeSession.Credits[ply._tradeSlot] = amount
        net.Start("NebulaInv.Trade:SyncStuff")
        net.WriteTable(tradeSession)
        net.Send(tradeSession.Players)
        tradeSession.Players[1]:SetNWBool("Trade.Ready", false)
        tradeSession.Players[2]:SetNWBool("Trade.Ready", false)
        net.Start("NebulaInv.Trade:UpdateInfoCredits")
        net.WriteEntity(ply)
        net.WriteInt(amount, 32)
        net.Send(tradeSession.Players)
    end
end)

net.Receive("NebulaInv.Trade:SendInvitation", function(l, ply)
    local target = net.ReadEntity()

    if timer.Exists(ply:SteamID64() .. "_tradeRequest") then
        ply:SendLua("Derma_Message('Wait for the other player to accept/decline your invitation first', 'Error', 'ok')")

        return
    end

    if target._tradeID or target._tradeHasInvite then
        ply:SendLua("Derma_Message('This player is busy', 'Error', 'ok')")

        return
    end

    target._tradeHasInvite = ply
    ply._tradeHasInvite = target
    net.Start("NebulaInv.Trade:SendInvitation")
    net.WriteEntity(ply)
    net.Send(target)

    timer.Create(ply:SteamID64() .. "_tradeRequest", 20, 1, function()
        if IsValid(ply) then
            ply._tradeHasInvite = nil
            ply:SendLua("Derma_Message('Your trade offer timed out', 'Oh noes')")

            if IsValid(target) then
                target._tradeHasInvite = nil
            end
        end
    end)
end)

net.Receive("NebulaInv.Trade:SendResponse", function(l, ply)
    local res = net.ReadBool()
    local target = ply._tradeHasInvite

    if IsValid(target) then
        if target._tradeID then return end

        if res then
            if not NebulaInv.Trade then
                NebulaInv.Trade = {
                    Sessions = {}
                }
            end

            NebulaInv.Trade:StartTrade(ply, target)
        else
            ply._tradeHasInvite = nil
            target._tradeHasInvite = nil
            target:SendLua("Derma_Message('Your trade offer has been declined', 'Oh noes')")
        end

        timer.Remove(target:SteamID64() .. "_tradeRequest")
    end
end)

net.Receive("NebulaInv.Trade:SendMessage", function(l, ply)
    local msg = net.ReadString()
    msg = string.Replace(msg, '"', "")

    if ply._tradeID then
        local session = NebulaInv.Trade.Sessions[ply._tradeID]

        if not session then
            ply._tradeID = nil
            net.Start("NebulaInv.Trade:Quit")
            net.Send(ply)

            return
        end

        table.insert(session.ChatLog, {
            Owner = ply,
            Message = msg
        })

        net.Start("NebulaInv.Trade:SendMessage")
        net.WriteString(msg)
        net.Send(session.Players[1] == ply and session.Players[2] or session.Players[1])
    end
end)

net.Receive("ASAP.Trade:ToggleVoiceChat", function(l, ply)
    ply:SetNWBool("Trade.Voice", not ply:GetNWBool("Trade.Voice", false))
end)

net.Receive("NebulaInv.Trade:Quit", function(l, ply)
    if ply._tradeID then
        local session = NebulaInv.Trade.Sessions[ply._tradeID]
        local otherply = session.Players[1] == ply and session.Players[2] or session.Players[1]

        if IsValid(otherply) then
            net.Start("NebulaInv.Trade:Quit")
            net.Send(otherply)
            DarkRP.notify(otherply, 0, 5, ply:Nick() .. " has cancelled the trade.")
            otherply._tradeID = nil
        end

        NebulaInv.Trade.Sessions[ply._tradeID] = nil
        ply._tradeID = nil
    end
end)

hook.Add("PlayerDisconnected", "NebulaInv.TradeQuit", function(ply)
    if ply._tradeID then
        local session = NebulaInv.Trade.Sessions[ply._tradeID]
        local target = session.Players[1] == ply and session.Players[2] or session.Players[1]
        net.Start("NebulaInv.Trade:Quit")
        net.Send(target)
        NebulaInv.Trade.Sessions[ply._tradeID] = nil
        target._tradeID = nil
    end
end)

hook.Add("canChatCommand" , "Neb.DontDrop", function(ply, cmd, args)
    if (ply._tradeID) then
        return false
    end
end)