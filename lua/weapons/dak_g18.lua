SWEP.Base = "dak_gun_base"

SWEP.PrintName = "Glock-18"
SWEP.Instructions = "plastic gun, Caliber: 9mm, Velocity: 375m/s, Damage: 31, RPM: 1200, Pen: 9mm"
SWEP.Category = "DakTank"

SWEP.Spawnable = true
SWEP.AdminOnly = true

SWEP.ViewModel  = "models/weapons/cstrike/c_pist_glock18.mdl"
SWEP.WorldModel = "models/weapons/w_pist_glock18.mdl"

SWEP.Primary.ClipSize		= 33
SWEP.Primary.DefaultClip	= 165
SWEP.Primary.Automatic		= true
SWEP.Primary.Ammo			= "Pistol"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.HoldType = "pistol"
SWEP.Slot = 2

-- Gun info
SWEP.Spread = 0.1 -- 0.1 for pistols, 0.075 for smgs, 0.05 for rifles
SWEP.PrimaryCooldown = 0.05
SWEP.FireSound = "weapons/glock/glock18-1.wav"
SWEP.IsPistol = true

-- Shell info
SWEP.DakCaliber = 9
SWEP.DakShellType = "AP"
SWEP.DakPenLossPerMeter = 0.0005
SWEP.DakExplosive = false
SWEP.DakVelocity = 14760