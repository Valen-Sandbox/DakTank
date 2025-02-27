SWEP.Base = "dak_gun_base"

SWEP.PrintName = "H&K G3SG/1"
SWEP.Instructions = "sharpshooter, Caliber: 7.62mm, Velocity: 800m/s, Damage: 85.6, RPM: 600, Pen: 16.26mm"
SWEP.Category = "DakTank"

SWEP.Spawnable = true
SWEP.AdminOnly = true

SWEP.ViewModel  = "models/weapons/cstrike/c_snip_g3sg1.mdl"
SWEP.WorldModel = "models/weapons/w_snip_g3sg1.mdl"

SWEP.Primary.ClipSize		= 20
SWEP.Primary.DefaultClip	= 60
SWEP.Primary.Automatic		= true
SWEP.Primary.Ammo			= "AR2"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.HoldType = "ar2"
SWEP.Slot = 4

-- Gun info
SWEP.Spread = 0.05 -- 0.1 for pistols, 0.075 for smgs, 0.05 for rifles
SWEP.PrimaryCooldown = 0.1
SWEP.FireSound = "weapons/g3sg1/g3sg1-1.wav"
SWEP.IsPistol = false
SWEP.IsRifle = true

-- Shell info
SWEP.DakCaliber = 7.62
SWEP.DakShellType = "AP"
SWEP.DakPenLossPerMeter = 0.0005
SWEP.DakExplosive = false
SWEP.DakVelocity = 31500
SWEP.Zoom = 40