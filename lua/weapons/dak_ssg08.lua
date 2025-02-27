SWEP.Base = "dak_gun_base"

SWEP.PrintName = "Steyr SSG 08"
SWEP.Instructions = "L33T $nip@r pr0, Caliber: 7.8mm, Velocity: 940m/s, Damage: 128, RPM: 60, Pen: 19.65mm"
SWEP.Category = "DakTank"

SWEP.Spawnable = true
SWEP.AdminOnly = true

SWEP.ViewModel  = "models/weapons/cstrike/c_snip_scout.mdl"
SWEP.WorldModel = "models/weapons/w_snip_scout.mdl"

SWEP.Primary.ClipSize		= 10
SWEP.Primary.DefaultClip	= 100
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo			= "SMG1"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.HoldType = "ar2"
SWEP.Slot = 5

-- Gun info
SWEP.Spread = 0.05 -- 0.1 for pistols, 0.075 for smgs, 0.05 for rifles
SWEP.PrimaryCooldown = 0.5
SWEP.FireSound = "weapons/scout/scout_fire-1.wav"
SWEP.IsPistol = false
SWEP.IsRifle = true
SWEP.heavyweapon = true

-- Shell info
SWEP.DakCaliber = 7.8
SWEP.DakShellType = "AP"
SWEP.DakPenLossPerMeter = 0.0005
SWEP.DakExplosive = false
SWEP.DakVelocity = 37200
SWEP.Zoom = 30