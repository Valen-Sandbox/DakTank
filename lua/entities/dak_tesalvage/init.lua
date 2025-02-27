AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

ENT.DakMaxHealth = 10
ENT.DakHealth = 10
ENT.DakArmor = 10
ENT.DakName = "Salvage"
ENT.DakModel = ""
ENT.DakPooled = 0
ENT.DakLastDamagePos = Vector(0,0,0)
ENT.LastHP = 0

local gibsModels = {
	["models/gibs/hgibs.mdl"] = true,
	["models/gibs/hgibs_spine.mdl"] = true,
	["models/gibs/hgibs_rib.mdl"] = true
}
local deathSounds = {
	"daktanks/closeexp1.mp3",
	"daktanks/closeexp2.mp3",
	"daktanks/closeexp3.mp3"
}

function ENT:Initialize()
	if not gibsModels[self:GetModel()] then
		self:SetMaterial("models/props_buildings/plasterwall021a")
	end

	self:SetModel( self.DakModel )
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetColor(Color(100,100,100,255))
	self:SetCollisionGroup( COLLISION_GROUP_WORLD )
	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:Wake()
	end

	self.SpawnTime = CurTime()
	self:EmitSound(deathSounds[math.random(1,#deathSounds)], 100, 100, 1, 3)

	if self:IsValid() and self.launch == 1 and self:GetPhysicsObject():IsValid() then
		self:GetPhysicsObject():ApplyForceCenter(VectorRand() * 70 * self:GetPhysicsObject():GetMass() * math.Rand(5,15))
	end
	if math.random(0,4) == 0 then
		self:Ignite(25,1)
	end
	self.DakBurnStacks = 0
end

function ENT:Think()
	if self:GetModel() == "models/gibs/hgibs_rib.mdl" and (self:GetParent() == NULL or self:GetParent() == nil) then
		local trace = {}
		trace.start = self.LastPos
		trace.endpos = self:GetPos() + self:GetVelocity() * 0.25
		trace.filter = self
		local Hit = util.TraceLine( trace )
		if Hit.Entity:IsValid() then
			self:SetParent(Hit.Entity)
			if Hit.Entity:GetParent():IsValid() then
				self:SetParent(Hit.Entity:GetParent())
				if Hit.Entity:GetParent():GetParent():IsValid() then
					self:SetParent(Hit.Entity:GetParent():GetParent())
				end
			end
			self:SetParent(Hit.Entity)
			self:SetMoveType(MOVETYPE_NONE)
			self:SetPos(Hit.HitPos)
		end
	end

	if self.SpawnTime + 30 < CurTime() then
		self:Remove()
	end

	self:NextThink(CurTime() + 0.25)

	return true
end