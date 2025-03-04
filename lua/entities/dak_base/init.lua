AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local DTTE = DTTE

ENT.DakBurnStacks = 0
ENT.CanSpark = false
ENT.SparkTime = 0
ENT.SlowThinkTime = 0
ENT.ThinkTime = 0.1

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)

	self.DakHealth = self.DakMaxHealth or 1

	if self.DakInitialize then
		self:DakInitialize()
	end
end

function ENT:Think()
	local selfTbl = self:GetTable()
	local curTime = CurTime()

	 -- This can be improved further but I can't be bothered right now.
	if selfTbl.CanSpark and curTime >= selfTbl.SparkTime + 0.33 and not selfTbl.DakDead then
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

		selfTbl.SparkTime = curTime
	end

	if curTime >= selfTbl.SlowThinkTime + 1 then
		DTTE.CheckSpherical(self)

		if selfTbl.DakSlowThink then
			self:DakSlowThink(selfTbl)
		end

		selfTbl.SlowThinkTime = curTime
	end

	if selfTbl.DakModel and self:GetModel() ~= selfTbl.DakModel then
		self:SetModel(selfTbl.DakModel)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
	end

	if selfTbl.DakHealth > selfTbl.DakMaxHealth then selfTbl.DakHealth = selfTbl.DakMaxHealth end

	local physObj = self:GetPhysicsObject()
	if selfTbl.DakMass and physObj:GetMass() ~= selfTbl.DakMass then
		physObj:SetMass(selfTbl.DakMass)
	end

	if selfTbl.DakThink then
		self:DakThink(selfTbl)
	end

	self:NextThink(curTime + selfTbl.ThinkTime)

	return true
end

function ENT:DTOnTakeDamage(Damage)
	if self.DakDead then return end

	if self.DakHealth <= 0 then
		if self.DakOwner:IsPlayer() and self.DakOwner ~= NULL then self.DakOwner:ChatPrint(self.DakName .. " Destroyed!") end
		self:SetMaterial("models/props_buildings/plasterwall021a")
		self:SetColor(Color(100, 100, 100, 255))
		self.DakDead = true
		if IsValid(self.DakGun) then self.DakGun.Loaded = 0 end

		return
	end

	if self.DakOnTakeDamage then
		self:DakOnTakeDamage(Damage)
	end
end

function ENT:PreEntityCopy()
	local info = {}
	info.DakName = self.DakName
	info.DakMaxHealth = self.DakMaxHealth
	info.DakHealth = self.DakHealth
	info.DakOwner = self.DakOwner

	if self.DakOnCopy then
		self:DakOnCopy(info)
	end

	duplicator.StoreEntityModifier(self, "DakTek", info)

	-- Wire dupe info
	self.BaseClass.PreEntityCopy(self)
end

function ENT:PostEntityPaste(Player, Ent, CreatedEntities)
	if Ent.EntityMods and Ent.EntityMods.DakTek then
		local EntMods = Ent.EntityMods.DakTek

		self.DakName = EntMods.DakName
		self.DakMaxHealth = EntMods.DakMaxHealth
		self.DakHealth = self.DakMaxHealth
		self.DakOwner = Player
		Ent.EntityMods.DakTekLink = nil

		if EntMods.DakColor then
			self:SetColor(EntMods.DakColor)
		end

		if self.DakOnPaste then
			self:DakOnPaste(EntMods, Ent, CreatedEntities)
		end
	end

	self.BaseClass.PostEntityPaste(self, Player, Ent, CreatedEntities)
end