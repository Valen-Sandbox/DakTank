AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.DakName = "Autoloader Module"
ENT.DakIsExplosive = true
ENT.DakArmor = 10
ENT.DakMaxHealth = 10
ENT.DakHealth = 10
ENT.DakPooled = 0
ENT.DakGun = nil
ENT.DakMass = 1000
ENT.CanSpark = true

function ENT:DakSlowThink()
	local selfTbl = self:GetTable()

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

	if selfTbl.DakDead ~= true then
		if self:IsOnFire() then
			selfTbl.DakHealth = selfTbl.DakHealth - 5
			self:DTOnTakeDamage(5)
		end
	else
		if IsValid(selfTbl.DakGun) then selfTbl.DakGun.Loaded = 0 end
		selfTbl.DakHealth = 0
	end
end

function ENT:DakOnTakeDamage()
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

function ENT:DakOnCopy(Info)
	Info.DakIsExplosive = self.DakIsExplosive
	if IsValid(self.DakGun) then Info.GunID = self.DakGun:EntIndex() end
	Info.DakColor = self:GetColor()

	-- Materials
	Info.DakMat0 = self:GetSubMaterial(0)
	Info.DakMat1 = self:GetSubMaterial(1)
end

function ENT:DakOnPaste(EntMods, Ent, CreatedEntities)
	self.DakIsExplosive = EntMods.DakIsExplosive
	self:SetSubMaterial(0, EntMods.DakMat0)
	self:SetSubMaterial(1, EntMods.DakMat1)

	local Gun = CreatedEntities[EntMods.GunID]
	if Gun and IsValid(Gun) then self.DakGun = Gun end

	self:Activate()
	Ent.EntityMods.DakTek = nil
end

function ENT:OnRemove()
	if IsValid(self.DakGun) then self.DakGun.Loaded = 0 end
end