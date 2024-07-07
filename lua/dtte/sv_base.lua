local DTTE = DTTE
local math = math
local bmax = 16384
local bmin = -bmax
hook.Add("InitPostEntity", "DakTekTankEditionRunOnLoadHook", function()
	local Settings = physenv.GetPerformanceSettings() -- copy table from physenfv
	Settings.MaxVelocity = 1000000 -- change max velocity
	physenv.SetPerformanceSettings(Settings) -- push max velocity back into engine.
	print("DakTekTankEditionLoaded")
end)

function DTTE.CheckSpherical(ent)
	local PhysObj = ent:GetPhysicsObject()
	if not PhysObj:GetMesh() then
		if ent.SentSphereMessage == nil and IsValid(ent.DakOwner) then
			ent.DakOwner:ChatPrint(ent.DakName .. " is made spherical and will be removed if unfrozen.")
			ent.SentSphereMessage = true
		end

		if PhysObj:IsMotionEnabled() then ent:Remove() end
	else
		ent.SentSphereMessage = nil
	end
end

-- New check for if in map bounds since modifying original vector is a big nono
local function InMapCheck(vec)
	if vec.x > bmin and vec.x < bmax and vec.y > bmin and vec.y < bmax and vec.z > bmin and vec.z < bmax then -- Shells above z max still cause errors so they won't be included for artillery purposes at this time
		return true
	else
		return false
	end
end

DTTE.ShellList = {} -- Create Entity list for storing things people spawn
-- Setup global daktek function for setting up affected entities.
function DTTE.SetupNewEnt(ent)
	if not IsValid(ent) then return end
	local entClass = ent:GetClass()
	if entClass == "dak_bot" then -- Exceptions for bots
		--ent.DakHealth = ent:GetPhysicsObject():GetMass()/20
		ent.DakBurnStacks = 0
		ent.DakHealth = 10
		ent.DakName = "Armor"
		ent.DakMaxHealth = 10
		--ent.DakMaxHealth = ent:GetPhysicsObject():GetMass()/20
		ent.DakPooled = 0
		ent.DakArmor = 10
		return
	end

	if string.Explode("_", entClass, false)[1] == "dak" then -- Make sure it's not daktek stuff
		return
	end

	-- setup values
	if ent.IsDakTekFutureTech ~= nil then
		ent.DakArmor = 1000
		return
	end

	-- ent.DakArmor = (ent:GetPhysicsObject():GetMass()*0.125)
	ent.DakBurnStacks = 0
	ent.DakName = "Armor"
	if ent.EntityMods and ent.EntityMods.IsERA == 1 then
		ent.DakMaxHealth = 5
		ent.DakPooled = 1
	else
		if ent:GetClass() == "prop_ragdoll" then
			ent.DakHealth = 100000000000000000000
		else
			if IsValid(ent:GetPhysicsObject()) then
				ent.DakHealth = ent:GetPhysicsObject():GetMass() / 20
			else
				ent.DakHealth = 100000000000000000000
			end
		end

		if IsValid(ent:GetPhysicsObject()) then
			ent.DakMaxHealth = ent:GetPhysicsObject():GetMass() / 20
		else
			ent.DakMaxHealth = 100000000000000000000
		end

		ent.DakPooled = 0
	end

	--1 mm of armor on a meter*meter plate would be 8kg
	--1 kg gives 0.125 armor
	if ent:IsSolid() then
		if IsValid(ent:GetPhysicsObject()) then
			local SA = ent:GetPhysicsObject():GetSurfaceArea()
			if SA == nil then
				--Volume = (4/3)*math.pi*math.pow( ent:OBBMaxs().x, 3 )
				ent.DakArmor = ent:OBBMaxs().x / 2
				ent.DakIsTread = 1
			else
				ent.DakArmor = 7.8125 * (ent:GetPhysicsObject():GetMass() / 4.6311781) * (288 / SA) - ent.DakBurnStacks * 0.25
			end
		end
	else
		ent.DakArmor = 0
	end
end

-- Set up duplicator functions for the given entity class
function DTTE.RegisterEntClass(entClass)
	duplicator.RegisterEntityClass(entClass, function(ply, data)
		return duplicator.GenericDuplicatorFunction(ply, data)
	end, "Data")
end

hook.Add("Think", "DakTankShellTableFunction", function()
	local ShellList = DTTE.ShellList
	local RemoveList = {}
	for i, shell in ipairs(ShellList) do
		local DakTankBulletThinkDelay = (shell.IsGuided and 0.03) or 0.1
		shell.ShellThinkTime = shell.ShellThinkTime or 0

		if CurTime() - DakTankBulletThinkDelay >= shell.ShellThinkTime then
			shell.ShellThinkTime = CurTime()
			if shell.LifeTime > 25 then
				shell.RemoveNow = 1
			else
				local trace = {}
				if shell.IsGuided then
					local indicatortrace = {}
					if not shell.Indicator or shell.Indicator == nil or shell.Indicator == NULL then
						indicatortrace.start = shell.DakVelocity:GetNormalized() * -10000
						indicatortrace.endpos = shell.DakVelocity:GetNormalized() * 10000
					else
						if shell.Indicator:IsPlayer() then
							indicatortrace.start = shell.Indicator:GetShootPos()
							indicatortrace.endpos = shell.Indicator:GetShootPos() + shell.Indicator:GetAimVector() * 1000000
						else
							indicatortrace.start = shell.Indicator:GetPos()
							indicatortrace.endpos = shell.Indicator:GetPos() + shell.Indicator:GetForward() * 1000000
						end
					end

					indicatortrace.filter = shell.Filter
					local indicator = util.TraceLine(indicatortrace)
					if not shell.SimPos then shell.SimPos = shell.Pos end
					local _, LocalAng = WorldToLocal(indicator.HitPos, (indicator.HitPos - shell.SimPos):GetNormalized():Angle(), shell.SimPos, shell.DakVelocity:GetNormalized():Angle())
					local pitch = 0
					local yaw = 0
					local roll = 0
					if shell.LifeTime > DakTankBulletThinkDelay * 2 then
						local clamp = 100 * DakTankBulletThinkDelay
						pitch = math.Clamp(LocalAng.pitch, -clamp, clamp)
						yaw = math.Clamp(LocalAng.yaw, -clamp, clamp)
						if math.abs(LocalAng.yaw) > 90 then yaw = -math.Clamp(LocalAng.yaw, -clamp, clamp) end
						roll = math.Clamp(LocalAng.roll, -clamp, clamp)
					end

					if shell.Propellant ~= nil then
						shell.DakVelocity = (shell.DakVelocity:GetNormalized():Angle() + Angle(pitch, yaw, roll)):Forward() * shell.Propellant * math.Clamp((6300 * shell.LifeTime) - (7875 / 20 * shell.LifeTime), 4725, 12600)
					else
						shell.DakVelocity = (shell.DakVelocity:GetNormalized():Angle() + Angle(pitch, yaw, roll)):Forward() * math.Clamp((6300 * shell.LifeTime) - (7875 / 20 * shell.LifeTime), 4725, 12600)
					end

					if shell.LifeTime == 0 then
						trace.start = shell.SimPos
						shell.SimPos = shell.SimPos + (shell.DakVelocity * DakTankBulletThinkDelay)
					else
						shell.SimPos = shell.SimPos + (shell.DakVelocity * DakTankBulletThinkDelay)
						trace.start = shell.SimPos + (shell.DakVelocity * -DakTankBulletThinkDelay)
					end

					trace.endpos = shell.SimPos + (shell.DakVelocity * DakTankBulletThinkDelay)
				else
					local shType = shell.DakShellType
					local dDiv = ((shType == "HVAP" or shType == "APFSDS") and 1000) or 2000
					local dMult = ((shType == "APFSDS") and 0.085) or 0.0245
					local velFactor = (shell.DakVelocity:Distance(vector_origin) * 0.0254) ^ 2
					local DragForce = dMult * velFactor * (math.pi * ((shell.DakCaliber / dDiv) ^ 2))

					if not (shType == "HEAT" or shType == "HEATFS" or shType == "ATGM" or shType == "HESH") then
						local PenLoss = shell.DakBasePenetration * ((((DragForce / (shell.DakMass / 2)) * DakTankBulletThinkDelay) * 39.37) / shell.DakBaseVelocity)
						shell.DakPenetration = shell.DakPenetration - PenLoss
					end

					local massMult = ((shType == "HEAT" or shType == "HVAP" or shType == "ATGM" or shType == "HEATFS" or shType == "APFSDS") and 8) or 1
					local velNormal = shell.DakVelocity:GetNormalized()

					shell.DakVelocity:Add(-((DragForce / (shell.DakMass * massMult / 2)) * DakTankBulletThinkDelay) * 39.37 * velNormal)

					if shell.IsMissile then shell.DakVelocity = velNormal * (shell.DakBaseVelocity * (shell.LifeTime + 1)) end
					if shell.JustBounced == 1 then
						trace.start = shell.Pos
						trace.endpos = shell.Pos + (shell.DakVelocity * (shell.LifeTime + 0.1)) - (-physenv.GetGravity() * (shell.LifeTime ^ 2) / 2)
						shell.JustBounced = 0
					else
						if shell.LifeTime == 0 then
							trace.start = shell.Pos
						else
							if shell.Pos == nil or shell.DakVelocity == nil or physenv.GetGravity() == nil then
								shell.RemoveNow = 1
							else
								trace.start = shell.Pos + (shell.DakVelocity * (shell.LifeTime - DakTankBulletThinkDelay)) - (-physenv.GetGravity() * ((shell.LifeTime - DakTankBulletThinkDelay) ^ 2) / 2)
							end
						end

						if shell.RemoveNow ~= 1 then
							if shell.FuzeDelay ~= nil and shell.LifeTime >= shell.FuzeDelay - DakTankBulletThinkDelay and shell.FuzeDelay > 0 then
								trace.endpos = shell.Pos + (shell.DakVelocity * (shell.LifeTime + (shell.FuzeDelay - shell.LifeTime))) - (-physenv.GetGravity() * ((shell.LifeTime + (shell.FuzeDelay - shell.LifeTime)) ^ 2) / 2)
							else
								trace.endpos = shell.Pos + (shell.DakVelocity * (shell.LifeTime + DakTankBulletThinkDelay)) - (-physenv.GetGravity() * ((shell.LifeTime + DakTankBulletThinkDelay) ^ 2) / 2)
							end
						end
					end
				end

				if shell.RemoveNow ~= 1 then
					trace.filter = shell.Filter
					trace.mins = Vector(-shell.DakCaliber * 0.02, -shell.DakCaliber * 0.02, -shell.DakCaliber * 0.02)
					trace.maxs = Vector(shell.DakCaliber * 0.02, shell.DakCaliber * 0.02, shell.DakCaliber * 0.02)
					if not (InMapCheck(trace.start) and InMapCheck(trace.endpos)) then shell.RemoveNow = 1 end
					local ShellTrace = util.TraceHull(trace)
					if ShellTrace ~= nil then
						if shell.Crushed ~= 1 then
							local effectdata = EffectData()
							effectdata:SetStart(ShellTrace.StartPos)
							effectdata:SetOrigin(ShellTrace.HitPos)
							effectdata:SetScale(shell.DakCaliber * 0.0393701)
							effectdata:SetMagnitude(DakTankBulletThinkDelay * 100)
							util.Effect(shell.DakTrail, effectdata, true, true)
						end

						if ShellTrace.Hit then
							if not (ShellTrace.HitSky and (ShellTrace.HitNormal == Vector(0, 0, -1))) then
								--check if aps is near if shellvel is low enough and shell type is right
								--also check if thing is large enough caliber
								--if caliber too big to kill then halve pen?
								--determine if shell is moving towards or away from APS
								shell.ShotDown = shell.ShotDown or 0
								local ExpPos = ShellTrace.StartPos
								local shType = shell.DakShellType
								if shell.DakVelocity:Length() < 27559.1 and (shType == "HEAT" or shType == "HEATFS" or shType == "ATGM") and shell.ShotDown ~= 1  then --max vel of shell it can catch 700m/s based off en.wikipedia.org/wiki/Drozd
									local APS = ents.FindByClass("dak_tankcore")
									for i, apsCore in ipairs(APS) do
										if apsCore.APSEnable then 

											local pos = apsCore:GetPos()
											local dist = ShellTrace.HitPos:Distance(pos) -- If < 275, it's in range ~7m based off drozd again
											local startPosCheck = ShellTrace.StartPos:Distance(pos) > dist -- It's coming at us

											if shell and shell.DakCaliber >= apsCore.APSMinCaliber and dist < 275 and startPosCheck then
												local _, a = WorldToLocal(pos, (ShellTrace.StartPos - pos):GetNormalized():Angle(), pos, apsCore.Forward:Angle())
												local frontalhit = false
												local sidehit = false
												local rearhit = false
												if math.abs(a.yaw) >= 0 and math.abs(a.yaw) <= 45 then frontalhit = true end
												if math.abs(a.yaw) >= 45 and math.abs(a.yaw) <= 135 then sidehit = true end
												if math.abs(a.yaw) >= 135 and math.abs(a.yaw) <= 180 then rearhit = true end
												local CanShoot = false
												if apsCore.APSFrontalArc == true and frontalhit == true then CanShoot = true end
												if apsCore.APSSideArc == true and sidehit == true then CanShoot = true end
												if apsCore.APSRearArc == true and rearhit == true then CanShoot = true end
												if CanShoot and apsCore.APSShots > 0 then -- May need to convert CanShoot to angle later for readouts, but this value is nice
													-- Play some effect or sound or something maybe
													apsCore.APSShots = apsCore.APSShots - 1
													shell.ShotDown = 1
													ExpPos = pos + (ShellTrace.StartPos - pos):GetNormalized() * 275
													break 
												end
											end
										end
									end
								end

								if shell.ShotDown == 1 then
									if shType == "HEAT" or shType == "HEATFS" or shType == "ATGM" then
										shell.RemoveNow = 1
										shell.ExplodeNow = true
										DTShellAirBurst(ExpPos, shell, trace.endpos - trace.start)
									end
								else
									local cal = shell.DakCaliber
									util.ScreenShake(ShellTrace.HitPos, cal, 2.5, 0.2, cal * 50)
									DTShellHit(ShellTrace.StartPos, ShellTrace.HitPos, ShellTrace.Entity, shell, ShellTrace.HitNormal)
								end
							end
						elseif shell.FuzeDelay ~= nil and shell.LifeTime >= shell.FuzeDelay - DakTankBulletThinkDelay and shell.FuzeDelay > 0 and (shell.DakShellType == "HE" or shell.DakShellType == "SM") then
							shell.ExplodeNow = true
							DTShellAirBurst(trace.endpos, shell, trace.endpos - trace.start)
						end
					end
				end
			end

			if shell.RemoveNow == 1 or (shell.DieTime and shell.DieTime < CurTime()) then
				table.insert(RemoveList, i)
			end
			shell.LifeTime = shell.LifeTime + DakTankBulletThinkDelay
		end
	end

	if #RemoveList > 0 then
		for i = #RemoveList, 1, -1 do
			table.remove(ShellList, RemoveList[i])
		end
	end
end)