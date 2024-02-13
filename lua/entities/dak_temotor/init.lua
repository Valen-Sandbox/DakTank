AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
local DTTE = DTTE
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

	if self.DakName == "Micro Engine" then
		self.DakMaxHealth = 5
		self.DakArmor = 5
		self.DakMass = 80
		self.DakSpeed = 0.4444
		self.DakModel = "models/daktanks/engine1.mdl"
		self.DakFuelReq = 24
		self.DakHP = 40
	elseif self.DakName == "Small Engine" then
		self.DakMaxHealth = 20
		self.DakArmor = 20
		self.DakMass = 265
		self.DakSpeed = 1.3888
		self.DakModel = "models/daktanks/engine2.mdl"
		self.DakFuelReq = 75
		self.DakHP = 125
	elseif self.DakName == "Standard Engine" then
		self.DakMaxHealth = 45
		self.DakArmor = 45
		self.DakMass = 625
		self.DakSpeed = 3.3333
		self.DakModel = "models/daktanks/engine3.mdl"
		self.DakFuelReq = 180
		self.DakHP = 300
	elseif self.DakName == "Large Engine" then
		self.DakMaxHealth = 90
		self.DakArmor = 90
		self.DakMass = 1225
		self.DakSpeed = 6.6666
		self.DakModel = "models/daktanks/engine4.mdl"
		self.DakFuelReq = 360
		self.DakHP = 600
	elseif self.DakName == "Huge Engine" then
		self.DakMaxHealth = 150
		self.DakArmor = 150
		self.DakMass = 2120
		self.DakSpeed = 11.1111
		self.DakModel = "models/daktanks/engine5.mdl"
		self.DakFuelReq = 600
		self.DakHP = 1000
	elseif self.DakName == "Ultra Engine" then
		self.DakMaxHealth = 360
		self.DakArmor = 360
		self.DakMass = 5020
		self.DakSpeed = 26.6666
		self.DakModel = "models/daktanks/engine6.mdl"
		self.DakFuelReq = 1440
		self.DakHP = 2400
	end

	if not self.FirstCheck and not (self.DakMaxHealth == 25) then
		self.FirstCheck = true
		self.DakHealth = self.DakMaxHealth
	end

	if self.DakHealth > self.DakMaxHealth then self.DakHealth = self.DakMaxHealth end
	self.DakSpeed = self.DakSpeed * (self.DakHealth / self.DakMaxHealth) * math.Clamp(self:GetHorsePowerMultiplier(), 0, 1) --Would be better to do this in ontake damage, but these values are reset every think.
	self.DakHP = self.DakHP * (self.DakHealth / self.DakMaxHealth) * math.Clamp(self:GetHorsePowerMultiplier(), 0, 1)
	if self.initsound ~= self.DakSound then
		self.initsound = self.DakSound
		self.Sound:Stop()
		self.Sound = CreateSound(self, self.DakSound, CReliableBroadcastRecipientFilter)
		self.Sound:PlayEx(1, 100)
		self.Sound:ChangePitch(0, 0)
		self.Sound:ChangeVolume(0, 0)
	end

	if self.DakModel and not (self:GetModel() == self.DakModel) then
		self:SetModel(self.DakModel)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
	end

	if self:GetPhysicsObject():GetMass() ~= self.DakMass then self:GetPhysicsObject():SetMass(self.DakMass) end
	if self.DakDead then
		self.DakHP = 0
		self.DakHealth = 0
	elseif self:IsOnFire() then
		local Dmg = self.DakMaxHealth * 0.025 * 0.25
		self.DakHealth = self.DakHealth - Dmg
		self:DTOnTakeDamage(Dmg)
	end

	self:NextThink(CurTime() + 0.25)
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
		if not Ent.EntityMods.DakTek.DakColor then
		else
			self:SetColor(Ent.EntityMods.DakTek.DakColor)
		end

		Ent.EntityMods.DakTek = nil
	end

	self.BaseClass.PostEntityPaste(self, Player, Ent, CreatedEntities)
end

function ENT:OnRemove()
	self.Sound:Stop()
end