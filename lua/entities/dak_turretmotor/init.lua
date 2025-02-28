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

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self.DakArmor = 10
	self.DakHealth = self.DakMaxHealth
	self.SparkTime = CurTime()
	self.DakBurnStacks = 0
end

function ENT:Think()
	local self = self
	local selfTbl = self:GetTable()

	DTTE.CheckSpherical(self)

	if CurTime() >= selfTbl.SparkTime + 0.33 then
		local scale
		if selfTbl.DakHealth <= (selfTbl.DakMaxHealth * 0.80) and selfTbl.DakHealth > (selfTbl.DakMaxHealth * 0.60) then
			scale = 1
		elseif selfTbl.DakHealth <= (selfTbl.DakMaxHealth * 0.60) and selfTbl.DakHealth > (selfTbl.DakMaxHealth * 0.40) then
			scale = 2
		elseif selfTbl.DakHealth <= (selfTbl.DakMaxHealth * 0.40) and selfTbl.DakHealth > (selfTbl.DakMaxHealth * 0.20) then
			scale = 3
		elseif selfTbl.DakHealth <= (selfTbl.DakMaxHealth * 0.20) then
			scale = 4
		end

		if scale then
			local effectdata = EffectData()
			effectdata:SetOrigin(self:GetPos())
			effectdata:SetEntity(self)
			effectdata:SetAttachment(1)
			effectdata:SetMagnitude(.5)
			effectdata:SetScale(scale)
			util.Effect("daktedamage", effectdata)
		end

		selfTbl.SparkTime = CurTime()
	end

	if selfTbl.DakName == "Turret Motor" or selfTbl.DakName == "TMotor" then selfTbl.DakName = "Small Turret Motor" end

	local curMotor = TurretMotors[selfTbl.DakName]
	selfTbl.DakMaxHealth = curMotor.MaxHealth
	selfTbl.DakMass = curMotor.Mass
	selfTbl.DakModel = curMotor.Model
	selfTbl.DakRotMult = curMotor.RotMult

	if selfTbl.DakModel and self:GetModel() ~= selfTbl.DakModel then
		self:SetModel(selfTbl.DakModel)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
	end

	if selfTbl.DakHealth > selfTbl.DakMaxHealth then selfTbl.DakHealth = selfTbl.DakMaxHealth end
	if selfTbl.DakRotMult then selfTbl.DakRotMult = selfTbl.DakRotMult * selfTbl.DakHealth / selfTbl.DakMaxHealth end
	if self:GetPhysicsObject():GetMass() ~= selfTbl.DakMass then self:GetPhysicsObject():SetMass(selfTbl.DakMass) end
	if selfTbl.DakDead then
		selfTbl.DakRotMult = 0
		selfTbl.DakHealth = 0
	elseif self:IsOnFire() then
		selfTbl.DakHealth = selfTbl.DakHealth - 0.33
		self:DTOnTakeDamage(0.33)
	end

	self:NextThink(CurTime() + 0.33)
	return true
end

function ENT:DTOnTakeDamage()
	if self.DakDead then return end
	if self.DakHealth <= 0 then
		if self.DakOwner:IsPlayer() and self.DakOwner ~= NULL then self.DakOwner:ChatPrint(self.DakName .. " Destroyed!") end
		self:SetMaterial("models/props_buildings/plasterwall021a")
		self:SetColor(Color(100, 100, 100, 255))
		self.DakDead = true
		return
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