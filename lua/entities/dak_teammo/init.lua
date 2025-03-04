AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local DTTE = DTTE

ENT.DakName = "Base Ammo"
ENT.DakIsExplosive = true
ENT.DakArmor = 5
ENT.DakMaxHealth = 30
ENT.DakHealth = 10
ENT.DakAmmoType = "Base"
ENT.DakPooled = 0
ENT.CanSpark = true

function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "Firing")
end

function ENT:DakInitialize()
	self.Inputs = Wire_CreateInputs(self, {"EjectAmmo"})
	self.Outputs = WireLib.CreateOutputs(self, {"Ammo", "MaxAmmo"})
	self.DumpTime = CurTime()
end

function ENT:DakThink(selfTbl)
	if self:IsOnFire() and selfTbl.DakDead ~= true then
		selfTbl.DakHealth = selfTbl.DakHealth - 0.1
		self:DTOnTakeDamage(0.1)
	end
end

local function setAmmoSettings(selfTbl, physObj)
	local splitString = string.Split(selfTbl.DakName, "m")

	if selfTbl.DakName ~= "Base Ammo" then
		selfTbl.DakCaliber = tonumber(splitString[1])

		if selfTbl.DakAmmoType == "Flamethrower Fuel" then
			selfTbl.DakMaxAmmo = 1000
		else
			-- steel density 0.132 kg/in3
			--cannon, launcher, and recoilless rifle
			local shellVolumeMult = 1
			local shellSize = 13

			--This part is pretty awful. Ammo type, calibre, and gun type shouldn't be stored together in one string.
			--I've Made it so that it at least isn't doing the work of splitting the string repeatedly, but ideally all of this code should just be indexing a table like twice

			--short cannon and hmg
			if (splitString[3][1] == "S" and splitString[3][2] == "C") or (splitString[3][1] == "H" and splitString[3][2] == "M" and splitString[3][3] == "G") then
				shellSize = 10
			--long cannon
			elseif splitString[3][1] == "L" and splitString[3][2] == "C" then
				shellSize = 18
			--Howitzer
			elseif splitString[3][1] == "H" and splitString[3][2] ~= "M" then
				shellSize = 8
			--Mortar
			elseif splitString[3][1] == "M" and splitString[3][2] ~= "G" then
				shellSize = 5.5
			--Grenade Launcher
			elseif splitString[3][1] == "G" and splitString[3][2] == "L" then
				shellSize = 7
			--Smoke Launcher
			elseif splitString[3][1] == "S" and splitString[3][2] == "L" then
				shellSize = 2.75
			--ATGM
			elseif (splitString[3][2] .. splitString[3][3] .. splitString[3][4] .. splitString[3][5]) == "ATGM" then
				shellSize = 13
				shellVolumeMult = 1.5
			end

			selfTbl.ShellVolume = math.pi * (((selfTbl.DakCaliber * 0.5) * 0.0393701) ^ 2) * (selfTbl.DakCaliber * 0.0393701 * shellSize) * shellVolumeMult
			selfTbl.ShellSquareVolume = ((selfTbl.DakCaliber * 0.0393701) ^ 2) * (selfTbl.DakCaliber * 0.0393701 * shellSize)
			selfTbl.DakMaxAmmo = math.floor((physObj:GetVolume() / selfTbl.ShellSquareVolume) * (1 / shellVolumeMult))
			selfTbl.ShellMass = selfTbl.ShellVolume * 0.044
		end
	end

	if not selfTbl.DakAmmo or selfTbl.DakAmmo > selfTbl.DakMaxAmmo then selfTbl.DakAmmo = selfTbl.DakMaxAmmo end

	local expectedMass = 10

	if selfTbl.DakAmmoType == "Flamethrower Fuel" then
		selfTbl.DakArmor = 12.5
		selfTbl.DakMaxHealth = 30
		expectedMass = 500
	else
		selfTbl.DakArmor = 5
		selfTbl.DakMaxHealth = 10
		expectedMass = selfTbl.ShellMass == nil and 10 or math.Round((selfTbl.ShellMass * selfTbl.DakAmmo) + 10)
	end

	if selfTbl.DakHealth >= selfTbl.DakMaxHealth then
		selfTbl.DakHealth = selfTbl.DakMaxHealth
	end

	if physObj:GetMass() ~= expectedMass then
		physObj:SetMass(expectedMass)
	end
end

function ENT:DakSlowThink(selfTbl)
	local physObj = self:GetPhysicsObject()

	setAmmoSettings(selfTbl, physObj)

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
end

function ENT:DakOnTakeDamage()
	if not self.DakAmmo then return end
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

function ENT:DakOnCopy(Info)
	Info.DakIsExplosive = self.DakIsExplosive
	Info.DakAmmo = self.DakMaxAmmo
	Info.DakMaxAmmo = self.DakMaxAmmo
	Info.DakAmmoType = self.DakAmmoType
	Info.DakIsHE = self.DakIsHE
end

function ENT:DakOnPaste(EntMods)
	self.DakIsExplosive = EntMods.DakIsExplosive
	self.DakMaxAmmo = EntMods.DakMaxAmmo
	self.DakAmmoType = EntMods.DakAmmoType
	self.DakIsHE = EntMods.DakIsHE
	self.DakAmmo = self.DakMaxAmmo

	setAmmoSettings(self:GetTable(), self:GetPhysicsObject())
end