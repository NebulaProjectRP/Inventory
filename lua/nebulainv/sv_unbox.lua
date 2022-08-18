if file.Exists("lua/bin/gmsv_securerandom_linux.dll", "MOD") then
    require("securerandom")
else
    random = {
        Number = function(a, b)
            return math.Rand(a, b)
        end
    }
end

NebulaInv.TotalCache = {}
function NebulaInv:Unbox(ply, case_id)
    luck = math.Clamp(ply.luckValue or 0, -100, 100)

    local case = self.Items[case_id].items
    if not case then
        MsgN("[Nebula] Case has not been configurated: " .. case_id)
        return false
    end

    if not self.TotalCache[case_id] then
        self.TotalCache[case_id] = 0
        for k, v in pairs(case) do
            self.TotalCache[case_id] = self.TotalCache[case_id] + v
        end
    end

    local maxItems = self.TotalCache[case_id]
    luck = luck / 100
    local ran = math.Round(random.Number(maxItems * luck + 1, maxItems))
    local total = 0
    local winner

    for k, v in SortedPairsByValue(case, true) do
        total = total + v
        if (ran <= total) then
            winner = k
            break
        end
    end

    local parity = ran / maxItems

    if (parity < .4) then
        ply.luckValue = (ply.luckValue or 0) + (2.5 + 5 * (1 - parity))
    elseif (parity < .75) then
        ply.luckValue = (ply.luckValue or 0) / 2
    elseif (parity < 1) then
        ply.luckValue = 0
    end

    ply.luckValue = math.Clamp(ply.luckValue, -100, 100)
    local ref = NebulaInv.Items[winner]
    local data = {}
    if (ref.type == "weapon") then
        data = NebulaInv.Types.weapon:Generate(winner)
    end
    local could = ply:addItem(winner, 1, data)
    if (not could) then
        ply:addItem(case_id, 1)
        return false
    end
    return winner, ran, self.TotalCache[case_id]
end

concommand.Add("nebula_unbox_benchmark", function(ply, cmd, args)
    if (IsValid(ply)) then return end

    //p(1).luckValue = 0
    local chances = {0, 0, 0, 0, 0}
    local fails = 0
    local promedio = 0
    local maxr = 0
    local steps = args[2] or 10
    local now = SysTime()

    local function runBenchmark(luck)

        chances = {0, 0, 0, 0, 0}
        fails = 0
        promedio = 0
        maxr = 0
        now = SysTime()

        for k = 1, steps do
            local winner, ran, max = NebulaInv:Unbox(p(1), 1, luck)
            if not winner then
                fails = fails + 1
                continue
            end
            chances[winner.rarity] = chances[winner.rarity] + 1
            if (promedio == 0) then
                promedio = ran
                maxr = max
            else
                promedio = (promedio + ran) / 2
                maxr = (maxr + max) / 2
            end
        end
    end

    runBenchmark(0)
    local gained = 0
    MsgN("[Nebula] Execution time for x" .. steps .. " unboxes: " .. (SysTime() - now))
    MsgN("[Nebula] Average random number: " .. math.Round(promedio) .. " (%" .. math.Round(100 * (promedio / maxr), 2) .. ")")
    MsgN("[Nebula] Max Items: " .. maxr)
    MsgN("[Nebula] Chances: ")
    for k, v in pairs(chances) do
        MsgN("[" .. k .. "]=>\t" .. (100 * math.Round(v / steps, 2)) .. "%\t=> " .. v)
        gained = gained + v
    end
    MsgN("[X]=>\t" .. (fails .. " fails"))
    
    if (args[3]) then
        local luck = args[1] or 50
        
        MsgN("\n")
        MsgN("[Nebula] Execution time for x" .. steps .. " unboxes: " .. (SysTime() - now))
        MsgN("[Nebula] Chances with %" .. luck .. " luck:")
        runBenchmark(luck)
        for k, v in pairs(chances) do
            MsgN("[" .. k .. "]=>\t" .. (100 * math.Round(v / steps, 2)) .. "%\t=> " .. v)
        end
        MsgN("[X]=>\t" .. (fails .. " fails"))
        MsgN("\n")
        MsgN("[Nebula] Execution time for x" .. steps .. " unboxes: " .. (SysTime() - now))
        MsgN("[Nebula] Chances with -%" .. luck .. " luck:")
        runBenchmark(-luck)
        for k, v in pairs(chances) do
            MsgN("[" .. k .. "]=>\t" .. (100 * math.Round(v / steps, 2)) .. "%\t=> " .. v)
        end
        MsgN("[X]=>\t" .. (fails .. " fails"))
    end

    MsgN("[L]=>\t" .. p(1).luckValue)
end)