SWEP.Base = "dak_gun_base"

SWEP.PrintName = "FN P90"
SWEP.Instructions = "personal defense weapon, Caliber: 5.7mm, Velocity: 716m/s, Damage: 28.7, RPM: 909, Pen: 10.9mm"
SWEP.Category = "DakTank"

SWEP.Spawnable = true
SWEP.AdminOnly = true

SWEP.ViewModel  = "models/weapons/cstrike/c_smg_p90.mdl"
SWEP.WorldModel = "models/weapons/w_smg_p90.mdl"

SWEP.Primary.ClipSize		= 50
SWEP.Primary.DefaultClip	= 200
SWEP.Primary.Automatic		= true
SWEP.Primary.Ammo			= "AR2"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.HoldType = "smg"
SWEP.Slot = 3

-- Gun info
SWEP.Spread = 0.075 -- 0.1 for pistols, 0.075 for smgs, 0.05 for rifles
SWEP.PrimaryCooldown = 0.066
SWEP.FireSound = "weapons/p90/p90-1.wav"
SWEP.IsPistol = false

-- Shell info
SWEP.DakCaliber = 5.7
SWEP.DakShellType = "AP"
SWEP.DakPenLossPerMeter = 0.0005
SWEP.DakExplosive = false
SWEP.DakVelocity = 28200