local DTTE = DTTE

local math = math
local bmax = 16384
local bmin = -bmax

hook.Add( "InitPostEntity", "DakTekTankEditionRunOnLoadHook", function()
	local Settings = physenv.GetPerformanceSettings() -- copy table from physenfv
	Settings.MaxVelocity = 1000000 -- change max velocity
	physenv.SetPerformanceSettings(Settings) -- push max velocity back into engine.
	print("DakTekTankEditionLoaded")
end )

function DTTE.CheckSpherical(ent) --This function has a bit of a performance impact due to how often it's called. Not sure how to improve it though as most of that seems to come from getting the physics object.
	local PhysObj = ent:GetPhysicsObject()
	if not PhysObj:GetMesh() then
		if ent.SentSphereMessage == nil and IsValid(ent.DakOwner) then
			ent.DakOwner:ChatPrint(ent.DakName .. " is made spherical and will be removed if unfrozen.")
			ent.SentSphereMessage = true
		end
		if PhysObj:IsMotionEnabled() then
			ent:Remove()
		end
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

	if string.Explode("_", entClass, false)[1] == "dak" then return end -- Make sure it's not daktek stuff
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
				ent.DakArmor = 7.8125 * ( ent:GetPhysicsObject():GetMass() / 4.6311781 ) * ( 288 / SA ) - ent.DakBurnStacks * 0.25
			end
	 	end
	else
		ent.DakArmor = 0
	end
end

--example hook add
--hook.Add( "DakTankDamageCheck", "DakTekTankEditionDamageCheck", function (Damaged,Damager)
--end )

hook.Add( "Think", "DakTankShellTableFunction", function()
	local ShellList = DTTE.ShellList
	local RemoveList = {}
	for i = 1, #ShellList do
		local DakTankBulletThinkDelay = 0.1
		if ShellList[i].IsGuided then
			DakTankBulletThinkDelay = 0.03
		end
		if ShellList[i].ShellThinkTime == nil then
			ShellList[i].ShellThinkTime = 0
		end
		if CurTime() - DakTankBulletThinkDelay >= ShellList[i].ShellThinkTime then
			ShellList[i].ShellThinkTime = CurTime()
			--ShellList[i].Gravity = physenv.GetGravity()*ShellList[i].LifeTime
			if ShellList[i].LifeTime > 25 then
				ShellList[i].RemoveNow = 1
			else
				local trace = {}
				if ShellList[i].IsGuided then
					local indicatortrace = {}
					if not ShellList[i].Indicator or ShellList[i].Indicator == nil or ShellList[i].Indicator == NULL then
						indicatortrace.start = ShellList[i].DakVelocity:GetNormalized() * -10000
						indicatortrace.endpos = ShellList[i].DakVelocity:GetNormalized() * 10000
					else
						if ShellList[i].Indicator:IsPlayer() then
							indicatortrace.start = ShellList[i].Indicator:GetShootPos()
							indicatortrace.endpos = ShellList[i].Indicator:GetShootPos() + ShellList[i].Indicator:GetAimVector() * 1000000
						else
							indicatortrace.start = ShellList[i].Indicator:GetPos()
							indicatortrace.endpos = ShellList[i].Indicator:GetPos() + ShellList[i].Indicator:GetForward() * 1000000
						end
					end
					indicatortrace.filter = ShellList[i].Filter
					local indicator = util.TraceLine(indicatortrace)
					if not ShellList[i].SimPos then
						ShellList[i].SimPos = ShellList[i].Pos
					end

					-- local difference = ShellList[i].DakVelocity:GetNormalized() - (indicator.HitPos-ShellList[i].SimPos):GetNormalized()
					local _, LocalAng = WorldToLocal( indicator.HitPos, (indicator.HitPos-ShellList[i].SimPos):GetNormalized():Angle(), ShellList[i].SimPos, ShellList[i].DakVelocity:GetNormalized():Angle() )
					local pitch = 0
					local yaw = 0
					local roll = 0
					if ShellList[i].LifeTime > DakTankBulletThinkDelay * 2 then
						local clamp = 100 * DakTankBulletThinkDelay
						pitch = math.Clamp( LocalAng.pitch, -clamp, clamp )
						yaw = math.Clamp( LocalAng.yaw, -clamp, clamp )
						if math.abs( LocalAng.yaw ) > 90 then yaw = -math.Clamp( LocalAng.yaw, -clamp, clamp ) end
						roll = math.Clamp( LocalAng.roll, -clamp, clamp )
					end
					if ShellList[i].Propellant ~= nil then
						ShellList[i].DakVelocity = ( ShellList[i].DakVelocity:GetNormalized():Angle() + Angle( pitch, yaw, roll ) ):Forward() * ShellList[i].Propellant * math.Clamp( ( 6300 * ShellList[i].LifeTime ) - ( 7875 / 20 * ShellList[i].LifeTime ), 4725, 12600 )
					else
						ShellList[i].DakVelocity = ( ShellList[i].DakVelocity:GetNormalized():Angle() + Angle( pitch, yaw, roll ) ):Forward() * math.Clamp( ( 6300 * ShellList[i].LifeTime ) - ( 7875 / 20 * ShellList[i].LifeTime ), 4725, 12600 )
					end

					if ShellList[i].LifeTime == 0 then
						trace.start = ShellList[i].SimPos
						ShellList[i].SimPos = ShellList[i].SimPos + ( ShellList[i].DakVelocity * DakTankBulletThinkDelay )
					else
						ShellList[i].SimPos = ShellList[i].SimPos + ( ShellList[i].DakVelocity * DakTankBulletThinkDelay )
						trace.start = ShellList[i].SimPos + ( ShellList[i].DakVelocity * -DakTankBulletThinkDelay )
					end
					trace.endpos = ShellList[i].SimPos + ( ShellList[i].DakVelocity * DakTankBulletThinkDelay )
				else
					local DragForce = 0.0245 * ((ShellList[i].DakVelocity:Distance(Vector(0,0,0))*0.0254)*(ShellList[i].DakVelocity:Distance(Vector(0,0,0))*0.0254)) * (math.pi * ((ShellList[i].DakCaliber/2000)*(ShellList[i].DakCaliber/2000)))
					if ShellList[i].DakShellType == "HVAP" then
						DragForce = 0.0245 * ((ShellList[i].DakVelocity:Distance(Vector(0,0,0))*0.0254)*(ShellList[i].DakVelocity:Distance(Vector(0,0,0))*0.0254)) * (math.pi * ((ShellList[i].DakCaliber/1000)*(ShellList[i].DakCaliber/1000)))
					end
					if ShellList[i].DakShellType == "APFSDS" then
						DragForce = 0.085 * ((ShellList[i].DakVelocity:Distance(Vector(0,0,0))*0.0254)*(ShellList[i].DakVelocity:Distance(Vector(0,0,0))*0.0254)) * (math.pi * ((ShellList[i].DakCaliber/1000)*(ShellList[i].DakCaliber/1000)))
					end
					if not(ShellList[i].DakShellType == "HEAT" or ShellList[i].DakShellType == "HEATFS" or ShellList[i].DakShellType == "ATGM" or ShellList[i].DakShellType == "HESH") then
						local PenLoss = ShellList[i].DakBasePenetration*((((DragForce/(ShellList[i].DakMass/2))*DakTankBulletThinkDelay)*39.37)/ShellList[i].DakBaseVelocity)
						ShellList[i].DakPenetration = ShellList[i].DakPenetration - PenLoss
					end
					if ShellList[i].DakShellType == "HEAT" or ShellList[i].DakShellType == "HVAP" or ShellList[i].DakShellType == "ATGM" or ShellList[i].DakShellType == "HEATFS" or ShellList[i].DakShellType == "APFSDS" then
						ShellList[i].DakVelocity = ShellList[i].DakVelocity - (((DragForce/(ShellList[i].DakMass*8/2))*DakTankBulletThinkDelay)*39.37)*ShellList[i].DakVelocity:GetNormalized()
					else
						ShellList[i].DakVelocity = ShellList[i].DakVelocity - (((DragForce/(ShellList[i].DakMass/2))*DakTankBulletThinkDelay)*39.37)*ShellList[i].DakVelocity:GetNormalized()
					end
					if ShellList[i].IsMissile == true then
						ShellList[i].DakVelocity = ShellList[i].DakVelocity:GetNormalized() * (ShellList[i].DakBaseVelocity*(ShellList[i].LifeTime+1))
					end
					if ShellList[i].JustBounced == 1 then
						trace.start = ShellList[i].Pos
						trace.endpos = ShellList[i].Pos + (ShellList[i].DakVelocity * (ShellList[i].LifeTime+0.1)) - (-physenv.GetGravity()*(ShellList[i].LifeTime^2)/2)
						ShellList[i].JustBounced = 0
					else
						if ShellList[i].LifeTime == 0 then
							trace.start = ShellList[i].Pos
						else
							if ShellList[i].Pos == nil or ShellList[i].DakVelocity == nil or physenv.GetGravity() == nil then
								ShellList[i].RemoveNow = 1
							else
								trace.start = ShellList[i].Pos + (ShellList[i].DakVelocity * (ShellList[i].LifeTime-DakTankBulletThinkDelay)) - (-physenv.GetGravity()*((ShellList[i].LifeTime-DakTankBulletThinkDelay)^2)/2)
							end
						end
						if ShellList[i].RemoveNow ~= 1 then
							if ShellList[i].FuzeDelay~=nil and ShellList[i].LifeTime >= ShellList[i].FuzeDelay-DakTankBulletThinkDelay and ShellList[i].FuzeDelay > 0 then
								trace.endpos = ShellList[i].Pos + (ShellList[i].DakVelocity * (ShellList[i].LifeTime+(ShellList[i].FuzeDelay-ShellList[i].LifeTime))) - (-physenv.GetGravity()*((ShellList[i].LifeTime+(ShellList[i].FuzeDelay-ShellList[i].LifeTime))^2)/2)
							else
								trace.endpos = ShellList[i].Pos + (ShellList[i].DakVelocity * (ShellList[i].LifeTime+DakTankBulletThinkDelay)) - (-physenv.GetGravity()*((ShellList[i].LifeTime+DakTankBulletThinkDelay)^2)/2)
							end
						end
					end
				end
				if ShellList[i].RemoveNow ~= 1 then
					trace.filter = ShellList[i].Filter
					trace.mins = Vector(-ShellList[i].DakCaliber*0.02,-ShellList[i].DakCaliber*0.02,-ShellList[i].DakCaliber*0.02)
					trace.maxs = Vector(ShellList[i].DakCaliber*0.02,ShellList[i].DakCaliber*0.02,ShellList[i].DakCaliber*0.02)

					if not(InMapCheck(trace.start) and InMapCheck(trace.endpos)) then
						ShellList[i].RemoveNow = 1
					end

					local ShellTrace = util.TraceHull( trace )

					if ShellTrace ~= nil then
						if ShellList[i].Crushed ~= 1 then
							local effectdata = EffectData()
							effectdata:SetStart( ShellTrace.StartPos )
							effectdata:SetOrigin( ShellTrace.HitPos )
							effectdata:SetScale( ShellList[i].DakCaliber * 0.0393701 )
							effectdata:SetMagnitude( DakTankBulletThinkDelay * 100 )
							if ShellTrace.Hit then
								util.Effect( ShellList[i].DakTrail, effectdata, true, true )
							else
								util.Effect( ShellList[i].DakTrail, effectdata, true, true )
							end
						end
						if ShellTrace.Hit then
							if not(ShellTrace.HitSky and (ShellTrace.HitNormal == Vector(0,0,-1))) then
								--check if aps is near if shellvel is low enough and shell type is right
								--also check if thing is large enough caliber
								--if caliber too big to kill then halve pen?
								--determine if shell is moving towards or away from APS
								if ShellList[i].ShotDown == nil then ShellList[i].ShotDown = 0 end
								local ExpPos = ShellTrace.StartPos
								if ShellList[i].DakVelocity:Length() < 27559.1 then --max vel of shell it can catch 700m/s based off en.wikipedia.org/wiki/Drozd
									if (ShellList[i].DakShellType == "HEAT" or ShellList[i].DakShellType == "HEATFS" or ShellList[i].DakShellType == "ATGM") and  ShellList[i].ShotDown ~= 1 then
										local APS = ents.FindByClass( "dak_tankcore" )
										local Done = 0
										for i = 1, #APS do
											local caliberCheck = ShellList[i].DakCaliber >= APS[i].APSMinCaliber
											local hitPos = ShellTrace.HitPos:Distance( APS[i]:GetPos() ) -- If < 275, it's in range ~7m based off drozd again
											local startPosCheck = ShellTrace.StartPos:Distance( APS[i]:GetPos() ) > hitPos -- It's coming at us
											if APS[i].APSEnable == true and ShellList[i] ~= nil and caliberCheck and Done == 0 and hitPos < 275 and startPosCheck then
												local _, a = WorldToLocal( APS[i]:GetPos(), (ShellTrace.StartPos-APS[i]:GetPos()):GetNormalized():Angle(), APS[i]:GetPos(), APS[i].Forward:Angle() )
												local frontalhit = false
												local sidehit = false
												local rearhit = false
												if math.abs(a.yaw) >= 0 and math.abs(a.yaw) <= 45 then
													frontalhit = true
												end
												if math.abs(a.yaw) >= 45 and math.abs(a.yaw) <= 135 then
													sidehit = true
												end
												if math.abs(a.yaw) >= 135 and math.abs(a.yaw) <= 180 then
													rearhit = true
												end
												local CanShoot = false
												if APS[i].APSFrontalArc == true and frontalhit == true then
													CanShoot = true
												end
												if APS[i].APSSideArc == true and sidehit == true then
													CanShoot = true
												end
												if APS[i].APSRearArc == true and rearhit == true then
													CanShoot = true
												end
												if CanShoot == true and APS[i].APSShots > 0 then -- May need to convert CanShoot to angle later for readouts, but this value is nice
													-- Play some effect or sound or something maybe
													APS[i].APSShots = APS[i].APSShots - 1
													Done = 1
													ShellList[i].ShotDown = 1
													ExpPos = APS[i]:GetPos() + ( ShellTrace.StartPos - APS[i]:GetPos() ):GetNormalized() * 275
												end
											end
										end
									end
								end
								if ShellList[i].ShotDown == 1 then
									if ShellList[i].DakShellType == "HEAT" or ShellList[i].DakShellType == "HEATFS" or ShellList[i].DakShellType == "ATGM" then
										ShellList[i].RemoveNow = 1
										ShellList[i].ExplodeNow = true
										DTShellAirBurst(ExpPos,ShellList[i],trace.endpos-trace.start)
									end
								else
									local cal = ShellList[i].DakCaliber
									util.ScreenShake( ShellTrace.HitPos, cal, 2.5, 0.2, cal * 50 )
									if ShellList[i].IsGuided then
										DTShellHit(ShellTrace.StartPos,ShellTrace.HitPos,ShellTrace.Entity,ShellList[i],ShellTrace.HitNormal)
									else
										DTShellHit(ShellTrace.StartPos,ShellTrace.HitPos,ShellTrace.Entity,ShellList[i],ShellTrace.HitNormal)
									end
								end
							end
						else
							if ShellList[i].FuzeDelay ~= nil and ShellList[i].LifeTime >= ShellList[i].FuzeDelay - DakTankBulletThinkDelay and ShellList[i].FuzeDelay > 0  and ( ShellList[i].DakShellType == "HE" or ShellList[i].DakShellType == "SM" ) then
								ShellList[i].ExplodeNow = true
								DTShellAirBurst( trace.endpos, ShellList[i], trace.endpos - trace.start )
							end
						end
					end
				end
			end

			if ShellList[i].DieTime and ShellList[i].DieTime < CurTime() then
				RemoveList[#RemoveList + 1] = ShellList[i]
			end

			if ShellList[i].RemoveNow == 1 then
				RemoveList[#RemoveList + 1] = ShellList[i]
			end
			ShellList[i].LifeTime = ShellList[i].LifeTime + DakTankBulletThinkDelay
		end
	end

	if #RemoveList > 0 then
		for i = 1, #RemoveList do
			table.RemoveByValue( ShellList, RemoveList[i] )
		end
	end
end )