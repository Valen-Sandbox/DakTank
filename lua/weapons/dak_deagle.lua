SWEP.Base = "dak_gun_base"

SWEP.PrintName = "IMI Desert Eagle"
SWEP.Instructions = "fiddy cal pistol, Caliber: 12.7mm, Velocity: 470m/s, Damage: 136.8, RPM: 600, Pen: 15.92mm"
SWEP.Category = "DakTank"

SWEP.Spawnable = true
SWEP.AdminOnly = true

SWEP.ViewModel  = "models/weapons/cstrike/c_pist_deagle.mdl"
SWEP.WorldModel = "models/weapons/w_pist_deagle.mdl"

SWEP.Primary.ClipSize		= 7
SWEP.Primary.DefaultClip	= 35
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
SWEP.FireSound = "weapons/deagle/deagle-1.wav"
SWEP.IsPistol = true

-- Shell info
SWEP.DakCaliber = 12.7
SWEP.DakShellType = "AP"
SWEP.DakPenLossPerMeter = 0.0005
SWEP.DakExplosive = false
SWEP.DakVelocity = 18503.9