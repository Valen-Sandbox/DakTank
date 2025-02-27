SWEP.Base = "dak_gun_base"

SWEP.PrintName = "H&K UMP"
SWEP.Instructions = "now that's a lot of stopping power, Caliber: 11.43mm, Velocity: 285m/s, Damage: 36.7, RPM: 600, Pen: 8.69mm"
SWEP.Category = "DakTank"

SWEP.Spawnable = true
SWEP.AdminOnly = true

SWEP.ViewModel  = "models/weapons/cstrike/c_smg_ump45.mdl"
SWEP.WorldModel = "models/weapons/w_smg_ump45.mdl"

SWEP.Primary.ClipSize		= 25
SWEP.Primary.DefaultClip	= 125
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
SWEP.PrimaryCooldown = 0.1
SWEP.FireSound = "weapons/ump45/ump45-1.wav"
SWEP.IsPistol = false

-- Shell info
SWEP.DakCaliber = 11.43
SWEP.DakShellType = "AP"
SWEP.DakPenLossPerMeter = 0.0005
SWEP.DakExplosive = false
SWEP.DakVelocity = 11220