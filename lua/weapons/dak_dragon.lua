SWEP.Base = "dak_gun_base"

SWEP.PrintName = "M47 Dragon"
SWEP.Instructions = "staring contest consolidation prize, Caliber: 140mm, Velocity: 200m/s, Damage: 17 vs armor, RPM: 30, Pen: 300mm"
SWEP.Category = "DakTank"

SWEP.Spawnable = true
SWEP.AdminOnly = true

SWEP.ViewModel  = "models/weapons/c_rpg.mdl"
SWEP.WorldModel = "models/weapons/w_rocket_launcher.mdl"

SWEP.Primary.ClipSize		= 1
SWEP.Primary.DefaultClip	= 2
SWEP.Primary.Automatic		= true
SWEP.Primary.Ammo			= "RPG_Round"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.HoldType = "rpg"
SWEP.Slot = 5

-- Gun info
SWEP.Spread = 0.05 -- 0.1 for pistols, 0.075 for smgs, 0.05 for rifles
SWEP.PrimaryCooldown = 1
SWEP.FireSound = "daktanks/extra/76mmUSA2.mp3"
SWEP.IsPistol = false
SWEP.heavyweapon = true

-- Shell info
SWEP.DakCaliber = 140
SWEP.DakShellType = "ATGM"
SWEP.DakPenLossPerMeter = 0.0
SWEP.DakExplosive = true
SWEP.DakVelocity = 3960
SWEP.DakIsGuided = true

SWEP.IsMissile = true
SWEP.PenOverride = 300

function SWEP:Think()
	local owner = self:GetOwner()

	if self.LastTime + 0.1 < CurTime() then
		if self.SpreadStacks > 0 then
			self.SpreadStacks = self.SpreadStacks - ( 0.1 * self.SpreadStacks )
		end

		self.LastTime = CurTime()
	end

	if owner.PerkType == 1 and self.AmmoGiven == nil then
		self.AmmoGiven = 1
		owner:GiveAmmo( self.Primary.DefaultClip, self:GetPrimaryAmmoType(), true )
	end
end