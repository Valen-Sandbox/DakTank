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
	self.SideDist = self:GetWheelOffsetY()
	self.TrackLength = self:GetWheelBase()
	self.WheelsPerSide = Clamp(self:GetWheelsPerSide(), 2, 20)
	self.RideHeight = self:GetWheelOffsetZ()
	self.RideLimit = Clamp(self:GetRideLimit(), 50, 200)
	self.SuspensionBias = Clamp(self:GetSuspensionBias(), -0.99, 0.99)
	self.RightChanges = {}
	self.RightInAir = {}
	self.RightLastAbsorbForce = {}
	self.RightPosChanges = {}
	self.RightRidePosChanges = {}
	self.RightLastHeights = {}
	self.LeftLastHeights = {}
	self.RightInts = {}
	self.LeftInts = {}
	self.LeftChanges = {}
	self.LeftInAir = {}
	self.LeftLastAbsorbForce = {}
	self.LeftPosChanges = {}
	self.LeftRidePosChanges = {}
	self.SlowThinkTime = CurTime()
	self.RealYaw = 0
	self.WheelYaw = 0
	for i = 1, self.WheelsPerSide do
		self.RightChanges[i] = 0
		self.LeftChanges[i] = 0
		self.RightInAir[i] = false
		self.LeftInAir[i] = false
		self.RightLastAbsorbForce[i] = 0
		self.LeftLastAbsorbForce[i] = 0
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

local m_to_in = 100 / 2.54 -- meters to inches
local in_to_m = 1 / m_to_in
local impFactor = in_to_m * in_to_m * 180 / math.pi
local PhysObj = FindMetaTable("PhysObj")
function PhysObj:ApplyImpulseOffsetF(impulse, position)
	self:ApplyForceCenter(impulse)
	local offset = position - self:LocalToWorld(self:GetMassCenter())
	local angimp = offset:Cross(impulse) * impFactor
	self:ApplyTorqueCenter(angimp)
end

function PhysObj:ApplyImpulseOffsetF_Optimized(impulse, offset) --Requires offset to be passed, so that we don't need to index the physobj a bunch of times when it's called.
	self:ApplyForceCenter(impulse)
	local angimp = offset:Cross(impulse) * impFactor
	self:ApplyTorqueCenter(angimp)
end

function PhysObj:ApplyImpulseOffsetFTorqueOnly(impulse, position)
	local offset = position - self:LocalToWorld(self:GetMassCenter())
	local angimp = offset:Cross(impulse) * impFactor
	self:ApplyTorqueCenter(angimp)
end

local function PID(goal, height, lastheight, lastintegral, selfTbl)
	--goal is ride height
	--height is current suspension extension
	local P = 1.125 * selfTbl.SuspensionForceMult
	local D = 125 / selfTbl.RideLimit
	local Time = (3 / selfTbl.RealInt) --3s to full power
	--proportional
	local Err = (goal - height) / selfTbl.TimeMult
	local Correction = Err * P
	--integral
	local Integral = (lastintegral * (Time - 1) + Err) / Time
	--derivative
	local LastErr = (goal - lastheight) / selfTbl.TimeMult
	local Derivative = (Err - LastErr) * D
	return Correction + Integral + Derivative, Integral
end

local function AngPID(goal, height, lastheight, lastintegral, selfTbl)
	--goal is ride height
	--height is current suspension extension
	local P = 1
	-- local I = 1
	local D = 100
	local Time = (1 / selfTbl.RealInt) * 3 --3s to full power
	--proportional
	local Err = (goal - height) / selfTbl.TimeMult
	local Correction = Err * P
	--integral
	local Integral = (lastintegral * (Time - 1) + Err) / Time
	--derivative
	local LastErr = (goal - lastheight) / selfTbl.TimeMult
	local Derivative = (Err - LastErr) * D
	return Correction + Integral + Derivative, Integral
end

function ENT:Think()
	local vector_origin = vector_origin
	local vector_up = vector_up
	local angle_zero = angle_zero
	--checkspherical was here but has been moved to slowthink
	local self = self
	local selfTbl = self:GetTable()

	local curTime = CurTime()
	selfTbl.RealInt = curTime - selfTbl.LastThink
	selfTbl.TimeMult = selfTbl.RealInt / (1 / 66)

	local TimeMult = selfTbl.TimeMult
	if selfTbl.dak_restoreLegacy then
		self:dak_restoreLegacy()
		selfTbl.dak_restoreLegacy = nil
		return
	end

	selfTbl.SideDist = selfTbl:GetWheelOffsetY() --TODO: Only set these values when editable values are updated
	selfTbl.TrackLength = selfTbl:GetWheelBase()
	selfTbl.WheelsPerSide = Clamp(selfTbl:GetWheelsPerSide(), 2, 20)
	selfTbl.RideHeight = selfTbl:GetWheelOffsetZ()
	selfTbl.RideLimit = Clamp(selfTbl:GetRideLimit(), 50, 200)
	selfTbl.SuspensionBias = Clamp(selfTbl:GetSuspensionBias(), -0.99, 0.99)
	selfTbl.SuspensionForceMult = Clamp(selfTbl:GetSuspensionForceMult(), 0, 2)
	selfTbl.FrontWheelRaise = selfTbl:GetDriveWOffsetZ()
	selfTbl.RearWheelRaise = selfTbl:GetIdlerWOffsetZ()
	selfTbl.ForwardOffset = selfTbl:GetWheelOffsetX()
	selfTbl.GearRatio = Clamp(selfTbl:GetGearRatio(), 50, 100) * 0.01
	selfTbl.WheelHeight = selfTbl:GetRoadWDiameter()
	selfTbl.FrontWheelHeight = selfTbl:GetDriveWDiameter()
	selfTbl.RearWheelHeight = selfTbl:GetIdlerWDiameter()
	selfTbl.SuspensionDamping = selfTbl:GetSuspensionDamping()

	if curTime >= selfTbl.SlowThinkTime + 1 then
		selfTbl.SlowThinkTime = curTime
		if selfTbl.DakName == "Micro Frontal Mount Gearbox" then
			selfTbl.DakMaxHealth = 7.5
			selfTbl.DakArmor = 7.5
			selfTbl.DakMass = 80
			selfTbl.DakModel = "models/daktanks/gearbox1f1.mdl"
			selfTbl.Torque = 1
			selfTbl.MaxHP = 80
		elseif selfTbl.DakName == "Small Frontal Mount Gearbox" then
			selfTbl.DakMaxHealth = 25
			selfTbl.DakArmor = 25
			selfTbl.DakMass = 265
			selfTbl.DakModel = "models/daktanks/gearbox1f2.mdl"
			selfTbl.Torque = 1
			selfTbl.MaxHP = 250
		elseif selfTbl.DakName == "Standard Frontal Mount Gearbox" then
			selfTbl.DakMaxHealth = 60
			selfTbl.DakArmor = 60
			selfTbl.DakMass = 630
			selfTbl.DakModel = "models/daktanks/gearbox1f3.mdl"
			selfTbl.Torque = 1
			selfTbl.MaxHP = 600
		elseif selfTbl.DakName == "Large Frontal Mount Gearbox" then
			selfTbl.DakMaxHealth = 120
			selfTbl.DakArmor = 120
			selfTbl.DakMass = 1230
			selfTbl.DakModel = "models/daktanks/gearbox1f4.mdl"
			selfTbl.Torque = 1
			selfTbl.MaxHP = 1200
		elseif selfTbl.DakName == "Huge Frontal Mount Gearbox" then
			selfTbl.DakMaxHealth = 200
			selfTbl.DakArmor = 200
			selfTbl.DakMass = 2130
			selfTbl.DakModel = "models/daktanks/gearbox1f5.mdl"
			selfTbl.Torque = 1
			selfTbl.MaxHP = 2000
		elseif selfTbl.DakName == "Ultra Frontal Mount Gearbox" then
			selfTbl.DakMaxHealth = 480
			selfTbl.DakArmor = 480
			selfTbl.DakMass = 5050
			selfTbl.DakModel = "models/daktanks/gearbox1f6.mdl"
			selfTbl.Torque = 1
			selfTbl.MaxHP = 4800
		elseif selfTbl.DakName == "Micro Rear Mount Gearbox" then
			selfTbl.DakMaxHealth = 7.5
			selfTbl.DakArmor = 7.5
			selfTbl.DakMass = 80
			selfTbl.DakModel = "models/daktanks/gearbox1r1.mdl"
			selfTbl.Torque = 1
			selfTbl.MaxHP = 80
		elseif selfTbl.DakName == "Small Rear Mount Gearbox" then
			selfTbl.DakMaxHealth = 25
			selfTbl.DakArmor = 25
			selfTbl.DakMass = 265
			selfTbl.DakModel = "models/daktanks/gearbox1r2.mdl"
			selfTbl.Torque = 1
			selfTbl.MaxHP = 250
		elseif selfTbl.DakName == "Standard Rear Mount Gearbox" then
			selfTbl.DakMaxHealth = 60
			selfTbl.DakArmor = 60
			selfTbl.DakMass = 630
			selfTbl.DakModel = "models/daktanks/gearbox1r3.mdl"
			selfTbl.Torque = 1
			selfTbl.MaxHP = 600
		elseif selfTbl.DakName == "Large Rear Mount Gearbox" then
			selfTbl.DakMaxHealth = 120
			selfTbl.DakArmor = 120
			selfTbl.DakMass = 1230
			selfTbl.DakModel = "models/daktanks/gearbox1r4.mdl"
			selfTbl.Torque = 1
			selfTbl.MaxHP = 1200
		elseif selfTbl.DakName == "Huge Rear Mount Gearbox" then
			selfTbl.DakMaxHealth = 200
			selfTbl.DakArmor = 200
			selfTbl.DakMass = 2130
			selfTbl.DakModel = "models/daktanks/gearbox1r5.mdl"
			selfTbl.Torque = 1
			selfTbl.MaxHP = 2000
		elseif selfTbl.DakName == "Ultra Rear Mount Gearbox" then
			selfTbl.DakMaxHealth = 480
			selfTbl.DakArmor = 480
			selfTbl.DakMass = 5050
			selfTbl.DakModel = "models/daktanks/gearbox1r6.mdl"
			selfTbl.Torque = 1
			selfTbl.MaxHP = 4800
		end

		DTTE.CheckSpherical(self)
	end

	if curTime >= selfTbl.SparkTime + 0.33 then
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

		selfTbl.SparkTime = curTime
	end

	if not selfTbl.FirstCheck and selfTbl.DakMaxHealth ~= 25 then
		selfTbl.FirstCheck = true
		selfTbl.DakHealth = selfTbl.DakMaxHealth
	end

	local DakTankCore = selfTbl.DakTankCore
	if IsValid(DakTankCore) and IsValid(DakTankCore.Motors[1]) and DakTankCore.Off ~= true then
		local DakTankCoreTbl = DakTankCore:GetTable()
		local motors = DakTankCoreTbl.Motors
		selfTbl.DakSpeed = 0
		selfTbl.DakFuel = 0
		selfTbl.DakFuelReq = 0
		selfTbl.DakHP = 0

		for i, v in ipairs(motors) do
			if IsValid(v) then
				selfTbl.DakSpeed = selfTbl.DakSpeed + v.DakSpeed
				selfTbl.DakFuelReq = selfTbl.DakFuelReq + v.DakFuelReq
				selfTbl.DakHP = selfTbl.DakHP + v.DakHP
			end
		end

		if #DakTankCoreTbl.Fuel > 0 then
			for i = 1, #DakTankCoreTbl.Fuel do
				if selfTbl.DakFuel and IsValid(DakTankCoreTbl.Fuel[i]) then selfTbl.DakFuel = selfTbl.DakFuel + DakTankCoreTbl.Fuel[i].DakFuel end
			end
		else
			selfTbl.DakHP = 0
		end

		selfTbl.DakSpeed = (selfTbl.DakSpeed * 2 * Clamp(selfTbl.DakFuel / selfTbl.DakFuelReq, 0, 1)) * Clamp(selfTbl.MaxHP / selfTbl.DakHP, 0, 1)
		selfTbl.CrewAlive = 1 --TODO: This should probably be a boolean. I can't be bothered to find where it's used right now to check.
		if selfTbl.DakCrew == NULL or selfTbl.DakCrew.DakEntity ~= self then
			selfTbl.DakSpeed = 0
			selfTbl.CrewAlive = 0
		else
			selfTbl.DakCrew.Job = 2
			if selfTbl.DakCrew.DakDead then
				selfTbl.DakSpeed = 0
				selfTbl.CrewAlive = 0
			end
		end

		if not self:IsSolid() then selfTbl.DakSpeed = 0 end
		if selfTbl.DakHealth > selfTbl.DakMaxHealth then selfTbl.DakHealth = selfTbl.DakMaxHealth end
		if self:GetModel() ~= selfTbl.DakModel then
			self:SetModel(selfTbl.DakModel)
			self:SetMoveType(MOVETYPE_VPHYSICS)
			self:SetSolid(SOLID_VPHYSICS)
		end

		local physObj = self:GetPhysicsObject()
		if selfTbl.AddonMass and physObj:GetMass() ~= selfTbl.DakMass + selfTbl.AddonMass then physObj:SetMass(selfTbl.DakMass + selfTbl.AddonMass) end
		selfTbl.MoveForward = selfTbl.Inputs.Forward.Value
		selfTbl.MoveReverse = selfTbl.Inputs.Reverse.Value
		selfTbl.MoveLeft = selfTbl.Inputs.Left.Value
		selfTbl.MoveRight = selfTbl.Inputs.Right.Value
		selfTbl.Brakes = selfTbl.Inputs.Brakes.Value
		selfTbl.Active = selfTbl.Inputs.Activate.Value
		selfTbl.ForwardEnt = selfTbl.Inputs.ForwardFacingEntity.Value
		if selfTbl.ForwardEnt == nil or selfTbl.ForwardEnt == NULL then selfTbl.ForwardEnt = self end
		if selfTbl.ForwardEnt ~= selfTbl.LastForwardEnt then
			self:SetNWEntity("ForwardEnt", selfTbl.ForwardEnt)
			selfTbl.LastForwardEnt = selfTbl.ForwardEnt
		end

		selfTbl.CarTurning = selfTbl.Inputs.CarTurning.Value

		local selfParent = self:GetParent()
		if IsValid(selfParent) and IsValid(selfParent:GetParent()) then
			local selfParent2 = selfParent:GetParent()
			if (not selfTbl.setup) then
				selfTbl.YawAng = Angle(0, selfParent2:GetAngles().yaw, 0)
				selfTbl.LastYaw = selfParent2:GetAngles().yaw
				selfTbl.setup = 1
			end

			local phys = selfParent2:GetPhysicsObject()
			if selfTbl.InertiaSet == nil and phys:IsMotionEnabled() == true then
				local oldinertia = phys:GetInertia()
				local multiplier = 2
				phys:SetInertia(Vector(oldinertia.x * multiplier, oldinertia.y * multiplier, oldinertia.z * multiplier))
				phys:SetMass(phys:GetMass()) --???
				phys:EnableGravity(false)
				selfTbl.InertiaSet = 1
			end
		end

		if selfTbl.TotalMass then
			if selfTbl.AddonMass == nil then selfTbl.AddonMass = math.Round(selfTbl.TotalMass * 0.1) end
			selfTbl.DakSpeed = selfTbl.DakSpeed * (10000 / selfTbl.TotalMass)
			selfTbl.TopSpeed = (29.851 * selfTbl.DakSpeed) * selfTbl.GearRatio
			if IsValid(selfParent) and IsValid(selfParent:GetParent()) then
				local selfParent2 = selfParent:GetParent()
				selfTbl.phy = selfParent2:GetPhysicsObject()
				selfTbl.base = selfParent2
				selfTbl.phy:SetDamping(0, 0)
			elseif not selfParent2 then
				selfTbl.phy = self:GetPhysicsObject()
				selfTbl.base = self
			end

			if selfTbl.base ~= selfTbl.Lastbase then
				self:SetNWEntity("Base", selfTbl.base)
				selfTbl.Lastbase = selfTbl.base
			end

			if selfTbl.DakDead ~= true then
				selfTbl.HPperTon = selfTbl.DakHP / (selfTbl.TotalMass / 1000) * math.Clamp(selfTbl.MaxHP / selfTbl.DakHP, 0, 1)
			else
				selfTbl.HPperTon = 0
			end

			if selfTbl.Active > 0 then
				if selfTbl.MoveForward <= 0 and selfTbl.MoveReverse <= 0 and selfTbl.MoveLeft <= 0 and selfTbl.MoveRight <= 0 then
					if selfTbl.RPM > 600 then
						selfTbl.RPM = selfTbl.RPM - 100
					elseif selfTbl.RPM < 600 then
						selfTbl.RPM = 600
					end
				else
					if selfTbl.MoveReverse > 0 then
						selfTbl.RPM = 1000 * Clamp(selfTbl.TopSpeed * 0.5 / (selfTbl.Speed * 1.5), 0.6, 2.0)
						if selfTbl.Speed * 1.5 > selfTbl.TopSpeed then selfTbl.RPM = 2000 * Clamp(selfTbl.Speed / selfTbl.TopSpeed * 0.5, 0.5, 1) end
					else
						selfTbl.RPM = 1000 * Clamp(selfTbl.TopSpeed / (selfTbl.Speed * 1.5), 0.6, 2.0)
						if selfTbl.Speed * 1.5 > selfTbl.TopSpeed then selfTbl.RPM = 2000 * Clamp(selfTbl.Speed / selfTbl.TopSpeed, 0.5, 1) end
					end
				end

				if #motors > 0 then
					for i, v in ipairs(motors) do
						if IsValid(v) then
							v.Sound:ChangeVolume(0.25, 1) 
						end
					end
				end

				if selfTbl.Brakes > 0 then
					selfTbl.Perc = 0
					--DO BRAKES BOTH
					selfTbl.RightBrake = 1
					selfTbl.LeftBrake = 1
					selfTbl.LeftForce = 0
					selfTbl.RightForce = 0
					if #motors > 0 then
						for i, v in ipairs(motors) do
							if IsValid(v) then
								v.Sound:ChangePitch(Clamp(255 * selfTbl.RPM / 2500, 0, 255), 0.5)
							end
						end
					end
				else
					if selfTbl.MoveForward <= 0 and selfTbl.MoveReverse <= 0 then
						if selfTbl.Perc > 0 then
							selfTbl.Perc = selfTbl.Perc - 0.1 * TimeMult
						elseif selfTbl.Perc < 0 then
							selfTbl.Perc = selfTbl.Perc + 0.1 * TimeMult
						end
					else
						if selfTbl.MoveForward > 0 then
							if selfTbl.Perc < 0 then selfTbl.Perc = 0 end
							if selfTbl.Perc < 1 then selfTbl.Perc = selfTbl.Perc + 0.1 * TimeMult end
						end

						if selfTbl.MoveReverse > 0 then
							if selfTbl.Perc > 0 then selfTbl.Perc = 0 end
							if selfTbl.Perc > -1 then selfTbl.Perc = selfTbl.Perc - 0.1 * TimeMult end
							selfTbl.TopSpeed = selfTbl.TopSpeed / 3
						end
					end

					if selfTbl.MoveRight <= 0 and selfTbl.MoveLeft <= 0 then selfTbl.TurnPerc = 0 end
					if selfTbl.Speed < selfTbl.TopSpeed then
						selfTbl.RBoost = 1
						selfTbl.LBoost = 1
						if selfTbl.MoveRight == 0 and selfTbl.MoveLeft == 0 then
							if selfTbl.CarTurning == 1 then
								if selfTbl.WheelYaw > 0 then
									selfTbl.WheelYaw = selfTbl.WheelYaw - 1 * TimeMult
								elseif selfTbl.WheelYaw < 0 then
									selfTbl.WheelYaw = selfTbl.WheelYaw + 1 * TimeMult
								end
							end
						end

						if selfTbl.Speed > 0 then
							--TRACTION CONTROL
							local _, temp = WorldToLocal(vector_origin, Angle(0, selfTbl.LastYaw, 0), vector_origin, Angle(0, selfTbl.base:GetAngles().yaw, 0))
							local TurnVal = temp.yaw / TimeMult

							local ControlForce = min(max(4, abs(TurnVal * 5)), 10)
							if selfTbl.Perc >= 0 then
								if TurnVal > 0.05 and selfTbl.MoveRight == 0 then
									selfTbl.LBoost = 0 - ControlForce
									selfTbl.RBoost = 2 + ControlForce
								elseif TurnVal < -0.05 and selfTbl.MoveLeft == 0 then
									selfTbl.LBoost = 2 + ControlForce
									selfTbl.RBoost = 0 - ControlForce
								end
							else
								if TurnVal > 0.05 and selfTbl.MoveLeft == 0 then
									selfTbl.LBoost = 2 + ControlForce
									selfTbl.RBoost = 0 - ControlForce
								elseif TurnVal < -0.05 and selfTbl.MoveRight == 0 then
									selfTbl.LBoost = 0 - ControlForce
									selfTbl.RBoost = 2 + ControlForce
								end
							end
						else
							selfTbl.LBoost = 1
							selfTbl.RBoost = 1
						end

						if selfTbl.CarTurning == 1 then
							--ENSURE BRAKES ARE OFF
							selfTbl.RightBrake = 0
							selfTbl.LeftBrake = 0
						else
							if selfTbl.MoveLeft == 0 then selfTbl.LeftBrake = 0 end
							if selfTbl.MoveRight == 0 then selfTbl.RightBrake = 0 end
						end

						local GearBoost = 0
						selfTbl.CurTopSpeed = 0
						selfTbl.LastTopSpeed = 0
						selfTbl.MaxSpeedDif = 0
						local G1Speed = selfTbl.TopSpeed * 0.15
						local G2Speed = selfTbl.TopSpeed * 0.4
						local G3Speed = selfTbl.TopSpeed * 0.75
						local G4Speed = selfTbl.TopSpeed
						selfTbl.LeftForce = 0
						selfTbl.RightForce = 0
						selfTbl.RightBrake = 0
						selfTbl.LeftBrake = 0
						local throttle = 0
						if selfTbl.MoveForward > 0 and selfTbl.MoveReverse == 0 then
							throttle = selfTbl.MoveForward
						elseif selfTbl.MoveForward == 0 and selfTbl.MoveReverse > 0 then
							throttle = selfTbl.MoveReverse
						end

						if selfTbl.Speed > 0 and selfTbl.Speed < G1Speed and selfTbl.Gear ~= 1 then
							selfTbl.Gear = 1
						elseif selfTbl.Speed > G1Speed and selfTbl.Speed < G2Speed and selfTbl.Gear ~= 2 then
							selfTbl.Gear = 2
						elseif selfTbl.Speed > G2Speed and selfTbl.Speed < G3Speed and selfTbl.Gear ~= 3 then
							selfTbl.Gear = 3
						elseif selfTbl.Speed > G3Speed and selfTbl.Speed < G4Speed and selfTbl.Gear ~= 4 then
							selfTbl.Gear = 4
						end

						if selfTbl.Gear == 1 then
							GearBoost = 0.4
							selfTbl.CurTopSpeed = G1Speed
							selfTbl.LastTopSpeed = 0
							selfTbl.MaxSpeedDif = G1Speed
						elseif selfTbl.Gear == 2 then
							GearBoost = 0.15
							selfTbl.CurTopSpeed = G2Speed
							selfTbl.LastTopSpeed = G1Speed
							selfTbl.MaxSpeedDif = G2Speed - selfTbl.TopSpeed * 0.1
						elseif selfTbl.Gear == 3 then
							GearBoost = 0.1
							selfTbl.CurTopSpeed = G3Speed
							selfTbl.LastTopSpeed = G2Speed
							selfTbl.MaxSpeedDif = G3Speed - G2Speed
						else
							GearBoost = 0.05
							selfTbl.CurTopSpeed = G4Speed
							selfTbl.LastTopSpeed = G3Speed
							selfTbl.MaxSpeedDif = G4Speed - G3Speed
						end
						selfTbl.LeftForce = (selfTbl.PhysicalMass / 3000) * selfTbl.LBoost * selfTbl.Perc * (1 / selfTbl.GearRatio) * selfTbl.HPperTon * 50 * GearBoost * min(throttle, 1)
						selfTbl.RightForce = (selfTbl.PhysicalMass / 3000) * selfTbl.RBoost * selfTbl.Perc * (1 / selfTbl.GearRatio) * selfTbl.HPperTon * 50 * GearBoost * min(throttle, 1)

						if selfTbl.lastshift == nil then selfTbl.lastshift = 0 end
						if selfTbl.LastGear == nil then selfTbl.LastGear = 1 end
						if selfTbl.Gear > selfTbl.LastGear then
							if selfTbl.lastshift + 2.5 < curTime then
								for i = 1, #motors do
									if IsValid(motors[i]) then
										local snd = motors[i].Sound
										snd:ChangeVolume(0.125, 0)
										snd:ChangeVolume(0.25, 0.15)
										snd:ChangePitch(50, 0.1)
									end
								end

								selfTbl.lastshift = curTime
							end
						end

						selfTbl.LastGear = selfTbl.Gear
						if selfTbl.LastMoving == nil then selfTbl.LastMoving = 0 end
						if selfTbl.MoveForward > 0 or selfTbl.MoveReverse > 0 or selfTbl.MoveLeft > 0 or selfTbl.MoveRight > 0 then
							selfTbl.LastMoving = 1
							if (selfTbl.MoveForward > 0 or selfTbl.MoveReverse > 0) and not (selfTbl.MoveLeft > 0 or selfTbl.MoveRight > 0) then
								for i = 1, #motors do
									if IsValid(motors[i]) then motors[i].Sound:ChangePitch(Clamp(((selfTbl.Speed - selfTbl.LastTopSpeed) / selfTbl.MaxSpeedDif) * min(throttle, 1), 0, 1) * 60 + ((selfTbl.Speed / selfTbl.TopSpeed) * 90) + 50, 0.1) end
								end
							else
								if selfTbl.CarTurning == 0 then
									if selfTbl.MoveLeft > 0 or selfTbl.MoveRight > 0 and #motors > 0 then
										for i = 1, #motors do
											if IsValid(motors[i]) then motors[i].Sound:ChangePitch(max(min(max(selfTbl.MoveRight, selfTbl.MoveLeft) / 1 * 100, 100), 50), 0.5) end
										end
									end
								else
									--if selfTbl.lastdump == nil then selfTbl.lastdump = 0 end
									selfTbl.lastdump = selfTbl.lastdump or 0
									if selfTbl.LastMoving == 1 and selfTbl.lastdump + 2.5 < curTime and selfTbl.Gear > 2 and Clamp((selfTbl.Speed - selfTbl.LastTopSpeed) / selfTbl.MaxSpeedDif, 0, 1) > 0.5 then
										selfTbl.lastdump = curTime
									end

									for i = 1, #motors do
										if IsValid(motors[i]) then
											if selfTbl.CarTurning == 0 then
												motors[i].Sound:ChangePitch(50, 0.1)
											else
												motors[i].Sound:ChangePitch(Clamp(((selfTbl.Speed - selfTbl.LastTopSpeed) / selfTbl.MaxSpeedDif) * min(throttle, 1), 0, 1) * 60 + ((selfTbl.Speed / selfTbl.TopSpeed) * 90) + 50, 0.1)
											end
										end
									end

									selfTbl.LastMoving = 0
								end
							end
						else
							--if selfTbl.lastdump == nil then selfTbl.lastdump = 0 end
							selfTbl.lastdump = selfTbl.lastdump or 0 --TODO: This value should probably be defined in init. I'm not sure where it's used yet so I can't be sure there isn't some part relying on it starting as nil somewhere.
							if selfTbl.LastMoving == 1 and selfTbl.lastdump + 2.5 < curTime and selfTbl.Gear > 2 and Clamp((selfTbl.Speed - selfTbl.LastTopSpeed) / selfTbl.MaxSpeedDif, 0, 1) > 0.5 then
								selfTbl.lastdump = curTime
							end

							for i = 1, #motors do
								if IsValid(motors[i]) then motors[i].Sound:ChangePitch(50, 0.1) end
							end

							selfTbl.LastMoving = 0
						end
					end

					if selfTbl.Speed > selfTbl.TopSpeed then
						selfTbl.LeftForce = 0
						selfTbl.RightForce = 0
					end

					if selfTbl.CarTurning == 0 then
						if selfTbl.MoveLeft > 0 or selfTbl.MoveRight > 0 then
							if abs(selfTbl.turnperc) < 1 then
								if selfTbl.MoveLeft > 0 then
									if selfTbl.turnperc < 0 then selfTbl.turnperc = 0 end
									selfTbl.turnperc = selfTbl.turnperc + 0.02 * TimeMult
								elseif selfTbl.MoveRight > 0 then
									if selfTbl.turnperc > 0 then selfTbl.turnperc = 0 end
									selfTbl.turnperc = selfTbl.turnperc - 0.02 * TimeMult
								end
							end

							if selfTbl.MoveReverse > 0 then
								if selfTbl.MoveLeft > 0 and selfTbl.MoveRight == 0 then
									selfTbl.MoveRight = selfTbl.MoveLeft
									selfTbl.MoveLeft = 0
								elseif selfTbl.MoveRight > 0 and selfTbl.MoveLeft == 0 then
									selfTbl.MoveLeft = selfTbl.MoveRight
									selfTbl.MoveRight = 0
								end

								selfTbl.Turn = -1
							else
								selfTbl.Turn = 1
							end
						else
							selfTbl.turnperc = 0
						end

						selfTbl.MoveRightOld = selfTbl.MoveRight
						selfTbl.MoveLeftOld = selfTbl.MoveLeft
						if selfTbl.Speed > 10 then
							if selfTbl.MoveLeft > 0 and selfTbl.MoveRight == 0 then
								if selfTbl.MoveReverse > 0 then
									if abs(selfTbl.RealYaw) < 1.5 then
										selfTbl.LeftBrake = 0
										selfTbl.RightBrake = 1
										selfTbl.LeftForce = selfTbl.LeftForce * 2
										selfTbl.RightForce = 0
									else
										selfTbl.LeftBrake = 1
										selfTbl.RightBrake = 0
										selfTbl.LeftForce = 0
										selfTbl.RightForce = selfTbl.RightForce * 2
									end
								else
									if abs(selfTbl.RealYaw) < 1.5 then
										selfTbl.LeftBrake = 1
										selfTbl.RightBrake = 0
										selfTbl.LeftForce = 0
										selfTbl.RightForce = selfTbl.RightForce * 2
									else
										selfTbl.LeftBrake = 0
										selfTbl.RightBrake = 1
										selfTbl.LeftForce = selfTbl.LeftForce * 2
										selfTbl.RightForce = 0
									end
								end
							elseif selfTbl.MoveRight > 0 and selfTbl.MoveLeft == 0 then
								if selfTbl.MoveReverse > 0 then
									if abs(selfTbl.RealYaw) < 1.5 then
										selfTbl.LeftBrake = 1
										selfTbl.RightBrake = 0
										selfTbl.LeftForce = 0
										selfTbl.RightForce = selfTbl.RightForce * 2
									else
										selfTbl.LeftBrake = 0
										selfTbl.RightBrake = 1
										selfTbl.LeftForce = selfTbl.LeftForce * 2
										selfTbl.RightForce = 0
									end
								else
									if abs(selfTbl.RealYaw) < 1.5 then
										selfTbl.LeftBrake = 0
										selfTbl.RightBrake = 1
										selfTbl.LeftForce = selfTbl.LeftForce * 2
										selfTbl.RightForce = 0
									else
										selfTbl.LeftBrake = 1
										selfTbl.RightBrake = 0
										selfTbl.LeftForce = 0
										selfTbl.RightForce = selfTbl.RightForce * 2
									end
								end
							end
						else
							local fuelMult = Clamp(selfTbl.DakFuel / selfTbl.DakFuelReq, 0, 1)
							local massMult = (selfTbl.PhysicalMass / 3000) * 0.5
							if selfTbl.MoveReverse > 0 then --This needs a refactor, almost everything inside these if statements is redundant.
								if selfTbl.MoveLeft > 0 and selfTbl.MoveRight == 0 then
									local HPVal = selfTbl.HPperTon^1.5 / 5
									selfTbl.LeftForce = fuelMult * massMult * selfTbl.Turn * 10 * Clamp((0.015 * (1 / selfTbl.GearRatio) * HPVal ) / (abs(selfTbl.LastYaw - selfTbl.base:GetAngles().yaw) / TimeMult) * 1.75, 0, 10 * abs(selfTbl.turnperc)) * 450 * (selfTbl.DakHealth / selfTbl.DakMaxHealth) * min(selfTbl.MoveLeft, 1)
									selfTbl.RightForce = fuelMult * -massMult * selfTbl.Turn * 10 * Clamp((0.015 * (1 / selfTbl.GearRatio) * HPVal ) / (abs(selfTbl.LastYaw - selfTbl.base:GetAngles().yaw) / TimeMult) * 1.75, 0, 10 * abs(selfTbl.turnperc)) * 450 * (selfTbl.DakHealth / selfTbl.DakMaxHealth) * min(selfTbl.MoveLeft, 1)
									--RIGHT FORWARD
									--LEFT BACKWARD
								elseif selfTbl.MoveRight > 0 and selfTbl.MoveLeft == 0 then
									local HPVal = selfTbl.HPperTon^1.5 / 5
									selfTbl.LeftForce = fuelMult * -massMult * selfTbl.Turn * 10 * Clamp((0.015 * (1 / selfTbl.GearRatio) * HPVal) / (abs(selfTbl.LastYaw - selfTbl.base:GetAngles().yaw) / TimeMult) * 1.75, 0, 10 * abs(selfTbl.turnperc)) * 450 * (selfTbl.DakHealth / selfTbl.DakMaxHealth) * min(selfTbl.MoveRight, 1)
									selfTbl.RightForce = fuelMult * massMult * selfTbl.Turn * 10 * Clamp((0.015 * (1 / selfTbl.GearRatio) * HPVal) / (abs(selfTbl.LastYaw - selfTbl.base:GetAngles().yaw) / TimeMult) * 1.75, 0, 10 * abs(selfTbl.turnperc)) * 450 * (selfTbl.DakHealth / selfTbl.DakMaxHealth) * min(selfTbl.MoveRight, 1)
									--RIGHT BACKWARD
									--LEFT FORWARD
								end
							else
								if selfTbl.MoveLeft > 0 and selfTbl.MoveRight == 0 then
									local HPVal = selfTbl.HPperTon^1.5 / 5
									selfTbl.LeftForce = fuelMult * -massMult * selfTbl.Turn * 10 * Clamp((0.015 * (1 / selfTbl.GearRatio) * HPVal) / (abs(selfTbl.LastYaw - selfTbl.base:GetAngles().yaw) / TimeMult) * 1.75, 0, 10 * abs(selfTbl.turnperc)) * 450 * (selfTbl.DakHealth / selfTbl.DakMaxHealth) * min(selfTbl.MoveLeft, 1)
									selfTbl.RightForce = fuelMult * massMult * selfTbl.Turn * 10 * Clamp((0.015 * (1 / selfTbl.GearRatio) * HPVal) / (abs(selfTbl.LastYaw - selfTbl.base:GetAngles().yaw) / TimeMult) * 1.75, 0, 10 * abs(selfTbl.turnperc)) * 450 * (selfTbl.DakHealth / selfTbl.DakMaxHealth) * min(selfTbl.MoveLeft, 1)
									--RIGHT BACKWARD
									--LEFT FORWARD
								elseif selfTbl.MoveRight > 0 and selfTbl.MoveLeft == 0 then
									local HPVal = selfTbl.HPperTon^1.5 / 5
									selfTbl.LeftForce = fuelMult * massMult * selfTbl.Turn * 10 * Clamp((0.015 * (1 / selfTbl.GearRatio) * HPVal) / (abs(selfTbl.LastYaw - selfTbl.base:GetAngles().yaw) / TimeMult) * 1.75, 0, 10 * abs(selfTbl.turnperc)) * 450 * (selfTbl.DakHealth / selfTbl.DakMaxHealth) * min(selfTbl.MoveRight, 1)
									selfTbl.RightForce = fuelMult * -massMult * selfTbl.Turn * 10 * Clamp((0.015 * (1 / selfTbl.GearRatio) * HPVal) / (abs(selfTbl.LastYaw - selfTbl.base:GetAngles().yaw) / TimeMult) * 1.75, 0, 10 * abs(selfTbl.turnperc)) * 450 * (selfTbl.DakHealth / selfTbl.DakMaxHealth) * min(selfTbl.MoveRight, 1)
									--RIGHT FORWARD
									--LEFT BACKWARD
								end
							end
						end
					else
						if selfTbl.MoveLeft > 0 and selfTbl.MoveRight == 0 then
							if selfTbl.WheelYaw > -Clamp(selfTbl:GetRoadWTurnAngle(), 0, 45) then selfTbl.WheelYaw = selfTbl.WheelYaw - 1 * TimeMult end
						elseif selfTbl.MoveRight > 0 and selfTbl.MoveLeft == 0 then
							if selfTbl.WheelYaw < Clamp(selfTbl:GetRoadWTurnAngle(), 0, 45) then selfTbl.WheelYaw = selfTbl.WheelYaw + 1 * TimeMult end
						elseif selfTbl.MoveRight == 0 and selfTbl.MoveLeft == 0 then
							if selfTbl.WheelYaw > 0 then
								selfTbl.WheelYaw = selfTbl.WheelYaw - 1 * TimeMult
							elseif selfTbl.WheelYaw < 0 then
								selfTbl.WheelYaw = selfTbl.WheelYaw + 1 * TimeMult
							end
						end

						self:SetNWFloat("WheelYaw", selfTbl.WheelYaw)
					end

					if selfTbl.MoveForward <= 0 and selfTbl.MoveReverse <= 0 and selfTbl.MoveLeft <= 0 and selfTbl.MoveRight <= 0 then
						selfTbl.RightBrake = 0
						selfTbl.LeftBrake = 0
						for i = 1, #motors do
							if IsValid(motors[i]) then motors[i].Sound:ChangePitch(50, 0.5) end
						end
					end
				end
			else
				selfTbl.LeftForce = 0
				selfTbl.RightForce = 0
				selfTbl.RightBrake = 1
				selfTbl.LeftBrake = 1
				if selfTbl.RPM > 0 then selfTbl.RPM = selfTbl.RPM - 10 end
				--STANDARD BRAKING, NO FORCE APPLIED
				for i = 1, #motors do
					if IsValid(motors[i]) then
						local snd = motors[i].Sound
						snd:ChangeVolume(0, 2)
						snd:ChangePitch(0, 2)
					end
				end
			end

			local phy = selfTbl.phy
			local centreMass = phy:LocalToWorld(phy:GetMassCenter())
			local gravity = physenv.GetGravity()
			local GravxTicks = gravity * (1 / 66)
			local Pos
			local ForcePos
			local selfpos = selfTbl.base:GetPos()
			local trace = {}
			local traceMins = Vector(-10, -10, -0)
			local traceMaxs = Vector(10, 10, 0)
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
			local ForwardEnt = selfTbl.ForwardEnt
			local WheelsPerSide = selfTbl.WheelsPerSide --min(selfTbl.WheelsPerSide,5)
			local TrackLength = selfTbl.TrackLength
			local ForwardOffset = selfTbl.ForwardOffset
			local RideHeight = selfTbl.RideHeight
			local FrontWheelRaise = selfTbl.FrontWheelRaise
			local RearWheelRaise = selfTbl.RearWheelRaise
			local forward = ForwardEnt:GetForward()
			local up = selfTbl.ForwardEnt:GetUp()
			local right = ForwardEnt:GetRight()
			local CurTraceHitPos
			local hydrabias = Clamp(selfTbl.Inputs.SuspensionBias.Value, -1, 1)
			if selfTbl.lasthydrabias == nil then selfTbl.lasthydrabias = hydrabias end

			local biasMult = (selfTbl.Inputs.NoBiasSpeedLimit.Value == 0 and 0.25) or 5
			hydrabias = Clamp(hydrabias, selfTbl.lasthydrabias - (biasMult / RideHeight), selfTbl.lasthydrabias + (biasMult / RideHeight))

			self:SetNWFloat("Hydra", hydrabias)
			selfTbl.lasthydrabias = hydrabias
			local hydrabiasside = Clamp(selfTbl.Inputs.SuspensionBiasSide.Value, -1, 1)
			if selfTbl.lasthydrabiasside == nil then selfTbl.lasthydrabiasside = hydrabiasside end

			local sideBiasMult = (selfTbl.Inputs.NoSideBiasSpeedLimit.Value == 0 and 0.25) or 5
			hydrabiasside = Clamp(hydrabiasside, selfTbl.lasthydrabiasside - (sideBiasMult / RideHeight), selfTbl.lasthydrabiasside + (sideBiasMult / RideHeight))

			self:SetNWFloat("HydraSide", hydrabiasside)
			selfTbl.lasthydrabiasside = hydrabiasside
			local SuspensionBias = selfTbl.SuspensionBias
			--TODO: We could avoid creating a vector here for a slight performance boost.
			local wheelweightforce = vector_up * (selfTbl.AddonMass / (WheelsPerSide * 2)) * -9.8 * (selfTbl.RealInt / TimeMult) * (selfTbl.PhysicalMass / selfTbl.TotalMass)
			if selfTbl.LastWheelsPerSide ~= WheelsPerSide then
				for i = 1, WheelsPerSide do
					selfTbl.RightChanges[i] = 0
					selfTbl.LeftChanges[i] = 0

					selfTbl.RightInAir[i] = false
					selfTbl.LeftInAir[i] = false

					selfTbl.RightLastAbsorbForce[i] = 0
					selfTbl.LeftLastAbsorbForce[i] = 0

					selfTbl.RightPosChanges[i] = selfpos
					selfTbl.LeftPosChanges[i] = selfpos
					selfTbl.RightRidePosChanges[i] = 0
					selfTbl.LeftRidePosChanges[i] = 0
					selfTbl.RightLastHeights[i] = 0
					selfTbl.LeftLastHeights[i] = 0
					selfTbl.RightInts[i] = 0
					selfTbl.LeftInts[i] = 0
				end
			end

			if selfTbl.RightGroundedLast == nil then selfTbl.RightGroundedLast = WheelsPerSide end
			if selfTbl.LeftGroundedLast == nil then selfTbl.LeftGroundedLast = WheelsPerSide end
			local CurRideHeight = 0
			local RearTurners = selfTbl:GetRearTurningWheels()
			local FrontTurners = selfTbl:GetForwardTurningWheels()
			if selfTbl.DakDead or selfTbl.CrewAlive == 0 then
				selfTbl.RightForce = 0
				selfTbl.LeftForce = 0
				if selfTbl.DakHealth < 0 then selfTbl.DakHealth = 0 end
			end

			local obbMaxs = selfTbl.base:OBBMaxs()
			local basesize = {obbMaxs.x, obbMaxs.y, obbMaxs.z}
			sort(basesize, function(a, b) return a > b end)

			local brakestiffness = selfTbl:GetBrakeStiffness()
			if selfTbl.Brakes > 0 then brakestiffness = 1 end
			local halfwheels = WheelsPerSide * 0.5
			local basefriction = selfTbl:GetDakFriction() * (selfTbl.PhysicalMass * -GravxTicks).z * 0.9 / (WheelsPerSide * 2)
			if selfTbl.CarTurning == 1 then basefriction = selfTbl:GetDakFriction() * (selfTbl.PhysicalMass * -GravxTicks).z * 0.9 / (WheelsPerSide * 2) end
			local multval = 1
			local localfriction
			local worldfriction
			local rotatedforward
			local ForwardEntPos = ForwardEnt:GetPos()
			local ForwardEntAng = ForwardEnt:GetAngles()
			local wheelBraking = Vector(0,2,0) --Set inside wheel loops, recycled because creating vector objects is expensive (for some reason)
			--local WheelYaw = selfTbl.WheelYaw
			local wheelAngleYaw = Angle(0,selfTbl.WheelYaw,0)
			local ShockForce = selfTbl.PhysicalMass * 5
			local InAir = true
			local isWheeled = selfTbl:GetVehicleMode() == "wheeled"
			--Right side
			local RightChanges = selfTbl.RightChanges
			local RightPosChanges = selfTbl.RightPosChanges

			--There are often traces that don't hit anything, which interferes with how we deal with slopes.
			--In these cases we set them to an average of resistanceAngles from last tick as an approximation.
			local avgResistAng = math.max(selfTbl.lastResistAng or 0, -ForwardEntAng[1])
			--local avgResistAng = selfTbl.lastResistAng
			local resistCount = 0
			local resistSum = 0

			local vector110 = Vector(1,1,0) --Optimization

			for i = 1, WheelsPerSide do
				RideHeight = selfTbl.RideHeight
				if i > halfwheels then
					RideHeight = RideHeight - (hydrabias * (math.floor(halfwheels) - (WheelsPerSide - i)) / math.floor(halfwheels) * RideHeight)
				else
					RideHeight = RideHeight + (hydrabias * (math.floor(halfwheels) - (i - 1)) / math.floor(halfwheels) * RideHeight)
				end

				RideHeight = RideHeight + hydrabiasside * RideHeight
				local trackVec = (forward * (((i - 1) * TrackLength / (WheelsPerSide - 1)) - (TrackLength * 0.5) + ForwardOffset))
				ForcePos = selfpos + trackVec
				Pos = selfpos + trackVec
				ForcePos:Add(right * (basesize[2] * 0.95))
				Pos:Add(right * selfTbl.SideDist)

				if isWheeled then
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

				local strtP = vector_up * (-CurRideHeight + 100)
				local endP = vector_up * -CurRideHeight
				strtP:Add(Pos)
				endP:Add(Pos)
				trace = {
					start = strtP,
					endpos = endP,
					mins = traceMins,
					maxs = traceMaxs,
					mask = MASK_SOLID_BRUSHONLY
				}

				CurTrace = tracehull(trace)
				if not CurTrace.StartSolid then
					local Ang = CurTrace.HitNormal:AngleEx(forward)

					local ResistAng = (Ang[1] + 90) * math.cos(math.rad(Ang[3]))
					ResistAng = (selfTbl.MoveReverse > 0 and ResistAng * -1) or ResistAng

					ResistAng = (CurTrace.Hit and ResistAng) or avgResistAng or 0
					resistCount = (CurTrace.Hit and resistCount + 1) or resistCount
					resistSum = (CurTrace.Hit and resistSum + ResistAng) or resistSum

					local wheelTerrainMult = Clamp(1 - math.sin(math.rad(ResistAng)), 0, 1)

					local wheelTerrainBraking = 0
					if wheelTerrainMult < 1 then
						wheelTerrainBraking = (1 - wheelTerrainMult) * 0.125
						if selfTbl.Brakes <= 0 then
							local fw = (selfTbl.MoveReverse <= 0 and -forward) or forward
							selfTbl.phy:ApplyForceCenter( (selfTbl.RealInt * fw * selfTbl.PhysicalMass * abs(gravity.z) * math.sin(math.rad(ResistAng))) / (WheelsPerSide * 2 * 10) )
						end
					end
					wheelBraking[1] = max(selfTbl.RightBrake * brakestiffness, wheelTerrainBraking) * 2

					CurTraceHitPos = CurTrace.HitPos
					CurTraceDist = max(CurTrace.StartPos:Distance(CurTraceHitPos), 80)
					lastchange = (selfTbl.RightInAir[i] and 0) or wheelTerrainMult * (CurTraceDist - RightChanges[i]) / selfTbl.RealInt
					RightChanges[i] = CurTraceDist
					selfTbl.RightInAir[i] = false

					lastvel = (CurTraceHitPos - RightPosChanges[i])
					lastvel:Div(TimeMult)

					rotatedforward = forward * 1 --Copy the existing forward instead of indexing the entity.
					if i <= RearTurners and i <= halfwheels then --Wheeled vehicles
						localfriction, _ = WorldToLocal(ForwardEntPos + lastvel, angle_zero, ForwardEntPos, ForwardEntAng + wheelAngleYaw)
						localfriction:Mul(wheelBraking)
						worldfriction, _ = LocalToWorld(localfriction, angle_zero, ForwardEntPos, ForwardEntAng + wheelAngleYaw)
						rotatedforward:Rotate(-wheelAngleYaw)
					elseif WheelsPerSide - (i - 1) <= FrontTurners and i >= halfwheels then
						localfriction, _ = WorldToLocal(ForwardEntPos + lastvel, angle_zero, ForwardEntPos, ForwardEntAng - wheelAngleYaw)
						localfriction:Mul(wheelBraking)
						worldfriction, _ = LocalToWorld(localfriction, angle_zero, ForwardEntPos, ForwardEntAng - wheelAngleYaw)
						rotatedforward:Rotate(-wheelAngleYaw)
					else --Tracked vehicles
						localfriction = ForwardEnt:WorldToLocal(ForwardEntPos + lastvel)
						localfriction:Mul(wheelBraking)
						worldfriction = ForwardEnt:LocalToWorld(localfriction)
					end

					lastvel = worldfriction - ForwardEntPos
					RightPosChanges[i] = CurTraceHitPos
					RidePos = Clamp(CurTraceDist - 100, -10, 10)
					if RidePos < -0.1 then
						AbsorbForce = selfTbl.SuspensionDamping * (5 / WheelsPerSide)
						if abs(hydrabias) > 0 then AbsorbForce = 1 end
						FrictionForce = basefriction
					else
						AbsorbForce = 0.0
						FrictionForce = 0
					end

					multval = 1
					if i <= halfwheels then
						multval = multval + SuspensionBias
					elseif i > halfwheels then
						multval = multval - SuspensionBias
					end

					local CurHeight = RideHeight + CurTraceDist - 100
					local Force, LastInt = PID(RideHeight, CurHeight, selfTbl.RightLastHeights[i], selfTbl.RightInts[i], selfTbl)
					selfTbl.RightLastHeights[i] = CurHeight
					selfTbl.RightInts[i] = LastInt
					if CurHeight >= RideHeight then
						Force = 0
					else
						InAir = false
					end

					--SuspensionForce = wheelweightforce + vector_up * ((selfTbl.PhysicalMass * 1.2) * (min(Force, 10) / WheelsPerSide) * multval)
					SuspensionForce = wheelweightforce + up * ((selfTbl.PhysicalMass * 1.2) * (min(Force, 10) / WheelsPerSide) * multval)
					SuspensionForce[1] = 0
					SuspensionForce[2] = 0

					if not CurTrace.Hit then
						lastchange = 0
						selfTbl.RightInAir[i] = true
						AbsorbForceFinal = 0
						selfTbl.RightLastAbsorbForce[i] = 0
					else
						AbsorbForceFinal = -(Clamp(selfTbl.PhysicalMass * lastchange / (WheelsPerSide * 2), -ShockForce, ShockForce) * AbsorbForce) * selfTbl.SuspensionForceMult / TimeMult
						AbsorbForceFinal = (AbsorbForceFinal + selfTbl.RightLastAbsorbForce[i]) / 2 --Smooth out changes to prevent extreme spikes.
						selfTbl.RightLastAbsorbForce[i] = AbsorbForceFinal
					end

					lastvelnorm = lastvel:GetNormalized()
					--TODO: We could avoid creating a new vector here for a slight performance boost.
					FrictionForceFinal = -Vector(Clamp(lastvel.x, -abs(lastvelnorm.x), abs(lastvelnorm.x)), Clamp(lastvel.y, -abs(lastvelnorm.y), abs(lastvelnorm.y)), 0) * FrictionForce

					selfTbl.RightRidePosChanges[i] = RidePos
					--TODO: This equation could be split up to reduce the number of vectors created
					--My first attempt at that actually ran slower than this. Not sure why.

					AbsorbForceFinal = max(0, AbsorbForceFinal * 2)
					local AbsorbForceFinalVec = up * AbsorbForceFinal
					AbsorbForceFinalVec[1] = 0
					AbsorbForceFinalVec[2] = 0
					selfTbl.phy:ApplyImpulseOffsetF_Optimized(TimeMult * ((rotatedforward * vector110) * (4 * (wheelTerrainMult * selfTbl.RightForce) / WheelsPerSide) + SuspensionForce + FrictionForceFinal + AbsorbForceFinalVec), ForcePos - centreMass)
				end
			end

			--Left side
			local LeftChanges = selfTbl.LeftChanges
			local LeftPosChanges = selfTbl.LeftPosChanges

			for i = 1, WheelsPerSide do
				RideHeight = selfTbl.RideHeight
				if i > halfwheels then
					RideHeight = RideHeight - (hydrabias * (math.floor(halfwheels) - (WheelsPerSide - i)) / math.floor(halfwheels) * RideHeight)
				else
					RideHeight = RideHeight + (hydrabias * (math.floor(halfwheels) - (i - 1)) / math.floor(halfwheels) * RideHeight)
				end

				RideHeight = RideHeight - hydrabiasside * RideHeight

				local trackVec = (forward * (((i - 1) * TrackLength / (WheelsPerSide - 1)) - (TrackLength * 0.5) + ForwardOffset))
				ForcePos = selfpos + trackVec
				Pos = selfpos + trackVec
				ForcePos:Add(-right * (basesize[2] * 0.95))
				Pos:Add(-right * selfTbl.SideDist)

				if isWheeled then
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

				local strtP = vector_up * (-CurRideHeight + 100)
				local endP = vector_up * -CurRideHeight
				strtP:Add(Pos)
				endP:Add(Pos)
				trace = {
					start = strtP,
					endpos = endP,
					mins = traceMins,
					maxs = traceMaxs,
					mask = MASK_SOLID_BRUSHONLY
				}

				CurTrace = tracehull(trace)
				if not CurTrace.StartSolid then
					local Ang = CurTrace.HitNormal:AngleEx(forward)

					local ResistAng = (Ang[1] + 90) * math.cos(math.rad(Ang[3]))
					ResistAng = (selfTbl.MoveReverse > 0 and ResistAng * -1) or ResistAng

					ResistAng = (CurTrace.Hit and ResistAng) or avgResistAng or 0
					resistCount = (CurTrace.Hit and resistCount + 1) or resistCount
					resistSum = (CurTrace.Hit and resistSum + ResistAng) or resistSum

					local wheelTerrainMult = Clamp(1 - math.sin(math.rad(ResistAng)), 0, 1)

					local wheelTerrainBraking = 0
					if wheelTerrainMult < 1 then
						wheelTerrainBraking = (1 - wheelTerrainMult) * 0.125
						if selfTbl.Brakes <= 0 then
							local fw = (selfTbl.MoveReverse <= 0 and -forward) or forward
							selfTbl.phy:ApplyForceCenter( (selfTbl.RealInt * fw * selfTbl.PhysicalMass * abs(gravity.z) * math.sin(math.rad(ResistAng))) / (WheelsPerSide * 2 * 10) )
						end
					end
					wheelBraking[1] = max(selfTbl.LeftBrake * brakestiffness, wheelTerrainBraking) * 2

					CurTraceHitPos = CurTrace.HitPos
					CurTraceDist = max(CurTrace.StartPos:Distance(CurTraceHitPos), 80)

					lastchange = (selfTbl.LeftInAir[i] and 0) or wheelTerrainMult * (CurTraceDist - LeftChanges[i]) / selfTbl.RealInt
					LeftChanges[i] = CurTraceDist
					selfTbl.LeftInAir[i] = false

					lastvel = (CurTraceHitPos - LeftPosChanges[i])
					lastvel:Div(TimeMult)

					rotatedforward = forward * 1 --Copy the existing forward instead of indexing the entity
					--TODO: Check if we actually need to use WorldToLocal/LocalToWorld or if we can get the same result more cheaply
					if i <= RearTurners and i <= halfwheels then --wheeled vehicles
						localfriction, _ = WorldToLocal(ForwardEntPos + lastvel, angle_zero, ForwardEntPos, ForwardEntAng + wheelAngleYaw)
						localfriction:Mul(wheelBraking)
						worldfriction, _ = LocalToWorld(localfriction, angle_zero, ForwardEntPos, ForwardEntAng + wheelAngleYaw)
						rotatedforward:Rotate(-wheelAngleYaw)
					elseif WheelsPerSide - (i - 1) <= FrontTurners and i >= halfwheels then
						localfriction, _ = WorldToLocal(ForwardEntPos + lastvel, angle_zero, ForwardEntPos, ForwardEntAng - wheelAngleYaw)
						localfriction:Mul(wheelBraking)
						worldfriction, _ = LocalToWorld(localfriction, angle_zero, ForwardEntPos, ForwardEntAng - wheelAngleYaw)
						rotatedforward:Rotate(-wheelAngleYaw)
					else --tracked vehicles
						localfriction = ForwardEnt:WorldToLocal(ForwardEntPos + lastvel)
						localfriction:Mul(wheelBraking)
						worldfriction = ForwardEnt:LocalToWorld(localfriction)
					end

					lastvel = worldfriction - ForwardEntPos
					LeftPosChanges[i] = CurTraceHitPos
					RidePos = Clamp(CurTraceDist - 100, -10, 10)
					if RidePos < -0.1 then
						AbsorbForce = selfTbl.SuspensionDamping * (5 / WheelsPerSide)
						if abs(hydrabias) > 0 then AbsorbForce = 1 end
						FrictionForce = basefriction
					else
						AbsorbForce = 0.0
						FrictionForce = 0
					end

					multval = 1
					if i <= halfwheels then
						multval = multval + SuspensionBias
					elseif i > halfwheels then
						multval = multval - SuspensionBias
					end

					local CurHeight = RideHeight + CurTraceDist - 100
					local Force, LastInt = PID(RideHeight, CurHeight, selfTbl.LeftLastHeights[i], selfTbl.LeftInts[i], selfTbl)
					selfTbl.LeftLastHeights[i] = CurHeight
					selfTbl.LeftInts[i] = LastInt
					if CurHeight >= RideHeight then
						Force = 0
					else
						InAir = false
					end

					--SuspensionForce = wheelweightforce + vector_up * ((selfTbl.PhysicalMass * 1.2) * (min(Force, 10) / WheelsPerSide) * multval)
					SuspensionForce = wheelweightforce + up * ((selfTbl.PhysicalMass * 1.2) * (min(Force, 10) / WheelsPerSide) * multval)
					SuspensionForce[1] = 0
					SuspensionForce[2] = 0

					if not CurTrace.Hit then
						lastchange = 0
						selfTbl.LeftInAir[i] = true
						AbsorbForceFinal = 0
						selfTbl.LeftLastAbsorbForce[i] = 0
					else
						AbsorbForceFinal = -(Clamp(selfTbl.PhysicalMass * lastchange / (WheelsPerSide * 2), -ShockForce, ShockForce) * AbsorbForce) * selfTbl.SuspensionForceMult / TimeMult
						AbsorbForceFinal = (AbsorbForceFinal + selfTbl.LeftLastAbsorbForce[i]) / 2
						selfTbl.LeftLastAbsorbForce[i] = AbsorbForceFinal
					end

					lastvelnorm = lastvel:GetNormalized()
					--TODO: We could avoid creating a new vector here for a slight performance boost.
					FrictionForceFinal = -Vector(Clamp(lastvel.x, -abs(lastvelnorm.x), abs(lastvelnorm.x)), Clamp(lastvel.y, -abs(lastvelnorm.y), abs(lastvelnorm.y)), 0) * FrictionForce

					selfTbl.LeftRidePosChanges[i] = RidePos
					--TODO: This equation could be split up to reduce the number of vectors created

					AbsorbForceFinal = max(0, AbsorbForceFinal * 2)
					local AbsorbForceFinalVec = up * AbsorbForceFinal
					AbsorbForceFinalVec[1] = 0
					AbsorbForceFinalVec[2] = 0
					selfTbl.phy:ApplyImpulseOffsetF_Optimized(TimeMult * ((rotatedforward * vector110) * (4 * (wheelTerrainMult * selfTbl.LeftForce) / WheelsPerSide) + SuspensionForce + FrictionForceFinal + AbsorbForceFinalVec), ForcePos - centreMass)
				end
			end


			selfTbl.lastResistAng = resistSum / resistCount
			selfTbl.LastWheelsPerSide = WheelsPerSide
			--mid air stabilization to lower flip rates when going over stuff
			if InAir then
				if selfTbl.LastRoll == nil then selfTbl.LastRoll = ForwardEntAng.roll end
				if selfTbl.LastRollInt == nil then selfTbl.LastRollInt = 0 end

				local rollforce, rollint = AngPID(0, ForwardEntAng.roll, selfTbl.LastRoll, selfTbl.LastRollInt, selfTbl)
				rollforce = Clamp(rollforce, -25, 25)

				selfTbl.phy:ApplyImpulseOffsetF(up * -(rollforce * selfTbl.PhysicalMass * 0.01 * TimeMult), selfpos + right * 100)
				selfTbl.phy:ApplyImpulseOffsetF(up * (rollforce * selfTbl.PhysicalMass * 0.01 * TimeMult), selfpos + right * -100)
				selfTbl.LastRoll = ForwardEntAng.roll
				selfTbl.LastRollInt = rollint

				if selfTbl.LastPitch == nil then selfTbl.LastPitch = ForwardEntAng.pitch end
				if selfTbl.LastPitchInt == nil then selfTbl.LastPitchInt = 0 end
				local pitchforce, pitchint = AngPID(0, ForwardEntAng.pitch, selfTbl.LastPitch, selfTbl.LastPitchInt, selfTbl)
				pitchforce = Clamp(pitchforce, -25, 25)
				selfTbl.phy:ApplyImpulseOffsetF(up * -(pitchforce * selfTbl.PhysicalMass * 0.01 * TimeMult), selfpos + forward * 100)
				selfTbl.phy:ApplyImpulseOffsetF(up * (pitchforce * selfTbl.PhysicalMass * 0.01 * TimeMult), selfpos + forward * -100)
				selfTbl.LastPitch = ForwardEntAng.pitch
				selfTbl.LastPitchInt = pitchint
			end

			selfTbl.phy:ApplyForceCenter(selfTbl.RealInt * selfTbl.PhysicalMass * gravity)

			local vel = selfTbl.phy:GetVelocity()

			selfTbl.Speed = vel:Length() * (0.277778 * 0.254)
			selfTbl.LastSpeed = selfTbl.LastSpeed or selfTbl.Speed

			local accel = selfTbl.Speed - selfTbl.LastSpeed
			selfTbl.phy:ApplyImpulseOffsetFTorqueOnly(selfTbl.phy:GetMass() * vel:GetNormalized() * -accel * Clamp(selfTbl:GetDakInertia(), 0, 10), selfpos + up * 100)

			selfTbl.LastSpeed = selfTbl.Speed
		end

		local isOnFire = self:IsOnFire()
		if selfTbl.DakBurnStacks > 40 then
			selfTbl.DakBurnStacks = 40
		elseif selfTbl.DakBurnStacks > 0 and not isOnFire then
			selfTbl.DakBurnStacks = selfTbl.DakBurnStacks - 0.1
		end

		if isOnFire and selfTbl.DakDead ~= true then
			local Dmg = selfTbl.DakMaxHealth * 0.025 * engine.TickInterval()
			selfTbl.DakHealth = selfTbl.DakHealth - Dmg
			self:DTOnTakeDamage(Dmg)
		end

		if selfTbl.SpeedTable == nil then --Why is this defined here and not in init?
			selfTbl.SpeedTable = {}
		end

		if selfTbl.LastAccel == nil then selfTbl.LastAccel = 0 end
		selfTbl.SpeedTable[#selfTbl.SpeedTable + 1] = (selfTbl.LastYaw - selfTbl.base:GetAngles().yaw) / TimeMult
		if #selfTbl.SpeedTable > 2 then table.remove(selfTbl.SpeedTable, 1) end
		local totalspeed = 0
		for i = 1, #selfTbl.SpeedTable do
			totalspeed = totalspeed + selfTbl.SpeedTable[i]
		end

		selfTbl.RealYaw = totalspeed / #selfTbl.SpeedTable
		selfTbl.LastYaw = selfParent:GetParent():GetAngles().yaw
	end

	selfTbl.LastThink = curTime
	self:NextThink(curTime)
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