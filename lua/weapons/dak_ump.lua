AddCSLuaFile( "dak_ai_translations.lua" )
include( "dak_ai_translations.lua" )
SWEP.Base 			= "dak_gun_base"
if SERVER then

	--AddCSLuaFile ("shared.lua")


	SWEP.Weight = 5

	SWEP.AutoSwitchTo = false
	SWEP.AutoSwitchFrom = false

elseif CLIENT then

	SWEP.PrintName = "H&K UMP"

	SWEP.Slot = 3
	SWEP.SlotPos = 1

	SWEP.DrawAmmo = true
	SWEP.DrawCrosshair = true
end

SWEP.Author = "DakTank"
SWEP.Purpose = "Shoots Things."
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

SWEP.UseHands = true

SWEP.HoldType = "smg"
SWEP.LastTime = CurTime()
SWEP.CSMuzzleFlashes = true

function SWEP:Initialize()
	self.SpreadStacks = 0
	self:SetHoldType( self.HoldType )
	local owner = self:GetOwner()

	if SERVER and owner:IsNPC() then
		owner:SetCurrentWeaponProficiency( WEAPON_PROFICIENCY_PERFECT )
		owner:CapabilitiesAdd( CAP_MOVE_GROUND )
		owner:CapabilitiesAdd( CAP_MOVE_JUMP )
		owner:CapabilitiesAdd( CAP_MOVE_CLIMB )
		owner:CapabilitiesAdd( CAP_MOVE_SWIM )
		owner:CapabilitiesAdd( CAP_MOVE_CRAWL )
		owner:CapabilitiesAdd( CAP_MOVE_SHOOT )
		owner:CapabilitiesAdd( CAP_USE )
		owner:CapabilitiesAdd( CAP_USE_SHOT_REGULATOR )
		owner:CapabilitiesAdd( CAP_SQUAD )
		owner:CapabilitiesAdd( CAP_DUCK )
		owner:CapabilitiesAdd( CAP_AIM_GUN )
		owner:CapabilitiesAdd( CAP_NO_HIT_SQUADMATES )
	end
	self.PrimaryLastFire = 0
	self.Fired = 0

	self.ShellList = {}
	self.RemoveList = {}

	--gun info
	self.ShotCount = 1
	self.Spread = 0.075 --0.1 for pistols, 0.075 for smgs, 0.05 for rifles
	self.PrimaryCooldown = 0.1
	self.FireSound = "weapons/ump45/ump45-1.wav"
	self.IsPistol = false

	--shell info
	self.DakTrail = "dakteballistictracer"
	self.DakCaliber = 11.43
	self.DakShellType = "AP"
	self.DakPenLossPerMeter = 0.0005
	self.DakExplosive = false
	self.DakVelocity = 11220
	self.ShellLengthMult = self.DakVelocity / 29527.6
	self.Zoom = 55
end
