SWEP.Base = "dak_gun_base"

SWEP.PrintName = "Colt M4A1"
SWEP.Instructions = "freedom dispenser, Caliber: 5.56mm, Velocity: 905m/s, Damage: 42.6, RPM: 952, Pen: 13.42mm"
SWEP.Category = "DakTank"

SWEP.Spawnable = true
SWEP.AdminOnly = true

SWEP.ViewModel  = "models/weapons/cstrike/c_rif_m4a1.mdl"
SWEP.WorldModel = "models/weapons/w_rif_m4a1.mdl"

SWEP.Primary.ClipSize		= 30
SWEP.Primary.DefaultClip	= 120
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
SWEP.PrimaryCooldown = 0.063
SWEP.FireSound = "weapons/m4a1/m4a1_unsil-1.wav"
SWEP.IsPistol = false
SWEP.IsRifle = true

-- Shell info
SWEP.DakCaliber = 5.56
SWEP.DakShellType = "AP"
SWEP.DakPenLossPerMeter = 0.0005
SWEP.DakExplosive = false
SWEP.DakVelocity = 35640