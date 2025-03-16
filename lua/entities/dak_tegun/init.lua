AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

util.AddNetworkString("daktankshotfired")

local DTTE = DTTE
local Weapons = DTTE.Classes.Weapons

ENT.DakOwner = NULL
ENT.DakName = "Base Gun"
ENT.DakModel = "models/daktanks/cannon25mm.mdl"
ENT.DakCooldown = 1
ENT.DakMaxHealth = 1
ENT.DakHealth = 1
ENT.DakAmmo = 0
ENT.DakMass = 1
ENT.DakAmmoType = ""
ENT.DakFireEffect = ""
ENT.DakFirePitch = 100
ENT.DakPellets = 1
--shell definition
ENT.DakShellTrail = "a"
ENT.DakShellVelocity = 1
ENT.DakShellDamage = 1
ENT.DakShellPenSounds = {}
ENT.DakShellMass = 1
ENT.DakShellSplashDamage = 1
ENT.DakShellPenetration = 1
ENT.DakShellExplosive = false
ENT.DakShellBlastRadius = 100
ENT.DakPenLossPerMeter = 0.0005
ENT.DakPooled = 0
ENT.DakArmor = 1
ENT.DakTankCore = nil
ENT.DakCrew = NULL
ENT.BasicVelocity = 29527.6
ENT.muzzle = NULL
ENT.ShellLengthMult = 1
ENT.ShellLengthExact = 1
ENT.DakGunType = "Cannon"
ENT.DakCaliber = 0

function ENT:Initialize()
	self.ShellLoaded = 0
	self.ShellLoaded2 = 0
	self.DakHealth = self.DakMaxHealth

	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)

	self.timer = CurTime()
	self.timer2 = CurTime()

	self.Inputs = Wire_CreateInputs(self, { "Fire", "SwapAmmo", "Indicator [ENTITY]", "FuzeDelay" })
	self.Outputs = WireLib.CreateOutputs( self, { "Cooldown" , "CooldownPercent", "MaxCooldown", "Ammo", "AmmoType [STRING]", "MuzzleVel", "ShellMass", "Penetration" } )
	self.Held = false
	self.Soundtime = CurTime()
	self.SlowThinkTime = 0
	self.MidThinkTime = CurTime()
	self.LastFireTime = CurTime()
	self.CurrentAmmoType = 1
	self.DakBurnStacks = 0
	self.BasicVelocity = 29527.6
	self.AutoSwapStacks = 0

	self.CooldownDistanceModifier = 1
	self.CooldownWeightMod = 5000
	self:SetNWFloat("Caliber",self.DakCaliber)

	self.muzzle = ents.Create("prop_physics")
	self.muzzle:SetAngles(self:GetForward():Angle() + Angle(0, -90, 0))
	self.muzzle:SetPos(self:GetPos())
	self.muzzle:SetMoveType(MOVETYPE_NONE)
	self.muzzle:PhysicsInit(SOLID_NONE)
	self.muzzle:SetParent(self)
	self.muzzle:SetModel( "models/daktanks/smokelauncher40mm.mdl" )
	self.muzzle:DrawShadow(false)
	self.muzzle:SetColor( Color(255, 255, 255, 0) )
	self.muzzle:SetRenderMode( RENDERMODE_TRANSCOLOR )
	self.muzzle:Spawn()
	self.muzzle:Activate()
	self.muzzle:SetMoveType(MOVETYPE_NONE)
	self.muzzle:PhysicsInit(SOLID_NONE)
end

function ENT:Think()
	self.FuzeDelay = self.Inputs.FuzeDelay.Value

	if self.ScaleSet == true then
		if self.DakGunType == nil then self:Remove() end
		if self:GetModel() ~= self.DakModel then
			self:SetModel(self.DakModel)
			--self:PhysicsInit(SOLID_VPHYSICS)
			self:SetMoveType(MOVETYPE_VPHYSICS)
			self:SetSolid(SOLID_VPHYSICS)
		end
		if self.DakCaliber ~= nil then
			if self.ScalingFinished == nil then
				self.ScalingFinished = true
				local muzzlepos1
				local muzzlepos2
				muzzlepos1, muzzlepos2 = self:GetModelBounds()
				local length = math.Max(math.abs(muzzlepos1.x),math.abs(muzzlepos1.y),math.abs(muzzlepos1.z),math.abs(muzzlepos2.x),math.abs(muzzlepos2.y),math.abs(muzzlepos2.z))*(self.DakCaliber/100)
				self.muzzle:SetPos(self:GetPos()+self:GetForward()*length)
				if IsValid(self.Controller) and self.Controller.DakFinishedPasting == 1 then
					if self:GetParent():IsValid() == false then
						self.DakOwner:ChatPrint("Parenting Error on "..self.DakName..". Please reparent, make sure the gate is parented to the aimer prop and the gun is parented to the gate.")
					else
						if self:GetParent():GetParent():IsValid() == false then
							self.DakOwner:ChatPrint("Parenting Error on "..self.DakName..". Please reparent, make sure the gate is parented to the aimer prop and the gun is parented to the gate.")
						end
					end
				end
			end
		end
		if CurTime() >= self.SlowThinkTime + 1 then
			if self.DakAmmoType == self.DakATGM then
				if self.DakCaliber ~= nil then
					self.BaseDakShellMass = (math.pi*((self.DakCaliber*0.001*0.5)^2)*(self.DakCaliber*0.001*6.5))*self.CooldownWeightMod
					self.DakCooldown = 0.75*self.BaseDakShellMass*self.CooldownDistanceModifier
					if self.DakGunType == "Dual ATGM Launcher" or self.DakGunType == "ATGM Launcher" then
						self.DakCooldown = self.DakCooldown*2
					end
				end
			end

			--if not(self.BaseDakShellDamage==nil) then self.DakShellSplashDamage = self.BaseDakShellDamage/2 end
			self.Loaders = 0
			self.Crew = {}
			if self.DakTankCore and self.TurretController then
				if self.DakTankCore.Crew then
					if #self.DakTankCore.Crew>0 then
						for i=1, #self.DakTankCore.Crew do
							if (self.DakTankCore.Crew[i].DakEntity == self or self.DakTankCore.Crew[i].DakEntity2 == self) and self.DakTankCore.Crew[i].DakDead ~= true then
								if IsValid(self.TurretController.TurretBase) and (self.TurretController:GetYawMin()+self.TurretController:GetYawMax()>90) then
									if self.DakTankCore.Crew[i]:IsValid() then
										if self.DakTankCore.Crew[i]:GetParent():IsValid() then
											if self.DakTankCore.Crew[i]:GetParent():GetParent():IsValid() then
												if self.DakTankCore.Crew[i]:GetParent():GetParent() == self.TurretController.TurretBase or self.DakTankCore.Crew[i]:GetParent():GetParent() == self:GetParent():GetParent() then
													if self.DakTankCore.Crew[i].BusyEnt == nil or (IsValid(self.DakTankCore.Crew[i].BusyEnt) and self.DakTankCore.Crew[i].BusyEnt == self) then self.Loaders = self.Loaders + 1	end
													if self.DakTankCore.Crew[i].Job == nil then self.DakTankCore.Crew[i].Job = 3 end
													self.Crew[#self.Crew+1] = self.DakTankCore.Crew[i]
												end
											end
										end
									end
								else
									if self.DakTankCore.Crew[i].BusyEnt == nil or (IsValid(self.DakTankCore.Crew[i].BusyEnt) and self.DakTankCore.Crew[i].BusyEnt == self) then self.Loaders = self.Loaders + 1	end
									if self.DakTankCore.Crew[i].Job == nil then self.DakTankCore.Crew[i].Job = 3 end
									self.Crew[#self.Crew+1] = self.DakTankCore.Crew[i]
								end
							end
						end
					end
					if self.Loaders < math.Max(math.Round( self.BaseDakShellMass/25 ) , 1) then
						self.DakCooldown = self.DakCooldown / (1/(math.Max(math.Round( self.BaseDakShellMass/25 ) , 1)+1))
					end
				end
			end

			local isCrewBusy = self.ShellLoaded ~= 1 and (self.ReadyRounds ~= 2 or (self.ReadyRounds == 2 and self.ShellLoaded2 ~= 1))

			if #self.Crew > 0 then
				for i = 1, #self.Crew do
					self.Crew[i].Busy = isCrewBusy
					self.Crew[i].BusyEnt = isCrewBusy and self or nil
				end
			end

			if self:GetParent():IsValid() and self:GetParent():GetParent():IsValid() and self.Controller ~= nil then
				local breechoffset
				breechoffset, _ = self:GetModelBounds()
				breechoffset = math.abs(breechoffset.x * (self.DakCaliber / 100)) * -1
				local startPos = self:GetPos() + self:GetForward() * breechoffset
				local caliber = self.DakCaliber * 0.5
				local filter = {self, self:GetParent(), self:GetParent():GetParent()}
				local BackDist = DTTE.SimpleRecurseTrace(startPos, startPos - (self:GetForward() * 1000), caliber, filter, self, false)
				local LeftDist = DTTE.SimpleRecurseTrace(startPos, startPos - (self:GetRight() * 1000), caliber, filter, self, false)
				local RightDist = DTTE.SimpleRecurseTrace(startPos, startPos + (self:GetRight() * 1000), caliber, filter, self, false)
				local UpDist = DTTE.SimpleRecurseTrace(startPos, startPos + (self:GetUp() * 1000), caliber, filter, self, false)
				local DownDist = DTTE.SimpleRecurseTrace(startPos, startPos - (self:GetUp() * 1000), caliber, filter, self, false)
				local ShellSize = (self.ShellLengthMult * 10 * self.DakCaliber * 0.0393701)
				if self.ReloadMult == nil then
					local quickmult = ( math.min((BackDist/ShellSize),2) + math.min((LeftDist/ShellSize),2) + math.min((RightDist/ShellSize),2) + math.min((UpDist/ShellSize),2) + math.min((DownDist/ShellSize),2) )*0.2
					self.DakOwner:ChatPrint("Reload speed on "..self.DakName.." #"..self:EntIndex() .. " at default position: "..(math.Round(quickmult,2)*100) .. "%.")
					if math.Round(BackDist,2) < math.Round(ShellSize,2) then
						self.DakOwner:ChatPrint("WARNING: "..self.DakName.." #"..self:EntIndex() .. " does not have ample room to load shell, reload time doubled. Required space behind breech: "..math.Round(ShellSize,2) .. " inches, given space: "..math.Round(BackDist,2) .. " inches.")
					end
				end
				self.ReloadMult = ( math.min((BackDist/ShellSize),2) + math.min((LeftDist/ShellSize),2) + math.min((RightDist/ShellSize),2) + math.min((UpDist/ShellSize),2) + math.min((DownDist/ShellSize),2) )*0.2
				self.DakCooldown = self.DakCooldown / self.ReloadMult
				if math.Round(BackDist,2) < math.Round(ShellSize,2) then
					self.DakCooldown = self.DakCooldown * 2
				end
			end
			self.DakCooldown = math.max(self.DakCooldown,1.25)
			if self.DakHealth > self.DakMaxHealth then
				self.DakHealth = self.DakMaxHealth
			end
			if self.DakFireSound2 == nil then
				self.DakFireSound2 = self.DakFireSound1
			end
			if self.DakFireSound3 == nil then
				self.DakFireSound3 = self.DakFireSound1
			end

			self:DakTEAmmoCheck()
		end

		if CurTime() >= self.MidThinkTime + 0.33 and self.BaseDakShellDamage ~= nil then
			self:DakTEAmmoCheck()
			if self.ShellLoaded == 1 or self.ShellLoaded2 == 1 then
				WireLib.TriggerOutput(self, "Cooldown", 0)
				WireLib.TriggerOutput(self, "CooldownPercent", 0)
			else
				WireLib.TriggerOutput(self, "Cooldown", math.Clamp((self.LastFireTime + self.DakCooldown) - CurTime(), 0, 10000))
				WireLib.TriggerOutput(self, "CooldownPercent", 100 * (math.Clamp((self.LastFireTime + self.DakCooldown) - CurTime(), 0, 100) / self.DakCooldown))
			end
			WireLib.TriggerOutput(self, "MaxCooldown",self.DakCooldown)
			self.MidThinkTime = CurTime()
		end
	end

	if CurTime() >= self.SlowThinkTime + 1 then
		local curGun = Weapons[self.DakGunType]
		local ammoPrefix = curGun.ShortName or ""
		local sizeMult = curGun.SizeMult or 1

		self.ShellLengthMult = curGun.ShellLengthMult or 1
		self.ShellLengthExact = curGun.ShellLengthExact or 1
		self.recoilless = curGun.Recoilless or false
		self.ReadyRounds = curGun.ReadyRounds or 0

		if curGun.SetSound and self.DakFireSound1 == nil then
			self.DakFireSound1 = curGun.SetSound(self.DakCaliber)
		end

		local shellLength = self.ShellLengthMult * 50
		self.DakName = self.DakCaliber .. "mm " .. self.DakGunType
		self.DakMaxHealth = self.DakCaliber
		self.DakArmor = self.DakCaliber * 5 * sizeMult
		self.DakMass = math.Round(sizeMult * ((((self.DakCaliber * self.ShellLengthExact) * (self.DakCaliber * 3) * (self.DakCaliber * 3)) + (math.pi * (self.DakCaliber ^ 2) * (self.DakCaliber * shellLength)) - (math.pi * ((self.DakCaliber / 2) ^ 2) * (self.DakCaliber * shellLength))) * 0.001 * 7.8125) / 1000)

		self.DakAP = math.Round(self.DakCaliber, 2) .. "mm" .. ammoPrefix .. "APAmmo"
		self.DakHE = math.Round(self.DakCaliber, 2) .. "mm" .. ammoPrefix .. "HEAmmo"
		self.DakHEAT = math.Round(self.DakCaliber, 2) .. "mm" .. ammoPrefix .. "HEATAmmo"
		self.DakHESH = math.Round(self.DakCaliber, 2) .. "mm" .. ammoPrefix .. "HESHAmmo"
		self.DakHVAP = math.Round(self.DakCaliber, 2) .. "mm" .. ammoPrefix .. "HVAPAmmo"
		self.DakATGM = math.Round(self.DakCaliber, 2) .. "mm" .. ammoPrefix .. "ATGMAmmo"
		self.DakHEATFS = math.Round(self.DakCaliber, 2) .. "mm" .. ammoPrefix .. "HEATFSAmmo"
		self.DakAPFSDS = math.Round(self.DakCaliber, 2) .. "mm" .. ammoPrefix .. "APFSDSAmmo"
		self.DakAPHE = math.Round(self.DakCaliber, 2) .. "mm" .. ammoPrefix .. "APHEAmmo"
		self.DakAPDS = math.Round(self.DakCaliber, 2) .. "mm" .. ammoPrefix .. "APDSAmmo"
		self.DakSM = math.Round(self.DakCaliber, 2) .. "mm" .. ammoPrefix .. "SMAmmo"

		self.BaseDakShellDamage = (math.pi * ((self.DakCaliber * 0.02 * 0.5) ^ 2) * (self.DakCaliber * 0.02 * self.ShellLengthExact)) * 25
		--get the volume of shell and multiply by density of steel
		--pi*radius^2 * height * density
		--Shell length ratio: Long Cannon - 9, Cannon - 6.5, Short Cannon - 5, Howitzer - 4, Mortar - 2.75
		self.BaseDakShellMass = (math.pi * ((self.DakCaliber * 0.001 * 0.5) ^ 2) * (self.DakCaliber * 0.001 * self.ShellLengthExact)) * self.CooldownWeightMod
		--print((math.pi*((75*0.001*0.5)^2)*(75*0.001*6.5))*7700)
		--print((math.pi*((200*0.001*0.5)^2)*(200*0.001*6.5))*7700)

		self.DakCooldown = (0.2484886 * self.BaseDakShellMass + 1.279318) * self.CooldownDistanceModifier
		self.DakShellSplashDamage = self.DakCaliber * 5
		self.BaseDakShellPenetration = (self.DakCaliber * 2) * self.ShellLengthMult
		--self.DakShellExplosive = false
		self.DakShellBlastRadius = (((self.DakCaliber / 155) * 50) * 39) * (-0.005372093 * shellLength + 1.118186)
		self.DakBaseShellFragPen = (2.137015 - 0.1086095 * self.DakCaliber + 0.002989107 * self.DakCaliber ^ 2) * (-0.005372093 * shellLength + 1.118186)

		self.DakFireEffect = "dakteballisticfire"
		self.DakFirePitch = 100
		self.DakShellTrail = "dakteballistictracer"
		self.BaseDakShellVelocity = self.BasicVelocity * self.ShellLengthMult
		self.DakPellets = 10

		if self.DakCaliber <= 75 then
			self.DakShellPenSounds = {"daktanks/daksmallpen1.mp3","daktanks/daksmallpen2.mp3","daktanks/daksmallpen3.mp3","daktanks/daksmallpen4.mp3"}
			self.ReloadSound = "daktanks/dakreloadlight.mp3"
		end
		if self.DakCaliber > 75 and self.DakCaliber < 120 then
			self.DakShellPenSounds = {"daktanks/dakmedpen1.mp3","daktanks/dakmedpen2.mp3","daktanks/dakmedpen3.mp3","daktanks/dakmedpen4.mp3","daktanks/dakmedpen5.mp3"}
			self.ReloadSound = "daktanks/dakreloadmedium.mp3"
		end
		if self.DakCaliber >= 120 then
			self.DakShellPenSounds = {"daktanks/dakhevpen1.mp3","daktanks/dakhevpen2.mp3","daktanks/dakhevpen3.mp3","daktanks/dakhevpen4.mp3","daktanks/dakhevpen5.mp3"}
			self.ReloadSound = "daktanks/dakreloadheavy.mp3"
		end

		local physObj = self:GetPhysicsObject()

		if physObj:IsValid() then
			if physObj:GetMass() ~= self.DakMass then
				physObj:SetMass(self.DakMass)
			end

			self.DakArmor = 3.90625 * (physObj:GetMass() / 4.6311781) * (288 / physObj:GetSurfaceArea()) - self.DakBurnStacks * 0.25
		end

		self.SlowThinkTime = CurTime()
	end

	if CurTime() > (self.timer + self.DakCooldown) then
		self.ShellLoaded = 1
	end

	if self.ReadyRounds == 2 and CurTime() > (self.timer2 + self.DakCooldown) then
		self.ShellLoaded2 = 1
	end

	self:NextThink(CurTime() + 0.1)

	return true
end

function ENT:DakTEAmmoUpdate()
	if self.CurrentAmmoType == 1 then
		WireLib.TriggerOutput(self, "AmmoType", "Armor Piercing")
		self.DakAmmoType = self.DakAP
		self.DakShellAmmoType = "AP"
		self.DakShellExplosive = false
		self.DakShellDamage = self.BaseDakShellDamage
		self.DakShellMass = self.BaseDakShellMass
		self.DakShellPenetration = self.BaseDakShellPenetration
		self.DakShellVelocity = self.BaseDakShellVelocity
		self.DakPenLossPerMeter = 0.0005
		self.DakShellFragPen = 0
		self.CooldownWeightMod = 5150
	end
	if self.CurrentAmmoType == 2 then
		WireLib.TriggerOutput(self, "AmmoType", "High Explosive")
		self.DakAmmoType = self.DakHE
		self.DakShellAmmoType = "HE"
		self.DakShellExplosive = true
		self.DakShellDamage = self.BaseDakShellDamage/2
		self.DakShellMass = self.BaseDakShellMass
		self.DakShellPenetration = self.DakMaxHealth*0.2
		self.DakShellVelocity = self.BaseDakShellVelocity
		self.DakPenLossPerMeter = 0.0005
		self.DakShellFragPen = self.DakBaseShellFragPen*0.1
		self.CooldownWeightMod = 5350
	end
	if self.CurrentAmmoType == 3 then
		WireLib.TriggerOutput(self, "AmmoType", "High Explosive Anti Tank")
		self.DakAmmoType = self.DakHEAT
		self.DakShellAmmoType = "HEAT"
		self.DakShellExplosive = true
		self.DakShellDamage = self.BaseDakShellDamage/8
		self.DakShellMass = self.BaseDakShellMass/8
		self.DakShellPenetration = self.DakMaxHealth*1.20
		if self.DakTankCore.ColdWar and self.DakTankCore.Modern then
			if self.DakTankCore.ColdWar == 1 or self.DakTankCore.Modern == 1 then
				self.DakShellPenetration = self.DakMaxHealth*5.4*0.431
			end
		end
		self.DakShellVelocity = self.BaseDakShellVelocity*0.75
		self.DakPenLossPerMeter = 0.0
		self.DakShellFragPen = self.DakBaseShellFragPen*0.75*0.1
		self.CooldownWeightMod = 3550
	end
	if self.CurrentAmmoType == 4 then
		WireLib.TriggerOutput(self, "AmmoType", "High Velocity Armor Piercing")
		self.DakAmmoType = self.DakHVAP
		self.DakShellAmmoType = "HVAP"
		self.DakShellExplosive = false
		self.DakShellDamage = self.BaseDakShellDamage/4
		self.DakShellMass = self.BaseDakShellMass/4
		self.DakShellPenetration = self.BaseDakShellPenetration*1.5
		self.DakShellVelocity = self.BaseDakShellVelocity*4/3
		self.DakPenLossPerMeter = 0.001
		self.DakShellFragPen = 0
		self.CooldownWeightMod = 3725
	end
	if self.CurrentAmmoType == 5 then
		WireLib.TriggerOutput(self, "AmmoType", "High Explosive Squash Head")
		self.DakAmmoType = self.DakHESH
		self.DakShellAmmoType = "HESH"
		self.DakShellExplosive = true
		self.DakShellDamage = 0
		self.DakShellMass = self.BaseDakShellMass
		self.DakShellPenetration = self.DakMaxHealth*0.05
		self.DakShellVelocity = self.BaseDakShellVelocity
		self.DakPenLossPerMeter = 0.0
		self.DakShellFragPen = 0
		self.CooldownWeightMod = 3450
	end
	if self.CurrentAmmoType == 6 then
		WireLib.TriggerOutput(self, "AmmoType", "Anti Tank Guided Missile")
		self.DakAmmoType = self.DakATGM
		self.DakShellAmmoType = "HEATFS"
		self.DakShellExplosive = true
		self.DakShellDamage = self.BaseDakShellDamage/8
		self.DakShellMass = self.BaseDakShellMass/8
		self.DakShellPenetration = self.DakMaxHealth*6.40
		if self.DakTankCore.ColdWar and self.DakTankCore.Modern then
			if self.DakTankCore.ColdWar == 1 and self.DakTankCore.Modern == 0 then
				self.DakShellPenetration = self.DakMaxHealth*6.40*0.45
			end
		end
		self.DakShellVelocity = 12600
		self.DakPenLossPerMeter = 0.0
		self.DakShellFragPen = self.DakBaseShellFragPen*0.75*0.1
		self.CooldownWeightMod = 3550
	end
	if self.CurrentAmmoType == 7 then
		WireLib.TriggerOutput(self, "AmmoType", "High Explosive Anti Tank Fin Stabilized")
		self.DakAmmoType = self.DakHEATFS
		self.DakShellAmmoType = "HEATFS"
		self.DakShellExplosive = true
		self.DakShellDamage = self.BaseDakShellDamage/8
		self.DakShellMass = self.BaseDakShellMass/8
		self.DakShellPenetration = self.DakMaxHealth*5.40
		if self.DakTankCore.ColdWar and self.DakTankCore.Modern then
			if self.DakTankCore.ColdWar == 1 and self.DakTankCore.Modern == 0 then
				self.DakShellPenetration = self.DakMaxHealth*5.40*0.658
			end
		end
		self.DakShellVelocity = self.BaseDakShellVelocity*1.3333
		self.DakPenLossPerMeter = 0.0
		self.DakShellFragPen = self.DakBaseShellFragPen*0.75*0.1
		self.CooldownWeightMod = 3550
	end
	if self.CurrentAmmoType == 8 then
		WireLib.TriggerOutput(self, "AmmoType", "Armor Piercing Fin Stabilized Discarding Sabot")
		self.DakAmmoType = self.DakAPFSDS
		self.DakShellAmmoType = "APFSDS"
		self.DakShellExplosive = false
		self.DakShellDamage = self.BaseDakShellDamage/8
		self.DakShellMass = self.BaseDakShellMass/8
		self.DakShellPenetration = self.BaseDakShellPenetration*7.8*0.5
		self.DakShellVelocity = self.BaseDakShellVelocity*2.394
		self.DakPenLossPerMeter = 0.001
		self.DakShellFragPen = 0
		self.CooldownWeightMod = 2750
	end
	if self.CurrentAmmoType == 9 then
		WireLib.TriggerOutput(self, "AmmoType", "Armor Piercing High Explosive")
		self.DakAmmoType = self.DakAPHE
		self.DakShellAmmoType = "APHE"
		self.DakShellExplosive = true
		self.DakShellDamage = self.BaseDakShellDamage
		self.DakShellMass = self.BaseDakShellMass
		self.DakShellPenetration = self.BaseDakShellPenetration*0.825
		self.DakShellVelocity = self.BaseDakShellVelocity
		self.DakPenLossPerMeter = 0.0005
		self.DakShellFragPen = self.DakBaseShellFragPen*0.1
		self.CooldownWeightMod = 5450
	end
	if self.CurrentAmmoType == 10 then
		WireLib.TriggerOutput(self, "AmmoType", "Armor Piercing Discarding Sabot")
		self.DakAmmoType = self.DakAPDS
		self.DakShellAmmoType = "APDS"
		self.DakShellExplosive = false
		self.DakShellDamage = self.BaseDakShellDamage/8
		self.DakShellMass = self.BaseDakShellMass/8
		self.DakShellPenetration = self.BaseDakShellPenetration*1.67
		self.DakShellVelocity = self.BaseDakShellVelocity*4/3
		self.DakPenLossPerMeter = 0.001
		self.DakShellFragPen = 0
		self.CooldownWeightMod = 3450
	end
	if self.CurrentAmmoType == 11 then
		WireLib.TriggerOutput(self, "AmmoType", "Smoke")
		self.DakAmmoType = self.DakSM
		self.DakShellAmmoType = "SM"
		self.DakShellExplosive = true
		self.DakShellDamage = self.BaseDakShellDamage/4
		self.DakShellMass = self.BaseDakShellMass
		self.DakShellPenetration = self.DakMaxHealth*0.1
		self.DakShellVelocity = self.BaseDakShellVelocity*0.42
		self.DakPenLossPerMeter = 0.001
		self.DakShellFragPen = 0
		self.CooldownWeightMod = 2700
	end

	WireLib.TriggerOutput(self, "MuzzleVel", self.DakShellVelocity)
	WireLib.TriggerOutput(self, "ShellMass", self.DakShellMass)
	WireLib.TriggerOutput(self, "Penetration", self.DakShellPenetration)
end

local function changeAmmoBox(ent, shouldUnload, shouldSort)
	if not IsValid(ent.DakTankCore) then return end

	local breechoffset
	ent.AmmoCount = 0

	if shouldSort then
		ent.SortedAmmo = {}
		breechoffset = ent:GetModelBounds()
		breechoffset = math.abs(breechoffset.x * (ent.DakCaliber / 100)) * -1
	end

	if ent.DakTankCore.Ammoboxes ~= nil then
		for i = 1, #ent.DakTankCore.Ammoboxes do
			if IsValid(ent.DakTankCore.Ammoboxes[i]) then
				if ent.DakTankCore.Ammoboxes[i].DakAmmoType == ent.DakAmmoType then
					ent.AmmoCount = ent.AmmoCount + ent.DakTankCore.Ammoboxes[i].DakAmmo
				end

				if shouldSort then
					ent.SortedAmmo[#ent.SortedAmmo + 1] = {ent.DakTankCore.Ammoboxes[i], ent.DakTankCore.Ammoboxes[i]:GetPos():Distance(ent:GetPos() + ent:GetForward() * breechoffset)}
				end
			end
		end

		if shouldSort then
			table.sort(ent.SortedAmmo, function(a, b) return a[2] < b[2] end)
		end
	end

	if ent.AmmoCount == 0 and ent.AutoSwapStacks < 9 and IsValid(ent) then
		ent.AutoSwapStacks = ent.AutoSwapStacks + 1
		ent.AmmoSwap = true
		ent:DakTEGunAmmoSwap()
	else
		ent.AutoSwapStacks = 0
	end

	if shouldUnload then
		ent.ShellLoaded = 0
		ent.ShellLoaded2 = 0
	end

	if shouldSort and ent.SortedAmmo ~= nil then
		local found = 0
		local box = 1
		local distance = 0

		while found == 0 and box <= #ent.SortedAmmo do
			if IsValid(ent.SortedAmmo[box][1]) and ent.SortedAmmo[box][1].DakAmmoType == ent.DakAmmoType and ent.SortedAmmo[box][1].DakAmmo > 0 then
				distance = ent.SortedAmmo[box][2]
				found = 1
				ent.CooldownDistanceModifier = math.max( distance, 25 ) / 60
			end

			box = box + 1
		end
	end

	WireLib.TriggerOutput(ent, "Ammo", ent.AmmoCount)
end

function ENT:DakTEAmmoCheck()
	self:DakTEAmmoUpdate()
	changeAmmoBox(self, false, true)
end

function ENT:DakTEFire()
	if self.Firing and self.DakDead ~= true then
		if IsValid(self.DakTankCore) then
			self.AmmoCount = 0
			if self.SortedAmmo ~= nil then
				for i = 1, #self.SortedAmmo do
					if IsValid(self.SortedAmmo[i][1]) then
						if self.SortedAmmo[i][1].DakAmmoType == self.DakAmmoType then
							self.AmmoCount = self.AmmoCount + self.SortedAmmo[i][1].DakAmmo
						end
					end
				end
			end
		end
		if self.AmmoCount > 0 then
			if self.ShellLoaded == 1 or self.ShellLoaded2 == 1 then
				--AMMO CHECK HERE
				for i = 1, #self.SortedAmmo do
					if IsValid(self.SortedAmmo[i][1]) then
						if self.SortedAmmo[i][1].DakAmmoType == self.DakAmmoType then
							if self.SortedAmmo[i][1].DakAmmo > 0 then
								self.SortedAmmo[i][1].DakAmmo = self.SortedAmmo[i][1].DakAmmo-1
							break end
						end
					end
				end
				--FIREBULLETHERE
				if self.ShellLoaded == 1 then
					self.ShellLoaded = 0
					self.timer = CurTime()
				else
					self.ShellLoaded2 = 0
					self.timer2 = CurTime()
				end
				self.LastFireTime = CurTime()
				local shootOrigin = self:GetPos()
				local shootAngles = (self:GetForward()*self.DakShellVelocity):GetNormalized():Angle()
				local initvel = self.DakTankCore:GetVelocity()
				if self.DakTankCore:GetParent():IsValid() then
					initvel = self.DakTankCore:GetParent():GetVelocity()
					if self.DakTankCore:GetParent():GetParent():IsValid() then
						initvel = self.DakTankCore:GetParent():GetParent():GetVelocity()
					end
				end

				local Propellant = math.Clamp(self:GetPropellant(), 10, 100) * 0.01
				local Shell = {}
				Shell.Pos = shootOrigin + ( self:GetForward() * 1 )
				Shell.DakTrail = self.DakShellTrail
				Shell.DakVelocity = ((self.DakShellVelocity * math.Rand( 0.99, 1.01 ) * Propellant) * (shootAngles + Angle(math.Rand(-0.05,0.05),math.Rand(-0.05,0.05),math.Rand(-0.05,0.05))):Forward()) + initvel
				Shell.DakBaseVelocity = self.DakShellVelocity * Propellant
				Shell.Propellant = Propellant
				Shell.DakDamage = self.DakShellDamage * math.Rand( 0.99, 1.01 )
				Shell.DakMass = self.DakShellMass
				Shell.DakIsPellet = false
				Shell.DakSplashDamage = self.DakShellSplashDamage * math.Rand( 0.99, 1.01 )
				Shell.DakPenetration = self.DakShellPenetration * math.Rand( 0.99, 1.01 )
				if self.DakShellAmmoType == "AP" or self.DakShellAmmoType == "HE" or self.DakShellAmmoType == "HVAP" or self.DakShellAmmoType == "APFSDS" or self.DakShellAmmoType == "APHE" or self.DakShellAmmoType == "APDS" or self.DakShellAmmoType == "SM" then
					Shell.DakPenetration = self.DakShellPenetration * math.Rand( 0.99, 1.01 ) * Propellant
				end
				Shell.DakExplosive = self.DakShellExplosive
				Shell.DakBlastRadius = self.DakShellBlastRadius
				Shell.DakPenSounds = self.DakShellPenSounds
				Shell.DakBasePenetration = self.BaseDakShellPenetration
				Shell.DakFragPen = self.DakShellFragPen
				Shell.DakCaliber = self.DakMaxHealth
				if self.CurrentAmmoType == 4 then
					Shell.DakCaliber = self.DakMaxHealth/2
				end
				if self.CurrentAmmoType == 8 or self.CurrentAmmoType == 10 then
					Shell.DakCaliber = self.DakMaxHealth/4
				end
				Shell.DakFireSound = self.DakFireSound1
				Shell.DakFirePitch = self.DakFirePitch
				Shell.DakGun = self
				local Driver = nil
				for i=1, #self.DakTankCore.Seats do
					if Driver == nil then
						if IsValid(self.DakTankCore.Seats[i]:GetDriver()) then
							Driver = self.DakTankCore.Seats[i]:GetDriver()
						end
					end
				end
				Shell.DakGun.DakOwner = Driver
				Shell.Filter = table.Copy(self.DakTankCore.Contraption)
				Shell.LifeTime = 0
				Shell.Gravity = 0
				Shell.DakPenLossPerMeter = self.DakPenLossPerMeter
				Shell.DakShellType = self.DakShellAmmoType
				if self.DakShellAmmoType == "HESH" or self.DakShellAmmoType == "HEAT" or self.DakShellAmmoType == "HEATFS" or self.DakShellAmmoType == "APHE" then
					Shell.DakBlastRadius = self.DakShellBlastRadius * 0.5
					Shell.DakSplashDamage = self.DakShellSplashDamage * math.Rand( 0.99, 1.01 ) * 0.5
				end
				if self.DakShellAmmoType == "SM" then
					Shell.DakBlastRadius = self.DakShellBlastRadius
					Shell.DakSplashDamage = self.DakShellSplashDamage * math.Rand( 0.99, 1.01 ) * 0.1
				end
				if self.DakName == "Flamethrower" then
					Shell.DakIsFlame = 1
				end
				if self.FuzeOverride == true then
					Shell.FuzeDelay = self.FuzeOverrideDelay
				else
					Shell.FuzeDelay = self.FuzeDelay
				end
				if self.DakAmmoType == self.DakATGM then
					Shell.IsGuided = true
					Shell.DakTrail = "daktemissiletracer"
					if IsValid(self.Inputs.Indicator.Value) then
						Shell.Indicator = self.Inputs.Indicator.Value
					else
						Shell.Indicator = self
					end
				end

				DTTE.ShellList[#DTTE.ShellList + 1] = Shell

				local FiringSound = {self.DakFireSound1,self.DakFireSound2,self.DakFireSound3}

				self:SetNWString("FireSound",FiringSound[math.random(1,3)])
				self:SetNWInt("FirePitch",self.DakFirePitch)
				self:SetNWFloat("Caliber",self.DakCaliber)

				net.Start( "daktankshotfired" )
				net.WriteVector( self:GetPos() )
				net.WriteFloat( self.DakCaliber )
				net.WriteString( FiringSound[math.random(1,3)] )
				net.Broadcast()

				self:SetNWBool("Firing",true)
				timer.Create("ResoundTimer" .. self:EntIndex(), 0.1, 1, function()
					self:SetNWBool("Firing", false)
				end)

				timer.Create( "ReloadFinishTimer"..self:EntIndex()..CurTime(), self.DakCooldown-SoundDuration(self.ReloadSound), 1, function()
					if IsValid(self) then
						self:EmitSound( self.ReloadSound, 60, 100, 1, 6)
					end
				end)

				local effectdata = EffectData()
				local muzzlepos1
				local muzzlepos2
				muzzlepos1, muzzlepos2 = self:GetModelBounds()
				local length = math.Max(math.abs(muzzlepos1.x),math.abs(muzzlepos1.y),math.abs(muzzlepos1.z),math.abs(muzzlepos2.x),math.abs(muzzlepos2.y),math.abs(muzzlepos2.z))*(self.DakCaliber/100)
				effectdata:SetOrigin( self:GetPos()+self:GetForward()*length )
				effectdata:SetAngles( self:GetAngles() )
				effectdata:SetEntity(self.muzzle)
				if self.DakGunType == "Dual ATGM Launcher" or self.DakGunType == "ATGM Launcher" then
					effectdata:SetScale( self.DakMaxHealth*0.05 )
				else
					effectdata:SetScale( self.DakMaxHealth*0.25 )
				end
				util.Effect( self.DakFireEffect, effectdata, true, true )
				--self:EmitSound( self.DakFireSound1, 100, self.DakFirePitch, 1, 6)

				if self:IsValid() then
					local recoilMult = (self.DakAmmoType == self.DakATGM or self.recoilless == true) and 0.1 or 1
					local forceDir = (-self:GetForward() * (self.BaseDakShellMass * (self.DakShellVelocity * 0.0254))) / self.DakTankCore.TotalMass

					if self.DakTankCore:GetParent():IsValid() and self.DakTankCore:GetParent():GetParent():IsValid() then
						local physObj = self.DakTankCore:GetParent():GetParent():GetPhysicsObject()
						physObj:ApplyForceOffset(recoilMult * physObj:GetMass() * forceDir, self:GetPos())
					else
						local physObj = self:GetPhysicsObject()
						physObj:ApplyForceCenter(recoilMult * physObj:GetMass() * forceDir)
					end
				end
			end
		end
	end

	changeAmmoBox(self)
end

function ENT:DakTEGunAmmoSwap()
	if self.AmmoSwap then
		self.CurrentAmmoType = self.CurrentAmmoType + 1
		if self.CurrentAmmoType > 11 then
			self.CurrentAmmoType = 1
		end
	else
		self.LastSwapTime = CurTime() - 1
	end

	self.timer = CurTime()
	self.timer2 = CurTime()
	self.LastFireTime = CurTime()

	self:DakTEAmmoUpdate()
	changeAmmoBox(self, true)
end

function ENT:TriggerInput(iname, value)
	if IsValid(self.DakTankCore) and hook.Run("DakTankCanFire", self) ~= false then
		self.Held = value
		if iname == "Fire" then
			if value > 0 then
				self.Firing = value > 0
				self:DakTEFire()
				timer.Create("RefireTimer" .. self:EntIndex(), self.DakCooldown / 10, 1, function()
					if IsValid(self) then
						self:TriggerInput("Fire", value)
					end
				end)
			else
				timer.Remove("RefireTimer" .. self:EntIndex())
			end
		end

		if iname == "SwapAmmo" and value then
			self.AmmoSwap = value > 0
			self:DakTEGunAmmoSwap()
		end
	end
end

function ENT:PreEntityCopy()
	local info = {}
	info.CrewID = self.DakCrew:EntIndex()
	info.DakName = self.DakName
	info.DakMaxHealth = self.DakMaxHealth
	info.DakHealth = self.DakHealth
	info.DakModel = self.DakModel
	info.DakOwner = self.DakOwner
	info.DakColor = self:GetColor()
	info.DakCaliber = self.DakCaliber
	info.DakGunType = self.DakGunType
	info.DakFireSound1 = self.DakFireSound1
	info.DakFireSound2 = self.DakFireSound2
	info.DakFireSound3 = self.DakFireSound3
	info.DakMass = self.DakMass

	-- Materials
	info.DakMat0 = self:GetSubMaterial(0)
	info.DakMat1 = self:GetSubMaterial(1)

	duplicator.StoreEntityModifier( self, "DakTek", info )

	-- Wire dupe info
	self.BaseClass.PreEntityCopy( self )
end

function ENT:PostEntityPaste( Player, Ent, CreatedEntities )
	if Ent.EntityMods and Ent.EntityMods.DakTek then
		local Crew = CreatedEntities[ Ent.EntityMods.DakTek.CrewID ]
		if Crew and IsValid(Crew) then
			self.DakCrew = Crew
		end
		self.DakName = Ent.EntityMods.DakTek.DakName
		self.DakMaxHealth = Ent.EntityMods.DakTek.DakMaxHealth
		self.DakHealth = self.DakMaxHealth
		self.DakModel = Ent.EntityMods.DakTek.DakModel
		self.DakCaliber = Ent.EntityMods.DakTek.DakCaliber
		self:SetNWFloat("Caliber",self.DakCaliber)
		self.DakGunType = Ent.EntityMods.DakTek.DakGunType
		if Ent.EntityMods.DakTek.DakFireSound and Ent.EntityMods.DakTek.DakFireSound1 == "" then
			self.DakFireSound1 = Ent.EntityMods.DakTek.DakFireSound
			self.DakFireSound2 = Ent.EntityMods.DakTek.DakFireSound
			self.DakFireSound3 = Ent.EntityMods.DakTek.DakFireSound
		else
			self.DakFireSound1 = Ent.EntityMods.DakTek.DakFireSound1
			self.DakFireSound2 = Ent.EntityMods.DakTek.DakFireSound2
			self.DakFireSound3 = Ent.EntityMods.DakTek.DakFireSound3
		end
		self.DakMass = Ent.EntityMods.DakTek.DakMass

		self.DakOwner = Player
		self:SetColor(Ent.EntityMods.DakTek.DakColor)
		self:SetSubMaterial( 0, Ent.EntityMods.DakTek.DakMat0 )
		self:SetSubMaterial( 1, Ent.EntityMods.DakTek.DakMat1 )

		self:Activate()

		Ent.EntityMods.DakTek = nil
	end
	self.BaseClass.PostEntityPaste( self, Player, Ent, CreatedEntities )
end