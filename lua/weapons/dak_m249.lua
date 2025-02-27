SWEP.Base = "dak_gun_base"

SWEP.PrintName = "M249 SAW"
SWEP.Instructions = "I AM THE SAW, Caliber: 5.56mm, Velocity: 914m/s, Damage: 43.5, RPM: 857, Pen: 13.56mm"
SWEP.Category = "DakTank"

SWEP.Spawnable = true
SWEP.AdminOnly = true

SWEP.ViewModel  = "models/weapons/cstrike/c_mach_m249para.mdl"
SWEP.WorldModel = "models/weapons/w_mach_m249para.mdl"

SWEP.Primary.ClipSize		= 200
SWEP.Primary.DefaultClip	= 600
SWEP.Primary.Automatic		= true
SWEP.Primary.Ammo			= "SMG1"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.HoldType = "ar2"
SWEP.Slot = 4

-- Gun info
SWEP.Spread = 0.05 -- 0.1 for pistols, 0.075 for smgs, 0.05 for rifles
SWEP.PrimaryCooldown = 0.07
SWEP.FireSound = "weapons/m249/m249-1.wav"
SWEP.IsPistol = false
SWEP.IsRifle = true
SWEP.heavyweapon = true

-- Shell info
SWEP.DakCaliber = 5.56
SWEP.DakShellType = "AP"
SWEP.DakPenLossPerMeter = 0.0005
SWEP.DakExplosive = false
SWEP.DakVelocity = 36000