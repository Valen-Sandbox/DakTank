AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
local DTTE = DTTE
ENT.DakName = "Autoloader Module"
ENT.DakIsExplosive = true
ENT.DakArmor = 10
ENT.DakMaxHealth = 10
ENT.DakHealth = 10
ENT.DakPooled = 0
ENT.DakGun = nil
function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self.DakArmor = 10
	self.DakMass = 1000
	self.Soundtime = CurTime()
	self.SparkTime = CurTime()
	if self.DakHealth > self.DakMaxHealth then self.DakHealth = self.DakMaxHealth end
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

	local magNames = {
		["Small Autoloader Clip"] = "Small Autoloader Magazine",
		["Medium Autoloader Clip"] = "Medium Autoloader Magazine",
		["Large Autoloader Clip"] = "Large Autoloader Magazine"
	}

	selfTbl.DakName = magNames[selfTbl.DakName] or selfTbl.DakName
	local magStats = {
		["Small Autoloader Magazine"] = 1000,
		["Medium Autoloader Magazine"] = 2000,
		["Large Autoloader Magazine"] = 3000
	}

	if magStats[selfTbl.DakName] then selfTbl.DakMass = magStats[selfTbl.DakName] end
	if IsValid(selfTbl.DakGun) and selfTbl.DakGun.IsAutoLoader == 1 then --Is there a reason for this to not be a boolean?
		if selfTbl.DakGun.TurretController and IsValid(self:GetParent()) then
			if self:GetParent():GetParent() == selfTbl.DakGun.TurretController.TurretBase or self:GetParent():GetParent() == selfTbl.DakGun:GetParent():GetParent() or (selfTbl.DakGun.TurretController:GetYawMin() <= 45 and selfTbl.DakGun.TurretController:GetYawMax() <= 45) then
				selfTbl.DakGun.DakMagazine = math.floor(0.27 * self:GetPhysicsObject():GetVolume() / (((selfTbl.DakGun.DakCaliber * 0.0393701) ^ 2) * (selfTbl.DakGun.DakCaliber * 0.0393701 * 13 * selfTbl.DakGun.ShellLengthMult)))
				if selfTbl.DakGun.DakMagazine > 0 then
					selfTbl.DakGun.DakReloadTime = selfTbl.DakGun.DakCooldown * selfTbl.DakGun.DakMagazine
					selfTbl.DakGun.HasMag = 1
					selfTbl.DakGun.Loaded = 1
				else
					selfTbl.DakGun.HasMag = 0
					selfTbl.DakGun.Loaded = 0
				end
			else
				selfTbl.DakGun.HasMag = 0
				selfTbl.DakGun.Loaded = 0
			end
		else
			selfTbl.DakGun.DakMagazine = math.floor(0.27 * self:GetPhysicsObject():GetVolume() / (((selfTbl.DakGun.DakCaliber * 0.0393701) ^ 2) * (selfTbl.DakGun.DakCaliber * 0.0393701 * 13 * selfTbl.DakGun.ShellLengthMult)))
			selfTbl.DakGun.DakReloadTime = selfTbl.DakGun.DakCooldown * selfTbl.DakGun.DakMagazine
			if selfTbl.DakGun.DakMagazine > 0 then
				selfTbl.DakGun.DakReloadTime = selfTbl.DakGun.DakCooldown * selfTbl.DakGun.DakMagazine
				selfTbl.DakGun.HasMag = 1
				selfTbl.DakGun.Loaded = 1
			else
				selfTbl.DakGun.HasMag = 0
				selfTbl.DakGun.Loaded = 0
			end
		end
	end

	if selfTbl.DakHealth > selfTbl.DakMaxHealth then selfTbl.DakHealth = selfTbl.DakMaxHealth end
	if self:GetPhysicsObject():GetMass() ~= selfTbl.DakMass then self:GetPhysicsObject():SetMass(selfTbl.DakMass) end
	if selfTbl.DakDead ~= true then
		if self:IsOnFire() then
			selfTbl.DakHealth = selfTbl.DakHealth - 5
			self:DTOnTakeDamage(5)
		end
	else
		if IsValid(selfTbl.DakGun) then selfTbl.DakGun.Loaded = 0 end
		selfTbl.DakHealth = 0
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
		if IsValid(self.DakGun) then self.DakGun.Loaded = 0 end
		return
	end

	if self.DakHealth < self.DakMaxHealth / 2 and self.DakIsExplosive then
		local effectdata = EffectData()
		effectdata:SetOrigin(self:GetPos())
		effectdata:SetEntity(self)
		effectdata:SetAttachment(1)
		effectdata:SetMagnitude(.5)
		effectdata:SetScale(500)
		effectdata:SetNormal(Vector(0, 0, -1))
		util.Effect("daktescalingexplosion", effectdata, true, true)
		self:DTExplosion(self:GetPos(), 20000, 500, 200, 100, self.DakOwner)
		self:EmitSound("daktanks/ammoexplode.mp3", 100, 75, 1)
		if self.DakOwner:IsPlayer() and self.DakOwner ~= NULL then self.DakOwner:ChatPrint(self.DakName .. " Exploded!") end
		self:SetMaterial("models/props_buildings/plasterwall021a")
		self:SetColor(Color(100, 100, 100, 255))
		self.DakDead = true
		if IsValid(self.DakGun) then self.DakGun.Loaded = 0 end
	end
end

function ENT:PreEntityCopy()
	local info = {}
	info.DakName = self.DakName
	info.DakIsExplosive = self.DakIsExplosive
	info.DakMaxHealth = self.DakMaxHealth
	info.DakHealth = self.DakHealth
	info.DakOwner = self.DakOwner
	if IsValid(self.DakGun) then info.GunID = self.DakGun:EntIndex() end
	info.DakColor = self:GetColor()

	--Materials
	info.DakMat0 = self:GetSubMaterial(0)
	info.DakMat1 = self:GetSubMaterial(1)
	duplicator.StoreEntityModifier(self, "DakTek", info)

	--Wire dupe info
	self.BaseClass.PreEntityCopy(self)
end

function ENT:PostEntityPaste(Player, Ent, CreatedEntities)
	if Ent.EntityMods and Ent.EntityMods.DakTek then
		self.DakName = Ent.EntityMods.DakTek.DakName
		self.DakIsExplosive = Ent.EntityMods.DakTek.DakIsExplosive
		self.DakMaxHealth = Ent.EntityMods.DakTek.DakMaxHealth
		self.DakHealth = self.DakMaxHealth
		self.DakOwner = Player
		self:SetColor(Ent.EntityMods.DakTek.DakColor)
		self:SetSubMaterial(0, Ent.EntityMods.DakTek.DakMat0)
		self:SetSubMaterial(1, Ent.EntityMods.DakTek.DakMat1)
		local Gun = CreatedEntities[Ent.EntityMods.DakTek.GunID]
		if Gun and IsValid(Gun) then self.DakGun = Gun end
		self:Activate()
		Ent.EntityMods.DakTek = nil
		Ent.EntityMods.DakTekLink = nil
	end

	self.BaseClass.PostEntityPaste(self, Player, Ent, CreatedEntities)
end

function ENT:OnRemove()
	if IsValid(self.DakGun) then self.DakGun.Loaded = 0 end
end