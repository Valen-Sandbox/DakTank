SWEP.Base = "dak_gun_base"

SWEP.PrintName = "Steyr TMP"
SWEP.Instructions = "special purpose pistol, Caliber: 9mm, Velocity: 400m/s, Damage: 35.3, RPM: 800, Pen: 9.60mm"
SWEP.Category = "DakTank"

SWEP.Spawnable = true
SWEP.AdminOnly = true

SWEP.ViewModel  = "models/weapons/cstrike/c_smg_tmp.mdl"
SWEP.WorldModel = "models/weapons/w_smg_tmp.mdl"

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
SWEP.PrimaryCooldown = 0.066
SWEP.FireSound = "weapons/tmp/tmp-1.wav"
SWEP.IsPistol = false

-- Shell info
SWEP.DakCaliber = 9
SWEP.DakShellType = "AP"
SWEP.DakPenLossPerMeter = 0.0005
SWEP.DakExplosive = false
SWEP.DakVelocity = 15744