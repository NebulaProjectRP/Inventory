AddCSLuaFile()

SWEP.PrintName = "Hands"
SWEP.Slot = 1
SWEP.SlotPos = 1
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false

SWEP.Author = "Gonzo"
SWEP.Contact = "Gonzo"
SWEP.Purpose = "Gonzo"
SWEP.Instructions = "Gonzo"

SWEP.WorldModel = "models/Items/item_item_crate_dynamic.mdl"
SWEP.ViewModel = "models/weapons/c_arms.mdl"
SWEP.UseHands = true

SWEP.Spawnable = false
SWEP.Primary = {
    ClipSize = -1,
    DefaultClip = -1,
    Automatic = false,
    Ammo = "none"
}

SWEP.Secondary = {
    ClipSize = -1,
    DefaultClip = -1,
    Automatic = true,
    Ammo = "none"
}

function SWEP:Initialize()
    self:SetHoldType("normal")
    if CLIENT then
        hook.Add("PreDrawHalos", self, function()
            self:ManageHalos()
        end)
    end
end

function SWEP:EvalEntity(ent)
    if (string.StartWith(ent:GetClass(), "neb_suitcrate_")) then
        return true, Color(255, 150, 50), "suit_" .. string.sub(ent:GetClass(), #"neb_suitcrate_" + 1)
    end

    if (ent:IsWeapon() and NebulaInv.Items["weapon_" .. ent:GetClass()]) then
        return true, Color(50, 255, 255), "weapon_" .. ent:GetClass()
    end
end

function SWEP:ManageHalos()
    local tr = util.QuickTrace(LocalPlayer():GetShootPos(), LocalPlayer():GetAimVector() * 128, LocalPlayer())
    local ent = tr.Entity
    if not IsValid(ent) then return end
    
    local can, col, item = self:EvalEntity(ent)
    if (can) then
        halo.Add({ent}, col, 4, 4, 1, true, true)
    end
end

function SWEP:PrimaryAttack()
    if CLIENT then return end
    local tr = util.QuickTrace(self:GetOwner():GetShootPos(), self:GetOwner():GetAimVector() * 128, self:GetOwner())
    local ent = tr.Entity
    if not IsValid(ent) then return end
    local can, col, item = self:EvalEntity(ent)

    if (can) then
        local b = self:GetOwner():addItem(item, 1)
        if b then
            local ref = NebulaInv.Items[item]
            DarkRP.notify(self:GetOwner(), 0, 4, "You have picked up a " .. ref.name)
            SafeRemoveEntity(ent)
        end
    end
    self:SetNextPrimaryFire(CurTime() + .5)
end

function SWEP:SecondaryAttack()
end

function SWEP:DrawHUD()
end

function SWEP:DrawWorldModel()
end

function SWEP:PreDrawViewModel()
    return false
end