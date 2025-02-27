SWEP.Base = "dak_gun_base"

SWEP.PrintName = "PTRS-41"
SWEP.Instructions = "Old Soviet AT rifle, Caliber: 14.5mm, Velocity: 1,013m/s, Damage: 1.89 vs Armor, RPM: 60, Pen: 39.17mm"
SWEP.Category = "DakTank"

SWEP.Spawnable = true
SWEP.AdminOnly = true

SWEP.ViewModel  = "models/weapons/cstrike/c_snip_awp.mdl"
SWEP.WorldModel = "models/weapons/w_snip_awp.mdl"

SWEP.Primary.ClipSize		= 5
SWEP.Primary.DefaultClip	= 50
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo			= "SMG1"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.HoldType = "ar2"
SWEP.Slot = 5

-- Gun info
SWEP.Spread = 0.05 -- 0.1 for pistols, 0.075 for smgs, 0.05 for rifles
SWEP.PrimaryCooldown = 0.5
SWEP.FireSound = "weapons/awp/awp1.wav"
SWEP.IsPistol = false
SWEP.IsRifle = true
SWEP.heavyweapon = true

-- Shell info
SWEP.DakCaliber = 14.5
SWEP.DakShellType = "AP"
SWEP.DakPenLossPerMeter = 0.0005
SWEP.DakExplosive = false
SWEP.DakVelocity = 39882
SWEP.Zoom = 30