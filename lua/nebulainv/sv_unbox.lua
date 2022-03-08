require("securerandom")

NebulaInv.Cases = {}

local function addCase(id, rarity)
    local r = 6 - rarity
    local data = {
        rarity = rarity,
        chances = math.Round(random.Number(r * 5, r * 10)),
        content = math.random(1, 50)
    }
    table.insert(NebulaInv.Cases[id], data)
end

for k = 1, 3 do
    NebulaInv.Cases[k] = {}
    for i = 1, math.random(10, 15) do
        addCase(k, 1)
    end

    for i = 1, math.random(5, 10) do
        addCase(k, 2)
    end

    for i = 1, math.random(1, 5) do
        addCase(k, 3)
    end

    for i = 1, math.random(1, 2) do
        addCase(k, 4)
    end

    addCase(k, 5)
end

NebulaInv.TotalCache = {}
function NebulaInv:Unbox(ply, case_id)
    luck = math.Clamp(ply.luckValue or 0, -100, 100)
    
    local case = self.Cases[case_id]
    if not case then
        MsgN("[NebulaInv] Case not found: " .. case_id)
        return false
    end

    if not self.TotalCache[case_id] then
        self.TotalCache[case_id] = 0
        for k, v in pairs(case) do
            self.TotalCache[case_id] = self.TotalCache[case_id] + v.chances
        end
    end
    
    local maxItems = self.TotalCache[case_id]
    local luck = luck / 100
    local ran = math.Round(random.Number(maxItems * (luck) + 1, maxItems))
    local total = 0
    local winner, id

    for k, v in SortedPairsByMemberValue(case, "chances", true) do
        total = total + v.chances
        if (ran <= total) then
            winner = v
            break
        end
    end

    if (winner.rarity < 3) then
        ply.luckValue = (ply.luckValue or 0) + (2.5 + 3 - winner.rarity)
    elseif (winner.rarity == 5) then
        ply.luckValue = 0
    elseif (winner.rarity == 4) then
        ply.luckValue = ply.luckValue / 2
    end
    
    ply.luckValue = math.Clamp(ply.luckValue, -100, 100)
    local could = ply:addItem(winner.content, 1)
    if (not could) then
        ply:addItem(winner.content, 1)
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
    MsgN("[NebulaInv] Execution time for x" .. steps .. " unboxes: " .. (SysTime() - now))
    MsgN("[NebulaInv] Average random number: " .. math.Round(promedio) .. " (%" .. math.Round(100 * (promedio / maxr), 2) .. ")")
    MsgN("[NebulaInv] Max Items: " .. maxr)
    MsgN("[NebulaInv] Chances: ")
    for k, v in pairs(chances) do
        MsgN("[" .. k .. "]=>\t" .. (100 * math.Round(v / steps, 2)) .. "%\t=> " .. v)
        gained = gained + v
    end
    MsgN("[X]=>\t" .. (fails .. " fails"))
    
    if (args[3]) then
        local luck = args[1] or 50
        
        MsgN("\n")
        MsgN("[NebulaInv] Execution time for x" .. steps .. " unboxes: " .. (SysTime() - now))
        MsgN("[NebulaInv] Chances with %" .. luck .. " luck:")
        runBenchmark(luck)
        for k, v in pairs(chances) do
            MsgN("[" .. k .. "]=>\t" .. (100 * math.Round(v / steps, 2)) .. "%\t=> " .. v)
        end
        MsgN("[X]=>\t" .. (fails .. " fails"))
        MsgN("\n")
        MsgN("[NebulaInv] Execution time for x" .. steps .. " unboxes: " .. (SysTime() - now))
        MsgN("[NebulaInv] Chances with -%" .. luck .. " luck:")
        runBenchmark(-luck)
        for k, v in pairs(chances) do
            MsgN("[" .. k .. "]=>\t" .. (100 * math.Round(v / steps, 2)) .. "%\t=> " .. v)
        end
        MsgN("[X]=>\t" .. (fails .. " fails"))
    end

    MsgN("[L]=>\t" .. p(1).luckValue)
end)