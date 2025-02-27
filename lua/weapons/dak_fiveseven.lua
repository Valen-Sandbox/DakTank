SWEP.Base = "dak_gun_base"

SWEP.PrintName = "FN Five-seveN"
SWEP.Instructions = "tacticool, Caliber: 5.7mm, Velocity: 762m/s, Damage: 32.5, RPM: 600, Pen: 11.58mm"
SWEP.Category = "DakTank"

SWEP.Spawnable = true
SWEP.AdminOnly = true

SWEP.ViewModel  = "models/weapons/cstrike/c_pist_fiveseven.mdl"
SWEP.WorldModel = "models/weapons/w_pist_fiveseven.mdl"

SWEP.Primary.ClipSize		= 20
SWEP.Primary.DefaultClip	= 160
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
SWEP.FireSound = "weapons/fiveseven/fiveseven-1.wav"
SWEP.IsPistol = true

-- Shell info
SWEP.DakCaliber = 5.7
SWEP.DakShellType = "AP"
SWEP.DakPenLossPerMeter = 0.0005
SWEP.DakExplosive = false
SWEP.DakVelocity = 30000