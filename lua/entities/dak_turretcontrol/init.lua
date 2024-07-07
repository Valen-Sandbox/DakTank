AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local math = math
local IsValid = IsValid
local pairs = pairs
local ipairs = ipairs

ENT.DakMaxHealth = 10
ENT.DakHealth = 10
ENT.DakArmor = 0
ENT.DakName = "Turret Control"
ENT.DakContraption = {}
ENT.DakTurretMotor = nil
ENT.SentError = 0
ENT.SentError2 = 0
ENT.DakCore = NULL
ENT.DakTurretMotors = {}
ENT.DakCrew = NULL

DTTE.RegisterEntClass("dak_turretcontrol")

local function GetTurretParents(ent, Results)
	Results = Results or {}
	local Parent = ent:GetParent()
	Results[ent] = ent
	if IsValid(Parent) then GetTurretParents(Parent, Results) end
	return Results
end

local function GetTurretPhysCons(ent, Results)
	Results = Results or {}
	if not IsValid(ent) then return end
	if Results[ent] then return end
	Results[ent] = ent
	local Constraints = constraint.GetTable(ent)
	for _, v in ipairs(Constraints) do
		if (v.Type ~= "NoCollide") and (v.Type ~= "Axis") and (v.Type ~= "Ballsocket") and (v.Type ~= "AdvBallsocket") and (v.Type ~= "Rope") and (v.Type ~= "Wire") then
			for _, Ent in pairs(v.Entity) do
				GetTurretPhysCons(Ent.Entity, Results)
			end
		end
	end
	return Results
end

local function normalizedVector(vector)
	local len = (vector[1] * vector[1] + vector[2] * vector[2] + vector[3] * vector[3]) ^ 0.5
	if len > 0.0000001 then
		return Vector(vector[1] / len, vector[2] / len, vector[3] / len)
	else
		return Vector(0, 0, 0)
	end
end

local function angClamp(ang, clamp1, clamp2)
	return Angle(math.Clamp(ang.pitch, clamp1.pitch, clamp2.pitch), math.Clamp(ang.yaw, clamp1.yaw, clamp2.yaw), math.Clamp(ang.roll, clamp1.roll, clamp2.roll))
end

local function angNumClamp(ang, clamp1, clamp2)
	return Angle(math.Clamp(ang.pitch, clamp1, clamp2), math.Clamp(ang.yaw, clamp1, clamp2), math.Clamp(ang.roll, clamp1, clamp2))
end

function ENT:Initialize()
	self:SetModel("models/beer/wiremod/gate_e2_mini.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self.DakHealth = self.DakMaxHealth
	self.DakArmor = 10
	self.timer = CurTime()
	self.CoreRemoteMult = 1
	self.Inputs = Wire_CreateInputs(self, {"Active", "Gun [ENTITY]", "Turret [ENTITY]", "CamTrace [RANGER]", "Lock", "CamTrace2 [RANGER]", "Active2", "AirBurst"})
	self.ErrorTime = CurTime()
	self.ErrorTime2 = CurTime()
	self.SlowThinkTime = CurTime()
	self.SentError = 0
	self.SentError2 = 0
	self.LastHullAngles = self:GetAngles()
	self.DakBurnStacks = 0
	self.DakTurretMotors = {}
	self.Locked = 0
	self.Off = true
	self.OffTicks = 0
	self.Accel = 0
	self.ShortStop = self:GetShortStopStabilizer()
	self.FixedGun = self:GetFixedGun()
	self.Stabilizer = self:GetStabilizer()
	self.FCS = self:GetFCS()
end

local function GetParents(ent, Results)
	Results = Results or {}
	local Parent = ent:GetParent()
	Results[ent] = ent
	if IsValid(Parent) then GetParents(Parent, Results) end
	return Results
end

function ENT:Think()
	local self = self
	local selfTbl = self:GetTable()

	local RotMult = 0.1
	selfTbl.WiredGun = selfTbl.Inputs.Gun.Value
	selfTbl.WiredTurret = selfTbl.Inputs.Turret.Value
	if #selfTbl.DakContraption > 0 then
		local GunEnt = selfTbl.Inputs.Gun.Value
		if IsValid(GunEnt) and selfTbl.Controller.Off ~= true then
			GunEnt.TurretController = self
			if IsValid(GunEnt:GetParent()) and IsValid(GunEnt:GetParent():GetParent()) then selfTbl.DakGun = GunEnt:GetParent():GetParent() end
			local DakGun = selfTbl.DakGun
			if IsValid(DakGun) then
				local Elevation = math.Clamp(self:GetElevation(), 0, 90)
				local Depression = math.Clamp(self:GetDepression(), 0, 90)
				local YawMin = math.Clamp(self:GetYawMin(), 0, 360)
				local YawMax = math.Clamp(self:GetYawMax(), 0, 360)
				local RotationMult = math.Clamp(self:GetRotationSpeedMultiplier(), 0, 1)
				if selfTbl.FCS ~= true then
					if self:GetTable().Inputs.CamTrace.Path and self:GetTable().Inputs.CamTrace.Path[1].Entity:GetClass() ~= "gmod_wire_cameracontroller" then selfTbl.FCS = true end
					if self:GetTable().Inputs.CamTrace2.Path and self:GetTable().Inputs.CamTrace2.Path[1].Entity:GetClass() ~= "gmod_wire_cameracontroller" then selfTbl.FCS = true end
					if selfTbl.FCS == true then selfTbl.DakOwner:ChatPrint("Custom FCS E2 detected, gun handling multiplier affected.") end
					selfTbl.CustomFCS = true
				end

				selfTbl.DakActive = selfTbl.Inputs.Active.Value
				selfTbl.DakActive2 = selfTbl.Inputs.Active2.Value
				local DakTurret = selfTbl.Inputs.Turret.Value
				selfTbl.DakTurret = DakTurret
				local hash = {}
				local res = {}
				for _, v in ipairs(selfTbl.DakTurretMotors) do
					if not hash[v] then
						res[#res + 1] = v
						hash[v] = true
					end
				end

				selfTbl.DakTurretMotors = res
				if #selfTbl.DakTurretMotors > 0 then
					for i = 1, #selfTbl.DakTurretMotors do
						if IsValid(selfTbl.DakTurretMotors[i]) then RotMult = RotMult + selfTbl.DakTurretMotors[i].DakRotMult end
					end
				end

				if selfTbl.DakParented ~= 1 then
					local gunParent = GunEnt:GetParent()
					if IsValid(gunParent) then
						gunParent = gunParent:GetParent()
						if IsValid(gunParent) then DakGun = gunParent end
						selfTbl.Turret = {}
						if IsValid(DakTurret) then
							table.Add(selfTbl.Turret, GetTurretParents(GunEnt))
							for _, v in pairs(GetTurretParents(GunEnt)) do
								table.Add(selfTbl.Turret, GetTurretPhysCons(v))
							end

							if IsValid(DakTurret) then
								table.Add(selfTbl.Turret, GetTurretParents(DakTurret))
								for _, v in pairs(GetTurretParents(DakTurret)) do
									table.Add(selfTbl.Turret, GetTurretPhysCons(v))
								end
							end

							for i = 1, #selfTbl.Turret do
								table.Add(selfTbl.Turret, selfTbl.Turret[i]:GetChildren())
								table.Add(selfTbl.Turret, selfTbl.Turret[i]:GetParent())
							end

							local Children = {}
							for i2 = 1, #selfTbl.Turret do
								if table.Count(selfTbl.Turret[i2]:GetChildren()) > 0 then table.Add(Children, selfTbl.Turret[i2]:GetChildren()) end
							end

							table.Add(selfTbl.Turret, Children)
						else
							table.Add(selfTbl.Turret, DakGun:GetChildren())
							for _, v in pairs(DakGun:GetChildren()) do
								table.Add(selfTbl.Turret, v:GetChildren())
							end
						end

						local hash = {}
						local res = {}
						for _, v in ipairs(selfTbl.Turret) do
							if not hash[v] then
								res[#res + 1] = v
								hash[v] = true
							end
						end

						selfTbl.Turret = res
						selfTbl.TurretBase = DakTurret
						DakGun.DakMovement = true
						selfTbl.TurretBase.DakMovement = true
						local Mass = 0
						selfTbl.Guns = {}
						for i = 1, #res do
							if res[i]:IsSolid() then
								if res[i]:GetClass() == "dak_tegun" or res[i]:GetClass() == "dak_teautogun" or res[i]:GetClass() == "dak_temachinegun" then
									Mass = Mass + res[i].DakMass
								else
									Mass = Mass + res[i]:GetPhysicsObject():GetMass()
								end
							end

							if res[i]:IsValid() then
								if res[i]:GetClass() == "dak_tegun" or res[i]:GetClass() == "dak_teautogun" or res[i]:GetClass() == "dak_temachinegun" then
									res[i].TurretController = self
									res[i].TurretBase = DakTurret
									selfTbl.Guns[#selfTbl.Guns + 1] = res[i]
								end
							end
						end

						selfTbl.GunMass = Mass
						selfTbl.DakParented = 1
						if IsValid(DakTurret) then selfTbl.YawDiff = DakTurret:GetAngles().yaw - DakGun:GetAngles().yaw end
					else
						selfTbl.DakParented = 0
					end
				end

				if IsValid(DakGun) then
					local BasePlate = selfTbl.Controller:GetParent():GetParent()
					if selfTbl.LastVel == nil then selfTbl.LastVel = 0 end
					if selfTbl.DakParented == 0 then
						if selfTbl.SentError == 0 then
							selfTbl.SentError = 1
							selfTbl.DakOwner:PrintMessage(HUD_PRINTTALK, "Turret Controller Error: Gun must be parented to an aimer prop.")
							selfTbl.ErrorTime = CurTime()
						elseif CurTime() >= selfTbl.ErrorTime + 10 then
							selfTbl.DakOwner:PrintMessage(HUD_PRINTTALK, "Turret Controller Error: Gun must be parented to an aimer prop.")
							selfTbl.ErrorTime = CurTime()
						end
					end

					local Class = GunEnt:GetClass()
					if Class ~= "dak_tegun" and Class ~= "dak_teautogun" and Class ~= "dak_temachinegun" then
						if selfTbl.SentError2 == 0 then
							selfTbl.SentError2 = 1
							selfTbl.DakOwner:PrintMessage(HUD_PRINTTALK, "Turret Controller Error: You must wire the gun input to the gun entity, not an aimer prop.")
							selfTbl.ErrorTime2 = CurTime()
						elseif CurTime() >= selfTbl.ErrorTime2 + 10 then
							selfTbl.DakOwner:PrintMessage(HUD_PRINTTALK, "Turret Controller Error: You must wire the gun input to the gun entity, not an aimer prop.")
							selfTbl.ErrorTime2 = CurTime()
						end
					end

					selfTbl.RotationSpeed = math.min(RotMult * (15000 / selfTbl.GunMass) * RotationMult, 5)
					local TimeScale = 66 / (1 / engine.TickInterval())
					if selfTbl.DakCrew == NULL then
						selfTbl.RotationSpeed = 0
						if selfTbl.GunnerErrorMessageSent1 == nil then
							selfTbl.DakOwner:ChatPrint(selfTbl.DakName .. " #" .. self:EntIndex() .. " gunner not detected, gun unable to move. Please link a crew member to the turret controller.")
							selfTbl.GunnerErrorMessageSent1 = true
						end
					else
						if selfTbl.DakCrew.DakEntity ~= self then
							selfTbl.RotationSpeed = 0
						else
							selfTbl.DakCrew.Job = 1
							if selfTbl.DakCrew.DakDead == true or selfTbl.DakCrew.Busy == true then selfTbl.RotationSpeed = 0 end
							if not (selfTbl.Controller.ColdWar == 1 or selfTbl.Controller.Modern == 1) then
								--check for both gun itself and pivot point
								if selfTbl.RemoteWeapon == true then
									selfTbl.RotationSpeed = 0
									if selfTbl.FloatGunErrorMessageSent == nil then
										selfTbl.DakOwner:ChatPrint(selfTbl.DakName .. " #" .. self:EntIndex() .. " Gun not within turret, remote weapon systems are cold war and modern only.")
										selfTbl.FloatGunErrorMessageSent = true
									end
								end

								if IsValid(selfTbl.TurretBase) and (math.Clamp(self:GetYawMin(), 0, 360) + math.Clamp(self:GetYawMax(), 0, 360) > 90) then
									if selfTbl.DakCrew:IsValid() then
										if selfTbl.DakCrew:GetParent():IsValid() then
											if selfTbl.DakCrew:GetParent():GetParent():IsValid() then
												if selfTbl.DakCrew:GetParent():GetParent() ~= selfTbl.TurretBase and selfTbl.DakCrew:GetParent():GetParent() ~= DakGun then
													selfTbl.RotationSpeed = 0
													if selfTbl.GunnerErrorMessageSent2 == nil then
														selfTbl.DakOwner:ChatPrint(selfTbl.DakName .. " #" .. self:EntIndex() .. " gunner not in turret, remote weapon systems are cold war and modern only.")
														selfTbl.GunnerErrorMessageSent2 = true
													end
												end
											end
										end
									end
								end

								if not IsValid(selfTbl.TurretBase) and (math.Clamp(self:GetYawMin(), 0, 360) + math.Clamp(self:GetYawMax(), 0, 360) > 90) then
									if selfTbl.DakCrew:IsValid() then
										if selfTbl.DakCrew:GetParent():IsValid() then
											if selfTbl.DakCrew:GetParent():GetParent():IsValid() then
												if selfTbl.DakCrew:GetParent():GetParent() == self:GetParent():GetParent() or selfTbl.DakCrew:GetParent():GetParent() == DakGun then
													selfTbl.RotationSpeed = 0
													if selfTbl.GunnerErrorMessageSent3 == nil then
														selfTbl.DakOwner:ChatPrint(selfTbl.DakName .. " #" .. self:EntIndex() .. " gunner not in hull, remote weapon systems are cold war and modern only.")
														selfTbl.GunnerErrorMessageSent3 = true
													end
												end
											end
										end
									end
								end
							else
								--check for both gun itself and pivot point
								if selfTbl.RemoteWeapon == true then
									selfTbl.RotationSpeed = selfTbl.RotationSpeed * selfTbl.CoreRemoteMult
									if selfTbl.nonWWIIRemoteGunErrorMessageSent == nil then
										selfTbl.DakOwner:ChatPrint(selfTbl.DakName .. " #" .. self:EntIndex() .. " remote weapon system detected, 50% cost increase added to gun handling multiplier for this turret.")
										selfTbl.nonWWIIRemoteGunErrorMessageSent = true
										selfTbl.RemoteWeapon = true
									end
								end

								if IsValid(selfTbl.TurretBase) and (math.Clamp(self:GetYawMin(), 0, 360) + math.Clamp(self:GetYawMax(), 0, 360) > 90) then
									if selfTbl.DakCrew:IsValid() then
										if selfTbl.DakCrew:GetParent():IsValid() then
											if selfTbl.DakCrew:GetParent():GetParent():IsValid() then
												if selfTbl.DakCrew:GetParent():GetParent() ~= selfTbl.TurretBase and selfTbl.DakCrew:GetParent():GetParent() ~= DakGun then
													selfTbl.RotationSpeed = selfTbl.RotationSpeed * selfTbl.CoreRemoteMult
													if selfTbl.nonWWIIRemoteGunErrorMessageSent == nil then
														selfTbl.DakOwner:ChatPrint(selfTbl.DakName .. " #" .. self:EntIndex() .. " remote weapon system detected, 50% cost increase added to gun handling multiplier for this turret.")
														selfTbl.nonWWIIRemoteGunErrorMessageSent = true
														selfTbl.RemoteWeapon = true
													end
												end
											end
										end
									end
								end

								if not IsValid(selfTbl.TurretBase) and (math.Clamp(self:GetYawMin(), 0, 360) + math.Clamp(self:GetYawMax(), 0, 360) > 90) then
									if selfTbl.DakCrew:IsValid() then
										if selfTbl.DakCrew:GetParent():IsValid() then
											if selfTbl.DakCrew:GetParent():GetParent():IsValid() then
												if selfTbl.DakCrew:GetParent():GetParent() == self:GetParent():GetParent() or selfTbl.DakCrew:GetParent():GetParent() == DakGun then
													selfTbl.RotationSpeed = selfTbl.RotationSpeed * selfTbl.CoreRemoteMult
													if selfTbl.nonWWIIRemoteGunErrorMessageSent == nil then
														selfTbl.DakOwner:ChatPrint(selfTbl.DakName .. " #" .. self:EntIndex() .. " remote weapon system detected, 50% cost increase added to gun handling multiplier for this turret.")
														selfTbl.nonWWIIRemoteGunErrorMessageSent = true
														selfTbl.RemoteWeapon = true
													end
												end
											end
										end
									end
								end
							end
						end
					end

					if selfTbl.DakActive > 0 then selfTbl.DakCamTrace = selfTbl.Inputs.CamTrace.Value end
					if selfTbl.DakActive2 > 0 then selfTbl.DakCamTrace = selfTbl.Inputs.CamTrace2.Value end
					if Class == "dak_tegun" or Class == "dak_teautogun" or Class == "dak_temachinegun" then
						if not selfTbl.Parented and selfTbl.FixedGun == false then
							timer.Simple(engine.TickInterval() * 1, function()
								constraint.RemoveAll(DakGun)
								if IsValid(DakTurret) then
									selfTbl.turretaimer = ents.Create("prop_physics")
									selfTbl.turretaimer:SetAngles(self:GetAngles())
									selfTbl.turretaimer:SetPos(DakTurret:GetPos())
									selfTbl.turretaimer:SetMoveType(MOVETYPE_NONE)
									selfTbl.turretaimer:PhysicsInit(SOLID_NONE)
									selfTbl.turretaimer:SetParent(self)
									selfTbl.turretaimer:SetModel("models/daktanks/smokelauncher100mm.mdl")
									selfTbl.turretaimer:DrawShadow(false)
									selfTbl.turretaimer:SetColor(Color(255, 255, 255, 0))
									selfTbl.turretaimer:SetRenderMode(RENDERMODE_TRANSCOLOR)
									selfTbl.turretaimer:Spawn()
									selfTbl.turretaimer:Activate()
									selfTbl.turretaimer:SetMoveType(MOVETYPE_NONE)
									selfTbl.turretaimer:PhysicsInit(SOLID_NONE)
									selfTbl.turretaimer.turretaimer = true
									DakTurret:SetParent()
									DakGun:SetParent()
									constraint.RemoveAll(DakTurret)
									constraint.AdvBallsocket(DakTurret, selfTbl.Controller:GetParent():GetParent(), 0, 0, Vector(0, 0, 0), Vector(0, 0, 0), 0, 0, -180, -180, -180, 180, 180, 180, 0, 0, 0, 1, 0)
									constraint.AdvBallsocket(DakGun, DakTurret, 0, 0, Vector(0, 0, 0), Vector(0, 0, 0), 0, 0, -180, -180, -180, 180, 180, 180, 0, 0, 0, 1, 0)
									constraint.AdvBallsocket(selfTbl.turretaimer, selfTbl.Controller:GetParent():GetParent(), 0, 0, Vector(0, 0, 0), Vector(0, 0, 0), 0, 0, -180, -180, -180, 180, 180, 180, 0, 0, 0, 1, 0)
									DakTurret:SetParent(selfTbl.turretaimer)
									DakGun:SetParent(selfTbl.turretaimer)
								else
									DakGun:SetParent()
									constraint.AdvBallsocket(DakGun, selfTbl.Controller:GetParent():GetParent(), 0, 0, Vector(0, 0, 0), Vector(0, 0, 0), 0, 0, -180, -180, -180, 180, 180, 180, 0, 0, 0, 1, 0)
									DakGun:SetParent(self:GetParent())
								end
							end)

							selfTbl.Parented = 1
						end

						if selfTbl.Parented == 1 then
							if selfTbl.DakActive > 0 or selfTbl.DakActive2 > 0 then
								if selfTbl.Inputs.Lock.Value > 0 then
									selfTbl.LastAngles = self:GetAngles()
									if selfTbl.LastPos == nil then selfTbl.LastPos = BasePlate:GetPos() end
									if IsValid(selfTbl.DakCore.Base) then if selfTbl.Locked == 0 then selfTbl.Locked = 1 end end
								else
									if selfTbl.Locked == 1 then selfTbl.Locked = 0 end
									if selfTbl.DakCamTrace then
										if selfTbl.FCS == true and not (selfTbl.CustomFCS == true) and not (GunEnt.DakShellAmmoType == "HEATFS" and GunEnt.DakShellPenetration == GunEnt.DakMaxHealth * 6.40) then --atgm has 6.40 maxhealth for pen and HEATFS ammo type
											local AirBurst = selfTbl.Inputs.AirBurst.Value
											local AddZ = 0
											if AirBurst ~= 0 then
												AddZ = self:GetAirburstHeight() * 39.3701
												for i = 1, #selfTbl.Guns do
													selfTbl.Guns[i].FuzeOverride = true
												end
											else
												for i = 1, #selfTbl.Guns do
													selfTbl.Guns[i].FuzeOverride = false
												end
											end

											local traceFCS = {}
											traceFCS.start = selfTbl.DakCamTrace.StartPos
											traceFCS.endpos = selfTbl.DakCamTrace.StartPos + selfTbl.DakCamTrace.Normal * 9999999999
											traceFCS.filter = selfTbl.DakContraption
											local PreCamTrace = util.TraceLine(traceFCS)
											if selfTbl.NoTarTicks == nil then selfTbl.NoTarTicks = 0 end
											local G = math.abs(physenv.GetGravity().z)
											local Caliber = GunEnt.DakMaxHealth
											local ShellType = GunEnt.DakShellAmmoType
											local V = GunEnt.DakShellVelocity * (GunEnt:GetPropellant() * 0.01)
											local ShellMass = GunEnt.DakShellMass
											local Drag = (((V * 0.0254) * (V * 0.0254)) * (math.pi * ((Caliber / 2000) * (Caliber / 2000)))) * 0.0245
											if ShellType == "HVAP" then Drag = (((V * 0.0254) * (V * 0.0254)) * (math.pi * (((Caliber * 0.5) / 1000) * ((Caliber * 0.5) / 1000)))) * 0.0245 end
											if ShellType == "APFSDS" then Drag = (((V * 0.0254) * (V * 0.0254)) * (math.pi * (((Caliber * 0.25) / 1000) * ((Caliber * 0.25) / 1000)))) * 0.085 end
											local VelLoss
											if ShellType == "HEAT" or ShellType == "HVAP" or ShellType == "ATGM" or ShellType == "HEATFS" or ShellType == "APFSDS" or ShellType == "APDS" then
												VelLoss = (Drag / (ShellMass * 8 / 2)) * 39.37
											else
												VelLoss = (Drag / (ShellMass / 2)) * 39.37
											end

											if PreCamTrace.Entity and not PreCamTrace.Entity:IsWorld() or selfTbl.Tar == nil then
												selfTbl.Tar = PreCamTrace.Entity
												selfTbl.CamTarPos = PreCamTrace.HitPos
											else
												selfTbl.NoTarTicks = selfTbl.NoTarTicks + 1
											end

											if selfTbl.NoTarTicks > 15 then
												selfTbl.Tar = PreCamTrace.Entity
												selfTbl.NoTarTicks = 0
											end

											local TarPos0
											local GunPos = GunEnt:GetPos()
											selfTbl.TarVel = Vector(0, 0, 0)
											if selfTbl.Tar and selfTbl.Tar:IsValid() then
												TarPos0 = selfTbl.Tar:GetPos() + (selfTbl.CamTarPos - selfTbl.Tar:GetPos()) + Vector(0, 0, AddZ)
												selfTbl.TarVel = selfTbl.Tar:GetVelocity()
											else
												TarPos0 = PreCamTrace.HitPos + Vector(0, 0, AddZ)
											end

											local basefound = false
											local base = selfTbl.Tar
											if IsValid(selfTbl.Tar) then
												while basefound == false do
													if IsValid(base:GetParent()) then
														base = base:GetParent()
													else
														basefound = true
													end
												end
											end

											if base ~= NULL and base:IsValid() then
												selfTbl.TarVel = base:GetVelocity()
											else
												selfTbl.TarVel = Vector(0, 0, 0)
											end

											local SelfVel = selfTbl.Controller:GetParent():GetParent():GetVelocity()
											local VelValue = V
											local VelLossFull = VelLoss
											local TravelTime = 0
											local Diff
											local X
											local Y
											local Disc
											local Ang
											local TarPos
											for i = 1, 2 do
												VelValue = V - VelLossFull
												TarPos = TarPos0 + ((selfTbl.TarVel - SelfVel) * (TravelTime + 0.1))
												Diff = TarPos - GunPos
												X = Vector(Diff.x, Diff.y, 0):Length()
												Y = Diff.z
												Disc = VelValue ^ 4 - G * (G * X * X + 2 * Y * VelValue * VelValue)
												Ang = math.atan(-(VelValue ^ 2 - math.sqrt(Disc)) / (G * X)) * 57.29577951
												TravelTime = X / (VelValue * math.cos(Ang * 0.017453293))
												VelLossFull = VelLoss * TravelTime
											end

											if AirBurst ~= 0 then
												for i = 1, #selfTbl.Guns do
													selfTbl.Guns[i].FuzeOverrideDelay = TravelTime
												end
											end

											--print(SelfVel)
											--print(TravelTime)
											if Ang ~= Ang then Ang = -45 end
											local yaw = Diff:Angle().yaw
											if yaw ~= yaw then yaw = (TarPos0 - GunPos):Angle().yaw end
											local traceFCS2 = {}
											traceFCS2.start = GunPos
											traceFCS2.endpos = GunPos + Angle(Ang, yaw, 0):Forward() * 100000000
											traceFCS2.filter = selfTbl.DakContraption
											selfTbl.CamTrace = util.TraceLine(traceFCS2)
										else
											local trace = {}
											trace.start = selfTbl.DakCamTrace.StartPos
											trace.endpos = selfTbl.DakCamTrace.StartPos + selfTbl.DakCamTrace.Normal * 9999999999
											trace.filter = selfTbl.DakContraption
											selfTbl.CamTrace = util.TraceLine(trace)
										end

										selfTbl.Shake = Angle(0, 0, 0)
										if selfTbl.Stabilizer == false then
											if selfTbl.LastPos == nil then selfTbl.LastPos = BasePlate:GetPos() end
											if selfTbl.LastAngles == nil then selfTbl.LastAngles = Angle(0, 0, 0) end
											local Speed = Vector(0, 0, 0):Distance(BasePlate:GetPos() - selfTbl.LastPos)
											if selfTbl.ShakeAmpX == nil then selfTbl.ShakeAmpX = 0 end
											selfTbl.ShakeAmpX = selfTbl.ShakeAmpX + math.random(-1, 1)
											if selfTbl.ShakeAmpX > 5 then selfTbl.ShakeAmpX = 5 end
											if selfTbl.ShakeAmpX < -5 then selfTbl.ShakeAmpX = -5 end
											if selfTbl.ShakeAmpX > 0 then selfTbl.ShakeAmpX = selfTbl.ShakeAmpX - 0.05 end
											if selfTbl.ShakeAmpX < 0 then selfTbl.ShakeAmpX = selfTbl.ShakeAmpX + 0.05 end
											if selfTbl.ShakeAmpY == nil then selfTbl.ShakeAmpY = 0 end
											selfTbl.ShakeAmpY = selfTbl.ShakeAmpY + math.random(-1, 1)
											if selfTbl.ShakeAmpY > 5 then selfTbl.ShakeAmpY = 5 end
											if selfTbl.ShakeAmpY < -5 then selfTbl.ShakeAmpY = -5 end
											if selfTbl.ShakeAmpY > 0 then selfTbl.ShakeAmpY = selfTbl.ShakeAmpY - 0.05 end
											if selfTbl.ShakeAmpY < 0 then selfTbl.ShakeAmpY = selfTbl.ShakeAmpY + 0.05 end
											local Shake
											if selfTbl.ShortStop == false then
												selfTbl.Accel = math.Clamp(selfTbl.Accel, -0.15, 0.15)
												Shake = (Angle(1 * selfTbl.ShakeAmpX, 0.1 * selfTbl.ShakeAmpY, 0) * (Speed * 0.025)) + Angle(-selfTbl.Accel * 25, 0, 0)
											else
												Shake = Angle(1 * selfTbl.ShakeAmpX, 0.1 * selfTbl.ShakeAmpY, 0) * (Speed * 0.0125)
											end

											selfTbl.Shake = Shake
										end

										selfTbl.LastAngles = self:GetAngles()
										--get angle that self has changed in last tick, infact this is done above in last angles
										local GunDir = normalizedVector(selfTbl.CamTrace.HitPos - selfTbl.CamTrace.StartPos + (selfTbl.CamTrace.StartPos - DakGun:GetPos()))
										if self:GetSetPitchOnLoading() and not (GunEnt.ShellLoaded == 1 or GunEnt.ShellLoaded2 == 1) then
											if IsValid(DakTurret) then
												GunDir = (selfTbl.turretaimer:GetAngles() + Angle(-self:GetLoadingAngle(), 0, 0)):Forward()
											else
												GunDir = (self:GetAngles() + Angle(-self:GetLoadingAngle(), 0, 0)):Forward()
											end
										end

										if self:GetQuadrantElevation() then
											local GunYaw = self:WorldToLocalAngles(DakGun:GetAngles()).yaw
											if GunYaw >= -45 and GunYaw <= 45 then
												--print("Forward")
												Elevation = math.Clamp(self:GetFrontElevation(), 0, 90)
												Depression = math.Clamp(self:GetFrontDepression(), 0, 90)
											elseif GunYaw < -45 and GunYaw > -135 then
												--print("Right")
												Elevation = math.Clamp(self:GetRightElevation(), 0, 90)
												Depression = math.Clamp(self:GetRightDepression(), 0, 90)
											elseif GunYaw > 45 and GunYaw < 135 then
												--print("Left")
												Elevation = math.Clamp(self:GetLeftElevation(), 0, 90)
												Depression = math.Clamp(self:GetLeftDepression(), 0, 90)
											else
												--print("Rear")
												Elevation = math.Clamp(self:GetRearElevation(), 0, 90)
												Depression = math.Clamp(self:GetRearDepression(), 0, 90)
											end
										end

										local Ang = angNumClamp(angClamp(self:WorldToLocalAngles(GunDir:Angle() + selfTbl.Shake), Angle(-Elevation, -YawMin, -1), Angle(Depression, YawMax, 1)) - self:WorldToLocalAngles(DakGun:GetAngles()), -selfTbl.RotationSpeed * TimeScale, selfTbl.RotationSpeed * TimeScale)
										if IsValid(DakTurret) then
											--turn both turret and gun
											local TurDir = normalizedVector(selfTbl.CamTrace.HitPos - selfTbl.CamTrace.StartPos + (selfTbl.CamTrace.StartPos - selfTbl.turretaimer:GetPos()))
											local TurClamp = self:LocalToWorldAngles(angClamp(self:WorldToLocalAngles(TurDir:Angle()), Angle(-Elevation, -YawMin, -1), Angle(Depression, YawMax, 1)))
											local TurAng = angNumClamp(selfTbl.turretaimer:WorldToLocalAngles(TurClamp), -selfTbl.RotationSpeed * TimeScale, selfTbl.RotationSpeed * TimeScale)
											if selfTbl.Off == true then
												selfTbl.OffTicks = selfTbl.OffTicks + 1
												if selfTbl.OffTicks > 70 then selfTbl.Off = false end
											else
												if selfTbl.Locked == 0 then
													selfTbl.turretaimer:SetAngles(self:LocalToWorldAngles(Angle(0, self:WorldToLocalAngles(selfTbl.turretaimer:GetAngles()).yaw, 0)) + Angle(0, TurAng.yaw, 0))
													local yawdiff = math.abs(selfTbl.turretaimer:WorldToLocalAngles(TurClamp).yaw)
													local pitch = Ang.pitch
													local Limit = 180
													local max = 0.5
													if selfTbl.Controller.Modern == 1 then
														Limit = 90
														max = 1
													elseif selfTbl.Controller.ColdWar == 1 then
														Limit = 45
														max = 0.5
													else
														Limit = 25
														max = 0.25
													end

													if yawdiff > Limit then
														pitch = 0
													else
														pitch = pitch * math.min((Limit - yawdiff) / Limit, max)
													end

													DakGun:SetAngles(selfTbl.turretaimer:LocalToWorldAngles(Angle(self:WorldToLocalAngles(DakGun:GetAngles()).pitch, 0, 0)) + Angle(pitch, 0, 0))
												end
											end
										else
											if selfTbl.Off == true then
												selfTbl.OffTicks = selfTbl.OffTicks + 1
												if selfTbl.OffTicks > 70 / (66 / (1 / engine.TickInterval())) then selfTbl.Off = false end
											else
												--turn gun
												DakGun:SetAngles(self:LocalToWorldAngles(Angle(self:WorldToLocalAngles(DakGun:GetAngles()).pitch, self:WorldToLocalAngles(DakGun:GetAngles()).yaw, 0)) + Angle(Ang.pitch, Ang.yaw, 0))
											end
										end
									end
								end
							else
								if selfTbl.Locked == 1 then selfTbl.Locked = 0 end
								--reposition to forward facing
								local GunDir = self:GetForward()
								local Ang = angNumClamp(angClamp(self:WorldToLocalAngles(GunDir:Angle() + Angle(-self:GetIdleElevation(), self:GetIdleYaw(), 0)), Angle(-Elevation, -YawMin, -1), Angle(Depression, YawMax, 1)) - self:WorldToLocalAngles(DakGun:GetAngles()), -selfTbl.RotationSpeed * TimeScale, selfTbl.RotationSpeed * TimeScale)
								if IsValid(DakTurret) and IsValid(selfTbl.turretaimer) then
									local TurDir = self:GetForward()
									local TurAng = angNumClamp(angClamp(self:WorldToLocalAngles(TurDir:Angle() + Angle(0, math.Clamp(self:GetIdleYaw(), -179.99, 179.99), 0)), Angle(-Elevation, -YawMin, -1), Angle(Depression, YawMax, 1)) - self:WorldToLocalAngles(selfTbl.turretaimer:GetAngles()), -selfTbl.RotationSpeed * TimeScale, selfTbl.RotationSpeed * TimeScale)
									selfTbl.turretaimer:SetAngles(self:LocalToWorldAngles(Angle(0, self:WorldToLocalAngles(selfTbl.turretaimer:GetAngles()).yaw, 0)) + Angle(0, TurAng.yaw, 0))
									DakGun:SetAngles(selfTbl.turretaimer:LocalToWorldAngles(Angle(self:WorldToLocalAngles(DakGun:GetAngles()).pitch, 0, 0)) + Angle(Ang.pitch, 0, 0))
								else
									DakGun:SetAngles(self:LocalToWorldAngles(Angle(self:WorldToLocalAngles(DakGun:GetAngles()).pitch, self:WorldToLocalAngles(DakGun:GetAngles()).yaw, 0)) + Angle(Ang.pitch, Ang.yaw, 0))
								end

								selfTbl.Off = true
								selfTbl.OffTicks = 0
								if selfTbl.LastPos == nil then selfTbl.LastPos = BasePlate:GetPos() end
								selfTbl.LastAngles = self:GetAngles()
							end
						end
					end

					if selfTbl.FixedGun == false then
						if selfTbl.SpeedTable == nil then selfTbl.SpeedTable = {} end
						if selfTbl.LastAccel == nil then selfTbl.LastAccel = 0 end
						selfTbl.SpeedTable[#selfTbl.SpeedTable + 1] = Vector(0, 0, 0):Distance(BasePlate:GetPos() - selfTbl.LastPos) - selfTbl.LastVel
						if #selfTbl.SpeedTable >= 5 then table.remove(selfTbl.SpeedTable, 1) end
						local totalspeed = 0
						for i = 1, #selfTbl.SpeedTable do
							totalspeed = totalspeed + selfTbl.SpeedTable[i]
						end

						selfTbl.Accel = totalspeed / #selfTbl.SpeedTable
						selfTbl.LastVel = Vector(0, 0, 0):Distance(BasePlate:GetPos() - selfTbl.LastPos)
						selfTbl.LastPos = BasePlate:GetPos()
					end
				end
			end
		end
	end

	self:NextThink(CurTime())
	return true
end

function ENT:PreEntityCopy()
	local info = {}
	-- local entids = {}
	info.TurretMotorIDs = {}
	if #self.DakTurretMotors > 0 then
		for i = 1, #self.DakTurretMotors do
			info.TurretMotorIDs[i] = self.DakTurretMotors[i]:EntIndex()
		end
	end

	info.CrewID = self.DakCrew:EntIndex()
	info.DakName = self.DakName
	info.DakHealth = self.DakHealth
	info.DakMaxHealth = self.DakMaxHealth
	info.DakMass = self.DakMass
	info.DakOwner = self.DakOwner
	duplicator.StoreEntityModifier(self, "DakTek", info)
	-- Wire dupe info
	self.BaseClass.PreEntityCopy(self)
end

function ENT:PostEntityPaste(Player, Ent, CreatedEntities)
	if Ent.EntityMods and Ent.EntityMods.DakTek then
		if Ent.EntityMods.DakTek.TurretMotorIDs then
			if #Ent.EntityMods.DakTek.TurretMotorIDs > 0 then
				for i = 1, #Ent.EntityMods.DakTek.TurretMotorIDs do
					self.DakTurretMotors[#self.DakTurretMotors + 1] = CreatedEntities[Ent.EntityMods.DakTek.TurretMotorIDs[i]]
				end
			end
		end

		local Crew = CreatedEntities[Ent.EntityMods.DakTek.CrewID]
		if Crew and IsValid(Crew) then self.DakCrew = Crew end
		self.DakArmor = 0
		self.DakName = Ent.EntityMods.DakTek.DakName
		self.DakMaxHealth = Ent.EntityMods.DakTek.DakMaxHealth
		if Ent.EntityMods.DakTek.DakMaxHealth == nil then self.DakMaxHealth = 10 end
		self.DakHealth = self.DakMaxHealth
		self.DakMass = Ent.EntityMods.DakTek.DakMass
		self.DakOwner = Player
		Ent.EntityMods.DakTek = nil
	end

	self.BaseClass.PostEntityPaste(self, Player, Ent, CreatedEntities)
end