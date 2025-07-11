AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local DTTE = DTTE

ENT.DakEntity = NULL
ENT.DakMaxHealth = 5
ENT.DakHealth = 5
ENT.DakArmor = 2.5
ENT.DakName = "Crew"
ENT.DakMass = 75
ENT.DakPooled = 0

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self.DakHealth = self.DakMaxHealth
	self.SparkTime = CurTime()
	self.DakBurnStacks = 0
	self.LastHealth = 5

	self.VO = self:GetVoice()
	if self.VO == 0 then self.VO = math.random(1, 6) end

	local VO1Death = file.Find("sound/daktanks/crew/aus/death*", "GAME")
	local VO1Pain = file.Find("sound/daktanks/crew/aus/pain*", "GAME")
	local VO1Suffer = file.Find("sound/daktanks/crew/aus/suffer*", "GAME")
	self.VO1Death = VO1Death
	self.VO1Pain = VO1Pain
	self.VO1Suffer = VO1Suffer
	local VO2Death = file.Find("sound/daktanks/crew/fre/death*", "GAME")
	local VO2Pain = file.Find("sound/daktanks/crew/fre/pain*", "GAME")
	local VO2Suffer = file.Find("sound/daktanks/crew/fre/suffer*", "GAME")
	self.VO2Death = VO2Death
	self.VO2Pain = VO2Pain
	self.VO2Suffer = VO2Suffer
	local VO3Death = file.Find("sound/daktanks/crew/ger/death*", "GAME")
	local VO3Pain = file.Find("sound/daktanks/crew/ger/pain*", "GAME")
	local VO3Suffer = file.Find("sound/daktanks/crew/ger/suffer*", "GAME")
	self.VO3Death = VO3Death
	self.VO3Pain = VO3Pain
	self.VO3Suffer = VO3Suffer
	local VO4Death = file.Find("sound/daktanks/crew/rus/death*", "GAME")
	local VO4Pain = file.Find("sound/daktanks/crew/rus/pain*", "GAME")
	local VO4Suffer = file.Find("sound/daktanks/crew/rus/suffer*", "GAME")
	self.VO4Death = VO4Death
	self.VO4Pain = VO4Pain
	self.VO4Suffer = VO4Suffer
	local VO5Death = file.Find("sound/daktanks/crew/sco/death*", "GAME")
	local VO5Pain = file.Find("sound/daktanks/crew/sco/pain*", "GAME")
	local VO5Suffer = file.Find("sound/daktanks/crew/sco/suffer*", "GAME")
	self.VO5Death = VO5Death
	self.VO5Pain = VO5Pain
	self.VO5Suffer = VO5Suffer
	local VO6Death = file.Find("sound/daktanks/crew/us/death*", "GAME")
	local VO6Pain = file.Find("sound/daktanks/crew/us/pain*", "GAME")
	local VO6Suffer = file.Find("sound/daktanks/crew/us/suffer*", "GAME")
	self.VO6Death = VO6Death
	self.VO6Pain = VO6Pain
	self.VO6Suffer = VO6Suffer
end

function ENT:Think()
	DTTE.CheckSpherical(self)
	self.DakMaxHealth = 5
	self.DakArmor = 2.5
	self.DakMass = 75
	if self.DakHealth > self.DakMaxHealth then self.DakHealth = self.DakMaxHealth end
	if self.DakModel and not (self:GetModel() == self.DakModel) then
		self:SetModel(self.DakModel)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
	end

	if self:GetPhysicsObject():GetMass() ~= self.DakMass then self:GetPhysicsObject():SetMass(self.DakMass) end
	self.VO = self:GetVoice()
	if self.VO == 0 then self.VO = math.random(1, 6) end
	if self.DakDead then
		self.DakHealth = 0
		if self.Screamed == nil then self.Screamed = false end
		if self.Screamed == false then
			if self.VO == 1 then
				sound.Play("daktanks/crew/aus/" .. self.VO1Death[math.random(1, #self.VO1Death)], self:GetPos(), 75, 100, 1)
			elseif self.VO == 2 then
				sound.Play("daktanks/crew/fre/" .. self.VO2Death[math.random(1, #self.VO2Death)], self:GetPos(), 75, 100, 1)
			elseif self.VO == 3 then
				sound.Play("daktanks/crew/ger/" .. self.VO3Death[math.random(1, #self.VO3Death)], self:GetPos(), 75, 100, 1)
			elseif self.VO == 4 then
				sound.Play("daktanks/crew/rus/" .. self.VO4Death[math.random(1, #self.VO4Death)], self:GetPos(), 75, 100, 1)
			elseif self.VO == 5 then
				sound.Play("daktanks/crew/sco/" .. self.VO5Death[math.random(1, #self.VO5Death)], self:GetPos(), 75, 100, 1)
			elseif self.VO == 6 then
				sound.Play("daktanks/crew/us/" .. self.VO6Death[math.random(1, #self.VO6Death)], self:GetPos(), 75, 100, 1)
			end

			self.Screamed = true
		end

		if self.RequestedReplacement == nil then self.RequestedReplacement = false end
		if self.RequestedReplacement == false then
			timer.Simple(10, function()
				if self:IsValid() and self.Job ~= nil then
					local ReplacementFound = false
					local CrewNum = 1
					while ReplacementFound == false and CrewNum <= #self.Controller.Crew do
						if self.Controller.Crew[CrewNum]:IsValid() and not (self.Controller.Crew[CrewNum].Job == 2) and (self.Controller.Crew[CrewNum].Job == nil or (self.Controller.Crew[CrewNum].Job ~= nil and (self.Controller.Crew[CrewNum].Job > self.Job or self.Job == 2))) and self.Controller.Crew[CrewNum].DakDead ~= true and (self.Controller.Crew[CrewNum].DakHealth ~= nil and self.Controller.Crew[CrewNum].DakHealth > 0) then
							if self.Job == 1 then -- gunner
								if self.Controller.Crew[CrewNum].Job == 2 then
									self.Controller.Crew[CrewNum].DakDead = true
									self.Controller.Crew[CrewNum]:SetMaterial("models/flesh")
									self:SetMaterial("")
									self.DakDead = false
									ReplacementFound = true
									self.Screamed = false
									self.Controller.Crew[CrewNum].Screamed = true
									self.DakHealth = self.Controller.Crew[CrewNum].DakHealth
									self.Controller.Crew[CrewNum].DakHealth = 0
									self:EmitSound("npc/combine_soldier/gear6.wav", 60, 100, 1, 6)
									local ReplacementFound2 = false
									local CrewNum2 = 1
									while ReplacementFound2 == false and CrewNum2 <= #self.Controller.Crew do
										if self.Controller.Crew[CrewNum2]:IsValid() and (self.Controller.Crew[CrewNum2].Job == nil or (self.Controller.Crew[CrewNum2].Job ~= nil and self.Controller.Crew[CrewNum2].Job > self.Controller.Crew[CrewNum].Job)) and self.Controller.Crew[CrewNum2].DakDead ~= true and self.Controller.Crew[CrewNum2].DakHealth > 0 then
											self.Controller.Crew[CrewNum2].DakDead = true
											self.Controller.Crew[CrewNum2]:SetMaterial("models/flesh")
											self.Controller.Crew[CrewNum]:SetMaterial("")
											self.Controller.Crew[CrewNum].DakDead = false
											ReplacementFound2 = true
											self.Controller.Crew[CrewNum].Screamed = false
											self.Controller.Crew[CrewNum2].Screamed = true
											self.Controller.Crew[CrewNum].DakHealth = self.Controller.Crew[CrewNum2].DakHealth
											self.Controller.Crew[CrewNum2].DakHealth = 0
											self.Controller.Crew[CrewNum]:EmitSound("npc/combine_soldier/gear6.wav", 60, 100, 1, 6)
										end

										CrewNum2 = CrewNum2 + 1
									end
								else
									self.Controller.Crew[CrewNum].DakDead = true
									self.Controller.Crew[CrewNum]:SetMaterial("models/flesh")
									self:SetMaterial("")
									self.DakDead = false
									ReplacementFound = true
									self.Screamed = false
									self.Controller.Crew[CrewNum].Screamed = true
									self.DakHealth = self.Controller.Crew[CrewNum].DakHealth
									self.Controller.Crew[CrewNum].DakHealth = 0
									self:EmitSound("npc/combine_soldier/gear6.wav", 60, 100, 1, 6)
								end
							elseif self.Job == 2 then
								-- driver
								self.Controller.Crew[CrewNum].DakDead = true
								self.Controller.Crew[CrewNum]:SetMaterial("models/flesh")
								self:SetMaterial("")
								self.DakDead = false
								ReplacementFound = true
								self.Screamed = false
								self.Controller.Crew[CrewNum].Screamed = true
								self.DakHealth = self.Controller.Crew[CrewNum].DakHealth
								self.Controller.Crew[CrewNum].DakHealth = 0
								self:EmitSound("npc/combine_soldier/gear6.wav", 60, 100, 1, 6)
							elseif self.Job == 3 then
								-- loader
								self.Controller.Crew[CrewNum].DakDead = true
								self.Controller.Crew[CrewNum]:SetMaterial("models/flesh")
								self:SetMaterial("")
								self.DakDead = false
								ReplacementFound = true
								self.Screamed = false
								self.Controller.Crew[CrewNum].Screamed = true
								self.DakHealth = self.Controller.Crew[CrewNum].DakHealth
								self.Controller.Crew[CrewNum].DakHealth = 0
								self:EmitSound("npc/combine_soldier/gear6.wav", 60, 100, 1, 6)
							end
						end

						if ReplacementFound == false then
							if self.Controller.Crew[CrewNum]:IsValid() and (self.Controller.Crew[CrewNum].Job == 1 and self.Job == 1) and self.Controller.Crew[CrewNum].DakDead ~= true and self.Controller.Crew[CrewNum].DakHealth > 0 then
								if self.DakEntity.GunMass > self.Controller.Crew[CrewNum].DakEntity.GunMass then
									self.Controller.Crew[CrewNum].DakDead = true
									self.Controller.Crew[CrewNum]:SetMaterial("models/flesh")
									self:SetMaterial("")
									self.DakDead = false
									ReplacementFound = true
									self.Screamed = false
									self.Controller.Crew[CrewNum].Screamed = true
									self.DakHealth = self.Controller.Crew[CrewNum].DakHealth
									self.Controller.Crew[CrewNum].DakHealth = 0
									self:EmitSound("npc/combine_soldier/gear6.wav", 60, 100, 1, 6)
								end
							end
						end

						CrewNum = CrewNum + 1
					end

					self.RequestedReplacement = false
				end
			end)

			self.RequestedReplacement = true
		end
	else
		if self.DakHealth ~= self.LastHealth and (self.LastHealth - self.DakHealth) > 0 then
			if (self.LastHealth - self.DakHealth) < 2 then
				--light damage
				if self.VO == 1 then
					sound.Play("daktanks/crew/aus/" .. self.VO1Pain[math.random(1, #self.VO1Pain)], self:GetPos(), 75, 100, 1)
				elseif self.VO == 2 then
					sound.Play("daktanks/crew/fre/" .. self.VO2Pain[math.random(1, #self.VO2Pain)], self:GetPos(), 75, 100, 1)
				elseif self.VO == 3 then
					sound.Play("daktanks/crew/ger/" .. self.VO3Pain[math.random(1, #self.VO3Pain)], self:GetPos(), 75, 100, 1)
				elseif self.VO == 4 then
					sound.Play("daktanks/crew/rus/" .. self.VO4Pain[math.random(1, #self.VO4Pain)], self:GetPos(), 75, 100, 1)
				elseif self.VO == 5 then
					sound.Play("daktanks/crew/sco/" .. self.VO5Pain[math.random(1, #self.VO5Pain)], self:GetPos(), 75, 100, 1)
				elseif self.VO == 6 then
					sound.Play("daktanks/crew/us/" .. self.VO6Pain[math.random(1, #self.VO6Pain)], self:GetPos(), 75, 100, 1)
				end
			else
				--heavy damage
				if self.VO == 1 then
					sound.Play("daktanks/crew/aus/" .. self.VO1Suffer[math.random(1, #self.VO1Suffer)], self:GetPos(), 75, 100, 1)
				elseif self.VO == 2 then
					sound.Play("daktanks/crew/fre/" .. self.VO2Suffer[math.random(1, #self.VO2Suffer)], self:GetPos(), 75, 100, 1)
				elseif self.VO == 3 then
					sound.Play("daktanks/crew/ger/" .. self.VO3Suffer[math.random(1, #self.VO3Suffer)], self:GetPos(), 75, 100, 1)
				elseif self.VO == 4 then
					sound.Play("daktanks/crew/rus/" .. self.VO4Suffer[math.random(1, #self.VO4Suffer)], self:GetPos(), 75, 100, 1)
				elseif self.VO == 5 then
					sound.Play("daktanks/crew/sco/" .. self.VO5Suffer[math.random(1, #self.VO5Suffer)], self:GetPos(), 75, 100, 1)
				elseif self.VO == 6 then
					sound.Play("daktanks/crew/us/" .. self.VO6Suffer[math.random(1, #self.VO6Suffer)], self:GetPos(), 75, 100, 1)
				end
			end
		end

		self.LastHealth = self.DakHealth
		if self:IsOnFire() then
			self.DakHealth = self.DakHealth - 0.5
			self:DTOnTakeDamage(0.5)
		end
	end

	if IsValid(self.DakEntity) and IsValid(self) then --Wouldn't self.DakEntity being valid imply that self is too?
		self.DakEntity.DakCrew = self
		if self.DakEntity:GetClass() == "dak_turretcontrol" then self.Job = 1 end
		if self.DakEntity:GetClass() == "dak_tegearbox" or self.DakEntity:GetClass() == "dak_tegearboxnew" then self.Job = 2 end
		if self.DakEntity:GetClass() == "dak_tegun" or self.DakEntity:GetClass() == "dak_teautogun" or self.DakEntity:GetClass() == "dak_temachinegun" then self.Job = 3 end
	end

	self:NextThink(CurTime() + 0.25)
	return true
end

function ENT:DTOnTakeDamage(Damage)
	if self.DakDead then return end
	if self.DakHealth <= 0 then
		if self.DakOwner:IsPlayer() then
			local jobs = {"Gunner", "Driver", "Loader", "Passenger"}
			self.DakOwner:ChatPrint(jobs[self.Job or 4] .. " Killed!")
		end

		self:SetMaterial("models/flesh")
		self.DakDead = true
		return
	end
end

function ENT:PreEntityCopy()
	local info = {}

	if IsValid(self.DakEntity) then info.DakEntityID = self.DakEntity:EntIndex() end
	if IsValid(self.DakEntity2) then info.DakEntity2ID = self.DakEntity2:EntIndex() end
	info.DakName = self.DakName
	info.DakMass = self.DakMass
	info.DakModel = self.DakModel
	info.DakColor = self:GetColor()
	info.DakMaxHealth = self.DakMaxHealth
	info.DakHealth = self.DakHealth
	duplicator.StoreEntityModifier(self, "DakTek", info)
	--Wire dupe info
	self.BaseClass.PreEntityCopy(self)
end

function ENT:PostEntityPaste(Player, Ent, CreatedEntities)
	if Ent.EntityMods and Ent.EntityMods.DakTek then
		local Job = CreatedEntities[Ent.EntityMods.DakTek.DakEntityID]
		local Job2 = CreatedEntities[Ent.EntityMods.DakTek.DakEntity2ID]
		if Job and IsValid(Job) then self.DakEntity = Job end
		if Job2 and IsValid(Job2) then self.DakEntity2 = Job2 end
		self.DakName = Ent.EntityMods.DakTek.DakName
		self.DakMass = Ent.EntityMods.DakTek.DakMass
		self.DakModel = Ent.EntityMods.DakTek.DakModel
		self.DakMaxHealth = Ent.EntityMods.DakTek.DakMaxHealth
		self.DakHealth = self.DakMaxHealth
		self.DakOwner = Player
		if not Ent.EntityMods.DakTek.DakColor then
		else
			self:SetColor(Ent.EntityMods.DakTek.DakColor)
		end

		self:Activate()
		Ent.EntityMods.DakTek = nil
	end

	self.BaseClass.PostEntityPaste(self, Player, Ent, CreatedEntities)
end

function ENT:OnRemove()
	if IsValid(self.DakEntity) then self.DakEntity.DakCrew = NULL end
	if IsValid(self.DakEntity2) then self.DakEntity2.DakCrew = NULL end
end