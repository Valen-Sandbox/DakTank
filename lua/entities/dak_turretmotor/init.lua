AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local DTTE = DTTE
local TurretMotors = DTTE.Classes.TurretMotors

ENT.DakName = "Small Turret Motor"
ENT.DakEngine = NULL
ENT.DakMaxHealth = 10
ENT.DakHealth = 10
ENT.DakMass = 250
ENT.DakPooled = 0
ENT.DakArmor = 10
ENT.ThinkTime = 0.33
ENT.CanSpark = true

function ENT:DakThink(selfTbl)
	if selfTbl.DakName == "Turret Motor" or selfTbl.DakName == "TMotor" then selfTbl.DakName = "Small Turret Motor" end

	local curMotor = TurretMotors[selfTbl.DakName]
	selfTbl.DakMaxHealth = curMotor.MaxHealth
	selfTbl.DakMass = curMotor.Mass
	selfTbl.DakModel = curMotor.Model
	selfTbl.DakRotMult = curMotor.RotMult

	if selfTbl.DakRotMult then selfTbl.DakRotMult = selfTbl.DakRotMult * selfTbl.DakHealth / selfTbl.DakMaxHealth end

	if selfTbl.DakDead then
		selfTbl.DakRotMult = 0
		selfTbl.DakHealth = 0
	elseif self:IsOnFire() then
		selfTbl.DakHealth = selfTbl.DakHealth - 0.33
		self:DTOnTakeDamage(0.33)
	end
end

function ENT:DakOnCopy(Info)
	if IsValid(self.TurretController) then
		Info.TurretID = self.TurretController:EntIndex()
	end

	Info.DakMass = self.DakMass
	Info.DakModel = self.DakModel
end

function ENT:DakOnPaste(EntMods, Ent, CreatedEntities)
	if EntMods.TurretID then
		local Eng = CreatedEntities[EntMods.TurretID]
		if Eng and IsValid(Eng) then self.TurretController = Eng end
	end

	self.DakMass = EntMods.DakMass
	self.DakModel = EntMods.DakModel

	self:Activate()
	Ent.EntityMods.DakTek = nil
end