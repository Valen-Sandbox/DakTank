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
ENT.ThinkTime = 0.25
ENT.CanSpark = true

function ENT:DakInitialize()
	self.initsound = self.DakSound
	self.Sound = CreateSound(self, self.DakSound, CReliableBroadcastRecipientFilter)
	self.Sound:PlayEx(1, 100)
	self.Sound:ChangePitch(0, 0)
	self.Sound:ChangeVolume(0, 0)
end

function ENT:DakThink(selfTbl)
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

	if selfTbl.DakDead then
		selfTbl.DakHP = 0
		selfTbl.DakHealth = 0
	elseif self:IsOnFire() then
		local Dmg = selfTbl.DakMaxHealth * 0.025 * 0.25
		selfTbl.DakHealth = selfTbl.DakHealth - Dmg
		self:DTOnTakeDamage(Dmg)
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