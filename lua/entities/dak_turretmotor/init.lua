AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
local DTTE = DTTE
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
	DTTE.CheckSpherical(self)
	if CurTime() >= self.SparkTime + 0.33 then
		local scale
		if self.DakHealth <= (self.DakMaxHealth * 0.80) and self.DakHealth > (self.DakMaxHealth * 0.60) then
			scale = 1
		elseif self.DakHealth <= (self.DakMaxHealth * 0.60) and self.DakHealth > (self.DakMaxHealth * 0.40) then
			scale = 2
		elseif self.DakHealth <= (self.DakMaxHealth * 0.40) and self.DakHealth > (self.DakMaxHealth * 0.20) then
			scale = 3
		elseif self.DakHealth <= (self.DakMaxHealth * 0.20) then
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

		self.SparkTime = CurTime()
	end

	if self.DakName == "Turret Motor" or self.DakName == "TMotor" then self.DakName = "Small Turret Motor" end
	if self.DakName == "Small Turret Motor" then
		self.DakMaxHealth = 10
		self.DakMass = 250
		self.DakModel = "models/xqm/hydcontrolbox.mdl"
		self.DakRotMult = 0.1
	elseif self.DakName == "Medium Turret Motor" then
		self.DakMaxHealth = 20
		self.DakMass = 500
		self.DakModel = "models/props_c17/utilityconducter001.mdl"
		self.DakRotMult = 0.25
	elseif self.DakName == "Large Turret Motor" then
		self.DakMaxHealth = 50
		self.DakMass = 1000
		self.DakModel = "models/props_c17/substation_transformer01d.mdl"
		self.DakRotMult = 0.6
	end

	if self.DakModel and self:GetModel() ~= self.DakModel then
		self:SetModel(self.DakModel)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
	end

	if self.DakHealth > self.DakMaxHealth then self.DakHealth = self.DakMaxHealth end
	if self.DakRotMult then self.DakRotMult = self.DakRotMult * self.DakHealth / self.DakMaxHealth end
	if self:GetPhysicsObject():GetMass() ~= self.DakMass then self:GetPhysicsObject():SetMass(self.DakMass) end
	if self.DakDead then
		self.DakRotMult = 0
		self.DakHealth = 0
	elseif self:IsOnFire() then
		self.DakHealth = self.DakHealth - 0.33
		self:DTOnTakeDamage(0.33)
	end

	self:NextThink(CurTime() + 0.33)
	return true
end

function ENT:DTOnTakeDamage(Damage)
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
	--local entids = {}
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
		if Ent.EntityMods.DakTek.DakColor == nil then
		else
			self:SetColor(Ent.EntityMods.DakTek.DakColor)
		end

		--self:PhysicsDestroy()
		--self:SetModel(self.DakModel)
		--self:PhysicsInit(SOLID_VPHYSICS)
		--self:SetMoveType(MOVETYPE_VPHYSICS)
		--self:SetSolid(SOLID_VPHYSICS)
		self:Activate()
		Ent.EntityMods.DakTek = nil
	end

	self.BaseClass.PostEntityPaste(self, Player, Ent, CreatedEntities)
end