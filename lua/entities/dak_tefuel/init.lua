AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local DTTE = DTTE
local FuelTanks = DTTE.Classes.FuelTanks

ENT.DakName = "Standard Fuel Tank"
ENT.DakIsExplosive = true
ENT.DakArmor = 10
ENT.DakMaxHealth = 10
ENT.DakPooled = 0
ENT.DakFuel = 0
ENT.DakMass = 1000
ENT.CanSpark = true

local function RecurseTrace(start, endpos, filter, isInitial)
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
			if not isInitial then
				filter[#filter + 1] = FireTrace.Entity
			end

			RecurseTrace(start, endpos, filter)
		end
	end
end

function ENT:DakSlowThink(selfTbl)
	if selfTbl.DakDead then
		selfTbl.DakHealth = 0
		selfTbl.DakFuel = 0
	end

	local curFuelTank = FuelTanks[selfTbl.DakName]
	selfTbl.DakMass = curFuelTank.Mass
	selfTbl.DakFuel = curFuelTank.Fuel
	selfTbl.DakMaxHealth = curFuelTank.MaxHealth

	selfTbl.DakFuel = selfTbl.DakFuel * (selfTbl.DakHealth / selfTbl.DakMaxHealth)

	if selfTbl.DakDead ~= true and self:IsOnFire() then
		for _ = 1, 10 do
			local Direction = VectorRand()
			local start = self:GetPos()
			local endpos = start + Direction * 50

			RecurseTrace(start, endpos, self, true)
		end

		selfTbl.DakHealth = selfTbl.DakHealth - 1
		self:DTOnTakeDamage(1)
	end
end

function ENT:DakOnTakeDamage()
	if self.DakHealth < (self.DakMaxHealth * 0.5) and self.DakIsExplosive then
		self:Ignite(60, 0)
	end
end

function ENT:DakOnCopy(Info)
	Info.DakIsExplosive = self.DakIsExplosive
end

function ENT:DakOnPaste(EntMods)
	self.DakIsExplosive = EntMods.DakIsExplosive
end