AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local DTTE = DTTE

ENT.DakName = "Base Ammo"
ENT.DakIsExplosive = true
ENT.DakArmor = 5
ENT.DakMaxHealth = 10
ENT.DakHealth = 10
ENT.DakAmmoType = "Base"
ENT.DakPooled = 0

DTTE.RegisterEntClass("dak_teammo")

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self.Inputs = Wire_CreateInputs(self, {"EjectAmmo"})
	self.Outputs = WireLib.CreateOutputs(self, {"Ammo", "MaxAmmo"})
	self.SparkTime = CurTime()
	self.DumpTime = CurTime()
	self.SlowThinkTime = CurTime()
	self.DakArmor = 5
	self.DakMaxHealth = 30
	self.DakHealth = 30
	self.DakBurnStacks = 0
	function self:SetupDataTables()
		self:NetworkVar("Bool", 0, "Firing")
	end
end

function ENT:Think()
	local self = self
	local selfTbl = self:GetTable()

	--Checkspherical moved to slowthink

	if CurTime() >= selfTbl.SparkTime + 0.33 then --This can be improved further but I can't be bothered right now. Ideally this should be inherited from a baseclass anyway.
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

	if CurTime() >= selfTbl.SlowThinkTime + 1 then
		DTTE.CheckSpherical(self)
		if not (selfTbl.DakName == "Base Ammo") then
			selfTbl.DakCaliber = tonumber(string.Split(selfTbl.DakName, "m")[1])
			if selfTbl.DakAmmoType == "Flamethrower Fuel" then
				selfTbl.DakMaxAmmo = 1000
				if not selfTbl.DakAmmo or selfTbl.DakAmmo > selfTbl.DakMaxAmmo then selfTbl.DakAmmo = selfTbl.DakMaxAmmo end
			else
				-- steel density 0.132 kg/in3
				--cannon, launcher, and recoilless rifle
				selfTbl.ShellVolume = math.pi * (((selfTbl.DakCaliber * 0.5) * 0.0393701) ^ 2) * (selfTbl.DakCaliber * 0.0393701 * 13)
				selfTbl.ShellMass = selfTbl.ShellVolume * 0.044
				selfTbl.ShellSquareVolume = ((selfTbl.DakCaliber * 0.0393701) ^ 2) * (selfTbl.DakCaliber * 0.0393701 * 13)
				selfTbl.DakMaxAmmo = math.floor(self:GetPhysicsObject():GetVolume() / selfTbl.ShellSquareVolume)

				--This part is pretty awful. Ammo type, calibre, and gun type shouldn't be stored together in one string.
				--I've Made it so that it at least isn't doing the work of splitting the string repeatedly, but ideally all of this code should just be indexing a table like twice

				local splitString = string.Split(selfTbl.DakName, "m")
				--short cannon and hmg
				if (splitString[3][1] == "S" and splitString[3][2] == "C") or (splitString[3][1] == "H" and splitString[3][2] == "M" and splitString[3][3] == "G") then
					selfTbl.ShellVolume = math.pi * (((selfTbl.DakCaliber * 0.5) * 0.0393701) ^ 2) * (selfTbl.DakCaliber * 0.0393701 * 10)
					selfTbl.ShellSquareVolume = ((selfTbl.DakCaliber * 0.0393701) ^ 2) * (selfTbl.DakCaliber * 0.0393701 * 10)
					selfTbl.DakMaxAmmo = math.floor(self:GetPhysicsObject():GetVolume() / selfTbl.ShellSquareVolume)
				--long cannon
				elseif splitString[3][1] == "L" and splitString[3][2] == "C" then
					selfTbl.ShellVolume = math.pi * (((selfTbl.DakCaliber * 0.5) * 0.0393701) ^ 2) * (selfTbl.DakCaliber * 0.0393701 * 18)
					selfTbl.ShellSquareVolume = ((selfTbl.DakCaliber * 0.0393701) ^ 2) * (selfTbl.DakCaliber * 0.0393701 * 18)
					selfTbl.DakMaxAmmo = math.floor(self:GetPhysicsObject():GetVolume() / selfTbl.ShellSquareVolume)
				--Howitzer
				elseif splitString[3][1] == "H" and splitString[3][2] ~= "M" then
					selfTbl.ShellVolume = math.pi * (((selfTbl.DakCaliber * 0.5) * 0.0393701) ^ 2) * (selfTbl.DakCaliber * 0.0393701 * 8)
					selfTbl.ShellSquareVolume = ((selfTbl.DakCaliber * 0.0393701) ^ 2) * (selfTbl.DakCaliber * 0.0393701 * 8)
					selfTbl.DakMaxAmmo = math.floor(self:GetPhysicsObject():GetVolume() / selfTbl.ShellSquareVolume)
				--Mortar
				elseif splitString[3][1] == "M" and splitString[3][2] ~= "G" then
					selfTbl.ShellVolume = math.pi * (((selfTbl.DakCaliber * 0.5) * 0.0393701) ^ 2) * (selfTbl.DakCaliber * 0.0393701 * 5.5)
					selfTbl.ShellSquareVolume = ((selfTbl.DakCaliber * 0.0393701) ^ 2) * (selfTbl.DakCaliber * 0.0393701 * 5.5)
					selfTbl.DakMaxAmmo = math.floor(self:GetPhysicsObject():GetVolume() / selfTbl.ShellSquareVolume)
				--Grenade Launcher
				elseif splitString[3][1] == "G" and splitString[3][2] == "L" then
					selfTbl.ShellVolume = math.pi * (((selfTbl.DakCaliber * 0.5) * 0.0393701) ^ 2) * (selfTbl.DakCaliber * 0.0393701 * 7)
					selfTbl.ShellSquareVolume = ((selfTbl.DakCaliber * 0.0393701) ^ 2) * (selfTbl.DakCaliber * 0.0393701 * 7)
					selfTbl.DakMaxAmmo = math.floor(self:GetPhysicsObject():GetVolume() / selfTbl.ShellSquareVolume)
				--Smoke Launcher
				elseif splitString[3][1] == "S" and splitString[3][2] == "L" then
					selfTbl.ShellVolume = math.pi * (((selfTbl.DakCaliber * 0.5) * 0.0393701) ^ 2) * (selfTbl.DakCaliber * 0.0393701 * 2.75)
					selfTbl.ShellSquareVolume = ((selfTbl.DakCaliber * 0.0393701) ^ 2) * (selfTbl.DakCaliber * 0.0393701 * 2.75)
					selfTbl.DakMaxAmmo = math.floor(self:GetPhysicsObject():GetVolume() / selfTbl.ShellSquareVolume)
				--ATGM
				elseif (splitString[3][2] .. splitString[3][3] .. splitString[3][4] .. splitString[3][5]) == "ATGM" then
					selfTbl.ShellVolume = math.pi * (((selfTbl.DakCaliber * 0.5) * 0.0393701) ^ 2) * (selfTbl.DakCaliber * 0.0393701 * 13)
					selfTbl.ShellMass = selfTbl.ShellVolume * 0.044
					selfTbl.ShellSquareVolume = ((selfTbl.DakCaliber * 0.0393701) ^ 2) * (selfTbl.DakCaliber * 0.0393701 * 13)
					selfTbl.DakMaxAmmo = math.floor(self:GetPhysicsObject():GetVolume() / selfTbl.ShellSquareVolume)
					selfTbl.DakMaxAmmo = math.floor(selfTbl.DakMaxAmmo * (1 / 1.5))
					selfTbl.ShellVolume = selfTbl.ShellVolume * 1.5
				end

				selfTbl.ShellMass = selfTbl.ShellVolume * 0.044
				if selfTbl.DakAmmo == nil then selfTbl.DakAmmo = selfTbl.DakMaxAmmo end
				if selfTbl.DakAmmo > selfTbl.DakMaxAmmo then selfTbl.DakAmmo = selfTbl.DakMaxAmmo end
			end
		end

		local physObj = self:GetPhysicsObject()
		local mass = physObj:GetMass()
		if selfTbl.DakAmmoType == "Flamethrower Fuel" then
			selfTbl.DakArmor = 12.5
			selfTbl.DakMaxHealth = 30
			if selfTbl.DakHealth >= selfTbl.DakMaxHealth then
				selfTbl.DakHealth = 30
			end
			if mass ~= 500 then
				physObj:SetMass(500)
			end
		else
			selfTbl.DakArmor = 5
			selfTbl.DakMaxHealth = 10
			if selfTbl.DakHealth >= selfTbl.DakMaxHealth then
				selfTbl.DakHealth = 10
			end
			if selfTbl.ShellMass == nil then
				if mass ~= 10 then
					physObj:SetMass(10)
				end
			else
				if mass ~= math.Round((selfTbl.ShellMass * selfTbl.DakAmmo) + 10) then
					physObj:SetMass(math.Round((selfTbl.ShellMass * selfTbl.DakAmmo) + 10))
				end
			end
		end

		WireLib.TriggerOutput(self, "Ammo", selfTbl.DakAmmo)
		WireLib.TriggerOutput(self, "MaxAmmo", selfTbl.DakMaxAmmo)
		if selfTbl.DakDead ~= true then
			selfTbl.DakEjectAmmo = selfTbl.Inputs.EjectAmmo.Value
			if selfTbl.DakEjectAmmo == 1 and CurTime() >= selfTbl.DumpTime + 0.5 and selfTbl.DakAmmo > 0 then
				selfTbl.DakAmmo = selfTbl.DakAmmo - math.Round(selfTbl.DakMaxAmmo / 10, 0)
				if selfTbl.DakAmmo < 0 then selfTbl.DakAmmo = 0 end
				self:EmitSound("dak/Jam.wav", 100, 75, 1)
				selfTbl.DumpTime = CurTime()
			end
		else
			selfTbl.DakAmmo = 0
			selfTbl.DakHealth = 0
		end

		selfTbl.SlowThinkTime = CurTime()
	end

	if self:IsOnFire() and selfTbl.DakDead ~= true then
		selfTbl.DakHealth = selfTbl.DakHealth - 0.1
		self:DTOnTakeDamage(0.1)
	end

	self:NextThink(CurTime() + 0.1)
	return true
end

function ENT:DTOnTakeDamage(Damage)
	if self.DakDead or not self.DakAmmo then return end
	if self.DakHealth <= 0 then
		if self.DakOwner:IsPlayer() and self.DakOwner ~= NULL then self.DakOwner:ChatPrint(self.DakName .. " Destroyed!") end
		self:SetMaterial("models/props_buildings/plasterwall021a")
		self:SetColor(Color(100, 100, 100, 255))
		self.DakDead = true
		return
	end

	if self.DakAmmo <= 0 or self.DakHealth >= (self.DakMaxHealth / 2) or not self.DakIsExplosive then return end
	if self.DakIsHE then
		local effectdata = EffectData()
		effectdata:SetOrigin(self:GetPos())
		effectdata:SetEntity(self)
		effectdata:SetAttachment(1)
		effectdata:SetMagnitude(.5)
		effectdata:SetScale(500)
		effectdata:SetNormal(Vector(0, 0, -1))
		util.Effect("daktescalingexplosionold", effectdata, true, true)
		timer.Create("AmmoBurnTimer" .. self:EntIndex(), 0.1, 5, function()
			if self.DakAmmo == nil or self.DakAmmo <= 0 then return end
			local effectdata2 = EffectData()
			effectdata2:SetOrigin(self:GetPos())
			effectdata2:SetEntity(self)
			effectdata2:SetAttachment(1)
			effectdata2:SetMagnitude(.5)
			effectdata2:SetScale((self.DakAmmo / self.DakMaxAmmo) * 350)
			effectdata2:SetNormal(Vector(0, 0, 1))
			util.Effect("dakteammocook", effectdata2, true, true)
		end)

		self:DTExplosion(self:GetPos(), 50000 * (self.DakAmmo / self.DakMaxAmmo), 500, 500, 300, self.DakOwner)
		sound.Play("daktanks/ammoexplode.mp3", self:GetPos(), 100, 75, 1)
		timer.Create("RemoveTimer" .. self:EntIndex(), 0.5, 1, function()
			if not self:IsValid() then return end
			if self.DakOwner:IsPlayer() and self.DakOwner ~= NULL then self.DakOwner:ChatPrint(self.DakName .. " Exploded!") end
			self:SetMaterial("models/props_buildings/plasterwall021a")
			self:SetColor(Color(100, 100, 100, 255))
			self.DakDead = true
		end)
	else
		if not self.CookingOff then return end
		timer.Create("AmmoDetTimer" .. self:EntIndex(), math.Rand(0.5, 2), self.DakAmmo, function()
			if not self.DakAmmo or self.DakAmmo <= 0 then return end
			local effectdata = EffectData()
			effectdata:SetOrigin(self:GetPos())
			effectdata:SetEntity(self)
			effectdata:SetAttachment(1)
			effectdata:SetMagnitude(.5)
			effectdata:SetScale((self.DakAmmo / self.DakMaxAmmo) * 350)
			effectdata:SetNormal(Vector(0, 0, -1))
			util.Effect("daktescalingexplosionold", effectdata, true, true)
			self:DTExplosion(self:GetPos(), 50000 * (self.DakAmmo / self.DakMaxAmmo), 500, 500, 200, self.DakOwner)
			sound.Play("daktanks/ammoexplode.mp3", self:GetPos(), 100, 75, 1)
			if self.DakOwner:IsPlayer() and self.DakOwner ~= NULL then self.DakOwner:ChatPrint(self.DakName .. " Cooked Off!") end
			self:SetMaterial("models/props_buildings/plasterwall021a")
			self:SetColor(Color(100, 100, 100, 255))
			self.DakDead = true
		end)

		timer.Create("AmmoBurnTimer" .. self:EntIndex(), 0.25, 100, function()
			if not self.DakAmmo or self.DakAmmo <= 0 then return end
			local effectdata2 = EffectData()
			effectdata2:SetOrigin(self:GetPos())
			effectdata2:SetEntity(self)
			effectdata2:SetAttachment(1)
			effectdata2:SetMagnitude(.5)
			effectdata2:SetScale((self.DakAmmo / self.DakMaxAmmo) * 350)
			effectdata2:SetNormal(Vector(0, 0, 1))
			util.Effect("dakteammocook", effectdata2, true, true)
		end)

		timer.Create("AmmoCookTimer" .. self:EntIndex(), math.Clamp(1 / math.pow(self.DakMaxAmmo, 0.5), 0.075, 2) * math.Rand(0.75, 1.25), self.DakAmmo, function()
			if not self.DakAmmo or self.DakAmmo <= 0 then return end
			local shootOrigin = self:GetPos()
			local shootAngles = AngleRand()
			if self.DakMaxAmmo < 5 then
				self.ShellSounds = {"daktanks/dakhevpen1.mp3", "daktanks/dakhevpen2.mp3", "daktanks/dakhevpen3.mp3", "daktanks/dakhevpen4.mp3", "daktanks/dakhevpen5.mp3"}
			elseif self.DakMaxAmmo >= 5 and self.DakMaxAmmo <= 15 then
				self.ShellSounds = {"daktanks/dakmedpen1.mp3", "daktanks/dakmedpen2.mp3", "daktanks/dakmedpen3.mp3", "daktanks/dakmedpen4.mp3", "daktanks/dakmedpen5.mp3"}
			elseif self.DakMaxAmmo > 15 then
				self.ShellSounds = {"daktanks/daksmallpen1.mp3", "daktanks/daksmallpen2.mp3", "daktanks/daksmallpen3.mp3", "daktanks/daksmallpen4.mp3"}
			end

			local shell = {}
			shell.Pos = shootOrigin + (self:GetForward() * 1)
			shell.Ang = shootAngles + Angle(math.Rand(-0.1, 0.1), math.Rand(-0.1, 0.1), math.Rand(-0.1, 0.1))
			shell.DakTrail = "dakshelltrail"
			shell.DakVelocity = 5000
			shell.DakDamage = math.Clamp(200 / self.DakMaxAmmo, 1, 200)
			shell.DakMass = 500 / self.DakMaxAmmo
			shell.DakIsPellet = false
			shell.DakSplashDamage = 0
			shell.DakPenetration = 150 / self.DakMaxAmmo + 10
			shell.DakExplosive = false
			shell.DakBlastRadius = 0
			shell.DakPenSounds = self.ShellSounds
			shell.DakBasePenetration = 150 / self.DakMaxAmmo + 10
			shell.DakCaliber = 500 / self.DakMaxAmmo + 5
			shell.DakFireSound = self.ShellSounds[math.random(1, #self.ShellSounds)]
			shell.DakFirePitch = 100
			shell.DakGun = self
			shell.Filter = {self}
			shell.LifeTime = 0
			shell.Gravity = 0
			shell.DakPenLossPerMeter = 0.0005
			if self.DakName == "Flamethrower" then shell.DakIsFlame = 1 end
			DTTE.ShellList[#DTTE.ShellList + 1] = Shell
			local effectdata = EffectData()
			effectdata:SetOrigin(self:GetPos())
			effectdata:SetEntity(self)
			effectdata:SetAttachment(1)
			effectdata:SetMagnitude(.5)
			effectdata:SetScale(50 / self.DakMaxAmmo)
			util.Effect("dakteshellimpact", effectdata, true, true)
			sound.Play(self.ShellSounds[math.random(1, #self.ShellSounds)], self:GetPos(), 100, 100, 1)
			self.DakAmmo = self.DakAmmo - 1
		end)

		self.CookingOff = 1
	end
end

function ENT:PreEntityCopy()
	local info = {}
	--local entids = {}
	info.DakName = self.DakName
	info.DakIsExplosive = self.DakIsExplosive
	info.DakAmmo = self.DakMaxAmmo
	info.DakMaxAmmo = self.DakMaxAmmo
	info.DakMaxHealth = self.DakMaxHealth
	info.DakHealth = self.DakHealth
	info.DakAmmoType = self.DakAmmoType
	info.DakOwner = self.DakOwner
	info.DakIsHE = self.DakIsHE
	duplicator.StoreEntityModifier(self, "DakTek", info)
	--Wire dupe info
	self.BaseClass.PreEntityCopy(self)
end

function ENT:PostEntityPaste(Player, Ent, CreatedEntities)
	if Ent.EntityMods and Ent.EntityMods.DakTek then
		self.DakName = Ent.EntityMods.DakTek.DakName
		self.DakIsExplosive = Ent.EntityMods.DakTek.DakIsExplosive
		self.DakAmmo = Ent.EntityMods.DakTek.DakMaxAmmo
		self.DakMaxAmmo = Ent.EntityMods.DakTek.DakMaxAmmo
		self.DakMaxHealth = Ent.EntityMods.DakTek.DakMaxHealth
		self.DakHealth = self.DakMaxHealth
		self.DakAmmoType = Ent.EntityMods.DakTek.DakAmmoType
		self.DakOwner = Player
		self.DakIsHE = Ent.EntityMods.DakTek.DakIsHE
		Ent.EntityMods.DakTekLink = nil
	end

	self.BaseClass.PostEntityPaste(self, Player, Ent, CreatedEntities)
	self.DakCaliber = tonumber(string.Split(self.DakName, "m")[1])
	if self.DakAmmoType == "Flamethrower Fuel" then
		self.DakMaxAmmo = 1000
		if not self.DakAmmo then self.DakAmmo = self.DakMaxAmmo end
		if self.DakAmmo > self.DakMaxAmmo then self.DakAmmo = self.DakMaxAmmo end
		if self:GetPhysicsObject():GetMass() ~= 500 then self:GetPhysicsObject():SetMass(500) end
	else
		-- steel density 0.132 kg/in3
		self.ShellVolume = math.pi * (((self.DakCaliber * 0.5) * 0.0393701) ^ 2) * (self.DakCaliber * 0.0393701 * 13)
		self.ShellMass = self.ShellVolume * 0.044
		self.ShellSquareVolume = ((self.DakCaliber * 0.0393701) ^ 2) * (self.DakCaliber * 0.0393701 * 13)
		self.DakMaxAmmo = math.floor(self:GetPhysicsObject():GetVolume() / self.ShellSquareVolume)
		if (string.Split(self.DakName, "m")[3][1] == "S" and string.Split(self.DakName, "m")[3][2] == "C") or (string.Split(self.DakName, "m")[3][1] == "H" and string.Split(self.DakName, "m")[3][2] == "M" and string.Split(self.DakName, "m")[3][3] == "G") then
			self.ShellVolume = math.pi * (((self.DakCaliber * 0.5) * 0.0393701) ^ 2) * (self.DakCaliber * 0.0393701 * 10)
			self.ShellSquareVolume = ((self.DakCaliber * 0.0393701) ^ 2) * (self.DakCaliber * 0.0393701 * 10)
			self.DakMaxAmmo = math.floor(self:GetPhysicsObject():GetVolume() / self.ShellSquareVolume)
		end

		if string.Split(self.DakName, "m")[3][1] == "L" and string.Split(self.DakName, "m")[3][2] == "C" then
			self.ShellVolume = math.pi * (((self.DakCaliber * 0.5) * 0.0393701) ^ 2) * (self.DakCaliber * 0.0393701 * 18)
			self.ShellSquareVolume = ((self.DakCaliber * 0.0393701) ^ 2) * (self.DakCaliber * 0.0393701 * 18)
			self.DakMaxAmmo = math.floor(self:GetPhysicsObject():GetVolume() / self.ShellSquareVolume)
		end

		if string.Split(self.DakName, "m")[3][1] == "H" and string.Split(self.DakName, "m")[3][2] ~= "M" then
			self.ShellVolume = math.pi * (((self.DakCaliber * 0.5) * 0.0393701) ^ 2) * (self.DakCaliber * 0.0393701 * 8)
			self.ShellSquareVolume = ((self.DakCaliber * 0.0393701) ^ 2) * (self.DakCaliber * 0.0393701 * 8)
			self.DakMaxAmmo = math.floor(self:GetPhysicsObject():GetVolume() / self.ShellSquareVolume)
		end

		if string.Split(self.DakName, "m")[3][1] == "M" and string.Split(self.DakName, "m")[3][2] ~= "G" then
			self.ShellVolume = math.pi * (((self.DakCaliber * 0.5) * 0.0393701) ^ 2) * (self.DakCaliber * 0.0393701 * 5.5)
			self.ShellSquareVolume = ((self.DakCaliber * 0.0393701) ^ 2) * (self.DakCaliber * 0.0393701 * 5.5)
			self.DakMaxAmmo = math.floor(self:GetPhysicsObject():GetVolume() / self.ShellSquareVolume)
		end

		if string.Split(self.DakName, "m")[3][1] == "G" and string.Split(self.DakName, "m")[3][2] == "L" then
			self.ShellVolume = math.pi * (((self.DakCaliber * 0.5) * 0.0393701) ^ 2) * (self.DakCaliber * 0.0393701 * 7)
			self.ShellSquareVolume = ((self.DakCaliber * 0.0393701) ^ 2) * (self.DakCaliber * 0.0393701 * 7)
			self.DakMaxAmmo = math.floor(self:GetPhysicsObject():GetVolume() / self.ShellSquareVolume)
		end

		if string.Split(self.DakName, "m")[3][1] == "S" and string.Split(self.DakName, "m")[3][2] == "L" then
			self.ShellVolume = math.pi * (((self.DakCaliber * 0.5) * 0.0393701) ^ 2) * (self.DakCaliber * 0.0393701 * 2.75)
			self.ShellSquareVolume = ((self.DakCaliber * 0.0393701) ^ 2) * (self.DakCaliber * 0.0393701 * 2.75)
			self.DakMaxAmmo = math.floor(self:GetPhysicsObject():GetVolume() / self.ShellSquareVolume)
		end

		if (string.Split(self.DakName, "m")[3][2] .. string.Split(self.DakName, "m")[3][3] .. string.Split(self.DakName, "m")[3][4] .. string.Split(self.DakName, "m")[3][5]) == "ATGM" then
			self.ShellVolume = math.pi * (((self.DakCaliber * 0.5) * 0.0393701) ^ 2) * (self.DakCaliber * 0.0393701 * 13)
			self.ShellMass = self.ShellVolume * 0.044
			self.ShellSquareVolume = ((self.DakCaliber * 0.0393701) ^ 2) * (self.DakCaliber * 0.0393701 * 13)
			self.DakMaxAmmo = math.floor(self:GetPhysicsObject():GetVolume() / self.ShellSquareVolume)
			self.DakMaxAmmo = math.floor(self.DakMaxAmmo * (1 / 1.5))
			self.ShellVolume = self.ShellVolume * 1.5
		end

		self.ShellMass = self.ShellVolume * 0.044
		if self.DakAmmo == nil then self.DakAmmo = self.DakMaxAmmo end
		if self.DakAmmo > self.DakMaxAmmo then self.DakAmmo = self.DakMaxAmmo end
		if self:GetPhysicsObject():GetMass() ~= math.Round((self.ShellMass * self.DakAmmo) + 10) then self:GetPhysicsObject():SetMass(math.Round((self.ShellMass * self.DakAmmo) + 10)) end
	end

	self.DakAmmo = self.DakMaxAmmo
end