AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local DTTE = DTTE
local Engines = DTTE.Classes.Engines

ENT.DakName = "Standard Engine"
ENT.DakFuel = NULL
ENT.DakMaxHealth = 25
ENT.DakHealth = 25
ENT.DakSpeed = 1.1725
ENT.DakMass = 1000
ENT.DakSound = "vehicles/apc/apc_cruise_loop3.wav"
ENT.DakPooled = 0
ENT.DakCrew = NULL
ENT.DakHP = 0

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self.DakHealth = self.DakMaxHealth
	self.initsound = self.DakSound
	self.Sound = CreateSound(self, self.DakSound, CReliableBroadcastRecipientFilter)
	self.Sound:PlayEx(1, 100)
	self.Sound:ChangePitch(0, 0)
	self.Sound:ChangeVolume(0, 0)
	self.SparkTime = CurTime()
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

	local curEngine = Engines[selfTbl.DakName]
	selfTbl.DakMaxHealth = curEngine.MaxHealth
	selfTbl.DakArmor = curEngine.Armor
	selfTbl.DakMass = curEngine.Mass
	selfTbl.DakSpeed = curEngine.Speed
	selfTbl.DakModel = curEngine.Model
	selfTbl.DakFuelReq = curEngine.FuelReq
	selfTbl.DakHP = curEngine.HP

	if not selfTbl.FirstCheck and selfTbl.DakMaxHealth ~= 25 then
		selfTbl.FirstCheck = true
		selfTbl.DakHealth = selfTbl.DakMaxHealth
	end

	if selfTbl.DakHealth > selfTbl.DakMaxHealth then selfTbl.DakHealth = selfTbl.DakMaxHealth end
	selfTbl.DakSpeed = selfTbl.DakSpeed * (selfTbl.DakHealth / selfTbl.DakMaxHealth) * math.Clamp(self:GetHorsePowerMultiplier(), 0, 1) --Would be better to do this in ontake damage, but these values are reset every think.
	selfTbl.DakHP = selfTbl.DakHP * (selfTbl.DakHealth / selfTbl.DakMaxHealth) * math.Clamp(self:GetHorsePowerMultiplier(), 0, 1)
	if selfTbl.initsound ~= selfTbl.DakSound then
		selfTbl.initsound = selfTbl.DakSound
		selfTbl.Sound:Stop()
		selfTbl.Sound = CreateSound(self, selfTbl.DakSound, CReliableBroadcastRecipientFilter)
		selfTbl.Sound:PlayEx(1, 100)
		selfTbl.Sound:ChangePitch(0, 0)
		selfTbl.Sound:ChangeVolume(0, 0)
	end

	if selfTbl.DakModel and self:GetModel() ~= selfTbl.DakModel then
		self:SetModel(selfTbl.DakModel)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
	end

	if self:GetPhysicsObject():GetMass() ~= selfTbl.DakMass then self:GetPhysicsObject():SetMass(selfTbl.DakMass) end
	if selfTbl.DakDead then
		selfTbl.DakHP = 0
		selfTbl.DakHealth = 0
	elseif self:IsOnFire() then
		local Dmg = selfTbl.DakMaxHealth * 0.025 * 0.25
		selfTbl.DakHealth = selfTbl.DakHealth - Dmg
		self:DTOnTakeDamage(Dmg)
	end

	self:NextThink(CurTime() + 0.25)
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
	info.FuelID = self.DakFuel:EntIndex()
	info.CrewID = self.DakCrew:EntIndex()
	info.DakName = self.DakName
	info.DakMass = self.DakMass
	info.DakModel = self.DakModel
	info.DakMaxHealth = self.DakMaxHealth
	info.DakHealth = self.DakHealth
	info.DakSpeed = self.DakSpeed
	info.DakSound = self.DakSound

	duplicator.StoreEntityModifier(self, "DakTek", info)

	--Wire dupe info
	self.BaseClass.PreEntityCopy(self)
end

function ENT:PostEntityPaste(Player, Ent, CreatedEntities)
	if Ent.EntityMods and Ent.EntityMods.DakTek then
		local Fuel = CreatedEntities[Ent.EntityMods.DakTek.FuelID]
		if Fuel and IsValid(Fuel) then self.DakFuel = Fuel end
		local Crew = CreatedEntities[Ent.EntityMods.DakTek.CrewID]
		if Crew and IsValid(Crew) then self.DakCrew = Crew end
		self.DakName = Ent.EntityMods.DakTek.DakName
		self.DakMass = Ent.EntityMods.DakTek.DakMass
		self.DakModel = Ent.EntityMods.DakTek.DakModel
		self.DakMaxHealth = Ent.EntityMods.DakTek.DakMaxHealth
		self.DakHealth = self.DakMaxHealth
		self.DakSpeed = Ent.EntityMods.DakTek.DakSpeed
		self.DakSound = Ent.EntityMods.DakTek.DakSound
		self.DakOwner = Player
		if Ent.EntityMods.DakTek.DakColor then
			self:SetColor(Ent.EntityMods.DakTek.DakColor)
		end

		Ent.EntityMods.DakTek = nil
	end

	self.BaseClass.PostEntityPaste(self, Player, Ent, CreatedEntities)
end

function ENT:OnRemove()
	self.Sound:Stop()
end