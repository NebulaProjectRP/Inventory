local DEF = {}
DEF.Name = "Weapon"
DEF.Help = "It's a weapon, you kill people with it!"
DEF.Icon = 1

function DEF:ProcessWeapon(wep, data, ply, slot)
    if (data.data.kills) then
        wep.TrackKills = true
        wep.KillCounter = data.data.kills
        wep.InvSlot = slot
    end

    if !wep.IsTFA then return end
    for k, v in pairs(data.data) do
        if (k == "kills") then continue end
        NebulaInv.Mutators[k]:Resolve(wep, v, ply)
    end
end

if SERVER then
    util.AddNetworkString("NebulaInv:SyncKills")
    hook.Add("PlayerDeath", "NebulaInv.SaveKills", function(ply, inf, att)
        if inf.TrackKills then
            inf.KillCounter = inf.KillCounter + 1
            if (inf.InvSlot and att._loadout[inf.InvSlot]) then
                att._loadout[inf.InvSlot].data.kills = inf.KillCounter
                net.Start("NebulaInv:SyncKills", true)
                net.WriteString(inf.InvSlot)
                net.WriteUInt(inf.KillCounter, 16)
                net.Send(att)
            end
        end
    end)
end

net.Receive("NebulaInv:SyncKills", function()
    local slot = net.ReadString()
    local kills = net.ReadUInt(16)

    if (NebulaInv.Loadout[slot] and NebulaInv.Loadout[slot].data) then
        NebulaInv.Loadout[slot].data.kills = kills
    end
end)

function DEF:OnEquip(ply, ref, id, item, slot)
    local wep = ply:Give(ref.class)
    if (not table.IsEmpty(item.data)) then
        self:ProcessWeapon(wep, item, ply, slot)
    end
    return true
end

function DEF:OnUse(ply, ref, id, item)
    local wep = ply:Give(ref.class)
    if (not table.IsEmpty(item.data)) then
        self:ProcessWeapon(wep, item, ply)
    end
    return true
end

function DEF:OpenMenu(menu, item, slot)
    local ref = NebulaInv.Items[item.id]
    menu:AddOption("Equip Weapon", function()
        if (not ref.basic) then
            if (ref.rarity >= 4) then
                Derma_Message("You cannot use weapons with this rarity, you have to equip it in your weapon slots!", "NebulaRP", "Ok")
                return
            end

            if (not table.IsEmpty(item.data)) then
                Derma_Message("You cannot use weapons with mutators, you have to equip it in your weapon slots!", "NebulaRP", "Ok")
                return
            end
        end
        net.Start("Nebula.Inv:UseItem")
        net.WriteUInt(slot, 16)
        net.SendToServer()
    end)
end

if SERVER then
    util.AddNetworkString("Nebula.Inv:AddMutator")
end

NebulaInv.Mutators = {
    ["faster"] = {
        Name = "Desperated",
        Levels = {.05, 0.075, 0.1, 0.125, 0.15},
        Color = Color(192, 18, 18),
        Description = "Fire rate increased by %#",
        Display = function(mut, level)
            return string.Replace(mut.Description, "#", tostring(math.Round(mut.Levels[level] * 100)))
        end,
        Resolve = function(mut, wep, level, ply)
            if not wep.SetStatRawL then return end
            wep:SetStatRawL("Primary.RPM", wep:GetStatL("Primary.RPM") + wep:GetStatL("Primary.RPM") * mut.Levels[level])
            wep:ClearStatCacheL("Primary.RPM")
            net.Start("Nebula.Inv:AddMutator")
            net.WriteString(wep:GetClass())
            net.WriteString("Primary.RPM")
            net.WriteFloat(wep:GetStatL("Primary.RPM"))
            net.Send(ply)
        end
    },
    ["tankier"] = {
        Name = "MagMax",
        Levels = {.05, 0.1, 0.15, 0.2, 0.25},
        Color = Color(118, 201, 24),
        Description = "Increases magazine by %#",
        Display = function(mut, level)
            return string.Replace(mut.Description, "#", tostring(math.Round(mut.Levels[level] * 100)))
        end,
        Resolve = function(mut, wep, level, ply)
            if not wep.SetStatRawL then return end
            wep:SetStatRawL("Primary.ClipSize", wep:GetStatL("Primary.ClipSize") + math.ceil(wep:GetStatL("Primary.ClipSize") * mut.Levels[level]))
            wep:ClearStatCacheL("Primary.ClipSize")
            wep:SetClip1(wep:GetStatL("Primary.ClipSize") + math.ceil(wep:GetStatL("Primary.ClipSize") * mut.Levels[level]))
            net.Start("Nebula.Inv:AddMutator")
            net.WriteString(wep:GetClass())
            net.WriteString("Primary.ClipSize")
            net.WriteFloat(wep:GetStatL("Primary.ClipSize"))
            net.Send(ply)
        end
    },
    ["critical"] = {
        Name = "Precise",
        Levels = {0.1, 0.125, 0.15, 0.175, 0.2},
        Color = Color(214, 157, 0),
        Description = "%# chances of doubling your damage",
        Display = function(mut, level)
            return string.Replace(mut.Description, "#", tostring(math.Round(mut.Levels[level] * 100)))
        end,
        Resolve = function(mut, wep, level)
            hook.Add("EntityTakeDamage", wep, function(w, ent, dmg)
                if (dmg:GetInflictor() != w) then return end
                local dice = math.Rand(0, 1)
                if dice <= mut.Levels[level] then
                    ent:EmitSound("suits/shield_spawn.mp3")
                    dmg:ScaleDamage(2)
                end
            end)
        end
    },
    ["savage"] = {
        Name = "Tossing",
        Levels = {20, 17, 15, 12, 9},
        Color = Color(0, 75, 214),
        Description = "Every # shoots you will shoot twice",
        Display = function(mut, level)
            return string.Replace(mut.Description, "#", mut.Levels[level])
        end,
        Resolve = function(mut, wep, level)
            hook.Add("EntityFireBullets", wep, function(w, ent, bullet)
                local weapon = ent:IsWeapon() and ent or bullet.Attacker:IsPlayer() and bullet.Attacker:GetActiveWeapon() or bullet.Attacker
                if (weapon != w) then return end
                if not w.bucket then
                    w.bucket = 0
                end
                w.bucket = w.bucket + bullet.Num
                if (w.bucket >= mut.Levels[level]) then
                    w.bucket = 0
                    bullet.Num = bullet.Num * 2
                    bullet.Attacker:EmitSound("suits/ghost_solid.mp3")
                end
            end)
        end
    },
    ["fuzzy"] = {
        Name = "Influence",
        Levels = {.05, .075, 0.1, 0.125, 0.15},
        Color = Color(0, 214, 71),
        Description = "%# chances to drug the target",
        Display = function(mut, level)
            return string.Replace(mut.Description, "#", tostring(math.Round(mut.Levels[level] * 100)))
        end,
        Resolve = function(mut, wep, level)
            hook.Add("EntityTakeDamage", wep, function(w, ent, dmg)
                if (dmg:GetInflictor() != w) then return end
                local dice = math.Rand(0, 1)
                if dice <= mut.Levels[level] then
                    ent:addBuff("weed", 1)
                end
            end)
        end
    },
    ["hotter"] = {
        Name = "Sun Core",
        Levels = {.05, .075, 0.1, 0.125, 0.15},
        Color = Color(214, 128, 0),
        Description = "%# chances to burn the target",
        Display = function(mut, level)
            return string.Replace(mut.Description, "#", tostring(math.Round(mut.Levels[level] * 100)))
        end,
        Resolve = function(mut, wep, level)
            hook.Add("EntityTakeDamage", wep, function(w, ent, dmg)
                if (dmg:GetInflictor() != w) then return end
                local dice = math.Rand(0, 1)
                if dice <= mut.Levels[level] then
                    ent:addBuff("ignite", 1, w:GetOwner())
                end
            end)
        end
    },
    ["freezer"] = {
        Name = "0°F",
        Levels = {.03, .04, 0.05, 0.06, 0.07},
        Color = Color(0, 207, 214),
        Description = "%# chances to freeze the target",
        Display = function(mut, level)
            return string.Replace(mut.Description, "#", tostring(math.Round(mut.Levels[level] * 100)))
        end,
        Resolve = function(mut, wep, level)
            hook.Add("EntityTakeDamage", wep, function(w, ent, dmg)
                if (dmg:GetInflictor() != w) then return end
                local dice = math.Rand(0, 1)
                if dice <= mut.Levels[level] then
                    ent:addBuff("ice", 1, w:GetOwner())
                end
            end)
        end
    }
}

function DEF:Generate(id, last)

    local ref = NebulaInv.Items[id]
    if (ref.basic) then
        return {}
    end

    local weapon = last or {}
    local dice = math.Round(random.Number(0, 50))
    if (dice < 15) then
        return weapon
    end

    weapon.kills = 0

    local i = 15
    for k, v in pairs(NebulaInv.Mutators) do
        if (dice <= i) then
            local level = 1
            while (math.random(1, 100) < 30 and level < 5) do
                level = level + 1
            end
            weapon[k] = level
            found = true
            break
        end
        i = i + 5
    end

    if (math.random(1, 100) < 30) then
        weapon = self:Generate(id, weapon)
    end

    return weapon
end

function DEF:CreateEditor(panel, container, data)
    panel:AddControl("DLabel", {
        Text = "Entity/Weapon Class",
        Font = NebulaUI:Font(20),
        TextColor = color_white,
        Tall = 20,
    })
    panel.ClassName = panel:AddControl("nebula.textentry", {
        PlaceholderText = "weapon_physgun",
        Text = data.class or "",
        Tall = 28,
    })
end

function DEF:OnUnequip(ply, item)
    local hasWeapon = ply:HasWeapon(item.class)
    if (not hasWeapon) then return false end

    ply:StripWeapon(item.class)
    ply:addItem(item.ID, 1)
end

function DEF:Build(data, id)
    local wep = weapons.GetStored(data.classname)
    if not wep then
        MsgN("[Nebula] Weapon " .. data.classname .. " not found!")
        return
    end
    local item = table.Copy(data)
    item.name = wep.PrintName
    item.class = data.classname
    return item
end

NebulaInv:RegisterType("weapon", DEF)

if CLIENT then
    net.Receive("Nebula.Inv:AddMutator", function()
        local wep = net.ReadString()
        local slot = net.ReadString()
        local val = net.ReadFloat()

        local function insertMutator(wep, slot, val)

            if not IsValid(LocalPlayer()) or not LocalPlayer().GetWeapon then
                timer.Simple(1, function()
                    insertMutator(wep, slot, val)
                end)
                return
            end
            
            local wep_ent = LocalPlayer():GetWeapon(wep)
            if not IsValid(wep_ent) then
                timer.Simple(0.1, function()
                    insertMutator(wep, slot, val)
                end)
                return
            end

            wep_ent:SetStatRawL(slot, val)
            wep_ent:ClearStatCacheL(slot)
        end

        insertMutator(wep, slot, val)
    end)
end
