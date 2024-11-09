AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
local DTTE = DTTE
ENT.DakName = "Fuel Tank"
ENT.DakIsExplosive = true
ENT.DakArmor = 10
ENT.DakMaxHealth = 10
ENT.DakHealth = 10
ENT.DakPooled = 0
ENT.DakFuel = 0
local function RecurseTrace(start, endpos, filter)
	local trace = {}
	trace.start = start
	trace.endpos = endpos
	trace.filter = filter
	trace.mins = Vector(-1, -1, -1)
	trace.maxs = Vector(1, 1, 1)
	local FireTrace = util.TraceHull(trace)
	if IsValid(FireTrace.Entity) then
		local Class = FireTrace.Entity:GetClass()
		if Class == "dak_crew" or Class == "dak_teammo" or Class == "dak_teautoloadingmodule" or Class == "dak_tefuel" or Class == "dak_tegearbox" or Class == "dak_temotor" or Class == "dak_turretmotor" then FireTrace.Entity:Ignite(60, 0) end
		if FireTrace.Entity.DakArmor == nil then DTTE.SetupNewEnt(FireTrace.Entity) end
		if FireTrace.Entity.DakArmor < 5 or DTTE.CheckClip(FireTrace.Entity, FireTrace.HitPos) then
			filter[#filter + 1] = FireTrace.Entity
			RecurseTrace(start, endpos, filter)
		end
	end
end

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self.DakArmor = 10
	self.DakMass = 1000
	self.PowerMod = 1
	self.DumpTime = CurTime()
	self.SparkTime = CurTime()
	if self.DakHealth > self.DakMaxHealth then self.DakHealth = self.DakMaxHealth end
	self.DakBurnStacks = 0
end

function ENT:Think()
	local self = self
	local selfTbl = self:GetTable()

	DTTE.CheckSpherical(self)
	if selfTbl.DakDead ~= true then
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
	else
		selfTbl.DakHealth = 0
		selfTbl.DakFuel = 0
	end

	local fuelTankStats = {
		--This should probably be defined somewhere else entirely. But for the moment, this is at least an improvement.
		["Micro Fuel Tank"] = {65, 45, 10},
		["Small Fuel Tank"] = {120, 90, 20},
		["Standard Fuel Tank"] = {240, 180, 30},
		["Large Fuel Tank"] = {475, 360, 40},
		["Huge Fuel Tank"] = {950, 720, 50},
		["Ultra Fuel Tank"] = {1900, 1440, 60}
	}

	if fuelTankStats[selfTbl.DakName] then
		selfTbl.DakMass = fuelTankStats[selfTbl.DakName][1]
		selfTbl.DakFuel = fuelTankStats[selfTbl.DakName][2]
		selfTbl.DakMaxHealth = fuelTankStats[selfTbl.DakName][3]
	end

	if selfTbl.DakHealth > selfTbl.DakMaxHealth then selfTbl.DakHealth = selfTbl.DakMaxHealth end
	selfTbl.DakFuel = selfTbl.DakFuel * (selfTbl.DakHealth / selfTbl.DakMaxHealth)
	if self:GetPhysicsObject():GetMass() ~= selfTbl.DakMass then self:GetPhysicsObject():SetMass(selfTbl.DakMass) end
	if selfTbl.DakDead ~= true and self:IsOnFire() then
		for i = 1, 10 do
			local Direction = VectorRand()
			local trace = {}
			trace.start = self:GetPos()
			trace.endpos = self:GetPos() + Direction * 50
			trace.filter = self
			trace.mins = Vector(-1, -1, -1)
			trace.maxs = Vector(1, 1, 1)
			local FireTrace = util.TraceHull(trace)
			if IsValid(FireTrace.Entity) then
				local Class = FireTrace.Entity:GetClass()
				if Class == "dak_crew" or Class == "dak_teammo" or Class == "dak_teautoloadingmodule" or Class == "dak_tefuel" or Class == "dak_tegearbox" or Class == "dak_temotor" or Class == "dak_turretmotor" then FireTrace.Entity:Ignite(60, 0) end
				if FireTrace.Entity.DakArmor == nil then DTTE.SetupNewEnt(FireTrace.Entity) end
				if FireTrace.Entity.DakArmor < 5 or DTTE.CheckClip(FireTrace.Entity, FireTrace.HitPos) then RecurseTrace(self:GetPos(), self:GetPos() + Direction * 50, {self, FireTrace.Entity}) end
			end
		end

		selfTbl.DakHealth = selfTbl.DakHealth - 1
		self:DTOnTakeDamage(1)
	end

	self:NextThink(CurTime() + 1)
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

	if self.DakHealth < (self.DakMaxHealth * 0.5) and self.DakIsExplosive then self:Ignite(60, 0) end
end

function ENT:PreEntityCopy()
	local info = {}
	-- local entids = {}
	info.DakName = self.DakName
	info.DakIsExplosive = self.DakIsExplosive
	info.DakMaxHealth = self.DakMaxHealth
	info.DakHealth = self.DakHealth
	info.DakOwner = self.DakOwner
	duplicator.StoreEntityModifier(self, "DakTek", info)
	-- Wire dupe info
	self.BaseClass.PreEntityCopy(self)
end

function ENT:PostEntityPaste(Player, Ent, CreatedEntities)
	if Ent.EntityMods and Ent.EntityMods.DakTek then
		self.DakName = Ent.EntityMods.DakTek.DakName
		self.DakIsExplosive = Ent.EntityMods.DakTek.DakIsExplosive
		self.DakMaxHealth = Ent.EntityMods.DakTek.DakMaxHealth
		self.DakHealth = self.DakMaxHealth
		self.DakOwner = Player
		Ent.EntityMods.DakTekLink = nil
	end

	self.BaseClass.PostEntityPaste(self, Player, Ent, CreatedEntities)
end