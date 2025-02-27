SWEP.Base = "dak_gun_base"

SWEP.PrintName = "SIG P228"
SWEP.Instructions = "compact, Caliber: 9mm, Velocity: 400m/s, Damage: 35.3, RPM: 600, Pen: 9.60mm"
SWEP.Category = "DakTank"

SWEP.Spawnable = true
SWEP.AdminOnly = true

SWEP.ViewModel  = "models/weapons/cstrike/c_pist_p228.mdl"
SWEP.WorldModel = "models/weapons/w_pist_p228.mdl"

SWEP.Primary.ClipSize		= 13
SWEP.Primary.DefaultClip	= 130
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
SWEP.FireSound = "weapons/p228/p228-1.wav"
SWEP.IsPistol = true

-- Shell info
SWEP.DakCaliber = 9
SWEP.DakShellType = "AP"
SWEP.DakPenLossPerMeter = 0.0005
SWEP.DakExplosive = false
SWEP.DakVelocity = 15744