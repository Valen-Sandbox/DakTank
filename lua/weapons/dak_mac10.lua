SWEP.Base = "dak_gun_base"

SWEP.PrintName = "MAC-10"
SWEP.Instructions = "nonstop poppop, Caliber: 11.43mm, Velocity: 280m/s, Damage: 35.4, RPM: 1091, Pen: 8.54mm"
SWEP.Category = "DakTank"

SWEP.Spawnable = true
SWEP.AdminOnly = true

SWEP.ViewModel  = "models/weapons/cstrike/c_smg_mac10.mdl"
SWEP.WorldModel = "models/weapons/w_smg_mac10.mdl"

SWEP.Primary.ClipSize		= 30
SWEP.Primary.DefaultClip	= 150
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
SWEP.PrimaryCooldown = 0.055
SWEP.FireSound = "weapons/mac10/mac10-1.wav"
SWEP.IsPistol = false

-- Shell info
SWEP.DakCaliber = 11.43
SWEP.DakShellType = "AP"
SWEP.DakPenLossPerMeter = 0.0005
SWEP.DakExplosive = false
SWEP.DakVelocity = 11028