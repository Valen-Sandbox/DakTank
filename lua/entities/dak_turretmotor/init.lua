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

function ENT:PreEntityCopy()
	local info = {}

	if IsValid(self.TurretController) then info.TurretID = self.TurretController:EntIndex() end
	info.DakName = self.DakName
	info.DakMass = self.DakMass
	info.DakModel = self.DakModel
	info.DakMaxHealth = self.DakMaxHealth
	info.DakHealth = self.DakHealth
	duplicator.StoreEntityModifier(self, "DakTek", info)

	--Wire dupe info
	self.BaseClass.PreEntityCopy(self)
end

function ENT:PostEntityPaste(Player, Ent, CreatedEntities)
	if Ent.EntityMods and Ent.EntityMods.DakTek then
		if Ent.EntityMods.DakTek.TurretID then
			local Eng = CreatedEntities[Ent.EntityMods.DakTek.TurretID]
			if Eng and IsValid(Eng) then self.TurretController = Eng end
		end

		self.DakName = Ent.EntityMods.DakTek.DakName
		self.DakMass = Ent.EntityMods.DakTek.DakMass
		self.DakModel = Ent.EntityMods.DakTek.DakModel
		self.DakMaxHealth = Ent.EntityMods.DakTek.DakMaxHealth
		self.DakHealth = self.DakMaxHealth
		self.DakOwner = Player
		if Ent.EntityMods.DakTek.DakColor then
			self:SetColor(Ent.EntityMods.DakTek.DakColor)
		end

		self:Activate()
		Ent.EntityMods.DakTek = nil
	end

	self.BaseClass.PostEntityPaste(self, Player, Ent, CreatedEntities)
end