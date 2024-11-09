local DTTE = DTTE

util.AddNetworkString( "daktankexplosion" )

do -- DTTE.SpawnFire
	local fireDuration		= 10 -- How long the fire lasts in seconds
	local fireDamageInterval  = 2 -- How often to check for targets to ignite every second
	local fireRadius		  = 250 -- Fire AoE
	local fireSoundInterval   = {0.25, 0.5} -- Random range, in seconds, for the fire sound to play
	local fireSound		   = "daktanks/flamerimpact.mp3"
	local fireNearestNeighbor = 100 -- How near a fire can be to another fire
	local fireIgniteTimeMult  = 10 -- Multiplier for how long a target is ignited based on distance

	-- TODO: add line of sight checks to this function
	local function fireBurn(fire)
		for _, target in ipairs(ents.FindInSphere(fire.pos, fireRadius)) do
			if not target:IsOnFire() then
				if (target:IsPlayer() or target:IsNPC() or target.Base == "base_nextbot" or target:GetClass() == "dak_gamemode_bot2") and not(target:IsPlayer() and target:InVehicle()) then -- TODO: Ensure nextbots have InVehicle
					target:TakeDamageInfo(fire.dmgInfo)
					target:Ignite(target:GetPos():Distance(fire.pos) / fireRadius * fireIgniteTimeMult)
				elseif target:GetClass() == "dak_tegearbox" or target:GetClass() == "dak_tegearboxnew" and target.Controller.ColdWar ~= 1 and target.Controller.Modern ~= 1 then
					target:Ignite(target:GetPos():Distance(fire.pos) / fireRadius * fireIgniteTimeMult)
					target.DakBurnStacks = target.DakBurnStacks + 1
				end
			end
		end
	end

	local function fireSound(fire)
		sound.Play("daktanks/flamerimpact.mp3", fire.pos, 100, 100 * math.Rand(0.6, 0.8), 1)
		if CurTime() > fire.timeLimit then
			timer.Remove("dtteFireSound " .. fire.id)
		else
			timer.Adjust("dtteFireSound " .. fire.id, math.Rand(fireSoundInterval[1], fireSoundInterval[2]))
		end
	end

	local function roundVector(vec, gridSize)
		vec.x = math.Round(vec.x / gridSize) * gridSize
		vec.y = math.Round(vec.y / gridSize) * gridSize
		vec.z = math.Round(vec.z / gridSize) * gridSize

		return vec
	end

	function DTTE.SpawnFire(pos, attacker, inflictor)
		local dmgInfo = DamageInfo()
			dmgInfo:SetAttacker(attacker or game.GetWorld())
			if IsValid(attacker) then
				dmgInfo:SetAttacker(attacker)
			else
				dmgInfo:SetAttacker(game.GetWorld())
			end
			if IsValid(inflictor) then
				dmgInfo:SetInflictor(inflictor)
			else
				dmgInfo:SetInflictor(game.GetWorld())
			end
			dmgInfo:SetReportedPosition(pos)
			dmgInfo:SetDamagePosition(pos)
			dmgInfo:SetDamageType(DMG_BURN)
			dmgInfo:SetDamage(1)

		local effect = EffectData()
			effect:SetOrigin(pos)
			effect:SetEntity(dmgInfo:GetInflictor())
			effect:SetAttachment(1)
			effect:SetMagnitude(.5)
			effect:SetScale(1)
		util.Effect("dakteflameimpact", effect, true, true)

		local fireGrid = roundVector(pos, fireNearestNeighbor)
		local fire	 = {
				pos			 = pos,
				id			  = string.format("[%s, %s, %s]", fireGrid.x, fireGrid.y, fireGrid.z),
				dmgInfo		 = dmgInfo,
				soundLastPlayed = -math.huge,
				burn			= fireBurn,
				playSound	   = fireSound,
				timeLimit	   = CurTime() + fireDuration
			}

		fire:burn()
		fire:playSound()

		timer.Create("dtteFire " .. fire.id, 1 / fireDamageInterval, fireDuration * fireDamageInterval, function()
			fire:burn()
		end)

		timer.Create("dtteFireSound " .. fire.id, math.Rand(fireSoundInterval[1], fireSoundInterval[2]), 0, function()
			fire:playSound()
		end)

		--debugoverlay.Cross(fire.pos, fireRadius, fireDuration, Color(255, 100, 0), true)
		--debugoverlay.Sphere(fire.pos, fireRadius, fireDuration, Color(255, 100, 0, 1), true)
	end
end

local entity = FindMetaTable( "Entity" )

function entity:DTShellApplyForce(HitPos,Normal,Shell)
	local selfParent = self:GetParent()
	if IsValid(selfParent) then
		selfParent = selfParent:GetParent()
		if IsValid(selfParent) then
			local physObj = selfParent:GetPhysicsObject()
			if not IsValid(physObj) then return end

			if self.Controller then
				physObj:ApplyForceOffset( -Normal * (0.5 * (((Shell.DakVelocity:Length()) * 0.254) ^ 2) * Shell.DakMass) / self.Controller.TotalMass * 0.04,selfParent:GetPos() + self:WorldToLocal(HitPos):GetNormalized() )
			else
				local Div = selfParent:OBBMaxs() / 75
				physObj:ApplyForceOffset( Div * ((Shell.DakVelocity:Length()) * Shell.DakMass / 50000) / physObj:GetMass() * 0.04,selfParent:GetPos() + self:WorldToLocal(HitPos):GetNormalized() )
			end
		end
	else
		local physObj = self:GetPhysicsObject()
		if IsValid(physObj) then
			local Div = self:OBBMaxs() / 75
			physObj:ApplyForceOffset( Div * ((Shell.DakVelocity:Length()) * Shell.DakMass / 50000) / physObj:GetMass() * 0.04,self:GetPos() + self:WorldToLocal(HitPos):GetNormalized() )
		end
	end
end

function entity:DTHEApplyForce(HitPos, Pos, Damage, Traces, Multipler)
	if IsValid(self:GetParent()) then
		if IsValid(self:GetParent():GetParent()) then
			if IsValid(self:GetParent():GetParent():GetPhysicsObject()) then
				self:GetParent():GetParent():GetPhysicsObject():ApplyForceCenter( (HitPos-Pos):GetNormalized() * (Damage / Traces) * Multipler * self:GetParent():GetParent():GetPhysicsObject():GetMass() * (1 - (HitPos:Distance(Pos) / 1000))  )
			end
		end
	else
		if IsValid(self:GetPhysicsObject()) then
			self:GetPhysicsObject():ApplyForceCenter( (HitPos-Pos):GetNormalized() * (Damage / Traces) * Multipler * self:GetPhysicsObject():GetMass() * (1 - (HitPos:Distance(Pos) / 1000))  )
		end
	end
end

local function CanDamage(Ent)
	local owner = Ent:CPPIGetOwner()
	if IsValid(owner) and owner:IsPlayer() and owner:HasGodMode() then return false end
	if Ent.DakIsTread ~= nil then return false end

	return true
end

local function DTDealDamage(Ent, Damage, Dealer, entbased)
	if Ent:GetClass() == "daktank_cap" then return end
	local entTbl = Ent:GetTable()
	entTbl.DakHealth = entTbl.DakHealth - Damage
	if isfunction(entTbl.DTOnTakeDamage) then Ent:DTOnTakeDamage(Damage) end

	if entbased == true then
		if (not Dealer) or Dealer.LastDamagedBy == nil or Dealer.LastDamagedBy == NULL then
			entTbl.LastDamagedBy = game.GetWorld()
		else
			entTbl.LastDamagedBy = Dealer.LastDamagedBy
		end
	else
		if (not Dealer) or Dealer.DakOwner == nil or Dealer.DakOwner == NULL then
			entTbl.LastDamagedBy = game.GetWorld()
		else
			entTbl.LastDamagedBy = Dealer.DakOwner
		end
	end
end

function DTGetStandoffMult(Start, End, Caliber, Filter, ShellType,nochecklegit)
	if tonumber(Caliber) == nil then return 0 end
	local Recurse = 1
	local NewFilter = Filter
	local Go = 1
	local FirstArmor = nil
	local SecondArmor = nil
	while Go == 1 and Recurse < 25 do
		local trace = {}
			trace.start = Start
			trace.endpos = End
			trace.filter = Filter
		local ShellSimTrace = util.TraceLine( trace )
		if IsValid(ShellSimTrace.Entity) then
			if ShellSimTrace.Entity:GetPhysicsObject() then
				if ShellSimTrace.Entity:GetPhysicsObject():GetMass() > 1 and not(DTTE.CheckClip(ShellSimTrace.Entity,ShellSimTrace.HitPos,nochecklegit)) then
					if FirstArmor == nil then
						FirstArmor = ShellSimTrace.HitPos
					else
						SecondArmor = ShellSimTrace.HitPos
						Go = 0
					end
				end
			end
			NewFilter[#NewFilter + 1] = ShellSimTrace.Entity
		else
			return 1
		end
		Recurse = Recurse + 1
	end
	if FirstArmor ~= nil and SecondArmor ~= nil then
		local Dist = FirstArmor:Distance(SecondArmor)
		local StandoffCalibers = ((Dist * 25.4) / Caliber) + 2.6
		if ShellType == "HEAT"  then
			StandoffCalibers = ((Dist * 25.4) / Caliber) + 1.06
		end
		if StandoffCalibers > 7.5 then
			return 1.4 / (StandoffCalibers / 7.5)
		else
			return math.sqrt(math.sqrt(StandoffCalibers)) / 1.185
		end
	else
		return 1
	end
end

function DTShellAirBurst(HitPos, Shell, Normal)
	if Shell.ExplodeNow ~= true then return end
	--This is kinda bad, but this function relies on a gun existing which can cause lua errors. I'd rather have a shell disappear than the entire system break.
	if not Shell.DakGun then return end

	Shell.ExplodeNow = false
	if Shell.DakExplosive then
		local effectdata3 = EffectData()
		effectdata3:SetOrigin(HitPos)
		effectdata3:SetEntity(Shell.DakGun)
		effectdata3:SetAttachment(1)
		effectdata3:SetMagnitude(.5)
		effectdata3:SetScale(Shell.DakBlastRadius)
		effectdata3:SetNormal( Normal )
		if Shell.DakShellType == "SM" then
			util.Effect("daktescalingsmoke", effectdata3, true, true)
		else
			util.Effect("daktescalingexplosion", effectdata3, true, true)
		end

		Shell.DakGun:SetNWFloat("ExpDamage",Shell.DakSplashDamage)
		if Shell.DakCaliber >= 75 then
			Shell.DakGun:SetNWBool("Exploding",true)
			timer.Create( "ExplodeTimer" .. Shell.DakGun:EntIndex(), 0.1, 1, function()
				Shell.DakGun:SetNWBool("Exploding",false)
			end)
		else
			local ExpSounds = {}
			if Shell.DakCaliber < 20 then
				ExpSounds = {"physics/surfaces/sand_impact_bullet1.wav","physics/surfaces/sand_impact_bullet2.wav","physics/surfaces/sand_impact_bullet3.wav","physics/surfaces/sand_impact_bullet4.wav"}
			else
				ExpSounds = {"daktanks/dakexp1.mp3","daktanks/dakexp2.mp3","daktanks/dakexp3.mp3","daktanks/dakexp4.mp3"}
			end
			sound.Play( ExpSounds[math.random(1,#ExpSounds)], HitPos, 100, 100, 1 )
		end
		if Shell.Exploded ~= true or Shell.Exploded == nil then
			if Shell.DakShellType == "HESH" then
				DTShockwave(HitPos,Shell.DakSplashDamage,Shell.DakBlastRadius,Shell.DakFragPen,Shell.DakGun.DakOwner,Shell,nil,true)
			else
				DTShockwave(HitPos,Shell.DakSplashDamage * 0.5,Shell.DakBlastRadius,Shell.DakFragPen,Shell.DakGun.DakOwner,Shell,nil,true)
				--DTExplosion(HitPos + (Normal * 2),Shell.DakSplashDamage * 0.5,Shell.DakBlastRadius,Shell.DakCaliber,Shell.DakFragPen,Shell.DakGun.DakOwner,Shell)
			end
		end
		Shell.Exploded = true
	else
		local effectdata = EffectData()
		if Shell.DakIsFlame == 1 then
			DTTE.SpawnFire(HitPos, Shell.DakGun.DakOwner, Shell.DakGun)
		else
			effectdata:SetOrigin(HitPos)
			effectdata:SetEntity(Shell.DakGun)
			effectdata:SetAttachment(1)
			effectdata:SetMagnitude(.5)
			effectdata:SetScale(Shell.DakCaliber * (Shell.DakBaseVelocity / 29527.6))
			if not Shell.IsFrag then
				util.Effect("dakteshellimpact", effectdata, true, true)
			end
			util.Decal( "Impact.Concrete", HitPos - ((HitPos-Start):GetNormalized() * 5), HitPos + ((HitPos-Start):GetNormalized() * 5), Shell.DakGun)
			local ExpSounds = {}
			if Shell.DakCaliber < 20 then
				ExpSounds = {"physics/surfaces/sand_impact_bullet1.wav","physics/surfaces/sand_impact_bullet2.wav","physics/surfaces/sand_impact_bullet3.wav","physics/surfaces/sand_impact_bullet4.wav"}
			else
				ExpSounds = {"daktanks/dakexp1.mp3","daktanks/dakexp2.mp3","daktanks/dakexp3.mp3","daktanks/dakexp4.mp3"}
			end

			if Shell.DakIsPellet then
				sound.Play( ExpSounds[math.random(1,#ExpSounds)], HitPos, 100, 150, 0.25 )
			else
				sound.Play( ExpSounds[math.random(1,#ExpSounds)], HitPos, 100, 100, 1 )
			end
		end
	end

	Shell.RemoveNow = 1
	if Shell.DakExplosive then
		Shell.ExplodeNow = true
	end
	Shell.LifeTime = 0
	Shell.DakVelocity = Vector(0,0,0)
	Shell.DakDamage = 0
end

local function DestroyEnt(Ent, Filter, Shell)
	if Ent.DakHealth > 0 or Ent.DakPooled ~= 0 then return end

	local Class = Ent:GetClass()

	if Class == "dak_crew" then
		for _ = 1, 15 do
			util.Decal("Blood", Ent:GetPos(), Ent:GetPos() + (VectorRand() * 500), Ent)
		end
	end

	Filter[#Filter + 1] = Ent

	if string.Explode("_", Class, false)[1] == "dak" then
		local Owner = Ent.DakOwner

		if Class ~= "dak_tesalvage" and Owner:IsValid() and Owner:IsPlayer() and Ent.DakDead ~= true then
			if Class == "dak_crew" then
				if Ent.Job == 1 then
					Owner:ChatPrint("Gunner Killed!")
				elseif Ent.Job == 2 then
					Owner:ChatPrint("Driver Killed!")
				elseif Ent.Job == 3 then
					Owner:ChatPrint("Loader Killed!")
				else
					Owner:ChatPrint("Passenger Killed!")
				end
				Ent:SetMaterial("models/flesh")
			else
				Owner:ChatPrint(Ent.DakName .. " Destroyed!")
				Ent:SetMaterial("models/props_buildings/plasterwall021a")
				Ent:SetColor(Color(100,100,100,255))
			end
		end

		Ent.DakDead = true
	else
		local CurPos = Ent:GetPos()
		local Salvage = ents.Create("dak_tesalvage")

		Shell.salvage = Salvage
		Salvage.DakModel = Ent:GetModel()
		Salvage.DakLastDamagePos = CurPos
		Salvage:SetPos(CurPos)
		Salvage:SetAngles(Ent:GetAngles())
		Salvage:Spawn()
		Filter[#Filter + 1] = Salvage
		Ent:Remove()
	end

	if Shell.salvage then
		Shell.Filter[#Shell.Filter + 1] = Shell.salvage
	end
end

local function KillEnemy(Ent, Owner, Shell, TraceCount, Damage, DamageMult)
	if not Ent:IsValid() then return end

	if Ent:IsPlayer() or Ent:IsNPC() or Ent.Base == "base_nextbot" then
		if Ent:GetClass() == "dak_bot" then
			Ent:SetHealth(Ent:Health() - (Damage / TraceCount) * DamageMult)
			if Ent:Health() <= 0 and Ent.revenge == 0 then
				--local body = ents.Create( "prop_ragdoll" )
				body:SetPos( Ent:GetPos() )
				body:SetModel( Ent:GetModel() )
				body:Spawn()
				body.DakHealth = 1000000
				body.DakMaxHealth = 1000000
				--Ent:Remove()
				local SoundList = {"npc/metropolice/die1.wav","npc/metropolice/die2.wav","npc/metropolice/die3.wav","npc/metropolice/die4.wav","npc/metropolice/pain4.wav"}
				body:EmitSound( SoundList[math.random(5)], 100, 100, 1, 2 )
				timer.Simple( 5, function()
					body:Remove()
				end )
			end
		else
			local Pain = DamageInfo()
			Pain:SetDamageForce(Direction * (Damage / TraceCount) * DamageMult * 10 * Shell.DakMass)
			Pain:SetDamage((Damage / TraceCount) * DamageMult)
			if Owner:IsPlayer() and Shell and Shell.DakGun then
				Pain:SetAttacker(Owner)
				Pain:SetInflictor(Shell.DakGun)
			else
				Pain:SetAttacker(game.GetWorld())
				Pain:SetInflictor(game.GetWorld())
			end
			Pain:SetReportedPosition(Shell.DakGun:GetPos())
			Pain:SetDamagePosition(Ent:GetPos())
			Pain:SetDamageType(DMG_BLAST)
			Ent:TakeDamageInfo(Pain)
		end
	end
end

local function DTShellContinue(Start, End, Shell, Normal, HitNonHitable)
	Shell.Hits = Shell.Hits + 1
	if Shell.Hits > 50 then
		Shell.RemoveNow = 1
		print("ERROR, RECURSE")
	return end
	local Fuze = 25
	if Shell.DakShellType == "HE" or Shell.DakShellType == "SM" then
		Fuze = 5
	end
	local newtrace = {}
		if (Shell.DakShellType == "APHE" or Shell.DakShellType == "HE" or Shell.DakShellType == "SM") and not HitNonHitable then
			newtrace.start = Shell.Pos
			newtrace.endpos = Shell.Pos + (Fuze * Shell.DakVelocity:GetNormalized())
		else
			newtrace.start = Start
			newtrace.endpos = End
		end
		newtrace.filter = Shell.Filter
		newtrace.mins = Vector(-Shell.DakCaliber * 0.02,-Shell.DakCaliber * 0.02,-Shell.DakCaliber * 0.02)
		newtrace.maxs = Vector(Shell.DakCaliber * 0.02,Shell.DakCaliber * 0.02,Shell.DakCaliber * 0.02)
	local ContShellTrace = util.TraceHull( newtrace )
	local ContCheckShellLineTrace = util.TraceLine( newtrace )
	Normal = ContCheckShellLineTrace.HitNormal
	if (Shell.DakShellType == "APHE" or Shell.DakShellType == "HE" or Shell.DakShellType == "SM") and not ContShellTrace.Hit and not HitNonHitable then
		if Shell.DieTime == nil then
			Shell.DieTime = CurTime()
		end
		Shell.RemoveNow = 1
		local effectdata3 = EffectData()
		effectdata3:SetOrigin(Shell.Pos + (Fuze * Shell.DakVelocity:GetNormalized()))
		effectdata3:SetEntity(Shell.DakGun)
		effectdata3:SetAttachment(1)
		effectdata3:SetMagnitude(.5)
		effectdata3:SetScale(Shell.DakBlastRadius)
		effectdata3:SetNormal( Normal )
		if Shell.DakShellType == "SM" then
			util.Effect("daktescalingsmoke", effectdata3, true, true)
		else
			util.Effect("daktescalingexplosion", effectdata3, true, true)
		end
		Shell.DakGun:SetNWFloat("ExpDamage",Shell.DakSplashDamage)
		if Shell.DakCaliber >= 75 then
			Shell.DakGun:SetNWBool("Exploding",true)
			timer.Create( "ExplodeTimer" .. Shell.DakGun:EntIndex(), 0.1, 1, function()
				Shell.DakGun:SetNWBool("Exploding",false)
			end)
		else
			local ExpSounds = {}
			if Shell.DakCaliber < 20 then
				ExpSounds = {"physics/surfaces/sand_impact_bullet1.wav","physics/surfaces/sand_impact_bullet2.wav","physics/surfaces/sand_impact_bullet3.wav","physics/surfaces/sand_impact_bullet4.wav"}
			else
				ExpSounds = {"daktanks/dakexp1.mp3","daktanks/dakexp2.mp3","daktanks/dakexp3.mp3","daktanks/dakexp4.mp3"}
			end
			sound.Play( ExpSounds[math.random(1,#ExpSounds)], Shell.Pos + (Fuze * Shell.DakVelocity:GetNormalized()), 100, 100, 1 )
		end
		if Shell.Exploded ~= true then
			if Shell.DakShellType == "APHE" then
				DTAPHE(Shell.Pos + (Fuze * Shell.DakVelocity:GetNormalized()),Shell.DakSplashDamage,Shell.DakBlastRadius,Shell.DakCaliber,Shell.DakFragPen,Shell.DakGun.DakOwner,Shell)
			else
				DTShockwave(Shell.Pos + (Fuze * Shell.DakVelocity:GetNormalized()),Shell.DakSplashDamage * 0.5,Shell.DakBlastRadius,Shell.DakFragPen,Shell.DakGun.DakOwner,Shell)
				--DTExplosion(Shell.Pos + (Fuze * Shell.DakVelocity:GetNormalized()),Shell.DakSplashDamage * 0.5,Shell.DakBlastRadius,Shell.DakCaliber,Shell.DakFragPen,Shell.DakGun.DakOwner,Shell)
			end
		end
		Shell.Exploded = true
	else
		local HitEnt = ContShellTrace.Entity
		--local End = ContShellTrace.HitPos
		local effectdata = EffectData()
		effectdata:SetStart(ContShellTrace.StartPos)
		effectdata:SetOrigin(ContShellTrace.HitPos)
		effectdata:SetScale(Shell.DakCaliber * 0.0393701)
		util.Effect("dakteballistictracer", effectdata, true, true)

		if hook.Run("DakTankDamageCheck", HitEnt, Shell.DakGun.DakOwner, Shell.DakGun) ~= false then
			if HitEnt.DakHealth == nil then
				DTTE.SetupNewEnt(HitEnt)
			end
			if (HitEnt.DakDead == true) then
				Shell.Filter[#Shell.Filter + 1] = HitEnt
				DTShellContinue(Start,End,Shell,Normal,true)
			end
			if (HitEnt:IsValid() and HitEnt:GetPhysicsObject():IsValid() and not(HitEnt:IsPlayer()) and not(HitEnt:IsNPC()) and not(HitEnt.Base == "base_nextbot") and HitEnt.DakHealth ~= nil ) or (HitEnt.DakName == "Damaged Component")  then --and HitEnt.DakHealth > 0
				if (DTTE.CheckClip(HitEnt,ContShellTrace.HitPos)) or (HitEnt:GetPhysicsObject():GetMass() <= 1 and not(HitEnt:IsVehicle()) and HitEnt.IsDakTekFutureTech ~= 1) or HitEnt.DakName == "Damaged Component" then
				--if (HitEnt:GetPhysicsObject():GetMass() <= 1 and not(HitEnt:IsVehicle()) and not(HitEnt.IsDakTekFutureTech == 1)) or HitEnt.DakName == "Damaged Component" or HitEnt.DakDead == true then
					if HitEnt.DakArmor == nil or HitEnt.DakBurnStacks == nil then
						DTTE.SetupNewEnt(HitEnt)
					end
					local SA = HitEnt:GetPhysicsObject():GetSurfaceArea()
					if HitEnt.DakBurnStacks == nil then
						HitEnt.DakBurnStacks = 0
					end
					if HitEnt.IsDakTekFutureTech == 1 then
						HitEnt.DakArmor = 1000
					else
						if SA == nil then
							--Volume = (4 / 3) * math.pi*math.pow( HitEnt:OBBMaxs().x, 3 )
							HitEnt.DakArmor = HitEnt:OBBMaxs().x / 2
							HitEnt.DakIsTread = 1
						else
							if HitEnt:GetClass() == "prop_physics" then
								DTTE.ArmorSanityCheck(HitEnt)
							end
						end
					end
					--fix issue where visclip happens twice when at intersections causing shells to go through armor at edges
					Shell.Filter[#Shell.Filter + 1] = HitEnt
					DTShellContinue(Start,End,Shell,Normal,true)
				else
					if HitEnt.DakArmor == nil or HitEnt.DakBurnStacks == nil then
						DTTE.SetupNewEnt(HitEnt)
					end
					local SA = HitEnt:GetPhysicsObject():GetSurfaceArea()
					if HitEnt.IsDakTekFutureTech == 1 then
						HitEnt.DakArmor = 1000
					else
						if SA == nil then
							--Volume = (4 / 3) * math.pi*math.pow( HitEnt:OBBMaxs().x, 3 )
							HitEnt.DakArmor = HitEnt:OBBMaxs().x / 2
							HitEnt.DakIsTread = 1
						else
							if HitEnt:GetClass() == "prop_physics" then
								DTTE.ArmorSanityCheck(HitEnt)
							end
						end
					end

					HitEnt.DakLastDamagePos = ContShellTrace.HitPos

					local Vel = Shell.DakVelocity:GetNormalized()
					local EffArmor = 0

					local CurrentPen = Shell.DakPenetration-Shell.DakPenetration * (Shell.DakVelocity:Distance( Vector(0,0,0) )) * Shell.LifeTime * (Shell.DakPenLossPerMeter / 52.49)

					local HitAng = math.deg(math.acos(Normal:Dot( -Vel:GetNormalized() )))

					local TDRatio = 0
					local PenRatio = 0
					local CompArmor
					if HitEnt.IsComposite == 1 or (HitEnt:CPPIGetOwner() ~= nil and HitEnt:CPPIGetOwner():IsWorld()) then
						CompArmor = DTTE.CompositesTrace( HitEnt, ContShellTrace.HitPos, Shell.DakVelocity:GetNormalized(), Shell.Filter )
						if HitEnt.EntityMods == nil then HitEnt.EntityMods = {} end
						if HitEnt.EntityMods.CompKEMult == nil then HitEnt.EntityMods.CompKEMult = 9.2 end
						if HitEnt.EntityMods.CompCEMult == nil then HitEnt.EntityMods.CompCEMult = 18.4 end
						if Shell.DakShellType == "HEAT" or Shell.DakShellType == "HEATFS" or Shell.DakShellType == "ATGM" or Shell.DakShellType == "HESH" then
							CompArmor = CompArmor * HitEnt.EntityMods.CompCEMult
							if Shell.IsTandem == true then
								if HitEnt.IsERA == 1 then
									CompArmor = 0
								end
							end
						else
							CompArmor = CompArmor * HitEnt.EntityMods.CompKEMult
						end
						if Shell.DakShellType == "APFSDS" or Shell.DakShellType == "APDS" then
							if Shell.DakShellType == "APFSDS" then
								TDRatio = (CompArmor / 3) / (Shell.DakCaliber * 2.5)
							else
								TDRatio = (CompArmor / 3) / (Shell.DakCaliber * 1.75)
							end
						else
							TDRatio = (CompArmor / 3) / Shell.DakCaliber
						end
						PenRatio = CurrentPen / CompArmor
					else
						if Shell.DakShellType == "APFSDS" or Shell.DakShellType == "APDS" then
							if Shell.DakShellType == "APFSDS" then
								TDRatio = HitEnt.DakArmor / (Shell.DakCaliber * 2.5)
							else
								TDRatio = HitEnt.DakArmor / (Shell.DakCaliber * 1.75)
							end
						else
							TDRatio = HitEnt.DakArmor / Shell.DakCaliber
						end
						PenRatio = CurrentPen / DTTE.GetArmor(HitEnt, Shell.DakShellType, Shell.DakCaliber)
					end

					--shattering occurs when TD ratio is above 0.8 and pen is 1.05 to 1.25 times more than the armor
					--random chance to pen happens between 0.9 and 1.2 pen to armor ratio
					--if pen to armor ratio is 0.9 or below round fails
					--if T/D ratio is above 0.8 and round pens it still shatters
					--round must also be going above 600m/s
					local Failed = 0
					local Shattered = 0
					local ShatterVel = 600
					if Shell.DakShellType == "APFSDS" then
						ShatterVel = 1500
					end
					if Shell.DakShellType == "APDS" then
						ShatterVel = 1050
					end
					if Shell.DakVelocity:Length() * 0.0254 > ShatterVel and not(Shell.DakShellType == "HEAT" or Shell.DakShellType == "HEATFS" or Shell.DakShellType == "ATGM" or Shell.DakShellType == "HESH") then
						if TDRatio > 0.8 then
							if PenRatio < 0.9 then
								Failed = 1
								Shattered = 0
							end
							if PenRatio >= 0.9 and PenRatio < 1.05 then
								Failed = math.random(0,1)
								Shattered = 0
							end
							if PenRatio >= 1.05 and PenRatio < 1.25 then
								Failed = 1
								Shattered = 1
							end
							if PenRatio >= 1.25 then
								Failed = 0
								Shattered = 1
							end
						else
							if PenRatio < 0.9 then
								Failed = 1
								Shattered = 0
							end
							if PenRatio >= 0.9 and PenRatio < 1.20 then
								Failed = math.random(0,1)
								Shattered = 0
							end
							if PenRatio >= 1.20 then
								Failed = 0
								Shattered = 0
							end
						end
					end
					if HitNonHitable and HitAng >= 70 and HitEnt.DakArmor >= Shell.DakCaliber * 0.85 and (Shell.DakShellType == "APFSDS" or Shell.DakShellType == "APDS") then Shattered = 1 end
					if HitNonHitable and HitAng >= 80 and HitEnt.DakArmor >= Shell.DakCaliber * 0.85 and (Shell.DakShellType == "APFSDS" or Shell.DakShellType == "APDS") then Shattered = 1 Failed = 1 end
					if HitEnt.IsComposite == 1 or (HitEnt:CPPIGetOwner() ~= nil and HitEnt:CPPIGetOwner():IsWorld()) then
						if HitEnt.EntityMods == nil then HitEnt.EntityMods = {} end
						if HitEnt.EntityMods.CompKEMult == nil then HitEnt.EntityMods.CompKEMult = 9.2 end
						if HitEnt.EntityMods.CompCEMult == nil then HitEnt.EntityMods.CompCEMult = 18.4 end
						EffArmor = CompArmor
						if Shell.DakShellType == "HEAT" or Shell.DakShellType == "HEATFS" or Shell.DakShellType == "ATGM" then
							EffArmor = EffArmor
						end
					else
						if Shell.DakShellType == "HEAT" or Shell.DakShellType == "HEATFS" or Shell.DakShellType == "ATGM" then
							EffArmor = (DTTE.GetArmor(HitEnt, Shell.DakShellType, Shell.DakCaliber) / math.abs(Normal:Dot(Vel:GetNormalized())) )
						end
						if Shell.DakShellType == "AP" or Shell.DakShellType == "APHE" or Shell.DakShellType == "HE" or Shell.DakShellType == "HVAP" or Shell.DakShellType == "SM" or Shell.DakShellType == "HESH" then
							if HitAng > 24 then
								local aVal = 2.251132 - 0.1955696 * math.max( HitAng, 24 ) + 0.009955601 * math.pow( math.max( HitAng, 24 ), 2 ) - 0.0001919089 * math.pow( math.max( HitAng, 24 ), 3 ) + 0.000001397442 * math.pow( math.max( HitAng, 20 ), 4 )
								local bVal = 0.04411227 - 0.003575789 * math.max( HitAng, 24 ) + 0.0001886652 * math.pow( math.max( HitAng, 24 ), 2 ) - 0.000001151088 * math.pow( math.max( HitAng, 24 ), 3 ) + 1.053822e-9 * math.pow( math.max( HitAng, 20 ), 4 )
								EffArmor = math.Clamp(DTTE.GetArmor(HitEnt, Shell.DakShellType, Shell.DakCaliber) * (aVal * math.pow( TDRatio, bVal )),DTTE.GetArmor(HitEnt, Shell.DakShellType, Shell.DakCaliber),10000000000)
							else
								EffArmor = (DTTE.GetArmor(HitEnt, Shell.DakShellType, Shell.DakCaliber) / math.abs(Normal:Dot(Vel:GetNormalized())) )
							end
						end
						if Shell.DakShellType == "APDS" then
							EffArmor = DTTE.GetArmor(HitEnt, Shell.DakShellType, Shell.DakCaliber) * math.pow( 2.71828, math.pow( HitAng, 2.6 ) * 0.00003011 )
						end
						if Shell.DakShellType == "APFSDS" then
							EffArmor = DTTE.GetArmor(HitEnt, Shell.DakShellType, Shell.DakCaliber) * math.pow( 2.71828, math.pow( HitAng, 2.6 ) * 0.00003011 )
						end
					end
					if HitAng >= 70 and EffArmor >= 5 and (Shell.DakShellType == "HEAT" or Shell.DakShellType == "HEATFS" or Shell.DakShellType == "ATGM" or Shell.DakShellType == "HESH") then Shattered = 1 end
					if HitAng >= 80 and EffArmor >= 5 and (Shell.DakShellType == "HEAT" or Shell.DakShellType == "HEATFS" or Shell.DakShellType == "ATGM" or Shell.DakShellType == "HESH") then Shattered = 1 Failed = 1 end
					if EffArmor < CurrentPen and HitEnt.IsDakTekFutureTech == nil and Failed == 0 then
						if CanDamage(HitEnt) then
							if HitEnt:GetClass() == "dak_tegun" or HitEnt:GetClass() == "dak_temachinegun" or HitEnt:GetClass() == "dak_teautogun" then
								DTDealDamage(HitEnt,math.Clamp(Shell.DakDamage * (CurrentPen / DTTE.GetArmor(HitEnt, Shell.DakShellType, Shell.DakCaliber)),0,DTTE.GetArmor(HitEnt, Shell.DakShellType, Shell.DakCaliber) * 2) * 0.001,Shell.DakGun)
								DTDealDamage(HitEnt.Controller,math.Clamp(Shell.DakDamage * (CurrentPen / DTTE.GetArmor(HitEnt, Shell.DakShellType, Shell.DakCaliber)),0,DTTE.GetArmor(HitEnt, Shell.DakShellType, Shell.DakCaliber) * 2),Shell.DakGun)
							else
								DTDealDamage(HitEnt,math.Clamp(Shell.DakDamage * (CurrentPen / DTTE.GetArmor(HitEnt, Shell.DakShellType, Shell.DakCaliber)),0,DTTE.GetArmor(HitEnt, Shell.DakShellType, Shell.DakCaliber) * 2),Shell.DakGun)
							end
						end
						--print("Shell Hit Function Secondary Impact Damage")
						--print(math.Clamp(Shell.DakDamage * (CurrentPen / DTTE.GetArmor(HitEnt, Shell.DakShellType, Shell.DakCaliber)),0,DTTE.GetArmor(HitEnt, Shell.DakShellType, Shell.DakCaliber) * 2))
						if (HitEnt:IsValid() and HitEnt.Base ~= "base_nextbot" and HitEnt:GetClass() ~= "prop_ragdoll") and Shell.DakIsFlame ~= 1 then
							HitEnt:DTShellApplyForce(ContShellTrace.HitPos,Normal,Shell)
						end
						Shell.Filter[#Shell.Filter + 1] = HitEnt
						if Shattered == 1 then
							if Shell.DakShellType == "HEAT" or Shell.DakShellType == "HEATFS" or Shell.DakShellType == "ATGM" then
								DTSpall(ContShellTrace.HitPos,EffArmor,HitEnt,Shell.DakCaliber * 0.5,CurrentPen,Shell.DakGun.DakOwner,Shell,Shell.DakVelocity:GetNormalized())
							else
								DTSpall(ContShellTrace.HitPos,EffArmor,HitEnt,Shell.DakCaliber * 2,CurrentPen,Shell.DakGun.DakOwner,Shell,Shell.DakVelocity:GetNormalized())
							end
						else
							DTSpall(ContShellTrace.HitPos,EffArmor,HitEnt,Shell.DakCaliber,CurrentPen,Shell.DakGun.DakOwner,Shell,Shell.DakVelocity:GetNormalized())
						end

						local effectdata = EffectData()
						effectdata:SetOrigin(ContShellTrace.HitPos)
						effectdata:SetEntity(HitEnt)
						effectdata:SetAttachment(1)
						effectdata:SetMagnitude(.5)
						effectdata:SetScale(Shell.DakCaliber * 0.25)
						if HitEnt:GetClass() ~= "dak_gamemode_bot2" and not(HitEnt:IsPlayer()) and not(HitEnt:IsNPC()) then
							util.Effect("dakteshellpenetrate", effectdata, true, true)
						else
							util.Decal( "Blood", ContShellTrace.HitPos - ((ContShellTrace.HitPos-Start):GetNormalized() * 5), ContShellTrace.HitPos + ((ContShellTrace.HitPos-Start):GetNormalized() * 500), Shell.DakGun)
							util.Decal( "Blood", ContShellTrace.HitPos - ((ContShellTrace.HitPos-Start):GetNormalized() * 5), ContShellTrace.HitPos + ((ContShellTrace.HitPos-Start):GetNormalized() * 500), HitEnt)
						end
						util.Decal( "Impact.Concrete", ContShellTrace.HitPos - ((ContShellTrace.HitPos-Start):GetNormalized() * 5), ContShellTrace.HitPos + ((ContShellTrace.HitPos-Start):GetNormalized() * 5), Shell.DakGun)
						util.Decal( "Impact.Concrete", ContShellTrace.HitPos + ((ContShellTrace.HitPos-Start):GetNormalized() * 5), ContShellTrace.HitPos - ((ContShellTrace.HitPos-Start):GetNormalized() * 5), Shell.DakGun)
						if HitEnt:GetClass() == "dak_crew" then
							util.Decal( "Blood", ContShellTrace.HitPos - ((ContShellTrace.HitPos-Start):GetNormalized() * 5), ContShellTrace.HitPos + ((ContShellTrace.HitPos-Start):GetNormalized() * 500), Shell.DakGun)
							util.Decal( "Blood", ContShellTrace.HitPos - ((ContShellTrace.HitPos-Start):GetNormalized() * 5), ContShellTrace.HitPos + ((ContShellTrace.HitPos-Start):GetNormalized() * 500), HitEnt)
						end
						Shell.DakVelocity = Shell.DakVelocity - (Shell.DakVelocity * (EffArmor / Shell.DakPenetration))
						Shell.Pos = ContShellTrace.HitPos

						Shell.DakDamage = Shell.DakDamage-Shell.DakDamage * (EffArmor / Shell.DakPenetration)
						Shell.DakPenetration = Shell.DakPenetration-EffArmor
						if Shattered == 1 then
							Shell.DakDamage = Shell.DakDamage * 0.5
							Shell.DakPenetration = Shell.DakPenetration * 0.5
							Shell.DakVelocity = Shell.DakVelocity * 0.5
						end
						--soundhere penetrate sound
						if Shell.DakIsPellet then
							sound.Play( Shell.DakPenSounds[math.random(1,#Shell.DakPenSounds)], ContShellTrace.HitPos, 100, 150, 0.25 )
						else
							sound.Play( Shell.DakPenSounds[math.random(1,#Shell.DakPenSounds)], ContShellTrace.HitPos, 100, 100, 1 )
						end

						if Shell.DakShellType == "HEAT" or Shell.DakShellType == "HEATFS" or Shell.DakShellType == "ATGM" then
							Shell.LifeTime = 0
							DTHEAT(ContShellTrace.HitPos,HitEnt,Shell.DakCaliber,Shell.DakPenetration,Shell.DakDamage,Shell.DakGun.DakOwner,Shell)
							Shell.HeatPen = true

							Shell.Pos = ContShellTrace.HitPos
							Shell.LifeTime = 0
							Shell.DakVelocity = Vector(0,0,0)
							Shell.DakDamage = 0
							Shell.ExplodeNow = true
						else
							DTShellContinue(Start,End,Shell,Normal)
							Shell.LifeTime = 0
						end
					else
						if Shell.DakShellType == "HESH" then
							if HitEnt.IsComposite == 1 or (HitEnt:CPPIGetOwner() ~= nil and HitEnt:CPPIGetOwner():IsWorld()) then
								if Shell.DakCaliber * 1.25 > CompArmor and HitAng < 80 then
									Shell.Filter[#Shell.Filter + 1] = HitEnt
									Shell.HeatPen = true
									DTSpall(ContShellTrace.HitPos,EffArmor,HitEnt,Shell.DakCaliber,Shell.DakCaliber * 1.25,Shell.DakGun.DakOwner,Shell,((ContShellTrace.HitPos - (Normal * 2)) - ContShellTrace.HitPos):Angle():Forward())
									Shell.Pos = HitPos
									Shell.LifeTime = 0
									Shell.DakVelocity = Vector(0,0,0)
									Shell.DakDamage = 0
									Shell.ExplodeNow = true
								end
							else
								if Shell.DakCaliber * 1.25 > DTTE.GetArmor(HitEnt, Shell.DakShellType, Shell.DakCaliber) and HitAng < 80 then
									Shell.Filter[#Shell.Filter + 1] = HitEnt
									Shell.HeatPen = true
									DTSpall(ContShellTrace.HitPos,EffArmor,HitEnt,Shell.DakCaliber,Shell.DakCaliber * 1.25,Shell.DakGun.DakOwner,Shell,((ContShellTrace.HitPos - (Normal * 2)) - ContShellTrace.HitPos):Angle():Forward())
									Shell.Pos = HitPos
									Shell.LifeTime = 0
									Shell.DakVelocity = Vector(0,0,0)
									Shell.DakDamage = 0
									Shell.ExplodeNow = true
								end
							end
						end
						if Shell.DakShellType == "HE" then
							if HitEnt.IsComposite == 1 or (HitEnt:CPPIGetOwner() ~= nil and HitEnt:CPPIGetOwner():IsWorld()) then
								if Shell.DakFragPen * 10 > CompArmor and HitAng < 70 then
									Shell.Filter[#Shell.Filter + 1] = HitEnt
									Shell.HeatPen = true
									DTSpall(ContShellTrace.HitPos,EffArmor,HitEnt,Shell.DakCaliber,Shell.DakFragPen * 10,Shell.DakGun.DakOwner,Shell,((ContShellTrace.HitPos - (Normal * 2)) - ContShellTrace.HitPos):Angle():Forward())
									Shell.Pos = HitPos
									Shell.LifeTime = 0
									Shell.DakVelocity = Vector(0,0,0)
									Shell.DakDamage = 0
									Shell.ExplodeNow = true
								end
							else
								if Shell.DakFragPen * 10 > DTTE.GetArmor(HitEnt, Shell.DakShellType, Shell.DakCaliber) and HitAng < 70 then
									Shell.Filter[#Shell.Filter + 1] = HitEnt
									Shell.HeatPen = true
									DTSpall(ContShellTrace.HitPos,EffArmor,HitEnt,Shell.DakCaliber,Shell.DakFragPen * 10,Shell.DakGun.DakOwner,Shell,((ContShellTrace.HitPos - (Normal * 2)) - ContShellTrace.HitPos):Angle():Forward())
									Shell.Pos = HitPos
									Shell.LifeTime = 0
									Shell.DakVelocity = Vector(0,0,0)
									Shell.DakDamage = 0
									Shell.ExplodeNow = true
								end
							end
						end
						if CanDamage(HitEnt) then
							if HitEnt:GetClass() == "dak_tegun" or HitEnt:GetClass() == "dak_temachinegun" or HitEnt:GetClass() == "dak_teautogun" then
								DTDealDamage(HitEnt,Shell.DakDamage * 0.25 * 0.001,Shell.DakGun)
								DTDealDamage(HitEnt.Controller,Shell.DakDamage * 0.25,Shell.DakGun)
							else
								DTDealDamage(HitEnt,Shell.DakDamage * 0.25,Shell.DakGun)
							end
						end
						--print("Shell Hit Function Secondary Impact Damage Fail Pen")
						--print(Shell.DakDamage * 0.25)
						if Shell.DakIsFlame == 1 then
							if SA then
								if HitEnt.DakArmor > (7.8125 * (HitEnt:GetPhysicsObject():GetMass() / 4.6311781) * (288 / SA)) * 0.5 then
									if HitEnt.DakBurnStacks == nil then
										HitEnt.DakBurnStacks = 0
									end
									HitEnt.DakBurnStacks = HitEnt.DakBurnStacks + 1
								end
							end
						end
						if (HitEnt:IsValid() and HitEnt.Base ~= "base_nextbot" and HitEnt:GetClass() ~= "prop_ragdoll") and Shell.DakIsFlame ~= 1 then
							HitEnt:DTShellApplyForce(ContShellTrace.HitPos,Normal,Shell)
						end
						local effectdata = EffectData()
						if Shell.DakIsFlame == 1 then
							DTTE.SpawnFire(ContShellTrace.HitPos, Shell.DakGun.DakOwner, Shell.DakGun)
						else
							Shell.Filter[#Shell.Filter + 1] = HitEnt
							if Shell.DakDamage >= 0 then
								util.Decal( "Impact.Glass", ContShellTrace.HitPos - ((ContShellTrace.HitPos-Start):GetNormalized() * 5), ContShellTrace.HitPos + ((ContShellTrace.HitPos-Start):GetNormalized() * 5), Shell.DakGun)
								if HitEnt:GetClass() == "dak_crew" or HitEnt:GetClass() == "dak_gamemode_bot2" or HitEnt:IsPlayer() or HitEnt:IsNPC() then
									util.Decal( "Blood", ContShellTrace.HitPos - ((ContShellTrace.HitPos-Start):GetNormalized() * 5), ContShellTrace.HitPos + ((ContShellTrace.HitPos-Start):GetNormalized() * 500), Shell.DakGun)
								end
								local Bounce = 0
								if (90-HitAng) <= 45 then
									local RNG = math.random(0,100)
									if (90-HitAng) <= 45 and (90-HitAng) > 30 then
										if RNG <= 25 then Bounce = 1 end
									end
									if (90-HitAng) <= 30 and (90-HitAng) > 20 then
										if RNG <= 50 then Bounce = 1 end
									end
									if (90-HitAng) <= 20 and (90-HitAng) > 10 then
										if RNG <= 75 then Bounce = 1 end
									end
									if (90-HitAng) <= 10 then
										Bounce = 1
									end
								else
									Bounce = 0
								end
								Bounce = 0
								if Shell.DakShellType == "HESH" or Shell.DakShellType == "ATGM" or Shell.DakIsFlame == 1 then Bounce = 0 end
								if Bounce == 1 then
									effectdata:SetOrigin(ContShellTrace.HitPos)
									effectdata:SetEntity(Shell.DakGun)
									effectdata:SetAttachment(1)
									effectdata:SetMagnitude(.5)
									effectdata:SetScale(Shell.DakCaliber * 0.25)
									util.Effect("dakteshellbounce", effectdata, true, true)
									local BounceSounds = {}
									if Shell.DakCaliber < 20 then
										BounceSounds = {"weapons/fx/rics/ric1.wav","weapons/fx/rics/ric2.wav","weapons/fx/rics/ric3.wav","weapons/fx/rics/ric4.wav","weapons/fx/rics/ric5.wav"}
									else
										BounceSounds = {"daktanks/dakrico1.mp3","daktanks/dakrico2.mp3","daktanks/dakrico3.mp3","daktanks/dakrico4.mp3","daktanks/dakrico5.mp3","daktanks/dakrico6.mp3"}
									end
									if Shell.DakIsPellet then
										sound.Play( BounceSounds[math.random(1,#BounceSounds)], ContShellTrace.HitPos, 100, 150, 0.25 )
									else
										sound.Play( BounceSounds[math.random(1,#BounceSounds)], ContShellTrace.HitPos, 100, 100, 1 )
									end
									Shell.DakVelocity = Shell.DakBaseVelocity * 0.5 * (Normal + ((ContShellTrace.HitPos-Start):GetNormalized() * 1 * (45 / (90 - HitAng)))):GetNormalized() + Angle(math.Rand(-1,1),math.Rand(-1,1),math.Rand(-1,1)):Forward()
									Shell.DakPenetration = Shell.DakPenetration * 0.5
									Shell.DakDamage = Shell.DakDamage * 0.5
									Shell.LifeTime = 0.0
									Shell.Pos = ContShellTrace.HitPos + (Normal * 2 * Shell.DakCaliber * 0.02)
									Shell.ShellThinkTime = 0
									Shell.JustBounced = 1
									DTShellContinue(ContShellTrace.HitPos + (Normal * 2 * Shell.DakCaliber * 0.02),Shell.DakVelocity:GetNormalized() * 1000,Shell,Normal,true)
									Shell.FinishedBouncing = 1
								else
									Shell.Crushed = 1
									effectdata:SetOrigin(ContShellTrace.HitPos)
									effectdata:SetEntity(Shell.DakGun)
									effectdata:SetAttachment(1)
									effectdata:SetMagnitude(.5)
									effectdata:SetScale(Shell.DakCaliber * (Shell.DakBaseVelocity / 29527.6))
									if Shell.IsFrag then
									else
										util.Effect("dakteshellimpact", effectdata, true, true)
									end
									local BounceSounds = {}
									if Shell.DakCaliber < 20 then
										BounceSounds = {"daktanks/dakrico1.mp3","daktanks/dakrico2.mp3","daktanks/dakrico3.mp3","daktanks/dakrico4.mp3","daktanks/dakrico5.mp3","daktanks/dakrico6.mp3"}
									else
										BounceSounds = {"daktanks/dakexp1.mp3","daktanks/dakexp2.mp3","daktanks/dakexp3.mp3","daktanks/dakexp4.mp3"}
									end
									if Shell.DakIsPellet then
										sound.Play( BounceSounds[math.random(1,#BounceSounds)], ContShellTrace.HitPos, 100, 150, 0.25 )
									else
										sound.Play( BounceSounds[math.random(1,#BounceSounds)], ContShellTrace.HitPos, 100, 100, 1 )
									end
									Shell.DakVelocity = Shell.DakBaseVelocity * 0.025 * (Normal + ((ContShellTrace.HitPos-Start):GetNormalized() * 1 * (45 / (90 - HitAng)))):GetNormalized() --+ Angle(math.Rand(-1,1),math.Rand(-1,1),math.Rand(-1,1))
									Shell.DakPenetration = 0
									Shell.DakDamage = 0
									Shell.LifeTime = 0.0
									Shell.Pos = ContShellTrace.HitPos
									Shell.RemoveNow = 1
									if Shell.DakExplosive then
										Shell.Pos = ContShellTrace.HitPos
										Shell.LifeTime = 0
										Shell.DakVelocity = Vector(0,0,0)
										Shell.DakDamage = 0
										Shell.ExplodeNow = true
									end
								end
							end
						end
					end

					DestroyEnt(HitEnt, Shell.Filter, Shell)
				end
			end
			if HitEnt:IsValid() then
				if HitEnt:IsPlayer() or HitEnt:IsNPC() or HitEnt.Base == "base_nextbot" then
					Shell.Pos = HitPos
					if HitEnt:GetClass() == "dak_bot" then
						HitEnt:SetHealth(HitEnt:Health() - Shell.DakDamage * 500)
						if HitEnt:Health() <= 0 and HitEnt.revenge == 0 then
							--local body = ents.Create( "prop_ragdoll" )
							body:SetPos( HitEnt:GetPos() )
							body:SetModel( HitEnt:GetModel() )
							body:Spawn()
							body.DakHealth = 1000000
							body.DakMaxHealth = 1000000
							if Shell.DakIsFlame == 1 then
								body:Ignite(10,1)
							end
							--HitEnt:Remove()
							local SoundList = {"npc/metropolice/die1.wav","npc/metropolice/die2.wav","npc/metropolice/die3.wav","npc/metropolice/die4.wav","npc/metropolice/pain4.wav"}
							body:EmitSound( SoundList[math.random(5)], 100, 100, 1, 2 )
							timer.Simple( 5, function()
								body:Remove()
							end )
						end
					else
						local Pain = DamageInfo()
						Pain:SetDamageForce( Shell.DakVelocity:GetNormalized() * (2500 * Shell.DakCaliber * (Shell.DakBaseVelocity / 29527.6)) )
						Pain:SetDamage( Shell.DakDamage * 250 )
						if Shell.DakGun.DakOwner and Shell and Shell.DakGun then
							Pain:SetAttacker( Shell.DakGun.DakOwner )
							Pain:SetInflictor( Shell.DakGun )
						else
							Pain:SetAttacker( game.GetWorld() )
							Pain:SetInflictor( game.GetWorld() )
						end
						Pain:SetReportedPosition( ContShellTrace.HitPos )
						Pain:SetDamagePosition( HitEnt:GetPos() )
						if Shell.DakIsFlame == 1 then
							Pain:SetDamageType(DMG_BURN)
						else
							Pain:SetDamageType(DMG_CRUSH)
						end
						HitEnt:TakeDamageInfo( Pain )
					end
					if HitEnt:Health() <= 0 and Shell.DakIsFlame ~= 1 then
						local effectdata = EffectData()
						effectdata:SetOrigin(ContShellTrace.HitPos)
						effectdata:SetEntity(HitEnt)
						effectdata:SetAttachment(1)
						effectdata:SetMagnitude(.5)
						effectdata:SetScale(Shell.DakCaliber * 0.25)
						if HitEnt:GetClass() ~= "dak_gamemode_bot2" and not(HitEnt:IsPlayer()) and not(HitEnt:IsNPC()) then
							util.Effect("dakteshellpenetrate", effectdata, true, true) --bloodeffectneeded
						else
							util.Decal( "Blood", ContShellTrace.HitPos - ((ContShellTrace.HitPos-Start):GetNormalized() * 5), ContShellTrace.HitPos + ((ContShellTrace.HitPos-Start):GetNormalized() * 500), Shell.DakGun)
							util.Decal( "Blood", ContShellTrace.HitPos - ((ContShellTrace.HitPos-Start):GetNormalized() * 5), ContShellTrace.HitPos + ((ContShellTrace.HitPos-Start):GetNormalized() * 500), HitEnt)
						end
						util.Decal( "Impact.Concrete", ContShellTrace.HitPos - ((ContShellTrace.HitPos-Start):GetNormalized() * 5), ContShellTrace.HitPos + ((ContShellTrace.HitPos-Start):GetNormalized() * 5), Shell.DakGun)
						util.Decal( "Impact.Concrete", ContShellTrace.HitPos + ((ContShellTrace.HitPos-Start):GetNormalized() * 5), ContShellTrace.HitPos - ((ContShellTrace.HitPos-Start):GetNormalized() * 5), Shell.DakGun)
						if HitEnt:GetClass() == "dak_crew" then
							util.Decal( "Blood", ContShellTrace.HitPos - ((ContShellTrace.HitPos-Start):GetNormalized() * 5), ContShellTrace.HitPos + ((ContShellTrace.HitPos-Start):GetNormalized() * 500), Shell.DakGun)
							util.Decal( "Blood", ContShellTrace.HitPos - ((ContShellTrace.HitPos-Start):GetNormalized() * 5), ContShellTrace.HitPos + ((ContShellTrace.HitPos-Start):GetNormalized() * 500), HitEnt)
						end
						Shell.Filter[#Shell.Filter + 1] = HitEnt
						if Shell.salvage then
							Shell.Filter[#Shell.Filter + 1] = Shell.salvage
						end
						DTShellContinue(Start,End,Shell,Normal)
						--soundhere penetrate human sound
						if Shell.DakIsPellet then
							sound.Play( Shell.DakPenSounds[math.random(1,#Shell.DakPenSounds)], ContShellTrace.HitPos, 100, 150, 0.25 )
						else
							sound.Play( Shell.DakPenSounds[math.random(1,#Shell.DakPenSounds)], ContShellTrace.HitPos, 100, 100, 1 )
						end
					else
						local effectdata = EffectData()
						if Shell.DakIsFlame == 1 then
							DTTE.SpawnFire(ContShellTrace.HitPos, Shell.DakGun.DakOwner, Shell.DakGun)
						else
							effectdata:SetOrigin(ContShellTrace.HitPos)
							effectdata:SetEntity(Shell.DakGun)
							effectdata:SetAttachment(1)
							effectdata:SetMagnitude(.5)
							effectdata:SetScale(Shell.DakCaliber * (Shell.DakBaseVelocity / 29527.6))
							if Shell.IsFrag then
							else
								util.Effect("dakteshellimpact", effectdata, true, true) --bloodeffectneeded
							end
							util.Decal( "Impact.Concrete", ContShellTrace.HitPos - ((ContShellTrace.HitPos-Start):GetNormalized() * 5), ContShellTrace.HitPos + ((ContShellTrace.HitPos-Start):GetNormalized() * 5), Shell.DakGun)
							if HitEnt:GetClass() == "dak_crew" or HitEnt:GetClass() == "dak_gamemode_bot2" or HitEnt:IsPlayer() or HitEnt:IsNPC() then
								util.Decal( "Blood", ContShellTrace.HitPos - ((ContShellTrace.HitPos-Start):GetNormalized() * 5), ContShellTrace.HitPos + ((ContShellTrace.HitPos-Start):GetNormalized() * 500), Shell.DakGun)
							end
							local ExpSounds = {}
							if Shell.DakCaliber < 20 then
								ExpSounds = {"physics/surfaces/sand_impact_bullet1.wav","physics/surfaces/sand_impact_bullet2.wav","physics/surfaces/sand_impact_bullet3.wav","physics/surfaces/sand_impact_bullet4.wav"}
							else
								ExpSounds = {"daktanks/dakexp1.mp3","daktanks/dakexp2.mp3","daktanks/dakexp3.mp3","daktanks/dakexp4.mp3"}
							end

							if Shell.DakIsPellet then
								sound.Play( ExpSounds[math.random(1,#ExpSounds)], ContShellTrace.HitPos, 100, 150, 0.25 )
							else
								sound.Play( ExpSounds[math.random(1,#ExpSounds)], ContShellTrace.HitPos, 100, 100, 1 )
							end
						end
						Shell.RemoveNow = 1
						--if Shell.DakExplosive then
						--	Shell.ExplodeNow = true
						--end
						Shell.LifeTime = 0
						Shell.DakVelocity = Vector(0,0,0)
						Shell.DakDamage = 0
					end
				end
			end
			if HitEnt:IsWorld() or Shell.ExplodeNow == true then
				local Penned, Exit, Dist = DTTE.WorldPen(ContShellTrace.HitPos,Shell.DakVelocity:GetNormalized(),Shell.DakPenetration,Shell.Filter,Shell.DakCaliber)
				if Shell.DakShellType == "HEAT" or Shell.DakShellType == "HEATFS" or Shell.DakShellType == "ATGM" or Shell.DakIsFlame == 1 then
					Shell.Pos = Exit
					Shell.LifeTime = 0
					Shell.DakVelocity = Vector(0,0,0)
					Shell.DakDamage = 0
					Shell.ExplodeNow = true
				else
					if Penned then
						local effectdata = EffectData()
						effectdata:SetOrigin(ContShellTrace.HitPos)
						effectdata:SetEntity(HitEnt)
						effectdata:SetAttachment(1)
						effectdata:SetMagnitude(.5)
						effectdata:SetScale(Shell.DakCaliber * 0.25)
						util.Effect("dakteshellpenetrate", effectdata, true, true)
						if Shell.DakIsPellet then
							sound.Play( Shell.DakPenSounds[math.random(1,#Shell.DakPenSounds)], ContShellTrace.HitPos, 100, 150, 0.25 )
						else
							sound.Play( Shell.DakPenSounds[math.random(1,#Shell.DakPenSounds)], ContShellTrace.HitPos, 100, 100, 1 )
						end
						util.Decal( "Impact.Concrete", ContShellTrace.HitPos, Exit, Shell.DakGun)
						util.Decal( "Impact.Concrete", Exit, ContShellTrace.HitPos, Shell.DakGun)
						Shell.Pos = Exit
						DTShellContinue(Exit,End,Shell,Normal) --set new start a bit further away to prevent recurse
						Shell.LifeTime = 0
						Shell.DakVelocity = Shell.DakVelocity - (Shell.DakVelocity * (Dist / Shell.DakPenetration))
						Shell.DakDamage = Shell.DakDamage - (Shell.DakDamage * (Dist / Shell.DakPenetration))
						Shell.DakPenetration = Shell.DakPenetration - (Shell.DakPenetration * (Dist / Shell.DakPenetration))
					else
						Shell.Pos = Exit
						Shell.LifeTime = 0
						Shell.DakVelocity = Vector(0,0,0)
						Shell.DakDamage = 0
						Shell.ExplodeNow = true
					end
				end
				if Penned == false then
					if Shell.DakExplosive then
						local effectdata3 = EffectData()
						effectdata3:SetOrigin(ContShellTrace.HitPos)
						effectdata3:SetEntity(Shell.DakGun)
						effectdata3:SetAttachment(1)
						effectdata3:SetMagnitude(.5)
						effectdata3:SetScale(Shell.DakBlastRadius)
						local newertrace = {}
							newertrace.start = ContShellTrace.HitPos + Vector(0,0,100)
							newertrace.endpos = ContShellTrace.HitPos - Vector(0,0,100)
							newertrace.filter = Shell.Filter
							newertrace.mins = Vector(-Shell.DakCaliber * 0.02,-Shell.DakCaliber * 0.02,-Shell.DakCaliber * 0.02)
							newertrace.maxs = Vector(Shell.DakCaliber * 0.02,Shell.DakCaliber * 0.02,Shell.DakCaliber * 0.02)
						local EffectTrace = util.TraceHull( newertrace )
						effectdata3:SetNormal( EffectTrace.HitNormal )
						if Shell.DakShellType == "SM" then
							util.Effect("daktescalingsmoke", effectdata3, true, true)
						else
							util.Effect("daktescalingexplosion", effectdata3, true, true)
						end

						Shell.DakGun:SetNWFloat("ExpDamage",Shell.DakSplashDamage)
						if Shell.DakCaliber >= 75 then
							Shell.DakGun:SetNWBool("Exploding",true)
							timer.Create( "ExplodeTimer" .. Shell.DakGun:EntIndex(), 0.1, 1, function()
								Shell.DakGun:SetNWBool("Exploding",false)
							end)
						else
							local ExpSounds = {}
							if Shell.DakCaliber < 20 then
								ExpSounds = {"physics/surfaces/sand_impact_bullet1.wav","physics/surfaces/sand_impact_bullet2.wav","physics/surfaces/sand_impact_bullet3.wav","physics/surfaces/sand_impact_bullet4.wav"}
							else
								ExpSounds = {"daktanks/dakexp1.mp3","daktanks/dakexp2.mp3","daktanks/dakexp3.mp3","daktanks/dakexp4.mp3"}
							end
							sound.Play( ExpSounds[math.random(1,#ExpSounds)], ContShellTrace.HitPos, 100, 100, 1 )
						end
						if Shell.Exploded ~= true then
							if Shell.DakShellType == "HESH" then
								DTShockwave(ContShellTrace.HitPos + (Normal * 2),Shell.DakSplashDamage,Shell.DakBlastRadius,Shell.DakFragPen,Shell.DakGun.DakOwner,Shell)
							else
								DTShockwave(ContShellTrace.HitPos + (Normal * 2),Shell.DakSplashDamage * 0.5,Shell.DakBlastRadius,Shell.DakFragPen,Shell.DakGun.DakOwner,Shell)
								--DTExplosion(ContShellTrace.HitPos + (Normal * 2),Shell.DakSplashDamage * 0.5,Shell.DakBlastRadius,Shell.DakCaliber,Shell.DakFragPen,Shell.DakGun.DakOwner,Shell)
							end
						end
						Shell.Exploded = true
					else
						local effectdata = EffectData()
						if Shell.DakIsFlame == 1 then
							DTTE.SpawnFire(ContShellTrace.HitPos, Shell.DakGun.DakOwner, Shell.DakGun)
						else
							effectdata:SetOrigin(ContShellTrace.HitPos)
							effectdata:SetEntity(Shell.DakGun)
							effectdata:SetAttachment(1)
							effectdata:SetMagnitude(.5)
							effectdata:SetScale(Shell.DakCaliber * (Shell.DakBaseVelocity / 29527.6))
							if Shell.IsFrag then
							else
								util.Effect("dakteshellimpact", effectdata, true, true)
							end
							util.Decal( "Impact.Concrete", ContShellTrace.HitPos - ((ContShellTrace.HitPos-Start):GetNormalized() * 5), ContShellTrace.HitPos + ((ContShellTrace.HitPos-Start):GetNormalized() * 5), Shell.DakGun)
							if HitEnt:GetClass() == "dak_crew" or HitEnt:GetClass() == "dak_gamemode_bot2" or HitEnt:IsPlayer() or HitEnt:IsNPC() then
								util.Decal( "Blood", ContShellTrace.HitPos - ((ContShellTrace.HitPos-Start):GetNormalized() * 5), ContShellTrace.HitPos + ((ContShellTrace.HitPos-Start):GetNormalized() * 500), Shell.DakGun)
							end
							local ExpSounds = {}
							if Shell.DakCaliber < 20 then
								ExpSounds = {"physics/surfaces/sand_impact_bullet1.wav","physics/surfaces/sand_impact_bullet2.wav","physics/surfaces/sand_impact_bullet3.wav","physics/surfaces/sand_impact_bullet4.wav"}
							else
								ExpSounds = {"daktanks/dakexp1.mp3","daktanks/dakexp2.mp3","daktanks/dakexp3.mp3","daktanks/dakexp4.mp3"}
							end

							if Shell.DakIsPellet then
								sound.Play( ExpSounds[math.random(1,#ExpSounds)], ContShellTrace.HitPos, 100, 150, 0.25 )
							else
								sound.Play( ExpSounds[math.random(1,#ExpSounds)], ContShellTrace.HitPos, 100, 100, 1 )
							end
						end
					end
					Shell.RemoveNow = 1
					if Shell.DakExplosive then
						Shell.ExplodeNow = true
					end
					Shell.LifeTime = 0
					Shell.DakVelocity = Vector(0,0,0)
					Shell.DakDamage = 0
				end
			end

			if Shell.DakPenetration <= 0 then
				Shell.Spent = 1
				if Shell.DieTime == nil then
					Shell.DieTime = CurTime()
				end
			end
		end
	end
end

local function ContEXP(Filter, IgnoreEnt, Pos, Damage, Radius, Caliber, Pen, Owner, Direction, Shell, Recurses)
	if Recurses == nil then Recurses = 1 end
	Recurses = Recurses + 1
	if Recurses >= 25 then
		print("ERROR: Entity Explosion Recurse Loop")
		return
	end

	local traces = math.Round(Caliber / 2)
	local trace = {}
		trace.start = Pos
		trace.endpos = Pos + Direction * Radius * 10
		trace.filter = Filter
		trace.mins = Vector( - (Caliber / traces) * 0.02, - (Caliber / traces) * 0.02, - (Caliber / traces) * 0.02)
		trace.maxs = Vector((Caliber / traces) * 0.02,(Caliber / traces) * 0.02,(Caliber / traces) * 0.02)
	local ExpTrace = util.TraceHull( trace )
	local ExpTraceLine = util.TraceLine( trace )

	if hook.Run("DakTankDamageCheck", ExpTrace.Entity, Owner, Shell.DakGun) == false then return end
	if ExpTrace.HitPos:Distance(Pos) > Radius * 2 then return end
	--decals don't like using the adjusted by normal Pos
	util.Decal( "Impact.Concrete", ExpTrace.HitPos - (Direction * 5), ExpTrace.HitPos + (Direction * 5), IgnoreEnt)
	if ExpTrace.Entity.DakHealth == nil then
		DTTE.SetupNewEnt(ExpTrace.Entity)
	end
	if ExpTrace.Entity.DakDead == true then
		Filter[#Filter + 1] = ExpTrace.Entity
		ContEXP(Filter, ExpTrace.Entity, Pos, Damage, Radius, Caliber, Pen, Owner, Direction, Shell, Recurses)
	end
	if (ExpTrace.Entity:IsValid() and not(ExpTrace.Entity:IsPlayer()) and not(ExpTrace.Entity:IsNPC()) and ExpTrace.Entity.Base ~= "base_nextbot" and (ExpTrace.Entity.DakHealth ~= nil and ExpTrace.Entity.DakHealth > 0)) or (ExpTrace.Entity.DakName == "Damaged Component") then
		if ExpTrace.Entity:GetClass() == "dak_crew" or ExpTrace.Entity:GetClass() == "dak_gamemode_bot2" or ExpTrace.Entity:IsPlayer() or ExpTrace.Entity:IsNPC() then
			util.Decal( "Blood", ExpTrace.HitPos - (Direction * 5), ExpTrace.HitPos + (Direction * 500), IgnoreEnt)
		end
		if (DTTE.CheckClip(ExpTrace.Entity,ExpTrace.HitPos)) or (ExpTrace.Entity:GetPhysicsObject():GetMass() <= 1 or (ExpTrace.Entity.DakIsTread == 1) and not(ExpTrace.Entity:IsVehicle()) and ExpTrace.Entity.IsDakTekFutureTech ~= 1) then
			if ExpTrace.Entity.DakArmor == nil or ExpTrace.Entity.DakBurnStacks == nil then
				DTTE.SetupNewEnt(ExpTrace.Entity)
			end
			local SA = ExpTrace.Entity:GetPhysicsObject():GetSurfaceArea()
			if ExpTrace.Entity.IsDakTekFutureTech == 1 then
				ExpTrace.Entity.DakArmor = 1000
			else
				if SA == nil then
					--Volume = (4 / 3) * math.pi*math.pow( ExpTrace.Entity:OBBMaxs().x, 3 )
					ExpTrace.Entity.DakArmor = ExpTrace.Entity:OBBMaxs().x / 2
					ExpTrace.Entity.DakIsTread = 1
				else
					if ExpTrace.Entity:GetClass() == "prop_physics" then
						DTTE.ArmorSanityCheck(ExpTrace.Entity)
					end
				end
			end
			Filter[#Filter + 1] = IgnoreEnt
			ContEXP(Filter, ExpTrace.Entity, Pos, Damage, Radius, Caliber, Pen, Owner, Direction, Shell, Recurses)
		else
			if ExpTrace.Entity.DakArmor == nil or ExpTrace.Entity.DakBurnStacks == nil then
				DTTE.SetupNewEnt(ExpTrace.Entity)
			end
			local SA = ExpTrace.Entity:GetPhysicsObject():GetSurfaceArea()
			if ExpTrace.Entity.IsDakTekFutureTech == 1 then
				ExpTrace.Entity.DakArmor = 1000
			else
				if SA == nil then
					--Volume = (4 / 3) * math.pi*math.pow( ExpTrace.Entity:OBBMaxs().x, 3 )
					ExpTrace.Entity.DakArmor = ExpTrace.Entity:OBBMaxs().x / 2
					ExpTrace.Entity.DakIsTread = 1
				else
					if ExpTrace.Entity:GetClass() == "prop_physics" then
						DTTE.ArmorSanityCheck(ExpTrace.Entity)
					end
				end
			end

			ExpTrace.Entity.DakLastDamagePos = ExpTrace.HitPos
			if CanDamage(ExpTrace.Entity) then
				if ExpTrace.Entity:GetClass() == "dak_tegun" or ExpTrace.Entity:GetClass() == "dak_temachinegun" or ExpTrace.Entity:GetClass() == "dak_teautogun" then
					DTDealDamage(ExpTrace.Entity, -math.Clamp((Damage / traces) * (Pen / DTTE.GetArmor(ExpTrace.Entity, "HE", Caliber)) * 0.001,0,DTTE.GetArmor(ExpTrace.Entity, "HE", Caliber) * 2),self,true)
					DTDealDamage(ExpTrace.Entity.Controller, -math.Clamp((Damage / traces) * (Pen / DTTE.GetArmor(ExpTrace.Entity, "HE", Caliber)),0,DTTE.GetArmor(ExpTrace.Entity, "HE", Caliber) * 2),self,true)
				else
					if ExpTrace.Entity.IsERA == 1 then
						DTDealDamage(ExpTrace.Entity, math.Clamp((Damage * 10 / traces) * (Pen / EffArmor),0,EffArmor * 2),self,true)
					else
						DTDealDamage(ExpTrace.Entity, math.Clamp((Damage / traces) * (Pen / DTTE.GetArmor(ExpTrace.Entity, "HE", Caliber)),0,DTTE.GetArmor(ExpTrace.Entity, "HE", Caliber) * 2),self,true)
					end
				end
			end
			local EffArmor = (DTTE.GetArmor(ExpTrace.Entity, Shell.DakShellType, 2) / math.abs(ExpTraceLine.HitNormal:Dot(Direction)))
			if ExpTrace.Entity.IsComposite == 1 or (ExpTrace.Entity:CPPIGetOwner() ~= nil and ExpTrace.Entity:CPPIGetOwner():IsWorld()) then
				if ExpTrace.Entity.EntityMods == nil then ExpTrace.Entity.EntityMods = {} end
				if ExpTrace.Entity.EntityMods.CompKEMult == nil then ExpTrace.Entity.EntityMods.CompKEMult = 9.2 end
				if ExpTrace.Entity.EntityMods.CompCEMult == nil then ExpTrace.Entity.EntityMods.CompCEMult = 18.4 end
				EffArmor = (ExpTrace.Entity:GetPhysicsObject():GetVolume() ^ (1 / 3)) * ExpTrace.Entity.EntityMods.CompCEMult--DTTE.CompositesTrace( ExpTrace.Entity, ExpTrace.HitPos, ExpTrace.Normal, Shell.Filter ) * ExpTrace.Entity.EntityMods.CompKEMult
			end
			if EffArmor < Pen and ExpTrace.Entity.IsDakTekFutureTech == nil then
				util.Decal( "Impact.Concrete", ExpTrace.HitPos + (Direction * 5), ExpTrace.HitPos - (Direction * 5), IgnoreEnt)
				if ExpTrace.Entity:GetClass() == "dak_crew" or ExpTrace.Entity:GetClass() == "dak_gamemode_bot2" or ExpTrace.Entity:IsPlayer() or ExpTrace.Entity:IsNPC() then
					util.Decal( "Blood", ExpTrace.HitPos - (Direction * 5), ExpTrace.HitPos + (Direction * 500), IgnoreEnt)
					util.Decal( "Blood", ExpTrace.HitPos - (Direction * 5), ExpTrace.HitPos + (Direction * 500), ExpTrace.Entity)
				end
				Filter[#Filter + 1] = IgnoreEnt
				ContEXP(Filter, ExpTrace.Entity, Pos, Damage * (1 - EffArmor / Pen), Radius, Caliber, Pen - EffArmor, Owner, Direction, Shell, Recurses)
			end

			DestroyEnt(ExpTrace.Entity, Filter, Shell)
		end
		if (ExpTrace.Entity:IsValid()) and not(ExpTrace.Entity:IsNPC()) and not(ExpTrace.Entity:IsPlayer()) then
			ExpTrace.Entity:DTHEApplyForce(ExpTrace.HitPos, Pos, Damage, traces, 0.35)
		end
	end

	KillEnemy(ExpTrace.Entity, Owner, Shell, traces, Damage, 500)
end

function DTAPHE(Pos, Damage, Radius, Caliber, Pen, Owner, Shell, HitEnt)
	local traces = math.Round(Caliber / 2)
	local Filter = {HitEnt}
	for i = 1, traces do
		local Direction = (Angle(math.Rand(-Caliber * 0.75,Caliber * 0.75),math.Rand(-Caliber * 0.75,Caliber * 0.75),math.Rand(-Caliber * 0.75,Caliber * 0.75))):Forward() + Shell.DakVelocity:GetNormalized()
		local trace = {}
			trace.start = Pos
			trace.endpos = Pos + Direction * Radius * 10
			trace.filter = Filter
			trace.mins = Vector( - (Caliber / traces) * 0.02, - (Caliber / traces) * 0.02, - (Caliber / traces) * 0.02)
			trace.maxs = Vector((Caliber / traces) * 0.02,(Caliber / traces) * 0.02,(Caliber / traces) * 0.02)
		local ExpTrace = util.TraceHull( trace )
		local ExpTraceLine = util.TraceLine( trace )

		if hook.Run("DakTankDamageCheck", ExpTrace.Entity, Owner, Shell.DakGun) ~= false and ExpTrace.HitPos:Distance(Pos) <= Radius then
			--decals don't like using the adjusted by normal Pos
			util.Decal( "Impact.Concrete", ExpTrace.HitPos - (Direction * 5), ExpTrace.HitPos + (Direction * 5), HitEnt)
			if ExpTrace.Entity.DakHealth == nil then
				DTTE.SetupNewEnt(ExpTrace.Entity)
			end
			if (ExpTrace.Entity.DakDead == true) then
				Filter[#Filter + 1] = ExpTrace.Entity
				ContEXP(Filter,ExpTrace.Entity,Pos,Damage,Radius,Caliber,Pen,Owner,Direction,Shell)
			end
			if (ExpTrace.Entity:IsValid() and not(ExpTrace.Entity:IsPlayer()) and not(ExpTrace.Entity:IsNPC()) and ExpTrace.Entity.Base ~= "base_nextbot" and (ExpTrace.Entity.DakHealth ~= nil and ExpTrace.Entity.DakHealth > 0)) or (ExpTrace.Entity.DakName == "Damaged Component") then
				if ExpTrace.Entity:GetClass() == "dak_crew" or ExpTrace.Entity:GetClass() == "dak_gamemode_bot2" or ExpTrace.Entity:IsPlayer() or ExpTrace.Entity:IsNPC() then
					util.Decal( "Blood", ExpTrace.HitPos - (Direction * 5), ExpTrace.HitPos + (Direction * 500), HitEnt)
				end
				if (DTTE.CheckClip(ExpTrace.Entity,ExpTrace.HitPos)) or (ExpTrace.Entity:GetPhysicsObject():GetMass() <= 1 or (ExpTrace.Entity.DakIsTread == 1) and not(ExpTrace.Entity:IsVehicle()) and ExpTrace.Entity.IsDakTekFutureTech ~= 1) then
					if ExpTrace.Entity.DakArmor == nil or ExpTrace.Entity.DakBurnStacks == nil then
						DTTE.SetupNewEnt(ExpTrace.Entity)
					end
					local SA = ExpTrace.Entity:GetPhysicsObject():GetSurfaceArea()
					if ExpTrace.Entity.IsDakTekFutureTech == 1 then
						ExpTrace.Entity.DakArmor = 1000
					else
						if SA == nil then
							--Volume = (4 / 3) * math.pi*math.pow( ExpTrace.Entity:OBBMaxs().x, 3 )
							ExpTrace.Entity.DakArmor = ExpTrace.Entity:OBBMaxs().x / 2
							ExpTrace.Entity.DakIsTread = 1
						else
							if ExpTrace.Entity:GetClass() == "prop_physics" then
								DTTE.ArmorSanityCheck(ExpTrace.Entity)
							end
						end
					end
					ContEXP(Filter,ExpTrace.Entity,Pos,Damage,Radius,Caliber,Pen,Owner,Direction,Shell)
				else
					if ExpTrace.Entity.DakArmor == nil or ExpTrace.Entity.DakBurnStacks == nil then
						DTTE.SetupNewEnt(ExpTrace.Entity)
					end
					local SA = ExpTrace.Entity:GetPhysicsObject():GetSurfaceArea()
					if ExpTrace.Entity.IsDakTekFutureTech == 1 then
						ExpTrace.Entity.DakArmor = 1000
					else
						if SA == nil then
							--Volume = (4 / 3) * math.pi*math.pow( ExpTrace.Entity:OBBMaxs().x, 3 )
							ExpTrace.Entity.DakArmor = ExpTrace.Entity:OBBMaxs().x / 2
							ExpTrace.Entity.DakIsTread = 1
						else
							if ExpTrace.Entity:GetClass() == "prop_physics" then
								DTTE.ArmorSanityCheck(ExpTrace.Entity)
							end
						end
					end

					ExpTrace.Entity.DakLastDamagePos = ExpTrace.HitPos
					if CanDamage(ExpTrace.Entity) then
						if ExpTrace.Entity:GetClass() == "dak_tegun" or ExpTrace.Entity:GetClass() == "dak_temachinegun" or ExpTrace.Entity:GetClass() == "dak_teautogun" then
							DTDealDamage(ExpTrace.Entity, math.Clamp((Damage / traces) * (Pen / DTTE.GetArmor(ExpTrace.Entity, Shell.DakShellType, Shell.DakCaliber)) * 0.001,0,DTTE.GetArmor(ExpTrace.Entity, Shell.DakShellType, Shell.DakCaliber) * 2),Shell.DakGun)
							DTDealDamage(ExpTrace.Entity.Controller, math.Clamp((Damage / traces) * (Pen / DTTE.GetArmor(ExpTrace.Entity, Shell.DakShellType, Shell.DakCaliber)),0,DTTE.GetArmor(ExpTrace.Entity, Shell.DakShellType, Shell.DakCaliber) * 2),Shell.DakGun)
						else
							DTDealDamage(ExpTrace.Entity, math.Clamp((Damage / traces) * (Pen / DTTE.GetArmor(ExpTrace.Entity, Shell.DakShellType, Shell.DakCaliber)),0,DTTE.GetArmor(ExpTrace.Entity, Shell.DakShellType, Shell.DakCaliber) * 2),Shell.DakGun)
						end
					end
					local EffArmor = (DTTE.GetArmor(ExpTrace.Entity, Shell.DakShellType, Shell.DakCaliber) / math.abs(ExpTraceLine.HitNormal:Dot(Direction)))
					if ExpTrace.Entity.IsComposite == 1 or (ExpTrace.Entity:CPPIGetOwner() ~= nil and ExpTrace.Entity:CPPIGetOwner():IsWorld()) then
						if ExpTrace.Entity.EntityMods == nil then ExpTrace.Entity.EntityMods = {} end
						if ExpTrace.Entity.EntityMods.CompKEMult == nil then ExpTrace.Entity.EntityMods.CompKEMult = 9.2 end
						if ExpTrace.Entity.EntityMods.CompCEMult == nil then ExpTrace.Entity.EntityMods.CompCEMult = 18.4 end
						EffArmor = (ExpTrace.Entity:GetPhysicsObject():GetVolume() ^ (1 / 3)) * ExpTrace.Entity.EntityMods.CompCEMult--DTTE.CompositesTrace( ExpTrace.Entity, ExpTrace.HitPos, ExpTrace.Normal, Shell.Filter ) * ExpTrace.Entity.EntityMods.CompKEMult
					end
					if EffArmor < Pen and ExpTrace.Entity.IsDakTekFutureTech == nil then
						util.Decal( "Impact.Concrete", ExpTrace.HitPos + (Direction * 5), ExpTrace.HitPos - (Direction * 5), Shell.DakGun)
						if ExpTrace.Entity:GetClass() == "dak_crew" or ExpTrace.Entity:GetClass() == "dak_gamemode_bot2" or ExpTrace.Entity:IsPlayer() or ExpTrace.Entity:IsNPC() then
							util.Decal( "Blood", ExpTrace.HitPos - (Direction * 5), ExpTrace.HitPos + (Direction * 500), HitEnt)
							util.Decal( "Blood", ExpTrace.HitPos - (Direction * 5), ExpTrace.HitPos + (Direction * 500), ExpTrace.Entity)
						end
						ContEXP(Filter,ExpTrace.Entity,Pos,Damage * (1-EffArmor / Pen),Radius,Caliber,Pen-EffArmor,Owner,Direction,Shell)
					end

					DestroyEnt(ExpTrace.Entity, Filter, Shell)
				end
				if (ExpTrace.Entity:IsValid()) and not(ExpTrace.Entity:IsNPC()) and not(ExpTrace.Entity:IsPlayer()) and ExpTrace.Entity.Base ~= "base_nextbot" then
					ExpTrace.Entity:DTHEApplyForce(ExpTrace.HitPos, Pos, Damage, traces, 0.35)
				end
			end

			KillEnemy(ExpTrace.Entity, Owner, Shell, traces, Damage, 500)
		end
	end
end

function DTShockwave(Pos,Damage,Radius,Pen,Owner,Shell,HitEnt,nocheck)
	if nocheck ~= true then
		local newtrace = {}
			newtrace.start = Pos - (Shell.DakVelocity:GetNormalized() * 1000)
			newtrace.endpos = Pos + (Shell.DakVelocity:GetNormalized() * 1000)
			newtrace.filter = Shell.Filter
			newtrace.mins = Vector(-Shell.DakCaliber * 0.02,-Shell.DakCaliber * 0.02,-Shell.DakCaliber * 0.02)
			newtrace.maxs = Vector(Shell.DakCaliber * 0.02,Shell.DakCaliber * 0.02,Shell.DakCaliber * 0.02)
		local HitCheckShellTrace = util.TraceHull( newtrace )
		Pos = HitCheckShellTrace.HitPos
	end
	--if Shell.DakCaliber >= 75 then
		net.Start( "daktankexplosion" )
		net.WriteVector( Pos )
		net.WriteFloat( Damage )
		net.WriteString( "daktanks/distexp1.mp3" )
		net.Broadcast()
	--end

	Shell.DakDamageList = {}
	Shell.IgnoreList = {}

	local Targets = ents.FindInSphere( Pos, Radius )
	if table.Count(Targets) > 0 then
		for i = 1, #Targets do
			if Targets[i]:IsValid() then
				if Targets[i].DakArmor == nil or Targets[i].DakBurnStacks == nil then
					DTTE.SetupNewEnt(Targets[i])
				end
				if hook.Run("DakTankDamageCheck", Targets[i], Owner, Shell.DakGun) == false then
					Shell.IgnoreList[#Shell.IgnoreList + 1] = Targets[i]
					--table.insert(Shell.IgnoreList,Targets[i])
				end
				if Targets[i].DakHealth == nil then
					DTTE.SetupNewEnt(Targets[i])
				end
				if Targets[i].DakHealth ~= nil then
					if (Targets[i].DakHealth <= 0 or Targets[i]:GetClass() == "dak_tesalvage" or Targets[i].DakIsTread == 1) and not(Targets[i]:IsPlayer() or Targets[i]:IsNPC() or Targets[i]:GetClass() == "dak_bot" or Targets[i]:GetClass() == "dak_gamemode_bot2") then
						if IsValid(Targets[i]:GetPhysicsObject()) then
							if Targets[i]:GetPhysicsObject():GetMass() <= 1 then
								Shell.IgnoreList[#Shell.IgnoreList + 1] = Targets[i]
								--table.insert(Shell.IgnoreList,Targets[i])
							end
						end
						Shell.IgnoreList[#Shell.IgnoreList + 1] = Targets[i]
						--table.insert(Shell.IgnoreList,Targets[i])
					end
				end
			end
		end
		local FiredFrag = false
		local IsHE = Shell.DakShellType == "HE"
		for i = 1, #Targets do
			local CurShockwaveTarget = Targets[i]
			local Class = CurShockwaveTarget:GetClass()

			--if tankcore then fire frag at it
			--self.BoxCenter is the center of a tank relative to its forward ent
			if IsHE then
				if Class == "dak_tankcore" and CurShockwaveTarget.ForwardEnt:IsValid() and CurShockwaveTarget:IsValid() then
					FiredFrag = true
					local AimPos = CurShockwaveTarget.ForwardEnt:LocalToWorld(CurShockwaveTarget.BoxCenter)
					local TargetArea = CurShockwaveTarget.BestWidth * CurShockwaveTarget.BestHeight
					local TarDistance = AimPos:Distance(Pos)
					-- local SphereArea = 4 * math.pi * (TarDistance * TarDistance)
					-- local FragmentationPercentage = math.min(TargetArea / SphereArea, 1)
					local RadiusPercentage = TarDistance / Radius
					local ConeRadius = math.sqrt(TargetArea / math.pi)
					--could use angle of cone to fire frags at target or just use the target height and width directly so no need to calc cone radius
					--though the height and width would need to be projected onto target, so basic angle may be more simple

					--note some 40mm shells have 1200 fragments built in
					local SpreadAng = math.deg(math.atan(ConeRadius / TarDistance))

					local Caliber = Shell.DakCaliber
					local traces = math.max(math.Round(Caliber * 0.1), 1)

					for i = 1, math.Max(math.Round(traces * RadiusPercentage),1) do --note, I'm using radius percentage here since fragment percentage is way too aggressive scaling for balance
						local Filter = {}
						local Direction = ((AimPos-Pos):GetNormalized():Angle() + Angle(math.Rand(-SpreadAng,SpreadAng),math.Rand(-SpreadAng,SpreadAng),0)):Forward():GetNormalized()
						--debugoverlay.Line( Pos, Pos + Direction*Radius * 2, 25, Color( 150+math.Rand(0,100), 150+math.Rand(0,100), 150+math.Rand(0,100) ), false )
						local trace = {}
							trace.start = Pos
							trace.endpos = Pos + Direction * Radius * 2
							trace.filter = Filter
							trace.mins = Vector( - (Caliber / traces) * 0.02, - (Caliber / traces) * 0.02, - (Caliber / traces) * 0.02)
							trace.maxs = Vector((Caliber / traces) * 0.02,(Caliber / traces) * 0.02,(Caliber / traces) * 0.02)
						local ExpTrace = util.TraceHull( trace )
						local ExpTraceLine = util.TraceLine( trace )

						if ExpTrace.Hit and i <= 10 then
							local effectdata = EffectData()
							effectdata:SetOrigin(ExpTrace.HitPos)
							effectdata:SetEntity(Shell.DakGun)
							effectdata:SetAttachment(1)
							effectdata:SetMagnitude(.5)
							effectdata:SetScale(12.7)
							util.Effect("dakteshellimpact", effectdata, true, true)
						end

						if hook.Run("DakTankDamageCheck", ExpTrace.Entity, Owner, Shell.DakGun) ~= false and ExpTrace.HitPos:Distance(Pos) <= Radius * 2 then
							--decals don't like using the adjusted by normal Pos
							util.Decal( "Impact.Concrete", ExpTrace.HitPos - (Direction * 5), ExpTrace.HitPos + (Direction * 5), HitEnt)
							if ExpTrace.Entity.DakHealth == nil then
								DTTE.SetupNewEnt(ExpTrace.Entity)
							end
							if (ExpTrace.Entity.DakDead == true) then
								Filter[#Filter + 1] = ExpTrace.Entity
								ContEXP(Filter,ExpTrace.Entity,Pos,Damage,Radius,Caliber,Pen,Owner,Direction,Shell)
							end
							if (ExpTrace.Entity:IsValid() and not(ExpTrace.Entity:IsPlayer()) and not(ExpTrace.Entity:IsNPC()) and ExpTrace.Entity.Base ~= "base_nextbot" and (ExpTrace.Entity.DakHealth ~= nil and ExpTrace.Entity.DakHealth > 0)) or (ExpTrace.Entity.DakName == "Damaged Component") then
								if ExpTrace.Entity:GetClass() == "dak_crew" or ExpTrace.Entity:GetClass() == "dak_gamemode_bot2" or ExpTrace.Entity:IsPlayer() or ExpTrace.Entity:IsNPC() then
									util.Decal( "Blood", ExpTrace.HitPos - (Direction * 5), ExpTrace.HitPos + (Direction * 500), HitEnt)
								end
								if (DTTE.CheckClip(ExpTrace.Entity,ExpTrace.HitPos)) or (ExpTrace.Entity:GetPhysicsObject():GetMass() <= 1 or (ExpTrace.Entity.DakIsTread == 1) and not(ExpTrace.Entity:IsVehicle()) and ExpTrace.Entity.IsDakTekFutureTech ~= 1) then
									if ExpTrace.Entity.DakArmor == nil or ExpTrace.Entity.DakBurnStacks == nil then
										DTTE.SetupNewEnt(ExpTrace.Entity)
									end
									local SA = ExpTrace.Entity:GetPhysicsObject():GetSurfaceArea()
									if ExpTrace.Entity.IsDakTekFutureTech == 1 then
										ExpTrace.Entity.DakArmor = 1000
									else
										if SA == nil then
											--Volume = (4 / 3) * math.pi*math.pow( ExpTrace.Entity:OBBMaxs().x, 3 )
											ExpTrace.Entity.DakArmor = ExpTrace.Entity:OBBMaxs().x / 2
											ExpTrace.Entity.DakIsTread = 1
										else
											if ExpTrace.Entity:GetClass() == "prop_physics" then
												DTTE.ArmorSanityCheck(ExpTrace.Entity)
											end
										end
									end
									ContEXP(Filter,ExpTrace.Entity,Pos,Damage,Radius,Caliber,Pen,Owner,Direction,Shell)
								else
									if ExpTrace.Entity.DakArmor == nil or ExpTrace.Entity.DakBurnStacks == nil then
										DTTE.SetupNewEnt(ExpTrace.Entity)
									end
									local SA = ExpTrace.Entity:GetPhysicsObject():GetSurfaceArea()
									if ExpTrace.Entity.IsDakTekFutureTech == 1 then
										ExpTrace.Entity.DakArmor = 1000
									else
										if SA == nil then
											--Volume = (4 / 3) * math.pi*math.pow( ExpTrace.Entity:OBBMaxs().x, 3 )
											ExpTrace.Entity.DakArmor = ExpTrace.Entity:OBBMaxs().x / 2
											ExpTrace.Entity.DakIsTread = 1
										else
											if ExpTrace.Entity:GetClass() == "prop_physics" then
												DTTE.ArmorSanityCheck(ExpTrace.Entity)
											end
										end
									end

									ExpTrace.Entity.DakLastDamagePos = ExpTrace.HitPos

									if CanDamage(ExpTrace.Entity) then
										if ExpTrace.Entity:GetClass() == "dak_tegun" or ExpTrace.Entity:GetClass() == "dak_temachinegun" or ExpTrace.Entity:GetClass() == "dak_teautogun" then
											DTDealDamage(ExpTrace.Entity, math.Clamp((Damage / traces) * (Pen / DTTE.GetArmor(ExpTrace.Entity, Shell.DakShellType, 2)) * 0.001,0,DTTE.GetArmor(ExpTrace.Entity, Shell.DakShellType, 2) * 2),Shell.DakGun)
											DTDealDamage(ExpTrace.Entity.Controller, math.Clamp((Damage / traces) * (Pen / DTTE.GetArmor(ExpTrace.Entity, Shell.DakShellType, 2)),0,DTTE.GetArmor(ExpTrace.Entity, Shell.DakShellType, 2) * 2),Shell.DakGun)
										else
											DTDealDamage(ExpTrace.Entity, math.Clamp((Damage / traces) * (Pen / DTTE.GetArmor(ExpTrace.Entity, Shell.DakShellType, 2)),0,DTTE.GetArmor(ExpTrace.Entity, Shell.DakShellType, 2) * 2),Shell.DakGun)
										end
									end
									local EffArmor = (DTTE.GetArmor(ExpTrace.Entity, Shell.DakShellType, 2) / math.abs(ExpTraceLine.HitNormal:Dot(Direction)))
									if ExpTrace.Entity.IsComposite == 1 or (ExpTrace.Entity:CPPIGetOwner() ~= nil and ExpTrace.Entity:CPPIGetOwner():IsWorld()) then
										if ExpTrace.Entity.EntityMods == nil then ExpTrace.Entity.EntityMods = {} end
										if ExpTrace.Entity.EntityMods.CompKEMult == nil then ExpTrace.Entity.EntityMods.CompKEMult = 9.2 end
										if ExpTrace.Entity.EntityMods.CompCEMult == nil then ExpTrace.Entity.EntityMods.CompCEMult = 18.4 end
										EffArmor = (ExpTrace.Entity:GetPhysicsObject():GetVolume() ^ (1 / 3)) * ExpTrace.Entity.EntityMods.CompCEMult--DTTE.CompositesTrace( ExpTrace.Entity, ExpTrace.HitPos, ExpTrace.Normal, Shell.Filter ) * ExpTrace.Entity.EntityMods.CompKEMult
									end
									if EffArmor < Pen and ExpTrace.Entity.IsDakTekFutureTech == nil then
										util.Decal( "Impact.Concrete", ExpTrace.HitPos + (Direction * 5), ExpTrace.HitPos - (Direction * 5), Shell.DakGun)
										if ExpTrace.Entity:GetClass() == "dak_crew" or ExpTrace.Entity:GetClass() == "dak_gamemode_bot2" or ExpTrace.Entity:IsPlayer() or ExpTrace.Entity:IsNPC() then
											util.Decal( "Blood", ExpTrace.HitPos - (Direction * 5), ExpTrace.HitPos + (Direction * 500), HitEnt)
											util.Decal( "Blood", ExpTrace.HitPos - (Direction * 5), ExpTrace.HitPos + (Direction * 500), ExpTrace.Entity)
										end
										ContEXP(Filter,ExpTrace.Entity,Pos,Damage * (1-EffArmor / Pen),Radius,Caliber,Pen-EffArmor,Owner,Direction,Shell)
									end

									DestroyEnt(ExpTrace.Entity, Filter, Shell)
								end
								if (ExpTrace.Entity:IsValid()) and not(ExpTrace.Entity:IsNPC()) and not(ExpTrace.Entity:IsPlayer()) and ExpTrace.Entity.Base ~= "base_nextbot" then
									ExpTrace.Entity:DTHEApplyForce(ExpTrace.HitPos, Pos, Damage, traces, 0.35)
								end
							end

							KillEnemy(ExpTrace.Entity, Owner, Shell, traces, Damage, 1)
						end
					end
				end
			end

			if Class == "dak_bot" or Class == "dak_crew" or Class == "dak_gamemode_bot2" or CurShockwaveTarget:IsPlayer() or CurShockwaveTarget:IsNPC() then
				if CurShockwaveTarget:IsValid() then
					local trace = {}
					trace.start = Pos
					trace.endpos = Pos + (CurShockwaveTarget:NearestPoint( Pos ) - Pos) * Radius
					trace.filter = Shell.IgnoreList
					trace.mins = Vector(-0.1,-0.1,-0.1)
					trace.maxs = Vector(0.1,0.1,0.1)
					local ExpTrace = util.TraceHull( trace )
					if ExpTrace.Entity == CurShockwaveTarget and (not(DTTE.CheckClip(CurShockwaveTarget,ExpTrace.HitPos))) then
						if not(string.Explode("_",CurShockwaveTarget:GetClass(),false)[2] == "wire") and not(CurShockwaveTarget:IsVehicle()) and CurShockwaveTarget:GetClass() ~= "dak_tesalvage" and CurShockwaveTarget.DakIsTread == nil and CurShockwaveTarget:GetClass() ~= "dak_turretcontrol" then
							if (not(ExpTrace.Entity:IsPlayer())) and (not(ExpTrace.Entity:IsNPC())) and (ExpTrace.Entity.Base ~= "base_nextbot") then
								if ExpTrace.Entity:GetPhysicsObject():IsValid() and ExpTrace.Entity:GetPhysicsObject():GetMass() > 1 then
									if ExpTrace.Entity.DakArmor == nil or ExpTrace.Entity.DakBurnStacks == nil then
										DTTE.SetupNewEnt(ExpTrace.Entity)
									end
									Shell.DakDamageList[#Shell.DakDamageList + 1] = ExpTrace.Entity[i]
									--table.insert(Shell.DakDamageList,ExpTrace.Entity)
									if ExpTrace.Entity:GetClass() == "dak_crew" or ExpTrace.Entity:GetClass() == "dak_gamemode_bot2" or ExpTrace.Entity:IsPlayer() or ExpTrace.Entity:IsNPC() then
										util.Decal( "Blood", ExpTrace.HitPos - (ExpTrace.Normal * 5), ExpTrace.HitPos + (ExpTrace.Normal * 500), Shell.IgnoreList)
										util.Decal( "Blood", ExpTrace.HitPos - (ExpTrace.Normal * 5), ExpTrace.HitPos + (ExpTrace.Normal * 500), ExpTrace.Entity)
									end
								end
							else
								local Dist = ExpTrace.Entity:GetPos():Distance(Pos)
								if CurShockwaveTarget:GetClass() == "dak_bot" then
									if Shell.DakShellType == "SM" then
										CurShockwaveTarget:SetHealth(CurShockwaveTarget:Health() - ( 1 * (1 - (Dist / Radius)) ))
										ExpTrace.Entity:Extinguish()
										ExpTrace.Entity:Ignite(25 * (1 - (ExpTrace.Entity:GetPos():Distance(Pos) / Radius)),1)
									else
										if Dist < Radius * 0.5 then
											CurShockwaveTarget:SetHealth(CurShockwaveTarget:Health() - ( Damage * 2.5 * (1 - (Dist / Radius)) ))
										else
											CurShockwaveTarget:SetHealth(CurShockwaveTarget:Health() - ( Damage * 1 * (1 - (Dist / Radius)) ))
										end
									end
									if CurShockwaveTarget:Health() <= 0 and Shell.revenge == 0 then
										--local body = ents.Create( "prop_ragdoll" )
										body:SetPos( CurShockwaveTarget:GetPos() )
										body:SetModel( CurShockwaveTarget:GetModel() )
										body:Spawn()
										--CurShockwaveTarget:Remove()
										local SoundList = {"npc/metropolice/die1.wav","npc/metropolice/die2.wav","npc/metropolice/die3.wav","npc/metropolice/die4.wav","npc/metropolice/pain4.wav"}
										body:EmitSound( SoundList[math.random(5)], 100, 100, 1, 2 )
										timer.Simple( 5, function()
											body:Remove()
										end )
									end
								else
									local ExpPain = DamageInfo()
									if Shell.DakShellType == "SM" then
										ExpPain:SetDamageForce( ExpTrace.Normal * (1 * (1 - (Dist / Radius))) )
										ExpPain:SetDamage( 1 * (1 - (Dist / Radius)) )
										ExpTrace.Entity:Extinguish()
										ExpTrace.Entity:Ignite(25 * (1 - (ExpTrace.Entity:GetPos():Distance(Pos) / Radius)),1)
									else
										if Dist < Radius * 0.5 then
											ExpPain:SetDamageForce( ExpTrace.Normal * (Damage * 250 * (1 - (Dist / Radius))) )
											ExpPain:SetDamage( Damage * 2.5 * (1 - (Dist / Radius)) )
										else
											ExpPain:SetDamageForce( ExpTrace.Normal * (Damage * 100 * (1 - (Dist / Radius))) )
											ExpPain:SetDamage( Damage * 1 * (1 - (Dist / Radius)) )
										end
									end
									if Owner ~= nil and Owner:IsValid() and Owner:IsPlayer() and Shell and Shell.DakGun then
										ExpPain:SetAttacker( Owner )
										ExpPain:SetInflictor( Shell.DakGun )
									else
										ExpPain:SetAttacker( game.GetWorld() )
										ExpPain:SetInflictor( game.GetWorld() )
									end
									if Shell.DakGun == NULL or not(IsValid(Shell.DakGun)) then
										ExpPain:SetReportedPosition( Shell.Pos )
									else
										ExpPain:SetReportedPosition( Shell.DakGun:GetPos() )
									end
									ExpPain:SetDamagePosition( ExpTrace.Entity:WorldSpaceCenter() )
									ExpPain:SetDamageType(DMG_BLAST)
									ExpTrace.Entity:TakeDamageInfo( ExpPain )
								end
							end
						end
					end
				end
			end
		end

		for i = 1, #Shell.DakDamageList do
			local CurTarget = Shell.DakDamageList[i]

			if IsValid(CurTarget) and CanDamage(CurTarget) then
				if CurTarget.DakIsTread == nil then
					local TargetArmor = DTTE.GetArmor(CurTarget, Shell.DakShellType, Shell.DakCaliber)
					local TargetDist = CurTarget:GetPos():Distance(Pos)
					local DamageMult = TargetDist > Radius / 2 and 1 - (TargetDist / Radius) or 1
					local InitialDamage = ((Damage / table.Count(Shell.DakDamageList)) * (Pen / TargetArmor)) * DamageMult
					local TargetClass = CurTarget:GetClass()

					if TargetClass == "dak_tegun" or TargetClass == "dak_temachinegun" or TargetClass == "dak_teautogun" then
						DTDealDamage(CurTarget, math.Clamp(InitialDamage * 0.001, 0, TargetArmor * 2), Shell.DakGun)
						DTDealDamage(CurTarget.Controller, math.Clamp(InitialDamage, 0, TargetArmor * 2), Shell.DakGun)
					else
						DTDealDamage(CurTarget, math.Clamp(InitialDamage, 0, TargetArmor * 2), Shell.DakGun)
					end
				end

				CurTarget.DakLastDamagePos = Pos

				DestroyEnt(CurTarget, Shell.Filter, Shell)
			end
		end
	end

	if Shell.DakShellType == "HE" and FiredFrag ~= true then
		local Caliber = Shell.DakCaliber
		local traces = math.Round(Caliber / 2)
		for i = 1, traces do
			local Filter = {}
			local Direction = VectorRand()
			local trace = {}
				trace.start = Pos
				trace.endpos = Pos + Direction * Radius * 2
				trace.filter = Filter
				trace.mins = Vector( - (Caliber / traces) * 0.02, - (Caliber / traces) * 0.02, - (Caliber / traces) * 0.02)
				trace.maxs = Vector((Caliber / traces) * 0.02,(Caliber / traces) * 0.02,(Caliber / traces) * 0.02)
			local ExpTrace = util.TraceHull( trace )
			local ExpTraceLine = util.TraceLine( trace )

			if ExpTrace.Hit and i <= 10 then
				local effectdata = EffectData()
				effectdata:SetOrigin(ExpTrace.HitPos)
				effectdata:SetEntity(Shell.DakGun)
				effectdata:SetAttachment(1)
				effectdata:SetMagnitude(.5)
				effectdata:SetScale(12.7)
				util.Effect("dakteshellimpact", effectdata, true, true)
			end

			if hook.Run("DakTankDamageCheck", ExpTrace.Entity, Owner, Shell.DakGun) ~= false and ExpTrace.HitPos:Distance(Pos) <= Radius * 2 then
				if not Owner then Owner = game.GetWorld() end
				--decals don't like using the adjusted by normal Pos
				util.Decal( "Impact.Concrete", ExpTrace.HitPos - (Direction * 5), ExpTrace.HitPos + (Direction * 5), HitEnt)
				if ExpTrace.Entity.DakHealth == nil then
					DTTE.SetupNewEnt(ExpTrace.Entity)
				end
				if (ExpTrace.Entity.DakDead == true) then
					Filter[#Filter + 1] = ExpTrace.Entity
					ContEXP(Filter,ExpTrace.Entity,Pos,Damage,Radius,Caliber,Pen,Owner,Direction,Shell)
				end
				if (ExpTrace.Entity:IsValid() and not(ExpTrace.Entity:IsPlayer()) and not(ExpTrace.Entity:IsNPC()) and ExpTrace.Entity.Base ~= "base_nextbot" and (ExpTrace.Entity.DakHealth ~= nil and ExpTrace.Entity.DakHealth > 0)) or (ExpTrace.Entity.DakName == "Damaged Component") then
					if ExpTrace.Entity:GetClass() == "dak_crew" or ExpTrace.Entity:GetClass() == "dak_gamemode_bot2" or ExpTrace.Entity:IsPlayer() or ExpTrace.Entity:IsNPC() then
						util.Decal( "Blood", ExpTrace.HitPos - (Direction * 5), ExpTrace.HitPos + (Direction * 500), HitEnt)
					end
					if (DTTE.CheckClip(ExpTrace.Entity,ExpTrace.HitPos)) or (ExpTrace.Entity:GetPhysicsObject():GetMass() <= 1 or (ExpTrace.Entity.DakIsTread == 1) and not(ExpTrace.Entity:IsVehicle()) and ExpTrace.Entity.IsDakTekFutureTech ~= 1) then
						if ExpTrace.Entity.DakArmor == nil or ExpTrace.Entity.DakBurnStacks == nil then
							DTTE.SetupNewEnt(ExpTrace.Entity)
						end
						local SA = ExpTrace.Entity:GetPhysicsObject():GetSurfaceArea()
						if ExpTrace.Entity.IsDakTekFutureTech == 1 then
							ExpTrace.Entity.DakArmor = 1000
						else
							if SA == nil then
								--Volume = (4 / 3) * math.pi*math.pow( ExpTrace.Entity:OBBMaxs().x, 3 )
								ExpTrace.Entity.DakArmor = ExpTrace.Entity:OBBMaxs().x / 2
								ExpTrace.Entity.DakIsTread = 1
							else
								if ExpTrace.Entity:GetClass() == "prop_physics" then
									DTTE.ArmorSanityCheck(ExpTrace.Entity)
								end
							end
						end
						ContEXP(Filter,ExpTrace.Entity,Pos,Damage,Radius,Caliber,Pen,Owner,Direction,Shell)
					else
						if ExpTrace.Entity.DakArmor == nil or ExpTrace.Entity.DakBurnStacks == nil then
							DTTE.SetupNewEnt(ExpTrace.Entity)
						end
						local SA = ExpTrace.Entity:GetPhysicsObject():GetSurfaceArea()
						if ExpTrace.Entity.IsDakTekFutureTech == 1 then
							ExpTrace.Entity.DakArmor = 1000
						else
							if SA == nil then
								--Volume = (4 / 3) * math.pi*math.pow( ExpTrace.Entity:OBBMaxs().x, 3 )
								ExpTrace.Entity.DakArmor = ExpTrace.Entity:OBBMaxs().x / 2
								ExpTrace.Entity.DakIsTread = 1
							else
								if ExpTrace.Entity:GetClass() == "prop_physics" then
									DTTE.ArmorSanityCheck(ExpTrace.Entity)
								end
							end
						end

						ExpTrace.Entity.DakLastDamagePos = ExpTrace.HitPos

						if CanDamage(ExpTrace.Entity) then
							if ExpTrace.Entity:GetClass() == "dak_tegun" or ExpTrace.Entity:GetClass() == "dak_temachinegun" or ExpTrace.Entity:GetClass() == "dak_teautogun" then
								DTDealDamage(ExpTrace.Entity, math.Clamp((Damage / traces) * (Pen / DTTE.GetArmor(ExpTrace.Entity, Shell.DakShellType, 2)) * 0.001,0,DTTE.GetArmor(ExpTrace.Entity, Shell.DakShellType, 2) * 2),Shell.DakGun)
								DTDealDamage(ExpTrace.Entity.Controller, math.Clamp((Damage / traces) * (Pen / DTTE.GetArmor(ExpTrace.Entity, Shell.DakShellType, 2)),0,DTTE.GetArmor(ExpTrace.Entity, Shell.DakShellType, 2) * 2),Shell.DakGun)
							else
								DTDealDamage(ExpTrace.Entity, math.Clamp((Damage / traces) * (Pen / DTTE.GetArmor(ExpTrace.Entity, Shell.DakShellType, 2)),0,DTTE.GetArmor(ExpTrace.Entity, Shell.DakShellType, 2) * 2),Shell.DakGun)
							end
						end
						local EffArmor = (DTTE.GetArmor(ExpTrace.Entity, Shell.DakShellType, 2) / math.abs(ExpTraceLine.HitNormal:Dot(Direction)))
						if ExpTrace.Entity.IsComposite == 1 or (ExpTrace.Entity:CPPIGetOwner() ~= nil and ExpTrace.Entity:CPPIGetOwner():IsWorld()) then
							if ExpTrace.Entity.EntityMods == nil then ExpTrace.Entity.EntityMods = {} end
							if ExpTrace.Entity.EntityMods.CompKEMult == nil then ExpTrace.Entity.EntityMods.CompKEMult = 9.2 end
							if ExpTrace.Entity.EntityMods.CompCEMult == nil then ExpTrace.Entity.EntityMods.CompCEMult = 18.4 end
							EffArmor = (ExpTrace.Entity:GetPhysicsObject():GetVolume() ^ (1 / 3)) * ExpTrace.Entity.EntityMods.CompCEMult--DTTE.CompositesTrace( ExpTrace.Entity, ExpTrace.HitPos, ExpTrace.Normal, Shell.Filter ) * ExpTrace.Entity.EntityMods.CompKEMult
						end
						if EffArmor < Pen and ExpTrace.Entity.IsDakTekFutureTech == nil then
							util.Decal( "Impact.Concrete", ExpTrace.HitPos + (Direction * 5), ExpTrace.HitPos - (Direction * 5), Shell.DakGun)
							if ExpTrace.Entity:GetClass() == "dak_crew" or ExpTrace.Entity:GetClass() == "dak_gamemode_bot2" or ExpTrace.Entity:IsPlayer() or ExpTrace.Entity:IsNPC() then
								util.Decal( "Blood", ExpTrace.HitPos - (Direction * 5), ExpTrace.HitPos + (Direction * 500), HitEnt)
								util.Decal( "Blood", ExpTrace.HitPos - (Direction * 5), ExpTrace.HitPos + (Direction * 500), ExpTrace.Entity)
							end
							ContEXP(Filter,ExpTrace.Entity,Pos,Damage * (1-EffArmor / Pen),Radius,Caliber,Pen-EffArmor,Owner,Direction,Shell)
						end

						DestroyEnt(ExpTrace.Entity, Filter, Shell)
					end
					if (ExpTrace.Entity:IsValid()) and not(ExpTrace.Entity:IsNPC()) and not(ExpTrace.Entity:IsPlayer()) and ExpTrace.Entity.Base ~= "base_nextbot" then
						ExpTrace.Entity:DTHEApplyForce(ExpTrace.HitPos, Pos, Damage, traces, 0.35)
					end
				end

				KillEnemy(ExpTrace.Entity, Owner, Shell, traces, Damage, 1)
			end
		end
	end
end

local function ContSpall(Filter, IgnoreEnt, Pos, Damage, Pen, Owner, Direction, Shell, Energy)
	Energy = Energy + 1
	if Energy > 25 then
		print("ERROR: Spalling Recurse Loop")

		return
	end

	local trace = {}
		trace.start = Pos - Direction * 2
		trace.endpos = Pos + Direction * 1000
		trace.filter = Filter
		trace.mins = Vector(-Shell.DakCaliber * 0.002,-Shell.DakCaliber * 0.002,-Shell.DakCaliber * 0.002)
		trace.maxs = Vector(Shell.DakCaliber * 0.002,Shell.DakCaliber * 0.002,Shell.DakCaliber * 0.002)
	local SpallTrace = util.TraceHull( trace )

	if hook.Run("DakTankDamageCheck", SpallTrace.Entity, Owner, Shell.DakGun) == false then return end

	if SpallTrace.HitPos:Distance(Pos) > 1000 then return end
	if not IsValid(SpallTrace.Entity) then return end

	if SpallTrace.Entity.DakDead == true then
		Filter[#Filter + 1] = SpallTrace.Entity
		ContSpall(Filter, SpallTrace.Entity, Pos, Damage, Pen, Owner, Direction, Shell, Energy)
	end
	if (not(SpallTrace.Entity:IsPlayer()) and not(SpallTrace.Entity:IsNPC()) and not(SpallTrace.Entity.Base == "base_nextbot") and (SpallTrace.Entity.DakHealth ~= nil and SpallTrace.Entity.DakHealth > 0)) or (SpallTrace.Entity.DakName == "Damaged Component") then
		if (DTTE.CheckClip(SpallTrace.Entity,SpallTrace.HitPos)) or (SpallTrace.Entity:GetPhysicsObject():GetMass() <= 1 or (SpallTrace.Entity.DakIsTread == 1) and not(SpallTrace.Entity:IsVehicle()) and SpallTrace.Entity.IsDakTekFutureTech ~= 1) then
			if SpallTrace.Entity.DakArmor == nil or SpallTrace.Entity.DakBurnStacks == nil then
				DTTE.SetupNewEnt(SpallTrace.Entity)
			end
			local SA = SpallTrace.Entity:GetPhysicsObject():GetSurfaceArea()
			if SpallTrace.Entity.IsDakTekFutureTech == 1 then
				SpallTrace.Entity.DakArmor = 1000
			else
				if SA == nil then
					--Volume = (4 / 3) * math.pi*math.pow( SpallTrace.Entity:OBBMaxs().x, 3 )
					SpallTrace.Entity.DakArmor = SpallTrace.Entity:OBBMaxs().x / 2
					SpallTrace.Entity.DakIsTread = 1
				else
					if SpallTrace.Entity:GetClass() == "prop_physics" then
						DTTE.ArmorSanityCheck(SpallTrace.Entity)
					end
				end
			end
			Filter[#Filter + 1] = IgnoreEnt
			ContSpall(Filter,SpallTrace.Entity,Pos,Damage,Pen,Owner,Direction,Shell,Energy)
		else
			if SpallTrace.Entity.DakArmor == nil or SpallTrace.Entity.DakBurnStacks == nil then
				DTTE.SetupNewEnt(SpallTrace.Entity)
			end
			local SA = SpallTrace.Entity:GetPhysicsObject():GetSurfaceArea()
			if SpallTrace.Entity.IsDakTekFutureTech == 1 then
				SpallTrace.Entity.DakArmor = 1000
			else
				if SA == nil then
					--Volume = (4 / 3) * math.pi*math.pow( SpallTrace.Entity:OBBMaxs().x, 3 )
					SpallTrace.Entity.DakArmor = SpallTrace.Entity:OBBMaxs().x / 2
					SpallTrace.Entity.DakIsTread = 1
				else
					if SpallTrace.Entity:GetClass() == "prop_physics" then
						DTTE.ArmorSanityCheck(SpallTrace.Entity)
					end
				end
			end

			SpallTrace.Entity.DakLastDamagePos = SpallTrace.HitPos
			if CanDamage(SpallTrace.Entity) then
				if SpallTrace.Entity:GetClass() == "dak_tegun" or SpallTrace.Entity:GetClass() == "dak_temachinegun" or SpallTrace.Entity:GetClass() == "dak_teautogun" then
					DTDealDamage(SpallTrace.Entity, math.Clamp(Damage * (Pen / DTTE.GetArmor(SpallTrace.Entity, Shell.DakShellType, Shell.DakCaliber)),0,DTTE.GetArmor(SpallTrace.Entity, Shell.DakShellType, Shell.DakCaliber) * 2) * 0.001,Shell.DakGun)
					DTDealDamage(SpallTrace.Entity.Controller, math.Clamp(Damage * (Pen / DTTE.GetArmor(SpallTrace.Entity, Shell.DakShellType, Shell.DakCaliber)),0,DTTE.GetArmor(SpallTrace.Entity, Shell.DakShellType, Shell.DakCaliber) * 2),Shell.DakGun)
				else
					DTDealDamage(SpallTrace.Entity, math.Clamp(Damage * (Pen / DTTE.GetArmor(SpallTrace.Entity, Shell.DakShellType, Shell.DakCaliber)),0,DTTE.GetArmor(SpallTrace.Entity, Shell.DakShellType, Shell.DakCaliber) * 2),Shell.DakGun)
				end
			end

			DestroyEnt(SpallTrace.Entity, Filter, Shell)

			local EffArmor = (DTTE.GetArmor(SpallTrace.Entity, Shell.DakShellType, Shell.DakCaliber) / math.abs(SpallTrace.HitNormal:Dot(Direction)))
			if SpallTrace.Entity.IsComposite == 1 or (SpallTrace.Entity:CPPIGetOwner() ~= nil and SpallTrace.Entity:CPPIGetOwner():IsWorld()) then
				if SpallTrace.Entity.EntityMods == nil then SpallTrace.Entity.EntityMods = {} end
				if SpallTrace.Entity.EntityMods.CompKEMult == nil then SpallTrace.Entity.EntityMods.CompKEMult = 9.2 end
				if SpallTrace.Entity.EntityMods.CompCEMult == nil then SpallTrace.Entity.EntityMods.CompCEMult = 18.4 end
				EffArmor = (SpallTrace.Entity:GetPhysicsObject():GetVolume() ^ (1 / 3)) * SpallTrace.Entity.EntityMods.CompCEMult--DTTE.CompositesTrace( SpallTrace.Entity, SpallTrace.HitPos, SpallTrace.Normal, Filter  ) * SpallTrace.Entity.EntityMods.CompKEMult
			end
			if EffArmor < Pen and SpallTrace.Entity.IsDakTekFutureTech == nil then
				--decals don't like using the adjusted by normal Pos
				--util.Decal( "Impact.Concrete", Pos, Pos + (Direction * 1000), {Shell.DakGun})
				--util.Decal( "Impact.Concrete", SpallTrace.HitPos + (Direction * 5), Pos, {Shell.DakGun})

				if SpallTrace.Entity:GetClass() == "dak_crew" or SpallTrace.Entity:GetClass() == "dak_gamemode_bot2" or SpallTrace.Entity:IsPlayer() or SpallTrace.Entity:IsNPC() then
					util.Decal( "Blood", SpallTrace.HitPos - (Direction * 5), SpallTrace.HitPos + (Direction * 500), Shell.DakGun)
					util.Decal( "Blood", SpallTrace.HitPos - (Direction * 5), SpallTrace.HitPos + (Direction * 500), SpallTrace.Entity)
				end

				Filter[#Filter + 1] = IgnoreEnt
				ContSpall(Filter,SpallTrace.Entity,Pos,Damage * (1-EffArmor / Pen),Pen-EffArmor,Owner,Direction,Shell,Energy)
			else
				--decals don't like using the adjusted by normal Pos
				--util.Decal( "Impact.Glass", Pos, Pos + (Direction * 1000), {Shell.DakGun,HitEnt})
				if SpallTrace.Entity:GetClass() == "dak_crew" or SpallTrace.Entity:GetClass() == "dak_gamemode_bot2" or SpallTrace.Entity:IsPlayer() or SpallTrace.Entity:IsNPC() then
					util.Decal( "Blood", SpallTrace.HitPos - (Direction * 5), SpallTrace.HitPos + (Direction * 500), Shell.DakGun)
				end
				--SpallBounceHere
				--local HitAng = math.deg(math.acos(SpallTrace.HitNormal:Dot(-SpallTrace.Normal)))
				--Energy = Energy - (HitAng * 0.1)
				--if Energy > 10 then
				--	Pen = Pen * (Energy / 10)
				--	Damage = Damage * (Energy / 10)
				--	local newDir = (((SpallTrace.HitNormal) + ((SpallTrace.HitPos-Pos):GetNormalized() * 1 * (45 / (90-HitAng)))):GetNormalized():Angle() + Angle(math.Rand(-1,1),math.Rand(-1,1),math.Rand(-1,1))):Forward()
				--	ContSpall({},Shell.DakGun,SpallTrace.HitPos+SpallTrace.HitNormal * 2,Damage,Pen,Owner,newDir,Shell,Energy)
				--end
			end
		end
	end

	KillEnemy(SpallTrace.Entity, Owner, Shell, 1, Damage, 250)
end

function DTSpall(Pos,Armor,HitEnt,Caliber,Pen,Owner,Shell,Dir)
	--local SpallVolume = math.pi * ((Caliber * 0.05) * (Caliber * 0.05)) * (Armor * 0.1)
	--local SpallMass = (SpallVolume * 0.0078125) * 0.1
	local SpallPen = Armor * 0.1
	local SpallDamage = math.pi * ((Caliber * 0.05) * (Caliber * 0.05)) * (Armor * 0.1) * 0.001
	local Ang = 90 * (Armor / Pen)
	if (Shell.DakShellType == "HESH" or Shell.DakShellType == "HE") and Shell.HeatPen == true then
		Ang = 30 * math.Clamp(Pen / Armor, 1, 3)
	end
	if Shell.DakShellType == "HE" then
		Ang = Ang * 2
	end
	Ang = math.Clamp(Ang,25,90)
	--if Ang < math.Clamp(Caliber * 0.5,10,22.5) then Ang = math.Clamp(Caliber * 0.5,10,22.5) end
	local traces = (Ang * Ang * 0.04)
	if (Shell.DakShellType == "HESH" or Shell.DakShellType == "HE") and Shell.HeatPen == true then
		--SpallMass = (SpallVolume * 0.0078125) * 0.05
		SpallDamage = math.pi * ((Caliber * 0.05) * (Caliber * 0.05)) * 2.5 * 0.005
		SpallPen = Caliber * 0.2
		traces = traces * 2
		--traces = 20 * math.Clamp((Pen/Armor),1,3)
	end
	if Shell.DakShellType == "HEAT" then
		--SpallMass = (SpallVolume * 0.0078125) * 0.05
		Caliber = Caliber / 8
		SpallDamage = math.pi * ((Caliber * 0.05) * (Caliber * 0.05)) * 5 * 0.005
		SpallPen = Armor * 0.2
		traces = traces * 2
		--traces = 20
	end
	if Shell.DakShellType == "HEATFS" then
		--SpallMass = (SpallVolume * 0.0078125) * 0.05
		Caliber = Caliber / 8
		SpallDamage = math.pi * ((Caliber * 0.05) * (Caliber * 0.05)) * 5 * 0.005
		SpallPen = Armor * 0.2
		--traces = 20
	end
	if HitEnt.EntityMods ~= nil and HitEnt.EntityMods.Ductility ~= nil then
		traces = math.Round(traces * HitEnt.EntityMods.Ductility)
		SpallDamage = math.Round(SpallDamage * HitEnt.EntityMods.Ductility,2)
		SpallPen = math.Round(SpallPen * HitEnt.EntityMods.Ductility,2)
	end
	--print(SpallDamage)
	--print("Angle: " .. Ang, "traces: " .. traces, "armor: " .. Armor, "pen: " .. Pen, "damage: " .. SpallDamage)
	if SpallDamage < 0.01 then traces = 0 end

	--print(traces)
	--if traces > 50 then
	--	SpallDamage = SpallDamage * (traces / 50)
	--	traces = 50
	--end

	for i = 1, traces do
		local Filter = table.Copy( Shell.Filter )
		local Direction = ((Angle(math.Rand(-Ang,Ang),math.Rand(-Ang,Ang),math.Rand(-Ang,Ang))) + Dir:Angle()):Forward()
		local trace = {}
			trace.start = Pos - Dir * 2
			trace.endpos = Pos + Direction * 1000
			trace.filter = Filter

			--trace.mins = Vector(-Caliber * 0.002,-Caliber * 0.002,-Caliber * 0.002)
			--trace.maxs = Vector(Caliber * 0.002,Caliber * 0.002,Caliber * 0.002)
		local SpallTrace = util.TraceHull( trace )
		if hook.Run("DakTankDamageCheck", SpallTrace.Entity, Owner, Shell.DakGun) ~= false and SpallTrace.HitPos:Distance(Pos) <= 1000 then
			if SpallTrace.Entity.DakHealth == nil then
				DTTE.SetupNewEnt(SpallTrace.Entity)
			end
			if (SpallTrace.Entity.DakDead == true) then
				Filter[#Filter + 1] = SpallTrace.Entity
				ContSpall(Filter,SpallTrace.Entity,Pos,SpallDamage,SpallPen,Owner,Direction,Shell,1)
			end
			if (SpallTrace.Entity:IsValid() and not(SpallTrace.Entity:IsPlayer()) and not(SpallTrace.Entity:IsNPC()) and not(SpallTrace.Entity.Base == "base_nextbot") and (SpallTrace.Entity.DakHealth ~= nil and SpallTrace.Entity.DakHealth > 0)) or (SpallTrace.Entity.DakName == "Damaged Component") then
				if (DTTE.CheckClip(SpallTrace.Entity,SpallTrace.HitPos)) or (SpallTrace.Entity:GetPhysicsObject():GetMass() <= 1 or (SpallTrace.Entity.DakIsTread == 1) and not(SpallTrace.Entity:IsVehicle()) and SpallTrace.Entity.IsDakTekFutureTech ~= 1) then
					if SpallTrace.Entity.DakArmor == nil or SpallTrace.Entity.DakBurnStacks == nil then
						DTTE.SetupNewEnt(SpallTrace.Entity)
					end
					local SA = SpallTrace.Entity:GetPhysicsObject():GetSurfaceArea()
					if SpallTrace.Entity.IsDakTekFutureTech == 1 then
						SpallTrace.Entity.DakArmor = 1000
					else
						if SA == nil then
							--Volume = (4 / 3) * math.pi*math.pow( SpallTrace.Entity:OBBMaxs().x, 3 )
							SpallTrace.Entity.DakArmor = SpallTrace.Entity:OBBMaxs().x / 2
							SpallTrace.Entity.DakIsTread = 1
						else
							if SpallTrace.Entity:GetClass() == "prop_physics" then
								DTTE.ArmorSanityCheck(SpallTrace.Entity)
							end
						end
					end
					Filter[#Filter + 1] = HitEnt
					ContSpall(Filter,SpallTrace.Entity,Pos,SpallDamage,SpallPen,Owner,Direction,Shell,1)
				else
					if SpallTrace.Entity.DakArmor == nil or SpallTrace.Entity.DakBurnStacks == nil then
						DTTE.SetupNewEnt(SpallTrace.Entity)
					end
					local SA = SpallTrace.Entity:GetPhysicsObject():GetSurfaceArea()
					if SpallTrace.Entity.IsDakTekFutureTech == 1 then
						SpallTrace.Entity.DakArmor = 1000
					else
						if SA == nil then
							--Volume = (4 / 3) * math.pi*math.pow( SpallTrace.Entity:OBBMaxs().x, 3 )
							SpallTrace.Entity.DakArmor = SpallTrace.Entity:OBBMaxs().x / 2
							SpallTrace.Entity.DakIsTread = 1
						else
							if SpallTrace.Entity:GetClass() == "prop_physics" then
								DTTE.ArmorSanityCheck(SpallTrace.Entity)
							end
						end
					end

					SpallTrace.Entity.DakLastDamagePos = SpallTrace.HitPos
					if CanDamage(SpallTrace.Entity) then
						if SpallTrace.Entity:GetClass() == "dak_tegun" or SpallTrace.Entity:GetClass() == "dak_temachinegun" or SpallTrace.Entity:GetClass() == "dak_teautogun" then
							DTDealDamage(SpallTrace.Entity, math.Clamp(SpallDamage * (SpallPen / DTTE.GetArmor(SpallTrace.Entity, Shell.DakShellType, Shell.DakCaliber)),0,DTTE.GetArmor(SpallTrace.Entity, Shell.DakShellType, Shell.DakCaliber) * 2) * 0.001,Shell.DakGun)
							DTDealDamage(SpallTrace.Entity.Controller, math.Clamp(SpallDamage * (SpallPen / DTTE.GetArmor(SpallTrace.Entity, Shell.DakShellType, Shell.DakCaliber)),0,DTTE.GetArmor(SpallTrace.Entity, Shell.DakShellType, Shell.DakCaliber) * 2),Shell.DakGun)
						else
							DTDealDamage(SpallTrace.Entity, math.Clamp(SpallDamage * (SpallPen / DTTE.GetArmor(SpallTrace.Entity, Shell.DakShellType, Shell.DakCaliber)),0,DTTE.GetArmor(SpallTrace.Entity, Shell.DakShellType, Shell.DakCaliber) * 2),Shell.DakGun)
						end
					end

					DestroyEnt(SpallTrace.Entity, Filter, Shell)

					local EffArmor = (DTTE.GetArmor(SpallTrace.Entity, Shell.DakShellType, Shell.DakCaliber) / math.abs(SpallTrace.HitNormal:Dot(Direction)))
					if SpallTrace.Entity.IsComposite == 1 or (SpallTrace.Entity:CPPIGetOwner() ~= nil and SpallTrace.Entity:CPPIGetOwner():IsWorld()) then
						if SpallTrace.Entity.EntityMods == nil then SpallTrace.Entity.EntityMods = {} end
						if SpallTrace.Entity.EntityMods.CompKEMult == nil then SpallTrace.Entity.EntityMods.CompKEMult = 9.2 end
						if SpallTrace.Entity.EntityMods.CompCEMult == nil then SpallTrace.Entity.EntityMods.CompCEMult = 18.4 end
						EffArmor = (SpallTrace.Entity:GetPhysicsObject():GetVolume() ^ (1 / 3)) * SpallTrace.Entity.EntityMods.CompCEMult--DTTE.CompositesTrace( SpallTrace.Entity, SpallTrace.HitPos, SpallTrace.Normal, Filter  ) * SpallTrace.Entity.EntityMods.CompKEMult
					end
					if EffArmor < SpallPen and SpallTrace.Entity.IsDakTekFutureTech == nil then
						--decals don't like using the adjusted by normal Pos
						--util.Decal( "Impact.Concrete", Pos, Pos + (Direction * 1000), {Shell.DakGun})
						--util.Decal( "Impact.Concrete", SpallTrace.HitPos + (Direction * 5), Pos, {Shell.DakGun})

						if SpallTrace.Entity:GetClass() == "dak_crew" or SpallTrace.Entity:GetClass() == "dak_gamemode_bot2" or SpallTrace.Entity:IsPlayer() or SpallTrace.Entity:IsNPC() then
							util.Decal( "Blood", SpallTrace.HitPos - (Direction * 5), SpallTrace.HitPos + (Direction * 500), Shell.DakGun)
							util.Decal( "Blood", SpallTrace.HitPos - (Direction * 5), SpallTrace.HitPos + (Direction * 500), SpallTrace.Entity)
						end

						Filter[#Filter + 1] = HitEnt
						ContSpall(Filter,SpallTrace.Entity,Pos,SpallDamage * (1-EffArmor / SpallPen),SpallPen-EffArmor,Owner,Direction,Shell,1)
					else
						--decals don't like using the adjusted by normal Pos
						--util.Decal( "Impact.Glass", Pos, Pos + (Direction * 1000), {Shell.DakGun,HitEnt})
						if SpallTrace.Entity:GetClass() == "dak_crew" or SpallTrace.Entity:GetClass() == "dak_gamemode_bot2" or SpallTrace.Entity:IsPlayer() or SpallTrace.Entity:IsNPC() then
							util.Decal( "Blood", SpallTrace.HitPos - (Direction * 5), SpallTrace.HitPos + (Direction * 500), Shell.DakGun)
						end
						--SpallBounceHere
						--local HitAng = math.deg(math.acos(SpallTrace.HitNormal:Dot(-SpallTrace.Normal)))
						--local Energy = 10 - (HitAng * 0.1)
						--if Energy > 10 then
						--	local newDir = (((SpallTrace.HitNormal) + ((SpallTrace.HitPos-Pos):GetNormalized() * 1 * (45 / (90-HitAng)))):GetNormalized():Angle() + Angle(math.Rand(-1,1),math.Rand(-1,1),math.Rand(-1,1))):Forward()
						--	ContSpall({},Shell.DakGun,SpallTrace.HitPos+SpallTrace.HitNormal * 2,SpallDamage * (Energy / 10),SpallPen * (Energy / 10),Owner,newDir,Shell,Energy)
						--end
					end
				end
			end

			local effectdata = EffectData()
			effectdata:SetStart(Pos)
			effectdata:SetScale(Shell.DakCaliber * 0.00393701)

			if SpallTrace.Entity:IsValid() then
				KillEnemy(SpallTrace.Entity, Owner, Shell, 1, SpallDamage, 500)

				effectdata:SetOrigin(SpallTrace.HitPos)
			else
				effectdata:SetOrigin(Pos + Direction * 1000)
			end

			util.Effect("dakteballistictracer", effectdata)
		end
	end
end

local function ContHEAT(Filter, IgnoreEnt, Pos, Damage, Pen, Owner, Direction, Shell, Triggered, Recurse)
	if Recurse == nil then Recurse = 1 end

	Recurse = Recurse + 1

	if Recurse >= 25 then
		print("ERROR: Heat Recurse Loop")
		return
	end

	if isangle(Direction) then
		Direction = Direction:Forward()
	end

	local trace = {}
		trace.start = Pos - Direction * 250
		trace.endpos = Pos + Direction * 1000
		trace.filter = Filter
		trace.mins = Vector(-Shell.DakCaliber * 0.02,-Shell.DakCaliber * 0.02,-Shell.DakCaliber * 0.02)
		trace.maxs = Vector(Shell.DakCaliber * 0.02,Shell.DakCaliber * 0.02,Shell.DakCaliber * 0.02)
	local HEATTrace = util.TraceHull( trace )
	local HEATTraceLine = util.TraceLine( trace )

	if hook.Run("DakTankDamageCheck", HEATTrace.Entity, Owner, Shell.DakGun) == false then return end
	if HEATTrace.HitPos:Distance(Pos) > 1000 then return end

	if HEATTrace.Entity.DakHealth == nil then
		DTTE.SetupNewEnt(HEATTrace.Entity)
	end

	if (HEATTrace.Entity.DakDead == true) then
		Filter[#Filter + 1] = HEATTrace.Entity
		ContHEAT(Filter,HEATTrace.Entity,Pos,Damage,Pen,Owner,Direction,Shell,false,Recurse)
	end

	if (HEATTrace.Entity:IsValid() and not(HEATTrace.Entity:IsPlayer()) and not(HEATTrace.Entity:IsNPC()) and HEATTrace.Entity.Base ~= "base_nextbot" and (HEATTrace.Entity.DakHealth ~= nil and HEATTrace.Entity.DakHealth > 0)) or HEATTrace.Entity.DakName == "Damaged Component" then
		if (DTTE.CheckClip(HEATTrace.Entity,HEATTrace.HitPos)) or (HEATTrace.Entity:GetPhysicsObject():GetMass() <= 1 or (HEATTrace.Entity.DakIsTread == 1) and not(HEATTrace.Entity:IsVehicle()) and HEATTrace.Entity.IsDakTekFutureTech ~= 1) then
			if HEATTrace.Entity.DakArmor == nil or HEATTrace.Entity.DakBurnStacks == nil then
				DTTE.SetupNewEnt(HEATTrace.Entity)
			end
			local SA = HEATTrace.Entity:GetPhysicsObject():GetSurfaceArea()
			if HEATTrace.Entity.IsDakTekFutureTech == 1 then
				HEATTrace.Entity.DakArmor = 1000
			else
				if SA == nil then
					--Volume = (4 / 3) * math.pi*math.pow( HEATTrace.Entity:OBBMaxs().x, 3 )
					HEATTrace.Entity.DakArmor = HEATTrace.Entity:OBBMaxs().x / 2
					HEATTrace.Entity.DakIsTread = 1
				else
					if HEATTrace.Entity:GetClass() == "prop_physics" then
						DTTE.ArmorSanityCheck(HEATTrace.Entity)
					end
				end
			end
			Filter[#Filter + 1] = IgnoreEnt
			ContHEAT(Filter,HEATTrace.Entity,Pos,Damage,Pen,Owner,Direction,Shell,false,Recurse)
		else
			if HEATTrace.Entity.DakArmor == nil or HEATTrace.Entity.DakBurnStacks == nil then
				DTTE.SetupNewEnt(HEATTrace.Entity)
			end
			local SA = HEATTrace.Entity:GetPhysicsObject():GetSurfaceArea()
			if HEATTrace.Entity.IsDakTekFutureTech == 1 then
				HEATTrace.Entity.DakArmor = 1000
			else
				if SA == nil then
					--Volume = (4 / 3) * math.pi*math.pow( HEATTrace.Entity:OBBMaxs().x, 3 )
					HEATTrace.Entity.DakArmor = HEATTrace.Entity:OBBMaxs().x / 2
					HEATTrace.Entity.DakIsTread = 1
				else
					if HEATTrace.Entity:GetClass() == "prop_physics" then
						DTTE.ArmorSanityCheck(HEATTrace.Entity)
					end
				end
			end

			HEATTrace.Entity.DakLastDamagePos = HEATTrace.HitPos
			--lose 2.54mm of pen per inch of air
			local HeatPenLoss = Pos:Distance(HEATTrace.HitPos) * 2.54

			if not Triggered then
				local StandoffCalibers = 0
				if Shell.DakShellType == "HEATFS" or Shell.DakShellType == "ATGM" then
					StandoffCalibers = ((Pos:Distance(HEATTrace.HitPos) * 25.4) / Shell.DakCaliber) + 2.6
				end
				if Shell.DakShellType == "HEAT" then
					StandoffCalibers = ((Pos:Distance(HEATTrace.HitPos) * 25.4) / Shell.DakCaliber) + 1.06
				end
				if StandoffCalibers > 7.5 then
					Pen = Pen * 1.4 / (StandoffCalibers / 7.5)
				else
					Pen = Pen * math.sqrt(math.sqrt(StandoffCalibers)) / 1.185
				end
			end

			local TargetArmor = DTTE.GetArmor(HEATTrace.Entity, Shell.DakShellType, Shell.DakCaliber)

			if CanDamage(HEATTrace.Entity) then
				if HEATTrace.Entity:GetClass() == "dak_tegun" or HEATTrace.Entity:GetClass() == "dak_temachinegun" or HEATTrace.Entity:GetClass() == "dak_teautogun" then
					DTDealDamage(HEATTrace.Entity, math.Clamp(Damage * ((Pen-HeatPenLoss) / TargetArmor),0,TargetArmor * 2) * 0.001,Shell.DakGun)
					DTDealDamage(HEATTrace.Entity.Controller, math.Clamp(Damage * ((Pen-HeatPenLoss) / TargetArmor),0,TargetArmor * 2),Shell.DakGun)
				else
					DTDealDamage(HEATTrace.Entity, math.Clamp(Damage * ((Pen-HeatPenLoss) / TargetArmor),0,TargetArmor * 2),Shell.DakGun)
				end
			end
			--print("Secondary Impact Damage")
			--print(math.Clamp(Damage * ((Pen-HeatPenLoss) / TargetArmor),0,TargetArmor * 2))

			DestroyEnt(HEATTrace.Entity, Filter, Shell)

			local EffArmor = (TargetArmor / math.abs(HEATTraceLine.HitNormal:Dot(Direction)))
			if HEATTrace.Entity.IsComposite == 1 or (HEATTrace.Entity:CPPIGetOwner() ~= nil and HEATTrace.Entity:CPPIGetOwner():IsWorld()) then
				if HEATTrace.Entity.EntityMods == nil then HEATTrace.Entity.EntityMods = {} end
				if HEATTrace.Entity.EntityMods.CompKEMult == nil then HEATTrace.Entity.EntityMods.CompKEMult = 9.2 end
				if HEATTrace.Entity.EntityMods.CompCEMult == nil then HEATTrace.Entity.EntityMods.CompCEMult = 18.4 end
				EffArmor = DTTE.CompositesTrace( HEATTrace.Entity, HEATTrace.HitPos, HEATTrace.Normal, Shell.Filter ) * HEATTrace.Entity.EntityMods.CompCEMult
				if Shell.IsTandem == true then
					if HEATTrace.Entity.IsERA == 1 then
						EffArmor = 0
					end
				end
			end
			if EffArmor < (Pen - HeatPenLoss) and HEATTrace.Entity.IsDakTekFutureTech == nil then
				--decals don't like using the adjusted by normal Pos
				util.Decal( "Impact.Concrete", HEATTrace.HitPos - (Direction * 5), HEATTrace.HitPos + (Direction * 5), {Shell.DakGun})
				util.Decal( "Impact.Concrete", HEATTrace.HitPos + (Direction * 5), HEATTrace.HitPos - (Direction * 5), {Shell.DakGun})
				if HEATTrace.Entity:GetClass() == "dak_crew" or HEATTrace.Entity:GetClass() == "dak_gamemode_bot2" or HEATTrace.Entity:IsPlayer() or HEATTrace.Entity:IsNPC() then
					util.Decal( "Blood", HEATTrace.HitPos - (Direction * 5), HEATTrace.HitPos + (Direction * 500), Shell.DakGun)
					util.Decal( "Blood", HEATTrace.HitPos - (Direction * 5), HEATTrace.HitPos + (Direction * 500), HEATTrace.Entity)
				end
				Filter[#Filter + 1] = IgnoreEnt
				Filter[#Filter + 1] = HEATTrace.Entity
				DTSpall(Pos,EffArmor,HEATTrace.Entity,Shell.DakCaliber,math.Clamp(Pen-HeatPenLoss,Pen * 0.05,Pen),Owner,Shell, Direction:Angle():Forward())
				ContHEAT(Filter,HEATTrace.Entity,HEATTrace.HitPos,Damage * (1-EffArmor / (Pen-HeatPenLoss)),(Pen-HeatPenLoss) - EffArmor,Owner,Direction,Shell,true,Recurse)
			else
				--decals don't like using the adjusted by normal Pos
				util.Decal( "Impact.Glass", HEATTrace.HitPos - (Direction * 5), HEATTrace.HitPos + (Direction * 5), {Shell.DakGun, HitEnt})
				if HEATTrace.Entity:GetClass() == "dak_crew" or HEATTrace.Entity:GetClass() == "dak_gamemode_bot2" or HEATTrace.Entity:IsPlayer() or HEATTrace.Entity:IsNPC() then
					util.Decal( "Blood", HEATTrace.HitPos - (Direction * 5), HEATTrace.HitPos + (Direction * 500), Shell.DakGun)
				end
			end
		end
	end

	local effectdata = EffectData()
	effectdata:SetStart(Pos)
	effectdata:SetScale(Shell.DakCaliber * 0.393701)

	if HEATTrace.Entity:IsValid() then
		KillEnemy(HEATTrace.Entity, Owner, Shell, 1, Damage, 500)

		effectdata:SetOrigin(HEATTrace.HitPos)
	else
		effectdata:SetOrigin(Pos + Direction * (Pen / 2.54))
	end

	util.Effect("dakteballistictracer", effectdata)
end

function DTHEAT(Pos, HitEnt, Caliber, Pen, Damage, Owner, Shell)
	local IsHEATFS = Shell.DakShellType == "HEATFS" or Shell.DakShellType == "ATGM"
	local HEATPen = Pen
	local HEATDamage = IsHEATFS and Damage or Damage / 5
	local Filter = {HitEnt}
	local Direction = Shell.DakVelocity:GetNormalized()

	local trace = {}
	trace.start = Pos - Direction * 250
	trace.endpos = Pos + Direction * 1000
	trace.filter = Filter
	trace.mins = Vector(-Caliber * 0.02,-Caliber * 0.02,-Caliber * 0.02)
	trace.maxs = Vector(Caliber * 0.02,Caliber * 0.02,Caliber * 0.02)

	local HEATTrace = util.TraceHull( trace )
	local HEATTraceLine = util.TraceLine( trace )

	if hook.Run("DakTankDamageCheck", HEATTrace.Entity, Owner, Shell.DakGun) == false then return end
	if HEATTrace.HitPos:Distance(Pos) > 1000 then return end

	if HEATTrace.Entity.DakHealth == nil then
		DTTE.SetupNewEnt(HEATTrace.Entity)
	end

	if (HEATTrace.Entity.DakDead == true) then
		Filter[#Filter + 1] = HEATTrace.Entity
		ContHEAT(Filter,HEATTrace.Entity,Pos,HEATDamage,HEATPen,Owner,Direction,Shell,false)
	end

	if (HEATTrace.Entity:IsValid() and not(HEATTrace.Entity:IsPlayer()) and not(HEATTrace.Entity:IsNPC()) and not(HEATTrace.Entity.Base == "base_nextbot") and (HEATTrace.Entity.DakHealth ~= nil and HEATTrace.Entity.DakHealth > 0)) or (HEATTrace.Entity.DakName == "Damaged Component") then
		if HEATTrace.Entity.DakArmor == nil or HEATTrace.Entity.DakBurnStacks == nil then
			DTTE.SetupNewEnt(HEATTrace.Entity)
		end
		local SA = HEATTrace.Entity:GetPhysicsObject():GetSurfaceArea()
		if HEATTrace.Entity.IsDakTekFutureTech == 1 then
			HEATTrace.Entity.DakArmor = 1000
		else
			if SA == nil then
				--Volume = (4 / 3) * math.pi*math.pow( HEATTrace.Entity:OBBMaxs().x, 3 )
				HEATTrace.Entity.DakArmor = HEATTrace.Entity:OBBMaxs().x / 2
				HEATTrace.Entity.DakIsTread = 1
			else
				if HEATTrace.Entity:GetClass() == "prop_physics" then
					DTTE.ArmorSanityCheck(HEATTrace.Entity)
				end
			end
		end

		if (DTTE.CheckClip(HEATTrace.Entity,HEATTrace.HitPos)) or (HEATTrace.Entity:GetPhysicsObject():GetMass() <= 1 or (HEATTrace.Entity.DakIsTread == 1) and not(HEATTrace.Entity:IsVehicle()) and HEATTrace.Entity.IsDakTekFutureTech ~= 1) then
			ContHEAT(Filter,HEATTrace.Entity,Pos,HEATDamage,HEATPen,Owner,Direction,Shell,false)
		else
			HEATTrace.Entity.DakLastDamagePos = HEATTrace.HitPos
			--lose 2.54mm of pen per inch of air
			local HeatPenLoss = Pos:Distance(HEATTrace.HitPos) * 2.54

			local CaliberAddition = IsHEATFS and 2.6 or 1.06
			local StandoffCalibers = ((Pos:Distance(HEATTrace.HitPos) * 25.4) / Shell.DakCaliber) + CaliberAddition
			if StandoffCalibers > 7.5 then
				HEATPen = HEATPen * 1.4 / (StandoffCalibers / 7.5)
			else
				HEATPen = HEATPen * math.sqrt(math.sqrt(StandoffCalibers)) / 1.185
			end

			local TargetArmor = DTTE.GetArmor(HEATTrace.Entity, Shell.DakShellType, Shell.DakCaliber)

			if CanDamage(HEATTrace.Entity) then
				if HEATTrace.Entity:GetClass() == "dak_tegun" or HEATTrace.Entity:GetClass() == "dak_temachinegun" or HEATTrace.Entity:GetClass() == "dak_teautogun" then
					DTDealDamage(HEATTrace.Entity, math.Clamp(HEATDamage * (math.Clamp(HEATPen-HeatPenLoss,HEATPen * 0.05,HEATPen) / TargetArmor),0,TargetArmor * 2) * 0.001,Shell.DakGun)
					DTDealDamage(HEATTrace.Entity.Controller, math.Clamp(HEATDamage * (math.Clamp(HEATPen-HeatPenLoss,HEATPen * 0.05,HEATPen) / TargetArmor),0,TargetArmor * 2),Shell.DakGun)
				else
					DTDealDamage(HEATTrace.Entity, math.Clamp(HEATDamage * (math.Clamp(HEATPen-HeatPenLoss,HEATPen * 0.05,HEATPen) / TargetArmor),0,TargetArmor * 2),Shell.DakGun)
				end
			end
			--print("First Impact Damage")
			--print(math.Clamp(HEATDamage * (math.Clamp(HEATPen-HeatPenLoss,HEATPen * 0.05,HEATPen) / TargetArmor),0,TargetArmor * 2))

			DestroyEnt(HEATTrace.Entity, Filter, Shell)

			local EffArmor = (TargetArmor / math.abs(HEATTraceLine.HitNormal:Dot(Direction)))
			if HEATTrace.Entity.IsComposite == 1 or (HEATTrace.Entity:CPPIGetOwner() ~= nil and HEATTrace.Entity:CPPIGetOwner():IsWorld()) then
				if HEATTrace.Entity.EntityMods == nil then HEATTrace.Entity.EntityMods = {} end
				if HEATTrace.Entity.EntityMods.CompKEMult == nil then HEATTrace.Entity.EntityMods.CompKEMult = 9.2 end
				if HEATTrace.Entity.EntityMods.CompCEMult == nil then HEATTrace.Entity.EntityMods.CompCEMult = 18.4 end
				EffArmor = DTTE.CompositesTrace( HEATTrace.Entity, HEATTrace.HitPos, HEATTrace.Normal, Shell.Filter ) * HEATTrace.Entity.EntityMods.CompCEMult
				if Shell.IsTandem == true then
					if HEATTrace.Entity.IsERA == 1 then
						EffArmor = 0
					end
				end
			end
			if EffArmor < math.Clamp(HEATPen-HeatPenLoss,HEATPen * 0.05,HEATPen) and HEATTrace.Entity.IsDakTekFutureTech == nil then
				Filter[#Filter + 1] = HEATTrace.Entity
				--decals don't like using the adjusted by normal Pos
				util.Decal( "Impact.Concrete", HEATTrace.HitPos - (Direction * 5), HEATTrace.HitPos + (Direction * 5), {Shell.DakGun})
				util.Decal( "Impact.Concrete", HEATTrace.HitPos + (Direction * 5), HEATTrace.HitPos - (Direction * 5), {Shell.DakGun})
				if HEATTrace.Entity:GetClass() == "dak_crew" or HEATTrace.Entity:GetClass() == "dak_gamemode_bot2" or HEATTrace.Entity:IsPlayer() or HEATTrace.Entity:IsNPC() then
					util.Decal( "Blood", HEATTrace.HitPos - (Direction * 5), HEATTrace.HitPos + (Direction * 500), Shell.DakGun)
					util.Decal( "Blood", HEATTrace.HitPos - (Direction * 5), HEATTrace.HitPos + (Direction * 500), HEATTrace.Entity)
				end
				DTSpall(Pos,EffArmor,HEATTrace.Entity,Shell.DakCaliber,math.Clamp(HEATPen-HeatPenLoss,HEATPen * 0.05,HEATPen),Owner,Shell, Direction:Angle():Forward())
				local FinalDirection = IsHEATFS and Direction:Angle():Forward() or Direction:Angle()
				ContHEAT(Filter,HEATTrace.Entity,HEATTrace.HitPos,HEATDamage * (1-EffArmor / math.Clamp(HEATPen-HeatPenLoss,HEATPen * 0.05,HEATPen)),math.Clamp(HEATPen-HeatPenLoss,HEATPen * 0.05,HEATPen) - EffArmor,Owner,FinalDirection,Shell,true)
			else
				--decals don't like using the adjusted by normal Pos
				util.Decal( "Impact.Glass", HEATTrace.HitPos - (Direction * 5), HEATTrace.HitPos + (Direction * 5), {Shell.DakGun,HitEnt})
				if HEATTrace.Entity:GetClass() == "dak_crew" or HEATTrace.Entity:GetClass() == "dak_gamemode_bot2" or HEATTrace.Entity:IsPlayer() or HEATTrace.Entity:IsNPC() then
					util.Decal( "Blood", HEATTrace.HitPos - (Direction * 5), HEATTrace.HitPos + (Direction * 500), Shell.DakGun)
				end
			end
		end
	end

	local effectdata = EffectData()
	effectdata:SetStart(Pos)
	effectdata:SetScale(Shell.DakCaliber * 0.00393701)

	if HEATTrace.Entity:IsValid() then
		KillEnemy(HEATTrace.Entity, Owner, Shell, 1, HEATDamage, 500)

		effectdata:SetOrigin(HEATTrace.HitPos)
	else
		effectdata:SetOrigin(Pos + Direction * (Pen / 2.54))
	end

	util.Effect("dakteballistictracer", effectdata)
end

function DTShellHit(Start, End, HitEnt, Shell, Normal)
	if Shell.Hits ~= nil and Shell.Hits > 50 then
		Shell.RemoveNow = 1
		print("ERROR: Shell Recurse Loop")
	return end
	Shell.Hits = 1
	local Step = (Shell.DakVelocity * 0.1) -- - (-physenv.GetGravity() * ((Shell.LifeTime-0.1) ^ 2) / 2)
	if Shell.FinishedBouncing == 1 and Shell.LifeTime == 0.1 then --figure out if this really is at lifetime 0.1 or 0 after trace fix
		Start = End
		Shell.FinishedBouncing = 0
	else
		Start = End-Step
	end
	if Shell.LifeTime == 0.0 then
		Start = End
	end
	End = End + Step
	local newtrace = {}
		newtrace.start = Start
		newtrace.endpos = End
		newtrace.filter = Shell.Filter
		newtrace.mins = Vector(-Shell.DakCaliber * 0.02,-Shell.DakCaliber * 0.02,-Shell.DakCaliber * 0.02)
		newtrace.maxs = Vector(Shell.DakCaliber * 0.02,Shell.DakCaliber * 0.02,Shell.DakCaliber * 0.02)
	local HitCheckShellTrace = util.TraceHull( newtrace )
	local HitCheckShellLineTrace = util.TraceLine( newtrace )
	Normal = HitCheckShellLineTrace.HitNormal
	HitEnt = HitCheckShellTrace.Entity
	local HitPos = HitCheckShellTrace.HitPos

	if hook.Run("DakTankDamageCheck", HitEnt, Shell.DakGun.DakOwner, Shell.DakGun) == false then return end
	if not Shell.DakGun then return end --Not ideal, but better than breaking the system entirely.

	if HitEnt.DakHealth == nil then
		DTTE.SetupNewEnt(HitEnt)
	end
	if (HitEnt.DakDead == true) then
		Shell.Filter[#Shell.Filter + 1] = HitEnt
		DTShellContinue(Start,End,Shell,Normal,true)
	end
	if (HitEnt:IsValid() and HitEnt:GetPhysicsObject():IsValid() and not(HitEnt:IsPlayer()) and not(HitEnt:IsNPC()) and not(HitEnt.Base == "base_nextbot") and (HitEnt.DakHealth ~= nil and HitEnt.DakHealth > 0)) or (HitEnt.DakName == "Damaged Component") then
		if (DTTE.CheckClip(HitEnt,HitPos)) or (HitEnt:GetPhysicsObject():GetMass() <= 1 and not(HitEnt:IsVehicle()) and HitEnt.IsDakTekFutureTech ~= 1) or HitEnt.DakName == "Damaged Component" then
			if HitEnt.DakArmor == nil or HitEnt.DakBurnStacks == nil then
				DTTE.SetupNewEnt(HitEnt)
			end
			local SA = HitEnt:GetPhysicsObject():GetSurfaceArea()
			if HitEnt.DakBurnStacks == nil then
				HitEnt.DakBurnStacks = 0
			end
			if HitEnt.IsDakTekFutureTech == 1 then
				HitEnt.DakArmor = 1000
			else
				if SA == nil then
					--Volume = (4 / 3) * math.pi*math.pow( HitEnt:OBBMaxs().x, 3 )
					HitEnt.DakArmor = HitEnt:OBBMaxs().x / 2
					HitEnt.DakIsTread = 1
				else
					if HitEnt:GetClass() == "prop_physics" then
						DTTE.ArmorSanityCheck(HitEnt)
					end
				end
			end
			Shell.Filter[#Shell.Filter + 1] = HitEnt
			DTShellContinue(Start,End,Shell,Normal,true)
		else
			if HitEnt.DakArmor == nil or HitEnt.DakBurnStacks == nil then
				DTTE.SetupNewEnt(HitEnt)
			end
			local SA = HitEnt:GetPhysicsObject():GetSurfaceArea()
			if HitEnt.IsDakTekFutureTech == 1 then
				HitEnt.DakArmor = 1000
			else
				if SA == nil then
					--Volume = (4 / 3) * math.pi*math.pow( HitEnt:OBBMaxs().x, 3 )
					HitEnt.DakArmor = HitEnt:OBBMaxs().x / 2
					HitEnt.DakIsTread = 1
				else
					if HitEnt:GetClass() == "prop_physics" then
						DTTE.ArmorSanityCheck(HitEnt)
					end
				end
			end

			HitEnt.DakLastDamagePos = HitPos

			local Vel = Shell.DakVelocity:GetNormalized()
			local EffArmor = 0

			local CurrentPen = Shell.DakPenetration-Shell.DakPenetration * (Shell.DakVelocity:Distance( Vector(0,0,0) )) * Shell.LifeTime * (Shell.DakPenLossPerMeter / 52.49)

			local HitAng = math.deg(math.acos(Normal:Dot( -Vel:GetNormalized() )))

			local TDRatio = 0
			local PenRatio = 0
			local CompArmor
			if HitEnt.IsComposite == 1 or (HitEnt:CPPIGetOwner() ~= nil and HitEnt:CPPIGetOwner():IsWorld()) then
				CompArmor = DTTE.CompositesTrace( HitEnt, HitPos, Shell.DakVelocity:GetNormalized(), Shell.Filter )
				if HitEnt.EntityMods == nil then HitEnt.EntityMods = {} end
				if HitEnt.EntityMods.CompKEMult == nil then HitEnt.EntityMods.CompKEMult = 9.2 end
				if HitEnt.EntityMods.CompCEMult == nil then HitEnt.EntityMods.CompCEMult = 18.4 end
				if Shell.DakShellType == "HEAT" or Shell.DakShellType == "HEATFS" or Shell.DakShellType == "ATGM" or Shell.DakShellType == "HESH" then
					CompArmor = CompArmor * HitEnt.EntityMods.CompCEMult
					if Shell.IsTandem == true then
						if HitEnt.IsERA == 1 then
							CompArmor = 0
						end
					end
				else
					CompArmor = CompArmor * HitEnt.EntityMods.CompKEMult
				end
				if Shell.DakShellType == "APFSDS" or Shell.DakShellType == "APDS" then
					if Shell.DakShellType == "APFSDS" then
						TDRatio = (CompArmor / 3) / (Shell.DakCaliber * 2.5)
					else
						TDRatio = (CompArmor / 3) / (Shell.DakCaliber * 1.75)
					end
				else
					TDRatio = (CompArmor / 3) / Shell.DakCaliber
				end
				PenRatio = CurrentPen / CompArmor
			else
				if Shell.DakShellType == "APFSDS" or Shell.DakShellType == "APDS" then
					if Shell.DakShellType == "APFSDS" then
						TDRatio = HitEnt.DakArmor / (Shell.DakCaliber * 2.5)
					else
						TDRatio = HitEnt.DakArmor / (Shell.DakCaliber * 1.75)
					end
				else
					TDRatio = HitEnt.DakArmor / Shell.DakCaliber
				end
				PenRatio = CurrentPen / DTTE.GetArmor(HitEnt, Shell.DakShellType, Shell.DakCaliber)
			end
			--shattering occurs when TD ratio is above 0.8 and pen is 1.05 to 1.25 times more than the armor
			--random chance to pen happens between 0.9 and 1.2 pen to armor ratio
			--if pen to armor ratio is 0.9 or below round fails
			--if T/D ratio is above 0.8 and round pens it still shatters
			--round must also be going above 600m/s
			local Failed = 0
			local Shattered = 0
			local ShatterVel = 600
			if Shell.DakShellType == "APFSDS" then
				ShatterVel = 1500
			end
			if Shell.DakShellType == "APDS" then
				ShatterVel = 1050
			end
			if (Shell.DakVelocity:Distance( Vector(0,0,0) )) * 0.0254 > ShatterVel and not(Shell.DakShellType == "HEAT" or Shell.DakShellType == "HEATFS" or Shell.DakShellType == "ATGM" or Shell.DakShellType == "HESH") then
				if TDRatio > 0.8 then
					if PenRatio < 0.9 then
						Failed = 1
						Shattered = 0
					end
					if PenRatio >= 0.9 and PenRatio < 1.05 then
						Failed = math.random(0,1)
						Shattered = 0
					end
					if PenRatio >= 1.05 and PenRatio < 1.25 then
						Failed = 1
						Shattered = 1
					end
					if PenRatio >= 1.25 then
						Failed = 0
						Shattered = 1
					end
				else
					if PenRatio < 0.9 then
						Failed = 1
						Shattered = 0
					end
					if PenRatio >= 0.9 and PenRatio < 1.20 then
						Failed = math.random(0,1)
						Shattered = 0
					end
					if PenRatio >= 1.20 then
						Failed = 0
						Shattered = 0
					end
				end
			end
			if HitAng >= 70 and HitEnt.DakArmor >= Shell.DakCaliber * 0.85 and (Shell.DakShellType == "APFSDS" or Shell.DakShellType == "APDS") then Shattered = 1 end
			if HitAng >= 80 and HitEnt.DakArmor >= Shell.DakCaliber * 0.85 and (Shell.DakShellType == "APFSDS" or Shell.DakShellType == "APDS") then Shattered = 1 Failed = 1 end
			if HitEnt.IsComposite == 1 or (HitEnt:CPPIGetOwner() ~= nil and HitEnt:CPPIGetOwner():IsWorld()) then
				if HitEnt.EntityMods == nil then HitEnt.EntityMods = {} end
				if HitEnt.EntityMods.CompKEMult == nil then HitEnt.EntityMods.CompKEMult = 9.2 end
				if HitEnt.EntityMods.CompCEMult == nil then HitEnt.EntityMods.CompCEMult = 18.4 end
				EffArmor = CompArmor
				if Shell.DakShellType == "HEAT" or Shell.DakShellType == "HEATFS" or Shell.DakShellType == "ATGM" then
					EffArmor = EffArmor
				end
			else
				if Shell.DakShellType == "HEAT" or Shell.DakShellType == "HEATFS" or Shell.DakShellType == "ATGM" then
					EffArmor = (DTTE.GetArmor(HitEnt, Shell.DakShellType, Shell.DakCaliber) / math.abs(Normal:Dot(Vel:GetNormalized())) )
				end
				if Shell.DakShellType == "AP" or Shell.DakShellType == "APHE" or Shell.DakShellType == "HE" or Shell.DakShellType == "HVAP" or Shell.DakShellType == "SM" or Shell.DakShellType == "HESH" then
					if HitAng > 24 then
						local aVal = 2.251132 - 0.1955696 * math.max( HitAng, 24 ) + 0.009955601 * math.pow( math.max( HitAng, 24 ), 2 ) - 0.0001919089 * math.pow( math.max( HitAng, 24 ), 3 ) + 0.000001397442 * math.pow( math.max( HitAng, 20 ), 4 )
						local bVal = 0.04411227 - 0.003575789 * math.max( HitAng, 24 ) + 0.0001886652 * math.pow( math.max( HitAng, 24 ), 2 ) - 0.000001151088 * math.pow( math.max( HitAng, 24 ), 3 ) + 1.053822e-9 * math.pow( math.max( HitAng, 20 ), 4 )
						EffArmor = math.Clamp(DTTE.GetArmor(HitEnt, Shell.DakShellType, Shell.DakCaliber) * (aVal * math.pow( TDRatio, bVal )),DTTE.GetArmor(HitEnt, Shell.DakShellType, Shell.DakCaliber),10000000000)
					else
						EffArmor = (DTTE.GetArmor(HitEnt, Shell.DakShellType, Shell.DakCaliber) / math.abs(Normal:Dot(Vel:GetNormalized())) )
					end
				end
				if Shell.DakShellType == "APDS" then
					EffArmor = DTTE.GetArmor(HitEnt, Shell.DakShellType, Shell.DakCaliber) * math.pow( 2.71828, math.pow( HitAng, 2.6 ) * 0.00003011 )
				end
				if Shell.DakShellType == "APFSDS" then
					EffArmor = DTTE.GetArmor(HitEnt, Shell.DakShellType, Shell.DakCaliber) * math.pow( 2.71828, math.pow( HitAng, 2.6 ) * 0.00003011 )
				end
			end
			if HitAng >= 70 and EffArmor >= 5 and (Shell.DakShellType == "HEAT" or Shell.DakShellType == "HEATFS" or Shell.DakShellType == "ATGM" or Shell.DakShellType == "HESH") then Shattered = 1 end
			if HitAng >= 80 and EffArmor >= 5 and (Shell.DakShellType == "HEAT" or Shell.DakShellType == "HEATFS" or Shell.DakShellType == "ATGM" or Shell.DakShellType == "HESH") then Shattered = 1 Failed = 1 end
			if EffArmor < CurrentPen and HitEnt.IsDakTekFutureTech == nil and Failed == 0 then
				if CanDamage(HitEnt) then
					if HitEnt:GetClass() == "dak_tegun" or HitEnt:GetClass() == "dak_temachinegun" or HitEnt:GetClass() == "dak_teautogun" then
						DTDealDamage(HitEnt,math.Clamp(Shell.DakDamage * (CurrentPen / DTTE.GetArmor(HitEnt, Shell.DakShellType, Shell.DakCaliber)),0,DTTE.GetArmor(HitEnt, Shell.DakShellType, Shell.DakCaliber) * 2) * 0.001,Shell.DakGun)
						DTDealDamage(HitEnt.Controller,math.Clamp(Shell.DakDamage * (CurrentPen / DTTE.GetArmor(HitEnt, Shell.DakShellType, Shell.DakCaliber)),0,DTTE.GetArmor(HitEnt, Shell.DakShellType, Shell.DakCaliber) * 2),Shell.DakGun)
					else
						DTDealDamage(HitEnt,math.Clamp(Shell.DakDamage * (CurrentPen / DTTE.GetArmor(HitEnt, Shell.DakShellType, Shell.DakCaliber)),0,DTTE.GetArmor(HitEnt, Shell.DakShellType, Shell.DakCaliber) * 2),Shell.DakGun)
					end
				end
				--print("Shell Hit Function First Impact Damage")
				--print(math.Clamp(Shell.DakDamage * (CurrentPen / DTTE.GetArmor(HitEnt, Shell.DakShellType, Shell.DakCaliber)),0,DTTE.GetArmor(HitEnt, Shell.DakShellType, Shell.DakCaliber) * 2))
				if (HitEnt:IsValid() and HitEnt.Base ~= "base_nextbot" and HitEnt:GetClass() ~= "prop_ragdoll") and Shell.DakIsFlame ~= 1 then
					HitEnt:DTShellApplyForce(HitPos,Normal,Shell)
				end
				Shell.Filter[#Shell.Filter + 1] = HitEnt
				if Shattered == 1 then
					if Shell.DakShellType == "HEAT" or Shell.DakShellType == "HEATFS" or Shell.DakShellType == "ATGM" then
						DTSpall(HitPos,EffArmor,HitEnt,Shell.DakCaliber * 0.5,CurrentPen,Shell.DakGun.DakOwner,Shell,Shell.DakVelocity:GetNormalized())
					else
						DTSpall(HitPos,EffArmor,HitEnt,Shell.DakCaliber * 2,CurrentPen,Shell.DakGun.DakOwner,Shell,Shell.DakVelocity:GetNormalized())
					end
				else
					DTSpall(HitPos,EffArmor,HitEnt,Shell.DakCaliber,CurrentPen,Shell.DakGun.DakOwner,Shell,Shell.DakVelocity:GetNormalized())
				end
				local effectdata = EffectData()
				effectdata:SetOrigin(HitPos)
				effectdata:SetEntity(HitEnt)
				effectdata:SetAttachment(1)
				effectdata:SetMagnitude(.5)
				effectdata:SetScale(Shell.DakCaliber * 0.25)
				if HitEnt:GetClass() ~= "dak_gamemode_bot2" and not(HitEnt:IsPlayer()) and not(HitEnt:IsNPC()) then
					util.Effect("dakteshellpenetrate", effectdata, true, true)
				else
					util.Decal( "Blood", HitPos - ((HitPos-Start):GetNormalized() * 5), HitPos + ((HitPos-Start):GetNormalized() * 500), Shell.DakGun)
					util.Decal( "Blood", HitPos - ((HitPos-Start):GetNormalized() * 5), HitPos + ((HitPos-Start):GetNormalized() * 500), HitEnt)
				end
				util.Decal( "Impact.Concrete", HitPos - ((HitPos-Start):GetNormalized() * 5), HitPos + ((HitPos-Start):GetNormalized() * 5), Shell.DakGun)
				util.Decal( "Impact.Concrete", HitPos + ((HitPos-Start):GetNormalized() * 5), HitPos - ((HitPos-Start):GetNormalized() * 5), Shell.DakGun)
				if HitEnt:GetClass() == "dak_crew" then
					util.Decal( "Blood", HitPos - ((HitPos-Start):GetNormalized() * 5), HitPos + ((HitPos-Start):GetNormalized() * 500), Shell.DakGun)
					util.Decal( "Blood", HitPos - ((HitPos-Start):GetNormalized() * 5), HitPos + ((HitPos-Start):GetNormalized() * 500), HitEnt)
				end
				Shell.DakVelocity = Shell.DakVelocity - Shell.DakVelocity * (EffArmor / Shell.DakPenetration)
				Shell.Pos = HitPos
				Shell.DakDamage = Shell.DakDamage-Shell.DakDamage * (EffArmor / Shell.DakPenetration)
				Shell.DakPenetration = Shell.DakPenetration-EffArmor
				if Shattered == 1 then
					Shell.DakDamage = Shell.DakDamage * 0.5
					Shell.DakPenetration = Shell.DakPenetration * 0.5
					Shell.DakVelocity = Shell.DakVelocity * 0.5
				end
				--soundhere penetrate sound
				if Shell.DakIsPellet then
					sound.Play( Shell.DakPenSounds[math.random(1,#Shell.DakPenSounds)], HitPos, 100, 150, 0.25 )
				else
					sound.Play( Shell.DakPenSounds[math.random(1,#Shell.DakPenSounds)], HitPos, 100, 100, 1 )
				end
				if Shell.DakShellType == "HEAT" or Shell.DakShellType == "HEATFS" or Shell.DakShellType == "ATGM" then
					if Shell.DakShellType == "HEAT" or Shell.DakShellType == "HEATFS" or Shell.DakShellType == "ATGM" then
						Shell.LifeTime = 0
						DTHEAT(HitPos,HitEnt,Shell.DakCaliber,Shell.DakPenetration,Shell.DakDamage,Shell.DakGun.DakOwner,Shell)
						Shell.HeatPen = true
					end
					Shell.Pos = HitPos
					Shell.LifeTime = 0
					Shell.DakVelocity = Vector(0,0,0)
					Shell.DakDamage = 0
					Shell.ExplodeNow = true
				else
					DTShellContinue(Start,End,Shell,Normal)
					Shell.LifeTime = 0
				end
			else
				if Shell.DakShellType == "HESH" then
					if HitEnt.IsComposite == 1 or (HitEnt:CPPIGetOwner() ~= nil and HitEnt:CPPIGetOwner():IsWorld()) then
						local ArmorCheck = Shell.DakCaliber * 1.25 > CompArmor or Shell.DakCaliber * 1.25 > DTTE.GetArmor(HitEnt, Shell.DakShellType, Shell.DakCaliber)

						if ArmorCheck and HitAng < 80 then
							Shell.Filter[#Shell.Filter + 1] = HitEnt
							Shell.HeatPen = true
							DTSpall(HitPos,EffArmor,HitEnt,Shell.DakCaliber,Shell.DakCaliber * 1.25,Shell.DakGun.DakOwner,Shell,((HitPos - (Normal * 2)) - HitPos):Angle():Forward())
							Shell.Pos = HitPos
							Shell.LifeTime = 0
							Shell.DakVelocity = Vector(0,0,0)
							Shell.DakDamage = 0
							Shell.ExplodeNow = true
						end
					end
				end
				if Shell.DakShellType == "HE" then
					if HitEnt.IsComposite == 1 or (HitEnt:CPPIGetOwner() ~= nil and HitEnt:CPPIGetOwner():IsWorld()) then
						local ArmorCheck = Shell.DakFragPen * 10 > CompArmor or Shell.DakFragPen * 10 > DTTE.GetArmor(HitEnt, Shell.DakShellType, Shell.DakCaliber)

						if ArmorCheck and HitAng < 70 then
							Shell.Filter[#Shell.Filter + 1] = HitEnt
							Shell.HeatPen = true
							DTSpall(HitPos,EffArmor,HitEnt,Shell.DakCaliber,Shell.DakFragPen * 10,Shell.DakGun.DakOwner,Shell,((HitPos - (Normal * 2)) - HitPos):Angle():Forward())
							Shell.Pos = HitPos
							Shell.LifeTime = 0
							Shell.DakVelocity = Vector(0,0,0)
							Shell.DakDamage = 0
							Shell.ExplodeNow = true
						end
					end
				end
				if CanDamage(HitEnt) then
					if HitEnt:GetClass() == "dak_tegun" or HitEnt:GetClass() == "dak_temachinegun" or HitEnt:GetClass() == "dak_teautogun" then
						DTDealDamage(HitEnt,Shell.DakDamage * 0.25 * 0.001,Shell.DakGun)
						DTDealDamage(HitEnt.Controller,Shell.DakDamage * 0.25,Shell.DakGun)
					else
						DTDealDamage(HitEnt,Shell.DakDamage * 0.25,Shell.DakGun)
					end
				end
				--print("Shell Hit Function First Impact Damage Fail Pen")
				--print(Shell.DakDamage * 0.25)
				if Shell.DakIsFlame == 1 then
					if SA then
						if HitEnt.DakArmor > (7.8125 * (HitEnt:GetPhysicsObject():GetMass() / 4.6311781) * (288 / SA)) * 0.5 then
							if HitEnt.DakBurnStacks == nil then
								HitEnt.DakBurnStacks = 0
							end
							HitEnt.DakBurnStacks = HitEnt.DakBurnStacks + 1
						end
					end
				end
				if (HitEnt:IsValid() and HitEnt.Base ~= "base_nextbot" and HitEnt:GetClass() ~= "prop_ragdoll") and Shell.DakIsFlame ~= 1 then
					HitEnt:DTShellApplyForce(HitPos,Normal,Shell)
				end

				--print( math.deg(math.acos(Normal:Dot( -Vel:GetNormalized() ))) ) -- hit angle
				local effectdata = EffectData()
				if Shell.DakIsFlame == 1 then
					DTTE.SpawnFire(HitPos, Shell.DakGun.DakOwner, Shell.DakGun)
				else
					Shell.Filter[#Shell.Filter + 1] = HitEnt
					if Shell.DakDamage >= 0 then
						util.Decal( "Impact.Glass", HitPos - ((HitPos-Start):GetNormalized() * 5), HitPos + ((HitPos-Start):GetNormalized() * 5), Shell.DakGun)
						if HitEnt:GetClass() == "dak_crew" or HitEnt:GetClass() == "dak_gamemode_bot2" or HitEnt:IsPlayer() or HitEnt:IsNPC() then
							util.Decal( "Blood", HitPos - ((HitPos-Start):GetNormalized() * 5), HitPos + ((HitPos-Start):GetNormalized() * 500), Shell.DakGun)
						end
						local Bounce = 0
						if (90-HitAng) <= 45 then
							local RNG = math.random(0,100)
							if (90-HitAng) <= 45 and (90-HitAng) > 30 then
								if RNG <= 25 then Bounce = 1 end
							end
							if (90-HitAng) <= 30 and (90-HitAng) > 20 then
								if RNG <= 50 then Bounce = 1 end
							end
							if (90-HitAng) <= 20 and (90-HitAng) > 10 then
								if RNG <= 75 then Bounce = 1 end
							end
							if (90-HitAng) <= 10 then
								Bounce = 1
							end
						else
							Bounce = 0
						end
						Bounce = 0
						if Shell.DakShellType == "HESH" or Shell.DakShellType == "ATGM" or Shell.DakIsFlame == 1 then Bounce = 0 end
						if Bounce == 1 then
							effectdata:SetOrigin(HitPos)
							effectdata:SetEntity(Shell.DakGun)
							effectdata:SetAttachment(1)
							effectdata:SetMagnitude(.5)
							effectdata:SetScale(Shell.DakCaliber * 0.25)
							util.Effect("dakteshellbounce", effectdata, true, true)
							local BounceSounds = {}
							if Shell.DakCaliber < 20 then
								BounceSounds = {"weapons/fx/rics/ric1.wav","weapons/fx/rics/ric2.wav","weapons/fx/rics/ric3.wav","weapons/fx/rics/ric4.wav","weapons/fx/rics/ric5.wav"}
							else
								BounceSounds = {"daktanks/dakrico1.mp3","daktanks/dakrico2.mp3","daktanks/dakrico3.mp3","daktanks/dakrico4.mp3","daktanks/dakrico5.mp3","daktanks/dakrico6.mp3"}
							end
							if Shell.DakIsPellet then
								sound.Play( BounceSounds[math.random(1,#BounceSounds)], HitPos, 100, 150, 0.25 )
							else
								sound.Play( BounceSounds[math.random(1,#BounceSounds)], HitPos, 100, 100, 1 )
							end
							Shell.DakVelocity = 0.5 * Shell.DakBaseVelocity * (Normal + ((HitPos - Start):GetNormalized() * 1 * (45 / (90 - HitAng)))):GetNormalized() + Angle(math.Rand(-1,1),math.Rand(-1,1),math.Rand(-1,1)):Forward()
							Shell.DakPenetration = Shell.DakPenetration * 0.5
							Shell.DakDamage = Shell.DakDamage * 0.5
							Shell.LifeTime = 0.0
							Shell.Pos = HitPos + (Normal * 2 * Shell.DakCaliber * 0.02)
							Shell.ShellThinkTime = 0
							Shell.JustBounced = 1
							DTShellContinue(HitPos + (Normal * 2 * Shell.DakCaliber * 0.02),Shell.DakVelocity:GetNormalized() * 1000,Shell,Normal,true)
							Shell.FinishedBouncing = 1
						else
							Shell.Crushed = 1
							effectdata:SetOrigin(HitPos)
							effectdata:SetEntity(Shell.DakGun)
							effectdata:SetAttachment(1)
							effectdata:SetMagnitude(.5)
							effectdata:SetScale(Shell.DakCaliber * (Shell.DakBaseVelocity / 29527.6))
							if Shell.IsFrag then
							else
								util.Effect("dakteshellimpact", effectdata, true, true)
							end
							local BounceSounds = {}
							if Shell.DakCaliber < 20 then
								BounceSounds = {"daktanks/dakrico1.mp3","daktanks/dakrico2.mp3","daktanks/dakrico3.mp3","daktanks/dakrico4.mp3","daktanks/dakrico5.mp3","daktanks/dakrico6.mp3"}
							else
								BounceSounds = {"daktanks/dakexp1.mp3","daktanks/dakexp2.mp3","daktanks/dakexp3.mp3","daktanks/dakexp4.mp3"}
							end
							if Shell.DakIsPellet then
								sound.Play( BounceSounds[math.random(1,#BounceSounds)], HitPos, 100, 150, 0.25 )
							else
								sound.Play( BounceSounds[math.random(1,#BounceSounds)], HitPos, 100, 100, 1 )
							end
							Shell.DakVelocity = Shell.DakBaseVelocity * 0.025 * (Normal + ((HitPos-Start):GetNormalized() * 1 * (45 / (90-HitAng)))):GetNormalized() --+ Angle(math.Rand(-1,1),math.Rand(-1,1),math.Rand(-1,1))
							Shell.DakPenetration = 0
							Shell.DakDamage = 0
							Shell.LifeTime = 0.0
							Shell.Pos = HitPos
							Shell.RemoveNow = 1
							if Shell.DakExplosive then
								Shell.Pos = HitPos
								Shell.LifeTime = 0
								Shell.DakVelocity = Vector(0,0,0)
								Shell.DakDamage = 0
								Shell.ExplodeNow = true
							end
						end
					end
				end
				--soundhere bounce sound
			end

			DestroyEnt(HitEnt, Shell.Filter, Shell)
		end
	end
	if HitEnt:IsValid() then
		if HitEnt:IsPlayer() or HitEnt:IsNPC() or HitEnt.Base == "base_nextbot" then
			Shell.Pos = HitPos
			if HitEnt:GetClass() == "dak_bot" then
				HitEnt:SetHealth(HitEnt:Health() - Shell.DakDamage * 500)
				if HitEnt:Health() <= 0 and HitEnt.revenge == 0 then
					--local body = ents.Create( "prop_ragdoll" )
					body:SetPos( HitEnt:GetPos() )
					body:SetModel( HitEnt:GetModel() )
					body:Spawn()
					body.DakHealth = 1000000
					body.DakMaxHealth = 1000000
					if Shell.DakIsFlame == 1 then
						body:Ignite(10,1)
					end
					--HitEnt:Remove()
					local SoundList = {"npc/metropolice/die1.wav","npc/metropolice/die2.wav","npc/metropolice/die3.wav","npc/metropolice/die4.wav","npc/metropolice/pain4.wav"}
					body:EmitSound( SoundList[math.random(5)], 100, 100, 1, 2 )
					timer.Simple( 5, function()
						body:Remove()
					end )
				end
			else
				local checkhitboxtrace = {}
					checkhitboxtrace.start = Shell.Pos + ((Shell.DakVelocity:Distance( Vector(0,0,0) )) * Shell.DakVelocity:GetNormalized() * (Shell.LifeTime-0.1)) - (-physenv.GetGravity() * ((Shell.LifeTime-0.1) ^ 2) / 2)
					checkhitboxtrace.endpos = Shell.Pos + ((Shell.DakVelocity:Distance( Vector(0,0,0) )) * Shell.DakVelocity:GetNormalized() * Shell.LifeTime) - (-physenv.GetGravity() * (Shell.LifeTime^2) / 2)
					checkhitboxtrace.filter = Shell.Filter
					checkhitboxtrace.mins = Vector(-Shell.DakCaliber * 0.02,-Shell.DakCaliber * 0.02,-Shell.DakCaliber * 0.02)
					checkhitboxtrace.maxs = Vector(Shell.DakCaliber * 0.02,Shell.DakCaliber * 0.02,Shell.DakCaliber * 0.02)
				local HitboxTrace = util.TraceHull( checkhitboxtrace )
				local Pain = DamageInfo()
				--Pain:SetDamageForce( Shell.DakVelocity:GetNormalized() * Shell.DakDamage*Shell.DakMass * (Shell.DakVelocity:Distance( Vector(0,0,0) )) )
				Pain:SetDamageForce( Shell.DakVelocity:GetNormalized() * (2500 * Shell.DakCaliber * (Shell.DakBaseVelocity / 29527.6)) )
				Pain:SetDamage( Shell.DakDamage * 250 )
				if Shell.DakGun.DakOwner and Shell and Shell.DakGun then
					Pain:SetAttacker( Shell.DakGun.DakOwner )
					Pain:SetInflictor( Shell.DakGun )
				else
					Pain:SetAttacker( game.GetWorld() )
					Pain:SetInflictor( game.GetWorld() )
				end
				Pain:SetReportedPosition( HitPos )
				Pain:SetDamagePosition( HitEnt:GetPos() )
				if Shell.DakIsFlame == 1 then
					Pain:SetDamageType(DMG_BURN)
				else
					Pain:SetDamageType(DMG_CRUSH)
				end
				HitEnt:TakeDamageInfo( Pain )
			end
			if HitEnt:Health() <= 0 and Shell.DakIsFlame ~= 1 then
				local effectdata = EffectData()
				effectdata:SetOrigin(HitPos)
				effectdata:SetEntity(HitEnt)
				effectdata:SetAttachment(1)
				effectdata:SetMagnitude(.5)
				effectdata:SetScale(Shell.DakCaliber * 0.25)
				if HitEnt:GetClass() ~= "dak_gamemode_bot2" and not(HitEnt:IsPlayer()) and not(HitEnt:IsNPC()) then
					util.Effect("dakteshellpenetrate", effectdata, true, true) --bloodeffectneeded
				else
					local blooddata = EffectData()
					blooddata:SetOrigin(HitPos)
					blooddata:SetEntity(HitEnt)
					blooddata:SetMagnitude(.5)
					blooddata:SetScale(6)
					blooddata:SetFlags(3)
					blooddata:SetColor(0)
					util.Effect( "bloodspray", effectdata, true, true )
					util.Effect( "BloodImpact", effectdata, true, true )
					util.Decal( "Blood", HitPos - ((HitPos-Start):GetNormalized() * 5), HitPos + ((HitPos-Start):GetNormalized() * 500), Shell.DakGun)
					util.Decal( "Blood", HitPos - ((HitPos-Start):GetNormalized() * 5), HitPos + ((HitPos-Start):GetNormalized() * 500), HitEnt)
				end
				util.Decal( "Impact.Concrete", HitPos - ((HitPos-Start):GetNormalized() * 5), HitPos + ((HitPos-Start):GetNormalized() * 5), Shell.DakGun)
				util.Decal( "Impact.Concrete", HitPos + ((HitPos-Start):GetNormalized() * 5), HitPos - ((HitPos-Start):GetNormalized() * 5), Shell.DakGun)
				if HitEnt:GetClass() == "dak_crew" then
					util.Decal( "Blood", HitPos - ((HitPos-Start):GetNormalized() * 5), HitPos + ((HitPos-Start):GetNormalized() * 500), Shell.DakGun)
					util.Decal( "Blood", HitPos - ((HitPos-Start):GetNormalized() * 5), HitPos + ((HitPos-Start):GetNormalized() * 500), HitEnt)
				end
				Shell.Filter[#Shell.Filter + 1] = HitEnt
				if Shell.salvage then
					Shell.Filter[#Shell.Filter + 1] = Shell.salvage
				end
				DTShellContinue(Start,End,Shell,Normal)
				--soundhere penetrate human sound
				if Shell.DakIsPellet then
					sound.Play( Shell.DakPenSounds[math.random(1,#Shell.DakPenSounds)], HitPos, 100, 150, 0.25 )
				else
					sound.Play( Shell.DakPenSounds[math.random(1,#Shell.DakPenSounds)], HitPos, 100, 100, 1 )
				end
			else
				local effectdata = EffectData()
				if Shell.DakIsFlame == 1 then
					DTTE.SpawnFire(HitPos, Shell.DakGun.DakOwner, Shell.DakGun)
				else
					effectdata:SetOrigin(HitPos)
					effectdata:SetEntity(Shell.DakGun)
					effectdata:SetAttachment(1)
					effectdata:SetMagnitude(.5)
					effectdata:SetScale(Shell.DakCaliber * (Shell.DakBaseVelocity / 29527.6))
					if Shell.IsFrag then
					else
						local blooddata = EffectData()
						blooddata:SetOrigin(HitPos)
						blooddata:SetEntity(HitEnt)
						blooddata:SetMagnitude(.5)
						blooddata:SetScale(6)
						blooddata:SetFlags(3)
						blooddata:SetColor(0)
						util.Effect( "bloodspray", effectdata, true, true )
						util.Effect( "BloodImpact", effectdata, true, true )
						--util.Effect("dakteshellimpact", effectdata, true, true) --bloodeffectneeded
					end
					util.Decal( "Impact.Concrete", HitPos - ((HitPos-Start):GetNormalized() * 5), HitPos + ((HitPos-Start):GetNormalized() * 5), Shell.DakGun)
					if HitEnt:GetClass() == "dak_crew" or HitEnt:GetClass() == "dak_gamemode_bot2" or HitEnt:IsPlayer() or HitEnt:IsNPC() then
						util.Decal( "Blood", HitPos - ((HitPos-Start):GetNormalized() * 5), HitPos + ((HitPos-Start):GetNormalized() * 500), Shell.DakGun)
					end
					local ExpSounds = {}
					if Shell.DakCaliber < 20 then
						ExpSounds = {"physics/surfaces/sand_impact_bullet1.wav","physics/surfaces/sand_impact_bullet2.wav","physics/surfaces/sand_impact_bullet3.wav","physics/surfaces/sand_impact_bullet4.wav"}
					else
						ExpSounds = {"daktanks/dakexp1.mp3","daktanks/dakexp2.mp3","daktanks/dakexp3.mp3","daktanks/dakexp4.mp3"}
					end

					if Shell.DakIsPellet then
						sound.Play( ExpSounds[math.random(1,#ExpSounds)], HitPos, 100, 150, 0.25 )
					else
						sound.Play( ExpSounds[math.random(1,#ExpSounds)], HitPos, 100, 100, 1 )
					end
				end
				Shell.RemoveNow = 1
				--if Shell.DakExplosive then
				--	Shell.ExplodeNow = true
				--end
				Shell.LifeTime = 0
				Shell.DakVelocity = Vector(0,0,0)
				Shell.DakDamage = 0
			end
		end
	end
	if HitEnt:IsWorld() or Shell.ExplodeNow == true or HitEnt == NULL then
		local Penned, Exit, Dist = DTTE.WorldPen(HitPos,Shell.DakVelocity:GetNormalized(),Shell.DakPenetration,Shell.Filter,Shell.DakCaliber)
		if Shell.DakShellType == "HEAT" or Shell.DakShellType == "HEATFS" or Shell.DakShellType == "ATGM" or Shell.DakIsFlame == 1 then
			--[[
			if Shell.DakShellType == "HEAT" or Shell.DakShellType == "HEATFS" or Shell.DakShellType == "ATGM" and Penned then
				Shell.LifeTime = 0
				DTHEAT(Exit,NULL,Shell.DakCaliber,Shell.DakPenetration,Shell.DakDamage,Shell.DakGun.DakOwner,Shell)
				Shell.HeatPen = true
			end
			--]]
			Shell.Pos = Exit
			Shell.LifeTime = 0
			Shell.DakVelocity = Vector(0,0,0)
			Shell.DakDamage = 0
			Shell.ExplodeNow = true
			Penned = false
		else
			if Penned then
				local effectdata = EffectData()
				effectdata:SetOrigin(HitPos)
				effectdata:SetEntity(HitEnt)
				effectdata:SetAttachment(1)
				effectdata:SetMagnitude(.5)
				effectdata:SetScale(Shell.DakCaliber * 0.25)
				util.Effect("dakteshellpenetrate", effectdata, true, true)
				if Shell.DakIsPellet then
					sound.Play( Shell.DakPenSounds[math.random(1,#Shell.DakPenSounds)], HitPos, 100, 150, 0.25 )
				else
					sound.Play( Shell.DakPenSounds[math.random(1,#Shell.DakPenSounds)], HitPos, 100, 100, 1 )
				end
				util.Decal( "Impact.Concrete", HitPos, Exit, Shell.DakGun)
				util.Decal( "Impact.Concrete", Exit, HitPos, Shell.DakGun)
				Shell.Pos = Exit
				DTShellContinue(Exit,End,Shell,Normal) --set new start a bit further away to prevent recurse
				Shell.LifeTime = 0
				Shell.DakVelocity = Shell.DakVelocity - (Shell.DakVelocity * (Dist / Shell.DakPenetration))
				Shell.DakDamage = Shell.DakDamage - (Shell.DakDamage * (Dist / Shell.DakPenetration))
				Shell.DakPenetration = Shell.DakPenetration - (Shell.DakPenetration * (Dist / Shell.DakPenetration))
			else
				Shell.Pos = Exit
				Shell.LifeTime = 0
				Shell.DakVelocity = Vector(0,0,0)
				Shell.DakDamage = 0
				Shell.ExplodeNow = true
			end
		end
		if Penned == false then
			if Shell.DakExplosive then
				local effectdata3 = EffectData()
				effectdata3:SetOrigin(HitPos)
				effectdata3:SetEntity(Shell.DakGun)
				effectdata3:SetAttachment(1)
				effectdata3:SetMagnitude(.5)
				effectdata3:SetScale(Shell.DakBlastRadius)
				local newertrace = {}
					newertrace.start = HitPos + Vector(0,0,100)
					newertrace.endpos = HitPos - Vector(0,0,100)
					newertrace.filter = Shell.Filter
					newertrace.mins = Vector(-Shell.DakCaliber * 0.02,-Shell.DakCaliber * 0.02,-Shell.DakCaliber * 0.02)
					newertrace.maxs = Vector(Shell.DakCaliber * 0.02,Shell.DakCaliber * 0.02,Shell.DakCaliber * 0.02)
				local EffectTrace = util.TraceHull( newertrace )
				effectdata3:SetNormal( EffectTrace.HitNormal )
				if Shell.DakShellType == "SM" then
					util.Effect("daktescalingsmoke", effectdata3, true, true)
				else
					util.Effect("daktescalingexplosion", effectdata3, true, true)
				end

				Shell.DakGun:SetNWFloat("ExpDamage",Shell.DakSplashDamage)
				if Shell.DakCaliber >= 75 then
					Shell.DakGun:SetNWBool("Exploding",true)
					timer.Create( "ExplodeTimer" .. Shell.DakGun:EntIndex(), 0.1, 1, function()
						Shell.DakGun:SetNWBool("Exploding",false)
					end)
				else
					local ExpSounds = {}
					if Shell.DakCaliber < 20 then
						ExpSounds = {"physics/surfaces/sand_impact_bullet1.wav","physics/surfaces/sand_impact_bullet2.wav","physics/surfaces/sand_impact_bullet3.wav","physics/surfaces/sand_impact_bullet4.wav"}
					else
						ExpSounds = {"daktanks/dakexp1.mp3","daktanks/dakexp2.mp3","daktanks/dakexp3.mp3","daktanks/dakexp4.mp3"}
					end
					sound.Play( ExpSounds[math.random(1,#ExpSounds)], HitPos, 100, 100, 1 )
				end
				if Shell.Exploded ~= true then
					if Shell.DakShellType == "HESH" then
						DTShockwave(HitPos + (Normal * 2),Shell.DakSplashDamage,Shell.DakBlastRadius,Shell.DakFragPen,Shell.DakGun.DakOwner,Shell)
					else
						DTShockwave(HitPos + (Normal * 2),Shell.DakSplashDamage * 0.5,Shell.DakBlastRadius,Shell.DakFragPen,Shell.DakGun.DakOwner,Shell)
						--DTExplosion(HitPos + (Normal * 2),Shell.DakSplashDamage * 0.5,Shell.DakBlastRadius,Shell.DakCaliber,Shell.DakFragPen,Shell.DakGun.DakOwner,Shell)
					end
				end
				Shell.Exploded = true
			else
				local effectdata = EffectData()
				if Shell.DakIsFlame == 1 then
					DTTE.SpawnFire(HitPos, Shell.DakGun.DakOwner, Shell.DakGun)
				else
					effectdata:SetOrigin(HitPos)
					effectdata:SetEntity(Shell.DakGun)
					effectdata:SetAttachment(1)
					effectdata:SetMagnitude(.5)
					effectdata:SetScale(Shell.DakCaliber * (Shell.DakBaseVelocity / 29527.6))
					if not Shell.IsFrag then
						util.Effect("dakteshellimpact", effectdata, true, true)
					end
					util.Decal( "Impact.Concrete", HitPos - ((HitPos-Start):GetNormalized() * 5), HitPos + ((HitPos-Start):GetNormalized() * 5), Shell.DakGun)
					local ExpSounds = {}
					if Shell.DakCaliber < 20 then
						ExpSounds = {"physics/surfaces/sand_impact_bullet1.wav","physics/surfaces/sand_impact_bullet2.wav","physics/surfaces/sand_impact_bullet3.wav","physics/surfaces/sand_impact_bullet4.wav"}
					else
						ExpSounds = {"daktanks/dakexp1.mp3","daktanks/dakexp2.mp3","daktanks/dakexp3.mp3","daktanks/dakexp4.mp3"}
					end

					if Shell.DakIsPellet then
						sound.Play( ExpSounds[math.random(1,#ExpSounds)], HitPos, 100, 150, 0.25 )
					else
						sound.Play( ExpSounds[math.random(1,#ExpSounds)], HitPos, 100, 100, 1 )
					end
				end
			end
			Shell.RemoveNow = 1
			if Shell.DakExplosive then
				Shell.ExplodeNow = true
			end
			Shell.LifeTime = 0
			Shell.DakVelocity = Vector(0,0,0)
			Shell.DakDamage = 0
		end
	end

	if Shell.DakPenetration <= 0 then
		Shell.Spent = 1
		if Shell.DieTime == nil then
			Shell.DieTime = CurTime()
		end
	end
end

function entity:DTExplosion(Pos,Damage,Radius,Caliber,Pen,Owner)
	local traces = math.Round(Caliber / 2)
	local Filter = {self}

	for i = 1, traces do
		local Direction = VectorRand()
		local trace = {}
			trace.start = Pos
			trace.endpos = Pos + Direction * Radius * 10
			trace.filter = Filter
			trace.mins = Vector( - (Caliber / traces) * 0.02, - (Caliber / traces) * 0.02, - (Caliber / traces) * 0.02)
			trace.maxs = Vector((Caliber / traces) * 0.02,(Caliber / traces) * 0.02,(Caliber / traces) * 0.02)
		local ExpTrace = util.TraceHull( trace )
		local ExpTraceLine = util.TraceLine( trace )

		if hook.Run("DakTankDamageCheck", ExpTrace.Entity, Owner) ~= false and ExpTrace.HitPos:Distance(Pos) <= Radius then
			--decals don't like using the adjusted by normal Pos
			--util.Decal( "Impact.Concrete", ExpTrace.HitPos - (Direction * 5), ExpTrace.HitPos + (Direction * 5), self)
			if ExpTrace.Entity.DakHealth == nil then
				DTTE.SetupNewEnt(ExpTrace.Entity)
			end
			if (ExpTrace.Entity.DakDead == true) then
				Filter[#Filter + 1] = ExpTrace.Entity
				ContEXP(Filter, ExpTrace.Entity, Pos, Damage, Radius, Caliber, Pen, Owner, Direction, self)
			end
			if (ExpTrace.Entity:IsValid() and not(ExpTrace.Entity:IsPlayer()) and not(ExpTrace.Entity:IsNPC()) and ExpTrace.Entity.Base ~= "base_nextbot" and (ExpTrace.Entity.DakHealth ~= nil and ExpTrace.Entity.DakHealth > 0)) or (ExpTrace.Entity.DakName == "Damaged Component") then
				if ExpTrace.Entity:GetClass() == "dak_crew" or ExpTrace.Entity:GetClass() == "dak_gamemode_bot2" or ExpTrace.Entity:IsPlayer() or ExpTrace.Entity:IsNPC() then
					util.Decal( "Blood", ExpTrace.HitPos - (Direction * 5), ExpTrace.HitPos + (Direction * 500), self)
				end
				if (DTTE.CheckClip(ExpTrace.Entity,ExpTrace.HitPos)) or (ExpTrace.Entity:GetPhysicsObject():GetMass() <= 1 or (ExpTrace.Entity.DakIsTread == 1) and not(ExpTrace.Entity:IsVehicle()) and ExpTrace.Entity.IsDakTekFutureTech ~= 1) then
					if ExpTrace.Entity.DakArmor == nil or ExpTrace.Entity.DakBurnStacks == nil then
						DTTE.SetupNewEnt(ExpTrace.Entity)
					end
					local SA = ExpTrace.Entity:GetPhysicsObject():GetSurfaceArea()
					if ExpTrace.Entity.IsDakTekFutureTech == 1 then
						ExpTrace.Entity.DakArmor = 1000
					else
						if SA == nil then
							--Volume = (4 / 3) * math.pi*math.pow( ExpTrace.Entity:OBBMaxs().x, 3 )
							ExpTrace.Entity.DakArmor = ExpTrace.Entity:OBBMaxs().x / 2
							ExpTrace.Entity.DakIsTread = 1
						else
							if ExpTrace.Entity:GetClass() == "prop_physics" then
								DTTE.ArmorSanityCheck(ExpTrace.Entity)
							end
						end
					end
					ContEXP(Filter, ExpTrace.Entity, Pos, Damage, Radius, Caliber, Pen, Owner, Direction, self)
				else
					if ExpTrace.Entity.DakArmor == nil or ExpTrace.Entity.DakBurnStacks == nil then
						DTTE.SetupNewEnt(ExpTrace.Entity)
					end
					local SA = ExpTrace.Entity:GetPhysicsObject():GetSurfaceArea()
					if ExpTrace.Entity.IsDakTekFutureTech == 1 then
						ExpTrace.Entity.DakArmor = 1000
					else
						if SA == nil then
							--Volume = (4 / 3) * math.pi*math.pow( ExpTrace.Entity:OBBMaxs().x, 3 )
							ExpTrace.Entity.DakArmor = ExpTrace.Entity:OBBMaxs().x / 2
							ExpTrace.Entity.DakIsTread = 1
						else
							if ExpTrace.Entity:GetClass() == "prop_physics" then
								DTTE.ArmorSanityCheck(ExpTrace.Entity)
							end
						end
					end

					ExpTrace.Entity.DakLastDamagePos = ExpTrace.HitPos
					local EffArmor = (DTTE.GetArmor(ExpTrace.Entity, "HE", Caliber) / math.abs(ExpTraceLine.HitNormal:Dot(Direction)))
					if ExpTrace.Entity.IsComposite == 1 or (ExpTrace.Entity:CPPIGetOwner() ~= nil and ExpTrace.Entity:CPPIGetOwner():IsWorld()) then
						if ExpTrace.Entity.EntityMods == nil then ExpTrace.Entity.EntityMods = {} end
						if ExpTrace.Entity.EntityMods.CompKEMult == nil then ExpTrace.Entity.EntityMods.CompKEMult = 9.2 end
						if ExpTrace.Entity.EntityMods.CompCEMult == nil then ExpTrace.Entity.EntityMods.CompCEMult = 18.4 end
						EffArmor = (ExpTrace.Entity:GetPhysicsObject():GetVolume() ^ (1 / 3)) * ExpTrace.Entity.EntityMods.CompCEMult--DTTE.CompositesTrace( ExpTrace.Entity, ExpTrace.HitPos, ExpTrace.Normal, Filter ) * ExpTrace.Entity.EntityMods.CompKEMult
					end
					if CanDamage(ExpTrace.Entity) then
						if ExpTrace.Entity:GetClass() == "dak_tegun" or ExpTrace.Entity:GetClass() == "dak_temachinegun" or ExpTrace.Entity:GetClass() == "dak_teautogun" then
							DTDealDamage(ExpTrace.Entity, math.Clamp((Damage / traces) * (Pen / DTTE.GetArmor(ExpTrace.Entity, "HE", Caliber)) * 0.001,0,DTTE.GetArmor(ExpTrace.Entity, "HE", Caliber) * 2),self,true)
							DTDealDamage(ExpTrace.Entity.Controller, math.Clamp((Damage / traces) * (Pen / DTTE.GetArmor(ExpTrace.Entity, "HE", Caliber)),0,DTTE.GetArmor(ExpTrace.Entity, "HE", Caliber) * 2),self,true)
						else
							if ExpTrace.Entity.IsERA == 1 then
								DTDealDamage(ExpTrace.Entity, math.Clamp((Damage * 10 / traces) * (Pen / EffArmor),0,EffArmor * 2),self,true)
							else
								DTDealDamage(ExpTrace.Entity, math.Clamp((Damage / traces) * (Pen / DTTE.GetArmor(ExpTrace.Entity, "HE", Caliber)),0,DTTE.GetArmor(ExpTrace.Entity, "HE", Caliber) * 2),self,true)
							end
						end
					end
					if EffArmor < Pen and ExpTrace.Entity.IsDakTekFutureTech == nil then
						--util.Decal( "Impact.Concrete", ExpTrace.HitPos + (Direction * 5), ExpTrace.HitPos - (Direction * 5), self)
						if ExpTrace.Entity:GetClass() == "dak_crew" or ExpTrace.Entity:GetClass() == "dak_gamemode_bot2" or ExpTrace.Entity:IsPlayer() or ExpTrace.Entity:IsNPC() then
							util.Decal( "Blood", ExpTrace.HitPos - (Direction * 5), ExpTrace.HitPos + (Direction * 500), self)
							util.Decal( "Blood", ExpTrace.HitPos - (Direction * 5), ExpTrace.HitPos + (Direction * 500), ExpTrace.Entity)
						end
						ContEXP(Filter, ExpTrace.Entity, Pos, Damage * (1 - EffArmor / Pen), Radius, Caliber, Pen - EffArmor, Owner, Direction, self)
					end

					DestroyEnt(ExpTrace.Entity, Filter, self)
				end
				if (ExpTrace.Entity:IsValid()) and not(ExpTrace.Entity:IsNPC()) and not(ExpTrace.Entity:IsPlayer()) and ExpTrace.Entity.Base ~= "base_nextbot" then
					ExpTrace.Entity:DTHEApplyForce(ExpTrace.HitPos, Pos, Damage, traces, 0.0035)
				end
			end
			if ExpTrace.Entity:IsValid() then
				if ExpTrace.Entity:IsPlayer() or ExpTrace.Entity:IsNPC() or ExpTrace.Entity.Base == "base_nextbot" then
					if ExpTrace.Entity:GetClass() == "dak_bot" then
						ExpTrace.Entity:SetHealth(ExpTrace.Entity:Health() - (Damage / traces) * 500)
						if ExpTrace.Entity:Health() <= 0 and ExpTrace.Entity.revenge == 0 then
							body:SetPos( ExpTrace.Entity:GetPos() )
							body:SetModel( ExpTrace.Entity:GetModel() )
							body:Spawn()
							body.DakHealth = 1000000
							body.DakMaxHealth = 1000000
							local SoundList = {"npc/metropolice/die1.wav","npc/metropolice/die2.wav","npc/metropolice/die3.wav","npc/metropolice/die4.wav","npc/metropolice/pain4.wav"}
							body:EmitSound( SoundList[math.random(5)], 100, 100, 1, 2 )
							timer.Simple( 5, function()
								body:Remove()
							end )
						end
					else
						local Pain = DamageInfo()
						Pain:SetDamageForce( Direction * (Damage / traces) * 5000 * 2 )
						Pain:SetDamage( (Damage / traces) * 500 )
						if Owner:IsPlayer() then
							Pain:SetAttacker( Owner )
						else
							Pain:SetAttacker( game.GetWorld() )
						end
						if self then
							Pain:SetAttacker( self )
							Pain:SetInflictor( self )
						else
							Pain:SetAttacker( game.GetWorld() )
							Pain:SetInflictor( game.GetWorld() )
						end
						Pain:SetReportedPosition( Pos )
						Pain:SetDamagePosition( ExpTrace.Entity:GetPos() )
						Pain:SetDamageType(DMG_BLAST)
						ExpTrace.Entity:TakeDamageInfo( Pain )
					end
				end
			end
		end
	end
end