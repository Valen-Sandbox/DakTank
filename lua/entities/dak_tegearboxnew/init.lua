AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
-- get suspension force multiplier working again
-- remove suspension give value
-- improve default forces since they affect different weights somewhat differently
-- make a check to see if the trace for determining speed going up or down a hill started underground, if so then just cut the speed as the hill is so steep it is beyond the limits and ends up giving a speed boost
local DTTE = DTTE
local math = math
local traceline = util.TraceLine
local tracehull = util.TraceHull
local Clamp = math.Clamp
local abs = math.abs
local max = math.max
local min = math.min
local IsValid = IsValid
local sort = table.sort
ENT.DakMaxHealth = 25
ENT.DakHealth = 25
ENT.DakName = "Light Motor"
ENT.DakModel = "models/daktanks/engine1.mdl"
ENT.DakSpeed = 1.1725
ENT.DakMass = 1000
ENT.DakPooled = 0
ENT.DakCrew = NULL
ENT.MaxHP = 0
function ENT:Initialize()
	_DakVar_INSTALL(self)
	self.TimeMult = engine.TickInterval() / (1 / 66)
	self.LastThink = CurTime()
	self.RealInt = engine.TickInterval()
	--self:SetModel(self.DakModel)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:DrawShadow(false)
	self.DakHealth = self.DakMaxHealth
	self.DakSpeed = 2
	--local phys = self:GetPhysicsObject()
	self.Inputs = Wire_CreateInputs(self, {"Forward", "Reverse", "Left", "Right", "Brakes", "Activate", "CarTurning", "ForwardFacingEntity [ENTITY]", "SuspensionBias", "SuspensionBiasSide", "NoBiasSpeedLimit", "NoSideBiasSpeedLimit"})
	self.Perc = 0
	self.TurnPerc = 0
	self.YawAng = Angle(0, self:GetAngles().yaw, 0)
	self.LastYaw = self:GetAngles().yaw
	self.Prev = {}
	self.PrevPos = self:GetPos()
	self.Time = CurTime()
	self.TopSpeed = 1
	self.RBoost = 1
	self.LBoost = 1
	self.Speed = 0
	self.ExtraTorque = 1
	self.Vel = 1
	self.DakBurnStacks = 0
	self.RPM = 0
	self.turnperc = 0
	self.SparkTime = CurTime()
	self.MoveRightOld = 0
	self.MoveLeftOld = 0
	self.LeftBrakesEnabled = 0
	self.RightBrakesEnabled = 0
	self.Gear = 0
	self.SideDist = self:GetSideDist()
	self.TrackLength = self:GetTrackLength()
	self.WheelsPerSide = Clamp(self:GetWheelsPerSide(), 2, 20)
	self.RideHeight = self:GetRideHeight()
	self.RideLimit = Clamp(self:GetRideLimit(), 50, 200)
	self.SuspensionBias = Clamp(self:GetSuspensionBias(), -0.99, 0.99)
	self.RightChanges = {}
	self.RightPosChanges = {}
	self.RightRidePosChanges = {}
	self.RightLastHeights = {}
	self.LeftLastHeights = {}
	self.RightInts = {}
	self.LeftInts = {}
	self.LeftChanges = {}
	self.LeftPosChanges = {}
	self.LeftRidePosChanges = {}
	self.SlowThinkTime = CurTime()
	self.RealYaw = 0
	self.WheelYaw = 0
	for i = 1, self.WheelsPerSide do
		self.RightChanges[i] = 0
		self.LeftChanges[i] = 0
		self.RightPosChanges[i] = self:GetPos()
		self.LeftPosChanges[i] = self:GetPos()
		self.RightRidePosChanges[i] = 0
		self.LeftRidePosChanges[i] = 0
		self.RightLastHeights[i] = 0
		self.LeftLastHeights[i] = 0
		self.RightInts[i] = 0
		self.LeftInts[i] = 0
	end

	self.LastWheelsPerSide = self.WheelsPerSide
	self:SetNWFloat("Hydra", 0)
	self:SetNWFloat("HydraSide", 0)
	self:SetNWEntity("ForwardEnt", self)
	self:SetNWEntity("Base", self)
end

-- lazy aliasing
local addcount = {
	tracked = 2,
	halftracked = 2,
	wheeled = 0
}

function ENT:GetWheelsPerSide()
	return self:GetRoadWCount() + (addcount[self:GetVehicleMode()] or 0)
end

local frontcount = {
	tracked = 0,
	halftracked = 1
}

function ENT:GetForwardTurningWheels()
	return frontcount[self:GetVehicleMode()] or self:GetRoadWTurnFront()
end

local rearcount = {
	tracked = 0,
	halftracked = 1
}

function ENT:GetRearTurningWheels()
	return rearcount[self:GetVehicleMode()] or self:GetRoadWTurnRear()
end

function ENT:GetTurnAngle()
	return self:GetRoadWTurnAngle()
end

function ENT:GetTrackLength()
	return self:GetWheelBase()
end

function ENT:GetWheelHeight()
	return self:GetRoadWDiameter()
end

function ENT:GetFrontWheelHeight()
	return self:GetDriveWDiameter()
end

function ENT:GetFrontWheelRaise()
	return self:GetDriveWOffsetZ()
end

function ENT:GetRearWheelHeight()
	return self:GetIdlerWDiameter()
end

function ENT:GetRearWheelRaise()
	return self:GetIdlerWOffsetZ()
end

function ENT:GetForwardOffset()
	return self:GetWheelOffsetX()
end

function ENT:GetSideDist()
	return self:GetWheelOffsetY()
end

function ENT:GetRideHeight()
	return self:GetWheelOffsetZ()
end

local m_to_in = 100 / 2.54 -- meters to inches
local in_to_m = 1 / m_to_in
local PhysObj = FindMetaTable("PhysObj")
function PhysObj:ApplyImpulseOffsetF(impulse, position)
	self:ApplyForceCenter(impulse)
	local offset = position - self:LocalToWorld(self:GetMassCenter())
	local angimp = offset:Cross(impulse) * in_to_m * in_to_m * 180 / math.pi
	self:ApplyTorqueCenter(angimp)
end

function PhysObj:ApplyImpulseOffsetFTorqueOnly(impulse, position)
	--self:ApplyForceCenter(impulse)
	local offset = position - self:LocalToWorld(self:GetMassCenter())
	local angimp = offset:Cross(impulse) * in_to_m * in_to_m * 180 / math.pi
	self:ApplyTorqueCenter(angimp)
end

function ENT:PID(goal, height, lastheight, lastintegral)
	--goal is ride height
	--height is current suspension extension
	local P = 1.125 * Clamp(self:GetSuspensionForceMult(), 0, 2)
	-- local I = 1
	local D = 1.25 * (100 / Clamp(self:GetRideLimit(), 50, 200))
	local Time = (1 / self.RealInt) * 3 --3s to full power
	--proportional
	local Err = (goal - height) / self.TimeMult
	local Correction = Err * P
	--integral
	local Integral = (lastintegral * (Time - 1) + Err) / Time
	--derivative
	local LastErr = (goal - lastheight) / self.TimeMult
	local Derivative = (Err - LastErr) * D
	return Correction + Integral + Derivative, Integral
end

function ENT:AngPID(goal, height, lastheight, lastintegral)
	--goal is ride height
	--height is current suspension extension
	local P = 1
	-- local I = 1
	local D = 100
	local Time = (1 / self.RealInt) * 3 --3s to full power
	--proportional
	local Err = (goal - height) / self.TimeMult
	local Correction = Err * P
	--integral
	local Integral = (lastintegral * (Time - 1) + Err) / Time
	--derivative
	local LastErr = (goal - lastheight) / self.TimeMult
	local Derivative = (Err - LastErr) * D
	return Correction + Integral + Derivative, Integral
end

function ENT:Think()
	DTTE.CheckSpherical(self)
	self.RealInt = CurTime() - self.LastThink
	self.TimeMult = self.RealInt / (1 / 66)
	local self = self
	if self.dak_restoreLegacy then
		self:dak_restoreLegacy()
		self.dak_restoreLegacy = nil
		return
	end

	self.SideDist = self:GetSideDist()
	self.TrackLength = self:GetTrackLength()
	self.WheelsPerSide = Clamp(self:GetWheelsPerSide(), 2, 20)
	self.RideHeight = self:GetRideHeight()
	self.RideLimit = Clamp(self:GetRideLimit(), 50, 200)
	self.SuspensionBias = Clamp(self:GetSuspensionBias(), -0.99, 0.99)
	self.FrontWheelRaise = self:GetFrontWheelRaise()
	self.RearWheelRaise = self:GetRearWheelRaise()
	self.ForwardOffset = self:GetForwardOffset()
	self.GearRatio = Clamp(self:GetGearRatio(), 50, 100) * 0.01
	self.WheelHeight = self:GetWheelHeight()
	self.FrontWheelHeight = self:GetFrontWheelHeight()
	self.RearWheelHeight = self:GetRearWheelHeight()
	if CurTime() >= self.SlowThinkTime + 1 then
		self.SlowThinkTime = CurTime()
		if self.DakName == "Micro Frontal Mount Gearbox" then
			self.DakMaxHealth = 7.5
			self.DakArmor = 7.5
			self.DakMass = 80
			self.DakModel = "models/daktanks/gearbox1f1.mdl"
			self.Torque = 1
			self.MaxHP = 80
		elseif self.DakName == "Small Frontal Mount Gearbox" then
			self.DakMaxHealth = 25
			self.DakArmor = 25
			self.DakMass = 265
			self.DakModel = "models/daktanks/gearbox1f2.mdl"
			self.Torque = 1
			self.MaxHP = 250
		elseif self.DakName == "Standard Frontal Mount Gearbox" then
			self.DakMaxHealth = 60
			self.DakArmor = 60
			self.DakMass = 630
			self.DakModel = "models/daktanks/gearbox1f3.mdl"
			self.Torque = 1
			self.MaxHP = 600
		elseif self.DakName == "Large Frontal Mount Gearbox" then
			self.DakMaxHealth = 120
			self.DakArmor = 120
			self.DakMass = 1230
			self.DakModel = "models/daktanks/gearbox1f4.mdl"
			self.Torque = 1
			self.MaxHP = 1200
		elseif self.DakName == "Huge Frontal Mount Gearbox" then
			self.DakMaxHealth = 200
			self.DakArmor = 200
			self.DakMass = 2130
			self.DakModel = "models/daktanks/gearbox1f5.mdl"
			self.Torque = 1
			self.MaxHP = 2000
		elseif self.DakName == "Ultra Frontal Mount Gearbox" then
			self.DakMaxHealth = 480
			self.DakArmor = 480
			self.DakMass = 5050
			self.DakModel = "models/daktanks/gearbox1f6.mdl"
			self.Torque = 1
			self.MaxHP = 4800
		elseif self.DakName == "Micro Rear Mount Gearbox" then
			self.DakMaxHealth = 7.5
			self.DakArmor = 7.5
			self.DakMass = 80
			self.DakModel = "models/daktanks/gearbox1r1.mdl"
			self.Torque = 1
			self.MaxHP = 80
		elseif self.DakName == "Small Rear Mount Gearbox" then
			self.DakMaxHealth = 25
			self.DakArmor = 25
			self.DakMass = 265
			self.DakModel = "models/daktanks/gearbox1r2.mdl"
			self.Torque = 1
			self.MaxHP = 250
		elseif self.DakName == "Standard Rear Mount Gearbox" then
			self.DakMaxHealth = 60
			self.DakArmor = 60
			self.DakMass = 630
			self.DakModel = "models/daktanks/gearbox1r3.mdl"
			self.Torque = 1
			self.MaxHP = 600
		elseif self.DakName == "Large Rear Mount Gearbox" then
			self.DakMaxHealth = 120
			self.DakArmor = 120
			self.DakMass = 1230
			self.DakModel = "models/daktanks/gearbox1r4.mdl"
			self.Torque = 1
			self.MaxHP = 1200
		elseif self.DakName == "Huge Rear Mount Gearbox" then
			self.DakMaxHealth = 200
			self.DakArmor = 200
			self.DakMass = 2130
			self.DakModel = "models/daktanks/gearbox1r5.mdl"
			self.Torque = 1
			self.MaxHP = 2000
		elseif self.DakName == "Ultra Rear Mount Gearbox" then
			self.DakMaxHealth = 480
			self.DakArmor = 480
			self.DakMass = 5050
			self.DakModel = "models/daktanks/gearbox1r6.mdl"
			self.Torque = 1
			self.MaxHP = 4800
		end
	end

	if CurTime() >= self.SparkTime + 0.33 then
		local scale
		if self.DakHealth <= (self.DakMaxHealth * 0.80) and self.DakHealth > (self.DakMaxHealth * 0.60) then
			scale = 1
		elseif self.DakHealth <= (self.DakMaxHealth * 0.60) and self.DakHealth > (self.DakMaxHealth * 0.40) then
			scale = 2
		elseif self.DakHealth <= (self.DakMaxHealth * 0.40) and self.DakHealth > (self.DakMaxHealth * 0.20) then
			scale = 3
		elseif self.DakHealth <= (self.DakMaxHealth * 0.20) then
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

		self.SparkTime = CurTime()
	end

	if not self.FirstCheck and self.DakMaxHealth ~= 25 then
		self.FirstCheck = true
		self.DakHealth = self.DakMaxHealth
	end

	if IsValid(self.DakTankCore) and IsValid(self.DakTankCore.Motors[1]) and self.DakTankCore.Off ~= true then
		self.DakSpeed = 0
		self.DakFuel = 0
		self.DakFuelReq = 0
		self.DakHP = 0
		if self.DakTankCore then
			if #self.DakTankCore.Motors > 0 then
				for i = 1, #self.DakTankCore.Motors do
					if IsValid(self.DakTankCore.Motors[i]) then
						self.DakSpeed = self.DakSpeed + self.DakTankCore.Motors[i].DakSpeed
						self.DakFuelReq = self.DakFuelReq + self.DakTankCore.Motors[i].DakFuelReq
						self.DakHP = self.DakHP + self.DakTankCore.Motors[i].DakHP
					end
				end
			else
				self.DakHP = 0
			end

			if #self.DakTankCore.Fuel > 0 then
				for i = 1, #self.DakTankCore.Fuel do
					if self.DakFuel then if IsValid(self.DakTankCore.Fuel[i]) then self.DakFuel = self.DakFuel + self.DakTankCore.Fuel[i].DakFuel end end
				end
			else
				self.DakHP = 0
			end
		end

		self.DakSpeed = (self.DakSpeed * 2 * Clamp(self.DakFuel / self.DakFuelReq, 0, 1)) * Clamp(self.MaxHP / self.DakHP, 0, 1)
		self.CrewAlive = 1 --TODO: This should probably be a boolean. I can't be bothered to find where it's used right now to check.
		if self.DakCrew == NULL or self.DakCrew.DakEntity ~= self then
			self.DakSpeed = 0
			self.CrewAlive = 0
		else
			self.DakCrew.Job = 2
			if self.DakCrew.DakDead then
				self.DakSpeed = 0
				self.CrewAlive = 0
			end
		end

		if not self:IsSolid() then self.DakSpeed = 0 end
		if self.DakHealth > self.DakMaxHealth then self.DakHealth = self.DakMaxHealth end
		if self:GetModel() ~= self.DakModel then
			self:SetModel(self.DakModel)
			self:SetMoveType(MOVETYPE_VPHYSICS)
			self:SetSolid(SOLID_VPHYSICS)
		end

		if self.AddonMass ~= nil and self:GetPhysicsObject():GetMass() ~= self.DakMass + self.AddonMass then self:GetPhysicsObject():SetMass(self.DakMass + self.AddonMass) end
		self.MoveForward = self.Inputs.Forward.Value
		self.MoveReverse = self.Inputs.Reverse.Value
		self.MoveLeft = self.Inputs.Left.Value
		self.MoveRight = self.Inputs.Right.Value
		self.Brakes = self.Inputs.Brakes.Value
		self.Active = self.Inputs.Activate.Value
		self.ForwardEnt = self.Inputs.ForwardFacingEntity.Value
		if self.ForwardEnt == nil or self.ForwardEnt == NULL then self.ForwardEnt = self end
		if self.ForwardEnt ~= self.LastForwardEnt then
			self:SetNWEntity("ForwardEnt", self.ForwardEnt)
			self.LastForwardEnt = self.ForwardEnt
		end

		self.CarTurning = self.Inputs.CarTurning.Value
		if IsValid(self.DakTankCore) and self.DakTankCore.Off ~= true then
			if self.setup == nil and IsValid(self:GetParent()) and IsValid(self:GetParent():GetParent()) then
				self.YawAng = Angle(0, self:GetParent():GetParent():GetAngles().yaw, 0)
				self.LastYaw = self:GetParent():GetParent():GetAngles().yaw
				-- print(self:GetParent():GetParent():GetPhysicsObject():GetInertia())
				self.setup = 1
			end

			if self.InertiaSet == nil and self:GetParent():GetParent():GetPhysicsObject():IsMotionEnabled() == true then
				local oldinertia = self:GetParent():GetParent():GetPhysicsObject():GetInertia()
				local multiplier = 2 --(self.TotalMass/self.PhysicalMass)--1--(self.TotalMass / 6000)
				self:GetParent():GetParent():GetPhysicsObject():SetInertia(Vector(oldinertia.x * multiplier, oldinertia.y * multiplier, oldinertia.z * multiplier))
				self:GetParent():GetParent():GetPhysicsObject():SetMass(self:GetParent():GetParent():GetPhysicsObject():GetMass())
				self:GetParent():GetParent():GetPhysicsObject():EnableGravity(false)
				self.InertiaSet = 1
			end

			if self.TotalMass then
				if self.AddonMass == nil then self.AddonMass = math.Round(self.TotalMass * 0.1) end
				self.DakSpeed = self.DakSpeed * (10000 / self.TotalMass)
				self.TopSpeed = (29.851 * self.DakSpeed) * self.GearRatio
				if self:GetParent():IsValid() and self:GetParent():GetParent():IsValid() then
					self.phy = self:GetParent():GetParent():GetPhysicsObject()
					self.base = self:GetParent():GetParent()
					self.base:GetPhysicsObject():SetDamping(0, 0)
				elseif not self:GetParent():IsValid() then
					self.phy = self:GetPhysicsObject()
					self.base = self
				end

				if self.base ~= self.Lastbase then
					self:SetNWEntity("Base", self.base)
					self.Lastbase = self.base
				end

				if self.DakDead ~= true then
					self.HPperTon = self.DakHP / (self.TotalMass / 1000) * math.Clamp(self.MaxHP / self.DakHP, 0, 1)
				else
					self.HPperTon = 0
				end

				if self.Active > 0 then
					if self.MoveForward <= 0 and self.MoveReverse <= 0 and self.MoveLeft <= 0 and self.MoveRight <= 0 then
						if self.RPM > 600 then
							self.RPM = self.RPM - 100
						elseif self.RPM < 600 then
							self.RPM = 600
						end
					else
						if self.MoveReverse > 0 then
							self.RPM = 1000 * Clamp(self.TopSpeed * 0.5 / (self.Speed * 1.5), 0.6, 2.0)
							if self.Speed * 1.5 > self.TopSpeed then self.RPM = 2000 * Clamp(self.Speed / self.TopSpeed * 0.5, 0.5, 1) end
						else
							self.RPM = 1000 * Clamp(self.TopSpeed / (self.Speed * 1.5), 0.6, 2.0)
							if self.Speed * 1.5 > self.TopSpeed then self.RPM = 2000 * Clamp(self.Speed / self.TopSpeed, 0.5, 1) end
						end
					end

					if #self.DakTankCore.Motors > 0 then
						for i = 1, #self.DakTankCore.Motors do
							if IsValid(self.DakTankCore.Motors[i]) then self.DakTankCore.Motors[i].Sound:ChangeVolume(0.25, 1) end
						end
					end

					if self.Brakes > 0 then
						self.Perc = 0
						--DO BRAKES BOTH
						self.RightBrake = 1
						self.LeftBrake = 1
						self.LeftForce = 0
						self.RightForce = 0
						if #self.DakTankCore.Motors > 0 then
							for i = 1, #self.DakTankCore.Motors do
								if IsValid(self.DakTankCore.Motors[i]) then self.DakTankCore.Motors[i].Sound:ChangePitch(Clamp(255 * self.RPM / 2500, 0, 255), 0.5) end
							end
						end
					else
						if self.MoveForward <= 0 and self.MoveReverse <= 0 then
							if self.Perc > 0 then
								self.Perc = self.Perc - 0.1 * self.TimeMult
							elseif self.Perc < 0 then
								self.Perc = self.Perc + 0.1 * self.TimeMult
							end
						else
							if self.MoveForward > 0 then
								if self.Perc < 0 then self.Perc = 0 end
								if self.Perc < 1 then self.Perc = self.Perc + 0.1 * self.TimeMult end
							end

							if self.MoveReverse > 0 then
								if self.Perc > 0 then self.Perc = 0 end
								if self.Perc > -1 then self.Perc = self.Perc - 0.1 * self.TimeMult end
								self.TopSpeed = self.TopSpeed / 3
							end
						end

						if self.MoveRight <= 0 and self.MoveLeft <= 0 then self.TurnPerc = 0 end
						if self.Speed < self.TopSpeed then
							self.RBoost = 1
							self.LBoost = 1
							if self.MoveRight == 0 and self.MoveLeft == 0 then
								if self.CarTurning == 1 then
									if self.WheelYaw > 0 then
										self.WheelYaw = self.WheelYaw - 1 * self.TimeMult
									elseif self.WheelYaw < 0 then
										self.WheelYaw = self.WheelYaw + 1 * self.TimeMult
									end
								end
							end

							if self.Speed > 0 then
								--TRACTION CONTROL
								local _, temp = WorldToLocal(Vector(0, 0, 0), Angle(0, self.LastYaw, 0), Vector(0, 0, 0), Angle(0, self.base:GetAngles().yaw, 0))
								local TurnVal = temp.yaw / self.TimeMult
								local ControlForce = min(max(4, abs(TurnVal * 5)), 10)
								if self.Perc >= 0 then
									if TurnVal > 0.05 and self.MoveRight == 0 then
										--abs(TurnVal)
										self.LBoost = 0 - ControlForce
										self.RBoost = 2 + ControlForce
									elseif TurnVal < -0.05 and self.MoveLeft == 0 then
										self.LBoost = 2 + ControlForce
										self.RBoost = 0 - ControlForce
									end
								else
									if TurnVal > 0.05 and self.MoveLeft == 0 then
										self.LBoost = 2 + ControlForce
										self.RBoost = 0 - ControlForce
									elseif TurnVal < -0.05 and self.MoveRight == 0 then
										self.LBoost = 0 - ControlForce
										self.RBoost = 2 + ControlForce
									end
								end
							else
								self.LBoost = 1
								self.RBoost = 1
							end

							if self.CarTurning == 1 then
								--ENSURE BRAKES ARE OFF
								self.RightBrake = 0
								self.LeftBrake = 0
							else
								if self.MoveLeft == 0 then self.LeftBrake = 0 end
								if self.MoveRight == 0 then self.RightBrake = 0 end
							end

							local GearBoost = 0
							self.CurTopSpeed = 0
							self.LastTopSpeed = 0
							self.MaxSpeedDif = 0
							local G1Speed = self.TopSpeed * 0.15
							local G2Speed = self.TopSpeed * 0.4
							local G3Speed = self.TopSpeed * 0.75
							local G4Speed = self.TopSpeed
							self.LeftForce = 0
							self.RightForce = 0
							self.RightBrake = 0
							self.LeftBrake = 0
							local throttle = 0
							if self.MoveForward > 0 and self.MoveReverse == 0 then
								throttle = self.MoveForward
							elseif self.MoveForward == 0 and self.MoveReverse > 0 then
								throttle = self.MoveReverse
							end

							if self.Speed > 0 and self.Speed < G1Speed and self.Gear ~= 1 then
								self.Gear = 1
							elseif self.Speed > G1Speed and self.Speed < G2Speed and self.Gear ~= 2 then
								self.Gear = 2
							elseif self.Speed > G2Speed and self.Speed < G3Speed and self.Gear ~= 3 then
								self.Gear = 3
							elseif self.Speed > G3Speed and self.Speed < G4Speed and self.Gear ~= 4 then
								self.Gear = 4
							end

							if self.Gear == 1 then
								--self.Gear = 1
								GearBoost = 0.4
								self.CurTopSpeed = G1Speed
								self.LastTopSpeed = 0
								self.MaxSpeedDif = G1Speed
								self.LeftForce = (self.PhysicalMass / 3000) * self.LBoost * self.Perc * (1 / self.GearRatio) * self.HPperTon * 50 * GearBoost * min(throttle, 1)
								self.RightForce = (self.PhysicalMass / 3000) * self.RBoost * self.Perc * (1 / self.GearRatio) * self.HPperTon * 50 * GearBoost * min(throttle, 1)
							elseif self.Gear == 2 then
								GearBoost = 0.15
								self.CurTopSpeed = G2Speed
								self.LastTopSpeed = G1Speed
								self.MaxSpeedDif = G2Speed - self.TopSpeed * 0.1
								self.LeftForce = (self.PhysicalMass / 3000) * self.LBoost * self.Perc * (1 / self.GearRatio) * self.HPperTon * 50 * GearBoost * min(throttle, 1)
								self.RightForce = (self.PhysicalMass / 3000) * self.RBoost * self.Perc * (1 / self.GearRatio) * self.HPperTon * 50 * GearBoost * min(throttle, 1)
							elseif self.Gear == 3 then
								GearBoost = 0.1
								self.CurTopSpeed = G3Speed
								self.LastTopSpeed = G2Speed
								self.MaxSpeedDif = G3Speed - G2Speed
								self.LeftForce = (self.PhysicalMass / 3000) * self.LBoost * self.Perc * (1 / self.GearRatio) * self.HPperTon * 50 * GearBoost * min(throttle, 1)
								self.RightForce = (self.PhysicalMass / 3000) * self.RBoost * self.Perc * (1 / self.GearRatio) * self.HPperTon * 50 * GearBoost * min(throttle, 1)
							else
								GearBoost = 0.05
								self.CurTopSpeed = G4Speed
								self.LastTopSpeed = G3Speed
								self.MaxSpeedDif = G4Speed - G3Speed
								self.LeftForce = (self.PhysicalMass / 3000) * self.LBoost * self.Perc * (1 / self.GearRatio) * self.HPperTon * 50 * GearBoost * min(throttle, 1)
								self.RightForce = (self.PhysicalMass / 3000) * self.RBoost * self.Perc * (1 / self.GearRatio) * self.HPperTon * 50 * GearBoost * min(throttle, 1)
							end

							if self.lastshift == nil then self.lastshift = 0 end
							if self.LastGear == nil then self.LastGear = 1 end
							if self.Gear > self.LastGear then
								if self.lastshift + 2.5 < CurTime() then
									if #self.DakTankCore.Motors > 0 then
										for i = 1, #self.DakTankCore.Motors do
											if IsValid(self.DakTankCore.Motors[i]) then
												self.DakTankCore.Motors[i].Sound:ChangeVolume(0.125, 0)
												self.DakTankCore.Motors[i].Sound:ChangeVolume(0.25, 0.15)
												self.DakTankCore.Motors[i].Sound:ChangePitch(50, 0.1)
											end
										end
									end

									self.lastshift = CurTime()
								end
							end

							self.LastGear = self.Gear
							if self.LastMoving == nil then self.LastMoving = 0 end
							if self.MoveForward > 0 or self.MoveReverse > 0 or self.MoveLeft > 0 or self.MoveRight > 0 then
								self.LastMoving = 1
								if (self.MoveForward > 0 or self.MoveReverse > 0) and not (self.MoveLeft > 0 or self.MoveRight > 0) then
									if #self.DakTankCore.Motors > 0 then
										for i = 1, #self.DakTankCore.Motors do
											if IsValid(self.DakTankCore.Motors[i]) then self.DakTankCore.Motors[i].Sound:ChangePitch(Clamp(((self.Speed - self.LastTopSpeed) / self.MaxSpeedDif) * min(throttle, 1), 0, 1) * 60 + ((self.Speed / self.TopSpeed) * 90) + 50, 0.1) end
										end
									end
								else
									if self.CarTurning == 0 then
										if self.MoveLeft > 0 or self.MoveRight > 0 then
											if #self.DakTankCore.Motors > 0 then
												for i = 1, #self.DakTankCore.Motors do
													if IsValid(self.DakTankCore.Motors[i]) then self.DakTankCore.Motors[i].Sound:ChangePitch(max(min(max(self.MoveRight, self.MoveLeft) / 1 * 100, 100), 50), 0.5) end
												end
											end
										end
									else
										if self.lastdump == nil then self.lastdump = 0 end
										if self.LastMoving == 1 then
											if self.lastdump + 2.5 < CurTime() then
												if self.Gear > 2 and Clamp((self.Speed - self.LastTopSpeed) / self.MaxSpeedDif, 0, 1) > 0.5 then
													--sound.Play("acf_extra/vehiclefx/boost/gear_change_dump1.wav",self:GetPos(),100,100,1)
													self.lastdump = CurTime()
												end
											end
										end

										if #self.DakTankCore.Motors > 0 then
											for i = 1, #self.DakTankCore.Motors do
												if IsValid(self.DakTankCore.Motors[i]) then
													if self.CarTurning == 0 then
														self.DakTankCore.Motors[i].Sound:ChangePitch(50, 0.1)
													else
														self.DakTankCore.Motors[i].Sound:ChangePitch(Clamp(((self.Speed - self.LastTopSpeed) / self.MaxSpeedDif) * min(throttle, 1), 0, 1) * 60 + ((self.Speed / self.TopSpeed) * 90) + 50, 0.1)
													end
												end
											end
										end

										self.LastMoving = 0
									end
								end
							else
								if self.lastdump == nil then self.lastdump = 0 end
								if self.LastMoving == 1 then
									if self.lastdump + 2.5 < CurTime() then
										if self.Gear > 2 and Clamp((self.Speed - self.LastTopSpeed) / self.MaxSpeedDif, 0, 1) > 0.5 then
											--sound.Play("acf_extra/vehiclefx/boost/gear_change_dump1.wav",self:GetPos(),100,100,1)
											self.lastdump = CurTime()
										end
									end
								end

								if #self.DakTankCore.Motors > 0 then
									for i = 1, #self.DakTankCore.Motors do
										if IsValid(self.DakTankCore.Motors[i]) then self.DakTankCore.Motors[i].Sound:ChangePitch(50, 0.1) end
									end
								end

								self.LastMoving = 0
							end
						end

						if self.Speed > self.TopSpeed then
							self.LeftForce = 0
							self.RightForce = 0
						end

						if self.CarTurning == 0 then
							if self.MoveLeft > 0 or self.MoveRight > 0 then
								if abs(self.turnperc) < 1 then
									if self.MoveLeft > 0 then
										if self.turnperc < 0 then self.turnperc = 0 end
										self.turnperc = self.turnperc + 0.02 * self.TimeMult
									elseif self.MoveRight > 0 then
										if self.turnperc > 0 then self.turnperc = 0 end
										self.turnperc = self.turnperc - 0.02 * self.TimeMult
									end
								end

								if self.MoveReverse > 0 then
									if self.MoveLeft > 0 and self.MoveRight == 0 then
										self.MoveRight = self.MoveLeft
										self.MoveLeft = 0
									elseif self.MoveRight > 0 and self.MoveLeft == 0 then
										self.MoveLeft = self.MoveRight
										self.MoveRight = 0
									end

									self.Turn = -1
								else
									self.Turn = 1
								end
							else
								self.turnperc = 0
							end

							self.MoveRightOld = self.MoveRight
							self.MoveLeftOld = self.MoveLeft
							if self.Speed > 10 then
								if self.MoveLeft > 0 and self.MoveRight == 0 then
									if self.MoveReverse > 0 then
										if abs(self.RealYaw) < 1.5 then
											self.LeftBrake = 0
											self.RightBrake = 1
											self.LeftForce = self.LeftForce * 2
											self.RightForce = 0
										else
											self.LeftBrake = 1
											self.RightBrake = 0
											self.LeftForce = 0
											self.RightForce = self.RightForce * 2
										end
									else
										if abs(self.RealYaw) < 1.5 then
											self.LeftBrake = 1
											self.RightBrake = 0
											self.LeftForce = 0
											self.RightForce = self.RightForce * 2
										else
											self.LeftBrake = 0
											self.RightBrake = 1
											self.LeftForce = self.LeftForce * 2
											self.RightForce = 0
										end
									end
								elseif self.MoveRight > 0 and self.MoveLeft == 0 then
									if self.MoveReverse > 0 then
										if abs(self.RealYaw) < 1.5 then
											self.LeftBrake = 1
											self.RightBrake = 0
											self.LeftForce = 0
											self.RightForce = self.RightForce * 2
										else
											self.LeftBrake = 0
											self.RightBrake = 1
											self.LeftForce = self.LeftForce * 2
											self.RightForce = 0
										end
									else
										if abs(self.RealYaw) < 1.5 then
											self.LeftBrake = 0
											self.RightBrake = 1
											self.LeftForce = self.LeftForce * 2
											self.RightForce = 0
										else
											self.LeftBrake = 1
											self.RightBrake = 0
											self.LeftForce = 0
											self.RightForce = self.RightForce * 2
										end
									end
								end
							else
								if self.MoveReverse > 0 then
									if self.MoveLeft > 0 and self.MoveRight == 0 then
										self.LeftForce = Clamp(self.DakFuel / self.DakFuelReq, 0, 1) * (self.PhysicalMass / 3000) * 0.5 * self.Turn * 10 * Clamp((0.015 * (1 / self.GearRatio) * self.HPperTon) / (abs(self.LastYaw - self.base:GetAngles().yaw) / self.TimeMult) * 1.75, 0, 10 * abs(self.turnperc)) * 450 * (self.DakHealth / self.DakMaxHealth) * min(self.MoveLeft, 1)
										self.RightForce = Clamp(self.DakFuel / self.DakFuelReq, 0, 1) * -(self.PhysicalMass / 3000) * 0.5 * self.Turn * 10 * Clamp((0.015 * (1 / self.GearRatio) * self.HPperTon) / (abs(self.LastYaw - self.base:GetAngles().yaw) / self.TimeMult) * 1.75, 0, 10 * abs(self.turnperc)) * 450 * (self.DakHealth / self.DakMaxHealth) * min(self.MoveLeft, 1)
										--RIGHT FORWARD
										--LEFT BACKWARD
									end

									if self.MoveRight > 0 and self.MoveLeft == 0 then
										self.LeftForce = Clamp(self.DakFuel / self.DakFuelReq, 0, 1) * -(self.PhysicalMass / 3000) * 0.5 * self.Turn * 10 * Clamp((0.015 * (1 / self.GearRatio) * self.HPperTon) / (abs(self.LastYaw - self.base:GetAngles().yaw) / self.TimeMult) * 1.75, 0, 10 * abs(self.turnperc)) * 450 * (self.DakHealth / self.DakMaxHealth) * min(self.MoveRight, 1)
										self.RightForce = Clamp(self.DakFuel / self.DakFuelReq, 0, 1) * (self.PhysicalMass / 3000) * 0.5 * self.Turn * 10 * Clamp((0.015 * (1 / self.GearRatio) * self.HPperTon) / (abs(self.LastYaw - self.base:GetAngles().yaw) / self.TimeMult) * 1.75, 0, 10 * abs(self.turnperc)) * 450 * (self.DakHealth / self.DakMaxHealth) * min(self.MoveRight, 1)
										--RIGHT BACKWARD
										--LEFT FORWARD
									end
								else
									if self.MoveLeft > 0 and self.MoveRight == 0 then
										self.LeftForce = Clamp(self.DakFuel / self.DakFuelReq, 0, 1) * -(self.PhysicalMass / 3000) * 0.5 * self.Turn * 10 * Clamp((0.015 * (1 / self.GearRatio) * self.HPperTon) / (abs(self.LastYaw - self.base:GetAngles().yaw) / self.TimeMult) * 1.75, 0, 10 * abs(self.turnperc)) * 450 * (self.DakHealth / self.DakMaxHealth) * min(self.MoveLeft, 1)
										self.RightForce = Clamp(self.DakFuel / self.DakFuelReq, 0, 1) * (self.PhysicalMass / 3000) * 0.5 * self.Turn * 10 * Clamp((0.015 * (1 / self.GearRatio) * self.HPperTon) / (abs(self.LastYaw - self.base:GetAngles().yaw) / self.TimeMult) * 1.75, 0, 10 * abs(self.turnperc)) * 450 * (self.DakHealth / self.DakMaxHealth) * min(self.MoveLeft, 1)
										--RIGHT BACKWARD
										--LEFT FORWARD
									end

									if self.MoveRight > 0 and self.MoveLeft == 0 then
										self.LeftForce = Clamp(self.DakFuel / self.DakFuelReq, 0, 1) * (self.PhysicalMass / 3000) * 0.5 * self.Turn * 10 * Clamp((0.015 * (1 / self.GearRatio) * self.HPperTon) / (abs(self.LastYaw - self.base:GetAngles().yaw) / self.TimeMult) * 1.75, 0, 10 * abs(self.turnperc)) * 450 * (self.DakHealth / self.DakMaxHealth) * min(self.MoveRight, 1)
										self.RightForce = Clamp(self.DakFuel / self.DakFuelReq, 0, 1) * -(self.PhysicalMass / 3000) * 0.5 * self.Turn * 10 * Clamp((0.015 * (1 / self.GearRatio) * self.HPperTon) / (abs(self.LastYaw - self.base:GetAngles().yaw) / self.TimeMult) * 1.75, 0, 10 * abs(self.turnperc)) * 450 * (self.DakHealth / self.DakMaxHealth) * min(self.MoveRight, 1)
										--RIGHT FORWARD
										--LEFT BACKWARD
									end
								end
							end
						else
							if self.MoveLeft > 0 and self.MoveRight == 0 then
								if self.WheelYaw > -Clamp(self:GetTurnAngle(), 0, 45) then self.WheelYaw = self.WheelYaw - 1 * self.TimeMult end
							elseif self.MoveRight > 0 and self.MoveLeft == 0 then
								if self.WheelYaw < Clamp(self:GetTurnAngle(), 0, 45) then self.WheelYaw = self.WheelYaw + 1 * self.TimeMult end
							elseif self.MoveRight == 0 and self.MoveLeft == 0 then
								if self.WheelYaw > 0 then
									self.WheelYaw = self.WheelYaw - 1 * self.TimeMult
								elseif self.WheelYaw < 0 then
									self.WheelYaw = self.WheelYaw + 1 * self.TimeMult
								end
							end

							self:SetNWFloat("WheelYaw", self.WheelYaw)
						end

						if self.MoveForward <= 0 and self.MoveReverse <= 0 and self.MoveLeft <= 0 and self.MoveRight <= 0 then
							self.RightBrake = 0
							self.LeftBrake = 0
							if #self.DakTankCore.Motors > 0 then
								for i = 1, #self.DakTankCore.Motors do
									if IsValid(self.DakTankCore.Motors[i]) then self.DakTankCore.Motors[i].Sound:ChangePitch(50, 0.5) end
								end
							end
						end
					end
				else
					self.LeftForce = 0
					self.RightForce = 0
					self.RightBrake = 1
					self.LeftBrake = 1
					if self.RPM > 0 then self.RPM = self.RPM - 10 end
					--STANDARD BRAKING, NO FORCE APPLIED
					if #self.DakTankCore.Motors > 0 then
						for i = 1, #self.DakTankCore.Motors do
							if IsValid(self.DakTankCore.Motors[i]) then
								self.DakTankCore.Motors[i].Sound:ChangeVolume(0, 2)
								self.DakTankCore.Motors[i].Sound:ChangePitch(0, 2)
							end
						end
					end
					--self.LastYaw = self.base:GetAngles().yaw
				end

				local GravxTicks = physenv.GetGravity() * (1 / 66)
				local Pos
				local ForcePos
				local selfpos = self.base:GetPos()
				local trace = {}
				local CurTrace
				local RidePos
				local SuspensionForce
				-- local SuspensionAbsorb
				local lastchange
				local lastvel
				local AbsorbForce
				local AbsorbForceFinal
				local FrictionForce
				local FrictionForceFinal
				local lastvelnorm
				local CurTraceDist
				local ForwardEnt = self.ForwardEnt
				local WheelsPerSide = self.WheelsPerSide --min(self.WheelsPerSide,5)
				local TrackLength = self.TrackLength
				local ForwardOffset = self.ForwardOffset
				local RideHeight = self.RideHeight
				local FrontWheelRaise = self.FrontWheelRaise
				local RearWheelRaise = self.RearWheelRaise
				local forward = ForwardEnt:GetForward()
				local right = ForwardEnt:GetRight()
				local CurTraceHitPos
				local hydrabias = Clamp(self.Inputs.SuspensionBias.Value, -1, 1)
				if self.lasthydrabias == nil then self.lasthydrabias = hydrabias end
				if self.Inputs.NoBiasSpeedLimit.Value == 0 then
					hydrabias = Clamp(hydrabias, self.lasthydrabias - (0.25 / RideHeight), self.lasthydrabias + (0.25 / RideHeight))
				else
					hydrabias = Clamp(hydrabias, self.lasthydrabias - (5 / RideHeight), self.lasthydrabias + (5 / RideHeight))
				end

				self:SetNWFloat("Hydra", hydrabias)
				self.lasthydrabias = hydrabias
				local hydrabiasside = Clamp(self.Inputs.SuspensionBiasSide.Value, -1, 1)
				if self.lasthydrabiasside == nil then self.lasthydrabiasside = hydrabiasside end
				if self.Inputs.NoSideBiasSpeedLimit.Value == 0 then
					hydrabiasside = Clamp(hydrabiasside, self.lasthydrabiasside - (0.25 / RideHeight), self.lasthydrabiasside + (0.25 / RideHeight))
				else
					hydrabiasside = Clamp(hydrabiasside, self.lasthydrabiasside - (5 / RideHeight), self.lasthydrabiasside + (5 / RideHeight))
				end

				self:SetNWFloat("HydraSide", hydrabiasside)
				self.lasthydrabiasside = hydrabiasside
				local SuspensionBias = self.SuspensionBias
				local wheelweightforce = Vector(0, 0, (self.AddonMass / (WheelsPerSide * 2)) * -9.8 * (self.RealInt / self.TimeMult)) * (self.PhysicalMass / self.TotalMass)
				if self.LastWheelsPerSide ~= WheelsPerSide then
					for i = 1, WheelsPerSide do
						self.RightChanges[i] = 0
						self.LeftChanges[i] = 0
						self.RightPosChanges[i] = selfpos
						self.LeftPosChanges[i] = selfpos
						self.RightRidePosChanges[i] = 0
						self.LeftRidePosChanges[i] = 0
						self.RightLastHeights[i] = 0
						self.LeftLastHeights[i] = 0
						self.RightInts[i] = 0
						self.LeftInts[i] = 0
					end
				end

				if self.RightGroundedLast == nil then self.RightGroundedLast = WheelsPerSide end
				if self.LeftGroundedLast == nil then self.LeftGroundedLast = WheelsPerSide end
				local CurRideHeight = 0
				local RearTurners = self:GetRearTurningWheels()
				local FrontTurners = self:GetForwardTurningWheels()
				if self.DakDead or self.CrewAlive == 0 then
					self.RightForce = 0
					self.LeftForce = 0
					if self.DakHealth < 0 then self.DakHealth = 0 end
				end

				local basesize = {self.base:OBBMaxs().x, self.base:OBBMaxs().y, self.base:OBBMaxs().z}
				sort(basesize, function(a, b) return a > b end)
				local fronttrace = {
					start = selfpos + Vector(0, 0, 100) + Angle(0, ForwardEnt:GetAngles().yaw, 0):Forward() * (TrackLength * 0.5),
					endpos = selfpos + Vector(0, 0, -1000) + Angle(0, ForwardEnt:GetAngles().yaw, 0):Forward() * (TrackLength * 0.5),
					mask = MASK_SOLID_BRUSHONLY
				}

				local FrontTrace = traceline(fronttrace)
				local backtrace = {
					start = selfpos + Vector(0, 0, 100) + Angle(0, ForwardEnt:GetAngles().yaw, 0):Forward() * -(TrackLength * 0.5),
					endpos = selfpos + Vector(0, 0, -1000) + Angle(0, ForwardEnt:GetAngles().yaw, 0):Forward() * -(TrackLength * 0.5),
					mask = MASK_SOLID_BRUSHONLY
				}

				local BackTrace = traceline(backtrace)
				local FrontHit = FrontTrace.HitPos
				local BackHit = BackTrace.HitPos
				local HeightDiff = FrontHit.z - BackHit.z
				local ResistAng = math.atan(HeightDiff / TrackLength) * 57.2958
				if self.MoveReverse > 0 then ResistAng = ResistAng * -1 end
				local TerrainMultiplier = Clamp(1 - math.sin(math.rad(ResistAng)), 0, 1)
				local TerrainBraking = 0
				if TerrainMultiplier < 1 then
					TerrainBraking = (1 - TerrainMultiplier) * 0.125
				else
					if self.Brakes <= 0 then
						if self.MoveReverse <= 0 then
							self.phy:ApplyForceCenter(self.RealInt * -forward * self.PhysicalMass * abs(physenv.GetGravity().z) * math.sin(math.rad(ResistAng)))
						else
							self.phy:ApplyForceCenter(self.RealInt * forward * self.PhysicalMass * abs(physenv.GetGravity().z) * math.sin(math.rad(ResistAng)))
						end
					end
				end

				local brakestiffness = self:GetBrakeStiffness()
				if self.Brakes > 0 then brakestiffness = 1 end
				local halfwheels = WheelsPerSide * 0.5
				local basefriction = self:GetDakFriction() * (self.PhysicalMass * -GravxTicks).z * 0.9 / (WheelsPerSide * 2)
				if self.CarTurning == 1 then basefriction = self:GetDakFriction() * (self.PhysicalMass * -GravxTicks).z * 0.9 / (WheelsPerSide * 2) end
				local multval = 1
				local localfriction
				local worldfriction
				local rotatedforward
				local ForwardEntPos = ForwardEnt:GetPos()
				local ForwardEntAng = ForwardEnt:GetAngles()
				local rightbraking = Vector(max(self.RightBrake * brakestiffness, TerrainBraking), 1, 0) * 2
				local leftbraking = Vector(max(self.LeftBrake * brakestiffness, TerrainBraking), 1, 0) * 2
				local WheelYaw = self.WheelYaw
				local ShockForce = 10 * self.PhysicalMass
				local InAir = true
				--Right side
				for i = 1, WheelsPerSide do --These two loops are a little over half of the average execution time. They're probably worth focusing on.
					RideHeight = self.RideHeight
					if i > halfwheels then --TODO: Check note further down
						RideHeight = RideHeight - (hydrabias * (math.floor(halfwheels) - (WheelsPerSide - i)) / math.floor(halfwheels) * RideHeight)
					elseif i <= halfwheels then
						RideHeight = RideHeight + (hydrabias * (math.floor(halfwheels) - (i - 1)) / math.floor(halfwheels) * RideHeight)
					end

					RideHeight = RideHeight + hydrabiasside * RideHeight
					ForcePos = selfpos + (forward * (((i - 1) * TrackLength / (WheelsPerSide - 1)) - (TrackLength * 0.5) + ForwardOffset)) + (right * basesize[2] * 0.95)
					Pos = selfpos + (forward * (((i - 1) * TrackLength / (WheelsPerSide - 1)) - (TrackLength * 0.5) + ForwardOffset)) + (right * self.SideDist)
					if self:GetVehicleMode() == "wheeled" then
						CurRideHeight = RideHeight
					else
						if i == WheelsPerSide then
							CurRideHeight = FrontWheelRaise
						elseif i == 1 then
							CurRideHeight = RearWheelRaise
						else
							CurRideHeight = RideHeight
						end
					end

					trace = {
						start = Pos + Vector(0, 0, 1) * (-CurRideHeight + 100),
						endpos = Pos + Vector(0, 0, 1) * -CurRideHeight,
						mins = Vector(-10, -10, -0),
						maxs = Vector(10, 10, 0),
						mask = MASK_SOLID_BRUSHONLY
					}

					CurTrace = tracehull(trace)
					CurTraceHitPos = CurTrace.HitPos
					CurTraceDist = max((CurTrace.StartPos - CurTraceHitPos):Length(), 80)
					lastchange = (CurTraceDist - self.RightChanges[i]) / self.RealInt
					self.RightChanges[i] = CurTraceDist
					lastvel = (CurTraceHitPos - self.RightPosChanges[i]) / self.TimeMult
					localfriction, _ = WorldToLocal(ForwardEntPos + lastvel, Angle(0, 0, 0), ForwardEntPos, ForwardEntAng)
					localfriction = localfriction * rightbraking
					worldfriction, _ = LocalToWorld(localfriction, Angle(0, 0, 0), ForwardEntPos, ForwardEntAng)
					rotatedforward = ForwardEnt:GetForward()
					if i <= RearTurners and i <= halfwheels then
						localfriction, _ = WorldToLocal(ForwardEntPos + lastvel, Angle(0, 0, 0), ForwardEntPos, ForwardEntAng + Angle(0, WheelYaw, 0))
						localfriction = localfriction * rightbraking
						worldfriction, _ = LocalToWorld(localfriction, Angle(0, 0, 0), ForwardEntPos, ForwardEntAng + Angle(0, WheelYaw, 0))
						rotatedforward:Rotate(Angle(0, -WheelYaw, 0))
					elseif WheelsPerSide - (i - 1) <= FrontTurners and i >= halfwheels then
						localfriction, _ = WorldToLocal(ForwardEntPos + lastvel, Angle(0, 0, 0), ForwardEntPos, ForwardEntAng + Angle(0, -WheelYaw, 0))
						localfriction = localfriction * rightbraking
						worldfriction, _ = LocalToWorld(localfriction, Angle(0, 0, 0), ForwardEntPos, ForwardEntAng + Angle(0, -WheelYaw, 0))
						rotatedforward:Rotate(Angle(0, -WheelYaw, 0))
					end

					lastvel = worldfriction - ForwardEntPos
					self.RightPosChanges[i] = CurTraceHitPos
					RidePos = Clamp(CurTraceDist - 100, -10, 10)
					if RidePos < -0.1 then
						AbsorbForce = self:GetSuspensionDamping() * (5 / WheelsPerSide)
						if abs(hydrabias) > 0 then AbsorbForce = 1 end
						FrictionForce = basefriction
					else
						AbsorbForce = 0.0
						FrictionForce = 0
					end

					multval = 1
					if i <= halfwheels then --TODO: Check if this actually needs to happen down here instead of up with the other version
						multval = multval + SuspensionBias
					elseif i > halfwheels then
						multval = multval - SuspensionBias
					end

					local CurHeight = RideHeight + CurTraceDist - 100
					local Force, LastInt = self:PID(RideHeight, CurHeight, self.RightLastHeights[i], self.RightInts[i])
					self.RightLastHeights[i] = CurHeight
					self.RightInts[i] = LastInt
					if CurHeight >= RideHeight then
						Force = 0
					else
						InAir = false
					end

					SuspensionForce = wheelweightforce + Vector(0, 0, (self.PhysicalMass * 1.2) * (min(Force, 10) / WheelsPerSide) * multval)
					AbsorbForceFinal = (-Vector(0, 0, Clamp(self.PhysicalMass * lastchange / (WheelsPerSide * 2), -ShockForce, ShockForce)) * AbsorbForce) * Clamp(self:GetSuspensionForceMult(), 0, 2) / self.TimeMult
					lastvelnorm = lastvel:GetNormalized()
					FrictionForceFinal = -Vector(Clamp(lastvel.x, -abs(lastvelnorm.x), abs(lastvelnorm.x)), Clamp(lastvel.y, -abs(lastvelnorm.y), abs(lastvelnorm.y)), 0) * FrictionForce
					self.RightRidePosChanges[i] = RidePos
					--print(FrictionForceFinal) ----------FIX ISSUE WHERE THIS SPERGS OUT AND GETS BIG FOR NO RAISIN
					--print(SuspensionForce)
					self.phy:ApplyImpulseOffsetF(self.TimeMult * ((rotatedforward * Vector(1, 1, 0)) * 4 * (TerrainMultiplier * self.RightForce) / WheelsPerSide + SuspensionForce + Vector(FrictionForceFinal.x, FrictionForceFinal.y, max(0, 2 * AbsorbForceFinal.z))), ForcePos)
				end

				--Left side
				for i = 1, WheelsPerSide do
					RideHeight = self.RideHeight
					if i > halfwheels then --TODO: This is the third time these values are checked
						RideHeight = RideHeight - (hydrabias * (math.floor(halfwheels) - (WheelsPerSide - i)) / math.floor(halfwheels) * RideHeight)
					elseif i <= halfwheels then
						RideHeight = RideHeight + (hydrabias * (math.floor(halfwheels) - (i - 1)) / math.floor(halfwheels) * RideHeight)
					end

					RideHeight = RideHeight - hydrabiasside * RideHeight
					ForcePos = selfpos + (forward * (((i - 1) * TrackLength / (WheelsPerSide - 1)) - (TrackLength * 0.5) + ForwardOffset)) - (right * basesize[2] * 0.95)
					Pos = selfpos + (forward * (((i - 1) * TrackLength / (WheelsPerSide - 1)) - (TrackLength * 0.5) + ForwardOffset)) - (right * self.SideDist)
					if self:GetVehicleMode() == "wheeled" then
						CurRideHeight = RideHeight
					else
						if i == WheelsPerSide then
							CurRideHeight = FrontWheelRaise
						elseif i == 1 then
							CurRideHeight = RearWheelRaise
						else
							CurRideHeight = RideHeight
						end
					end

					trace = {
						start = Pos + Vector(0, 0, 1) * (-CurRideHeight + 100),
						endpos = Pos + Vector(0, 0, 1) * -CurRideHeight,
						mins = Vector(-10, -10, -0),
						maxs = Vector(10, 10, 0),
						mask = MASK_SOLID_BRUSHONLY
					}

					CurTrace = tracehull(trace)
					CurTraceHitPos = CurTrace.HitPos
					CurTraceDist = max((CurTrace.StartPos - CurTraceHitPos):Length(), 80)
					lastchange = (CurTraceDist - self.LeftChanges[i]) / self.RealInt
					self.LeftChanges[i] = CurTraceDist
					lastvel = (CurTraceHitPos - self.LeftPosChanges[i]) / self.TimeMult
					localfriction, _ = WorldToLocal(ForwardEntPos + lastvel, Angle(0, 0, 0), ForwardEntPos, ForwardEntAng)
					localfriction = localfriction * leftbraking
					worldfriction, _ = LocalToWorld(localfriction, Angle(0, 0, 0), ForwardEntPos, ForwardEntAng)
					rotatedforward = ForwardEnt:GetForward()
					if i <= RearTurners and i <= halfwheels then
						localfriction, _ = WorldToLocal(ForwardEntPos + lastvel, Angle(0, 0, 0), ForwardEntPos, ForwardEntAng + Angle(0, WheelYaw, 0))
						localfriction = localfriction * leftbraking
						worldfriction, _ = LocalToWorld(localfriction, Angle(0, 0, 0), ForwardEntPos, ForwardEntAng + Angle(0, WheelYaw, 0))
						rotatedforward:Rotate(Angle(0, -WheelYaw, 0))
					elseif WheelsPerSide - (i - 1) <= FrontTurners and i >= halfwheels then
						localfriction, _ = WorldToLocal(ForwardEntPos + lastvel, Angle(0, 0, 0), ForwardEntPos, ForwardEntAng + Angle(0, -WheelYaw, 0))
						localfriction = localfriction * leftbraking
						worldfriction, _ = LocalToWorld(localfriction, Angle(0, 0, 0), ForwardEntPos, ForwardEntAng + Angle(0, -WheelYaw, 0))
						rotatedforward:Rotate(Angle(0, -WheelYaw, 0))
					end

					lastvel = worldfriction - ForwardEntPos
					self.LeftPosChanges[i] = CurTraceHitPos
					RidePos = Clamp(CurTraceDist - 100, -10, 10)
					if RidePos < -0.1 then
						AbsorbForce = self:GetSuspensionDamping() * (5 / WheelsPerSide)
						if abs(hydrabias) > 0 then AbsorbForce = 1 end
						FrictionForce = basefriction
					else
						AbsorbForce = 0.0
						FrictionForce = 0
					end

					multval = 1
					if i <= halfwheels then --4th
						multval = multval + SuspensionBias
					elseif i > halfwheels then
						multval = multval - SuspensionBias
					end

					local CurHeight = RideHeight + CurTraceDist - 100
					local Force, LastInt = self:PID(RideHeight, CurHeight, self.LeftLastHeights[i], self.LeftInts[i])
					self.LeftLastHeights[i] = CurHeight
					self.LeftInts[i] = LastInt
					if CurHeight >= RideHeight then
						Force = 0
					else
						InAir = false
					end

					SuspensionForce = wheelweightforce + Vector(0, 0, (self.PhysicalMass * 1.2) * (min(Force, 10) / WheelsPerSide) * multval)
					AbsorbForceFinal = (-Vector(0, 0, Clamp(self.PhysicalMass * lastchange / (WheelsPerSide * 2), -ShockForce, ShockForce)) * AbsorbForce) * Clamp(self:GetSuspensionForceMult(), 0, 2) / self.TimeMult
					lastvelnorm = lastvel:GetNormalized() -- * (Vector(1-forward.x,1-forward.y,1-forward.z)) + forward*self.LeftBrake
					FrictionForceFinal = -Vector(Clamp(lastvel.x, -abs(lastvelnorm.x), abs(lastvelnorm.x)), Clamp(lastvel.y, -abs(lastvelnorm.y), abs(lastvelnorm.y)), 0) * FrictionForce
					self.LeftRidePosChanges[i] = RidePos
					self.phy:ApplyImpulseOffsetF(self.TimeMult * ((rotatedforward * Vector(1, 1, 0)) * 4 * (TerrainMultiplier * self.LeftForce) / WheelsPerSide + SuspensionForce + Vector(FrictionForceFinal.x, FrictionForceFinal.y, max(0, 2 * AbsorbForceFinal.z))), ForcePos)
				end

				self.LastWheelsPerSide = WheelsPerSide
				--mid air stabilization to lower flip rates when going over stuff
				if InAir then
					if self.LastRoll == nil then self.LastRoll = self.ForwardEnt:GetAngles().roll end
					if self.LastRollInt == nil then self.LastRollInt = 0 end
					local rollforce, rollint = self:AngPID(0, self.ForwardEnt:GetAngles().roll, self.LastRoll, self.LastRollInt)
					rollforce = Clamp(rollforce, -25, 25)
					self.phy:ApplyImpulseOffsetF(-rollforce * self.ForwardEnt:GetUp() * self.PhysicalMass * 0.01 * self.TimeMult, self.base:GetPos() + self.ForwardEnt:GetRight() * 100)
					self.phy:ApplyImpulseOffsetF(rollforce * self.ForwardEnt:GetUp() * self.PhysicalMass * 0.01 * self.TimeMult, self.base:GetPos() + self.ForwardEnt:GetRight() * -100)
					self.LastRoll = self.ForwardEnt:GetAngles().roll
					self.LastRollInt = rollint
					if self.LastPitch == nil then self.LastPitch = self.ForwardEnt:GetAngles().pitch end
					if self.LastPitchInt == nil then self.LastPitchInt = 0 end
					local pitchforce, pitchint = self:AngPID(0, self.ForwardEnt:GetAngles().pitch, self.LastPitch, self.LastPitchInt)
					pitchforce = Clamp(pitchforce, -25, 25)
					self.phy:ApplyImpulseOffsetF(-pitchforce * self.ForwardEnt:GetUp() * self.PhysicalMass * 0.01 * self.TimeMult, self.base:GetPos() + self.ForwardEnt:GetForward() * 100)
					self.phy:ApplyImpulseOffsetF(pitchforce * self.ForwardEnt:GetUp() * self.PhysicalMass * 0.01 * self.TimeMult, self.base:GetPos() + self.ForwardEnt:GetForward() * -100)
					self.LastPitch = self.ForwardEnt:GetAngles().pitch
					self.LastPitchInt = pitchint
				end

				self.phy:ApplyForceCenter(self.RealInt * self.PhysicalMass * physenv.GetGravity())
				if self.LastSpeed == nil then self.LastSpeed = Vector(0, 0, 0):Distance(self.phy:GetVelocity()) * (0.277778 * 0.254) end
				self.Speed = Vector(0, 0, 0):Distance(self.phy:GetVelocity()) * (0.277778 * 0.254)
				local accel = self.Speed - self.LastSpeed
				self.phy:ApplyImpulseOffsetFTorqueOnly(self.phy:GetMass() * self.phy:GetVelocity():GetNormalized() * -accel * Clamp(self:GetDakInertia(), 0, 10), self.base:GetPos() + self.ForwardEnt:GetUp() * 100)
				self.LastSpeed = self.Speed
			end
		end

		if self.DakBurnStacks > 40 then
			self.DakBurnStacks = 40
		elseif self.DakBurnStacks > 0 and not self:IsOnFire() then
			self.DakBurnStacks = self.DakBurnStacks - 0.1
		end

		if self:IsOnFire() and self.DakDead ~= true then
			local Dmg = self.DakMaxHealth * 0.025 * engine.TickInterval()
			self.DakHealth = self.DakHealth - Dmg
			self:DTOnTakeDamage(Dmg)
		end

		if self.SpeedTable == nil then --Why is this defined here and not in init?
			self.SpeedTable = {}
		end

		if self.LastAccel == nil then self.LastAccel = 0 end
		self.SpeedTable[#self.SpeedTable + 1] = (self.LastYaw - self.base:GetAngles().yaw) / self.TimeMult
		if #self.SpeedTable > 2 then table.remove(self.SpeedTable, 1) end
		local totalspeed = 0
		for i = 1, #self.SpeedTable do
			totalspeed = totalspeed + self.SpeedTable[i]
		end

		self.RealYaw = totalspeed / #self.SpeedTable
		self.LastYaw = self:GetParent():GetParent():GetAngles().yaw
	end

	self.LastThink = CurTime()
	self:NextThink(CurTime())
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
end

function ENT:PreEntityCopy()
	local info = {}
	-- local entids = {}
	info.CrewID = self.DakCrew:EntIndex()
	info.DakName = self.DakName
	info.DakMass = self.DakMass
	info.DakModel = self.DakModel
	info.DakMaxHealth = self.DakMaxHealth
	info.DakHealth = self.DakHealth
	duplicator.StoreEntityModifier(self, "DakTek", info)
	-- Wire dupe info
	self.BaseClass.PreEntityCopy(self)
end

function ENT:PostEntityPaste(Player, Ent, CreatedEntities)
	if Ent.EntityMods and Ent.EntityMods.DakTek then
		local Crew = CreatedEntities[Ent.EntityMods.DakTek.CrewID]
		if Crew and IsValid(Crew) then self.DakCrew = Crew end
		self.DakName = Ent.EntityMods.DakTek.DakName
		self.DakMass = Ent.EntityMods.DakTek.DakMass
		self.DakModel = Ent.EntityMods.DakTek.DakModel
		self.DakMaxHealth = Ent.EntityMods.DakTek.DakMaxHealth
		self.DakHealth = self.DakMaxHealth
		self.DakOwner = Player
		if Ent.EntityMods.DakTek.DakColor then self:SetColor(Ent.EntityMods.DakTek.DakColor) end
		--self:PhysicsDestroy()
		--self:SetModel(self.DakModel)
		--self:PhysicsInit(SOLID_VPHYSICS)
		--self:SetMoveType(MOVETYPE_VPHYSICS)
		--self:SetSolid(SOLID_VPHYSICS)
		self:Activate()
		Ent.EntityMods.DakTek = nil
	end

	self.BaseClass.PostEntityPaste(self, Player, Ent, CreatedEntities)
end

function ENT:OnDuplicated(data)
	local dt = data.DT
	if not istable(dt) or dt.TrackLength == nil then
		if data.EntityMods and data.EntityMods._DakVar_DUPED then -- hack...
			self.dak_restoreLegacy = function() self:_DakVar_RESTORE(data.EntityMods._DakVar_DUPED) end
		end
		return
	end

	self.dak_restoreLegacy = function()
		MsgN(tostring(self), "restoring legacy daktank gearbox values")
		-- mobility
		self:SetVehicleMode(dt.WheeledMode == true and "wheeled" or "tracked")
		self:SetWheelBase(dt.TrackLength)
		self:SetWheelOffsetX(dt.ForwardOffset)
		self:SetWheelOffsetY(dt.SideDist)
		self:SetWheelOffsetZ(dt.RideHeight)
		self:SetGearRatio(dt.GearRatio)
		self:SetSuspensionBias(dt.SuspensionBias)
		self:SetSuspensionDamping(dt.SuspensionDamping)
		self:SetSuspensionForceMult(dt.SuspensionForceMult)
		self:SetRideLimit(dt.RideLimit)
		self:SetBrakeStiffness(dt.BrakeStiffness)
		-- visual
		local color = dt.WheelColor
		if isvector(color) then self:SetWheelColor(Vector(color.x * 255, color.y * 255, color.z * 255)) end
		if dt.WheeledMode == true then
			self:SetRoadWTurnFront(dt.ForwardTurningWheels)
			self:SetRoadWTurnRear(dt.RearTurningWheels)
			self:SetRoadWTurnAngle(dt.TurnAngle)
			self:SetDriveWOffsetZ(dt.FrontWheelRaise)
			self:SetIdlerWOffsetZ(dt.RearWheelRaise)
			self:SetDriveWDiameter(dt.WheelHeight)
			self:SetIdlerWDiameter(dt.WheelHeight)
		else
			self:SetTrackTension(1)
			self:SetRollerWCount(0)
			self:SetTrackHeight(dt.TreadHeight)
			self:SetTrackWidth(dt.TreadWidth)
			color = dt.TreadColor
			if isvector(color) then self:SetTrackColor(Vector(color.x * 255, color.y * 255, color.z * 255)) end
			self:SetDriveWOffsetZ(dt.FrontWheelRaise * 0.5 - dt.FrontWheelHeight * 0.5 - dt.TreadHeight) -- bug?
			self:SetIdlerWOffsetZ(dt.RearWheelRaise * 0.5 - dt.RearWheelHeight * 0.5 - dt.TreadHeight)
			self:SetDriveWDiameter(dt.FrontWheelHeight)
			self:SetIdlerWDiameter(dt.RearWheelHeight)
		end

		-- front
		self:SetDriveWModel(dt.WheelModel)
		self:SetDriveWWidth(dt.WheelWidth)
		self:SetDriveWBGroup(string.format("%d%d%d", dt.WheeBodygroup1 or 0, dt.WheeBodygroup2 or 0, (dt.FrontSprocket and 1) or tonumber(dt.WheelBodygroup3) or 0))
		-- road
		if tonumber(dt.WheelsPerSide) then self:SetRoadWCount(dt.WheelsPerSide - (dt.WheeledMode and 0 or 2)) end
		self:SetRoadWModel(dt.WheelModel)
		self:SetRoadWDiameter(dt.WheelHeight)
		self:SetRoadWWidth(dt.WheelWidth)
		self:SetRoadWBGroup(string.format("%d%d%d", dt.WheeBodygroup1 or 0, dt.WheelBodygroup2 or 0, dt.WheelBodygroup3 or 0))
		-- rear
		self:SetIdlerWModel(dt.WheelModel)
		self:SetIdlerWWidth(dt.WheelWidth)
		self:SetIdlerWBGroup(string.format("%d%d%d", dt.WheeBodygroup1 or 0, dt.WheeBodygroup2 or 0, (dt.RearSprocket and 1) or tonumber(dt.WheelBodygroup3) or 0))
	end
end