SWEP.Base = "dak_gun_base"

SWEP.PrintName = "H&K USP"
SWEP.Instructions = "MANSTOPPAH, Caliber: 11.43mm, Velocity: 285m/s, Damage: 36.7, RPM: 600, Pen: 8.69mm"
SWEP.Category = "DakTank"

SWEP.Spawnable = true
SWEP.AdminOnly = true

SWEP.ViewModel  = "models/weapons/cstrike/c_pist_usp.mdl"
SWEP.WorldModel = "models/weapons/w_pist_usp.mdl"

SWEP.Primary.ClipSize		= 12
SWEP.Primary.DefaultClip	= 120
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo			= "Pistol"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.HoldType = "pistol"
SWEP.Slot = 2

-- Gun info
SWEP.Spread = 0.1 -- 0.1 for pistols, 0.075 for smgs, 0.05 for rifles
SWEP.PrimaryCooldown = 0.1
SWEP.FireSound = "weapons/usp/usp_unsil-1.wav"
SWEP.IsPistol = true

-- Shell info
SWEP.DakCaliber = 11.43
SWEP.DakShellType = "AP"
SWEP.DakPenLossPerMeter = 0.0005
SWEP.DakExplosive = false
SWEP.DakVelocity = 11220