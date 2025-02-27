SWEP.Base = "dak_gun_base"

SWEP.PrintName = "AT4"
SWEP.Instructions = "84 millimeter tank deleter, Caliber: 84mm, Velocity: 290m/s, Damage: 30 vs armor, RPM: 30, Pen: 420mm"
SWEP.Category = "DakTank"

SWEP.Spawnable = true
SWEP.AdminOnly = true

SWEP.ViewModel  = "models/weapons/c_rpg.mdl"
SWEP.WorldModel = "models/weapons/w_rocket_launcher.mdl"

SWEP.Primary.ClipSize		= 1
SWEP.Primary.DefaultClip	= 3
SWEP.Primary.Automatic		= true
SWEP.Primary.Ammo			= "RPG_Round"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.HoldType = "rpg"
SWEP.Slot = 5

-- Gun info
SWEP.Spread = 0.05 -- 0.1 for pistols, 0.075 for smgs, 0.05 for rifles
SWEP.PrimaryCooldown = 1
SWEP.FireSound = "daktanks/extra/76mmUSA2.mp3"
SWEP.IsPistol = false
SWEP.heavyweapon = true

-- Shell info
SWEP.DakCaliber = 84
SWEP.DakShellType = "HEAT"
SWEP.DakPenLossPerMeter = 0.0
SWEP.DakExplosive = true
SWEP.DakVelocity = 11400

SWEP.IsMissile = true
SWEP.PenOverride = 420