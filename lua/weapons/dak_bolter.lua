SWEP.Base = "dak_gun_base"

SWEP.PrintName = "Bolter"
SWEP.Instructions = "FOR DA EMPRAH BROTHA, Caliber: 19.05mm, Velocity: 716m/s, Damage: all of it, RPM: 600, Pen: 36.4mm"
SWEP.Category = "DakTank"

SWEP.Spawnable = true
SWEP.AdminOnly = true

SWEP.ViewModel  = "models/weapons/v_xm25.mdl"
SWEP.WorldModel = "models/weapons/w_xm25.mdl"

SWEP.Primary.ClipSize		= 25
SWEP.Primary.DefaultClip	= 75
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
SWEP.PrimaryCooldown = 0.10
SWEP.FireSound = "daktanks/c25.mp3"
SWEP.IsPistol = false
SWEP.IsRifle = true

-- Shell info
SWEP.DakCaliber = 19.05
SWEP.DakPenLossPerMeter = 0.0005
SWEP.DakShellType = "APHE"
SWEP.DakExplosive = true
SWEP.DakVelocity = 28200