SWEP.Base = "dak_gun_base"

SWEP.PrintName = "Semiauto Shotgun"
SWEP.Instructions = "totally not a famas, Caliber: 5.56mm, Velocity: 635m/s, Damage: 210, RPM: 300, Pen: 5.56mm"
SWEP.Category = "DakTank"

SWEP.Spawnable = true
SWEP.AdminOnly = true

SWEP.ViewModel  = "models/weapons/cstrike/c_rif_famas.mdl"
SWEP.WorldModel = "models/weapons/w_rif_famas.mdl"

SWEP.Primary.ClipSize		= 5
SWEP.Primary.DefaultClip	= 100
SWEP.Primary.Automatic		= true
SWEP.Primary.Ammo			= "Buckshot"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.HoldType = "ar2"
SWEP.Slot = 4

-- Gun info
SWEP.ShotCount = 10
SWEP.Spread = 1 -- 0.1 for pistols, 0.075 for smgs, 0.05 for rifles
SWEP.PrimaryCooldown = 0.2
SWEP.FireSound = "weapons/xm1014/xm1014-1.wav"
SWEP.IsPistol = false

-- Shell info
SWEP.DakCaliber = 5.56
SWEP.DakShellType = "AP"
SWEP.DakPenLossPerMeter = 0.0005
SWEP.DakExplosive = false
SWEP.DakVelocity = 25000
SWEP.ShellLengthMult = 0.5