SWEP.Base = "dak_gun_base"

SWEP.PrintName = "IMI Galil"
SWEP.Instructions = "bottle opener standard feature, Caliber: 5.56mm, Velocity: 950m/s, Damage: 46.9, RPM: 750, Pen: 14.09mm"
SWEP.Category = "DakTank"

SWEP.Spawnable = true
SWEP.AdminOnly = true

SWEP.ViewModel  = "models/weapons/cstrike/c_rif_galil.mdl"
SWEP.WorldModel = "models/weapons/w_rif_galil.mdl"

SWEP.Primary.ClipSize		= 35
SWEP.Primary.DefaultClip	= 105
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
SWEP.PrimaryCooldown = 0.08
SWEP.FireSound = "weapons/galil/galil-1.wav"
SWEP.IsPistol = false
SWEP.IsRifle = true

-- Shell info
SWEP.DakCaliber = 5.56
SWEP.DakShellType = "AP"
SWEP.DakPenLossPerMeter = 0.0005
SWEP.DakExplosive = false
SWEP.DakVelocity = 37401.6