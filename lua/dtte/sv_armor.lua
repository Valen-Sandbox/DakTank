local DTTE = DTTE

function DTTE.GetArmor( Ent, ShellType, Caliber )
	if Ent.EntityMods ~= nil and Ent.EntityMods.ArmorType ~= nil and Ent.EntityMods.ArmorType == "CHA" then
		if Ent.DakArmor < 175 then
			return math.Clamp( -11.6506 + 1.072239 * Ent.DakArmor + 0.0004415663 * Ent.DakArmor ^ 2 - 0.000002624166 * Ent.DakArmor ^ 3, Ent.DakArmor * 0.5, Ent.DakArmor )
		else
			return Ent.DakArmor
		end
	end
	if Ent.EntityMods ~= nil and Ent.EntityMods.ArmorType ~= nil and Ent.EntityMods.ArmorType == "HHA" then
		if ShellType == "HE" or ShellType == "HESH" or ShellType == "HEAT" or ShellType == "HEATFS" or ShellType == "ATGM" then
			return Ent.DakArmor
		end
		return Ent.DakArmor * ( 9.7707 * Caliber ^ 0.06111 * ( Ent.DakArmor / Caliber ) ^ 0.2821 * 450 ^ -0.4363 ) --hardness value of 450
	end
	if Ent.DakArmor == nil then Ent.DakArmor = 1000 end

	return Ent.DakArmor
end

function DTTE.ArmorSanityCheck(Ent)
	local SA = Ent:GetPhysicsObject():GetSurfaceArea()
	if Ent.EntityMods == nil or Ent.EntityMods.Hardness == nil then Ent.ArmorMod = 7.8125 else Ent.ArmorMod = 7.8125 * Ent.EntityMods.Hardness end
	--Ent.DakArmor > (7.8125 * (Ent:GetPhysicsObject():GetMass() / 4.6311781) * (288 / SA)) * 0.5
	if Ent.DakBurnStacks == nil then Ent.DakBurnStacks = 0 end
	if SA ~= nil then
		if Ent.DakArmor ~= 7.8125 * (Ent:GetPhysicsObject():GetMass() / 4.6311781) * (288 / SA) - Ent.DakBurnStacks * 0.25 then
			Ent.DakArmor = 7.8125 * (Ent:GetPhysicsObject():GetMass() / 4.6311781) * (288 / SA) - Ent.DakBurnStacks * 0.25
		end
		if Ent.DakArmor <= 0 then Ent.DakArmor = 0.001 end
	end
end

function DTTE.GetEffArmor(Start, End, ShellType, Caliber, Filter, core, nochecklegit)
	if tonumber(Caliber) == nil then return 0, NULL, Vector(0,0,0), 0, 0, 0 end
	local trace = {}
		trace.start = Start
		trace.endpos = End
		trace.filter = Filter
		trace.min = Vector(0,0,0)
		trace.max = Vector(0,0,0)
		trace.ignoreworld = true
	local ShellSimTrace = util.TraceHull( trace )
	if core ~= nil and core ~= NULL then
		if ShellSimTrace.Entity.Controller ~= nil then
			if ShellSimTrace.Entity.Controller ~= core then
				return 0, ShellSimTrace.Entity, Vector(0,0,0), 0, 0, 0
			end
		end
	end
	local HitEnt = ShellSimTrace.Entity
	local EffArmor = 0
	local Shatter = 0
	local Failed = 0
	local HitGun = 0
	local HitGear = 0
	local HitAng = math.deg(math.acos(ShellSimTrace.HitNormal:Dot(-ShellSimTrace.Normal)))
	if HitEnt.DakHealth == nil then
		DTTE.SetupNewEnt(HitEnt)
	end
	if (HitEnt:IsValid() and HitEnt:GetPhysicsObject():IsValid() and not(HitEnt:IsPlayer()) and not(HitEnt:IsNPC()) and not(HitEnt.Base == "base_nextbot") and (HitEnt.DakHealth ~= nil and HitEnt.DakHealth > 0)) then
		local physobj = HitEnt:GetPhysicsObject()
		if not((DTCheckClip(HitEnt,ShellSimTrace.HitPos,nochecklegit)) or (physobj:GetMass() <= 1 and not(HitEnt:IsVehicle()) and HitEnt.IsDakTekFutureTech ~= 1) or HitEnt.DakName == "Damaged Component") then
			local HitEntClass = HitEnt:GetClass()
			local SA = physobj:GetSurfaceArea()
			if HitEnt.DakArmor == nil or HitEnt.DakBurnStacks == nil then
				DTTE.SetupNewEnt(HitEnt)
			end
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
					if HitEntClass == "prop_physics" then
						DTTE.ArmorSanityCheck(HitEnt)
					end
				end
			end

			if HitEntClass == "dak_tegun" or HitEntClass == "dak_teautogun" or HitEntClass == "dak_temachinegun" then
				HitGun = 1
			end
			if HitEntClass == "dak_tegearbox" or HitEntClass == "dak_tegearboxnew" then
				HitGear = 1
			end
			local TDRatio = HitEnt.DakArmor / Caliber
			if ShellType == "APFSDS" then
				TDRatio = HitEnt.DakArmor / (Caliber * 2.5)
			end
			if ShellType == "APDS" then
				TDRatio = HitEnt.DakArmor / (Caliber * 1.75)
			end
			if HitEnt.IsComposite == 1 or (HitEnt:CPPIGetOwner() ~= nil and HitEnt:CPPIGetOwner():IsWorld()) then
				EffArmor = DTCompositesTrace( HitEnt, ShellSimTrace.HitPos, ShellSimTrace.Normal, Filter )
				if HitEnt.EntityMods == nil then HitEnt.EntityMods = {} end
				if HitEnt.EntityMods.CompKEMult == nil then HitEnt.EntityMods.CompKEMult = 9.2 end
				if HitEnt.EntityMods.CompCEMult == nil then HitEnt.EntityMods.CompCEMult = 18.4 end
				if ShellType == "HEAT" or ShellType == "HEATFS" or ShellType == "ATGM" then
					EffArmor = EffArmor * HitEnt.EntityMods.CompCEMult
				else
					EffArmor = EffArmor * HitEnt.EntityMods.CompKEMult
				end
				if ShellType == "APFSDS" or ShellType == "APDS" then
					if ShellType == "APFSDS" then
						if (EffArmor / 3) / (Caliber * 2.5) >= 0.8 then
							Shatter = 1
						end
					else
						if (EffArmor / 3) / (Caliber * 1.75) >= 0.8 then
							Shatter = 1
						end
					end
				else
					if (EffArmor / 3) / Caliber >= 0.8 and not(ShellType == "HEAT" or ShellType == "HEATFS" or ShellType == "ATGM" or ShellType == "HESH") then
						Shatter = 1
					end
				end
				if HitAng >= 70 and EffArmor >= Caliber * 0.85 and (ShellType == "APFSDS" or ShellType == "APDS") then Shatter = 1 end
				if HitAng >= 80 and EffArmor >= Caliber * 0.85 and (ShellType == "APFSDS" or ShellType == "APDS") then Failed = 1 Shatter = 1 end
			else
				if TDRatio >= 0.8 and not(ShellType == "HEAT" or ShellType == "HEATFS" or ShellType == "ATGM" or ShellType == "HESH") then
					Shatter = 1
				end
				if HitAng >= 70 and HitEnt.DakArmor >= Caliber * 0.85 and (ShellType == "APFSDS" or ShellType == "APDS") then Shatter = 1 end
				if HitAng >= 80 and HitEnt.DakArmor >= Caliber * 0.85 and (ShellType == "APFSDS" or ShellType == "APDS") then Failed = 1 Shatter = 1 end
				if ShellType == "HESH" then
					EffArmor = DTTE.GetArmor(HitEnt, ShellType, Caliber)
				end
				if ShellType == "HEAT" or ShellType == "HEATFS" or ShellType == "ATGM" then
					EffArmor = (DTTE.GetArmor(HitEnt, ShellType, Caliber) / math.abs(ShellSimTrace.HitNormal:Dot(ShellSimTrace.Normal)) )
				end
				local mathmax = math.max
				local mathpow = math.pow
				if ShellType == "AP" or ShellType == "APHE" or ShellType == "HE" or ShellType == "HVAP" or ShellType == "SM" then
					if HitAng > 24 then
						local aVal = 2.251132 - 0.1955696 * mathmax( HitAng, 24 ) + 0.009955601 * mathpow( mathmax( HitAng, 24 ), 2 ) - 0.0001919089 * mathpow( mathmax( HitAng, 24 ), 3 ) + 0.000001397442 * mathpow( mathmax( HitAng, 20 ), 4 )
						local bVal = 0.04411227 - 0.003575789 * mathmax( HitAng, 24 ) + 0.0001886652 * mathpow( mathmax( HitAng, 24 ), 2 ) - 0.000001151088 * mathpow( mathmax( HitAng, 24 ), 3 ) + 1.053822e-9 * mathpow( mathmax( HitAng, 20 ), 4 )
						EffArmor = math.Clamp(DTTE.GetArmor(HitEnt, ShellType, Caliber) * (aVal * mathpow( TDRatio, bVal )),DTTE.GetArmor(HitEnt, ShellType, Caliber),10000000000)
					else
						EffArmor = (DTTE.GetArmor(HitEnt, ShellType, Caliber) / math.abs(ShellSimTrace.HitNormal:Dot(ShellSimTrace.Normal)) )
					end
				end
				if ShellType == "APDS" then
					EffArmor = DTTE.GetArmor(HitEnt, ShellType, Caliber) * mathpow( 2.71828, mathpow( HitAng, 2.6 ) * 0.00003011 )
				end
				if ShellType == "APFSDS" then
					EffArmor = DTTE.GetArmor(HitEnt, ShellType, Caliber) * mathpow( 2.71828, mathpow( HitAng, 2.6 ) * 0.00003011 )
				end
				if HitAng >= 70 and EffArmor >= 5 and (ShellType == "HEAT" or ShellType == "HEATFS" or ShellType == "ATGM" or ShellType == "HESH") then Shatter = 1 end
				if HitAng >= 80 and EffArmor >= 5 and (ShellType == "HEAT" or ShellType == "HEATFS" or ShellType == "ATGM" or ShellType == "HESH") then Failed = 1 Shatter = 1 end
			end
		end
	end
	local EndPos
	if ShellSimTrace.Hit then
		EndPos = ShellSimTrace.HitPos
	else
		EndPos = End
	end
	if HitEnt.DakDead == true then
		return 0, HitEnt, EndPos, 0, 0, 0, 0
	else
		return EffArmor, HitEnt, EndPos, Shatter, Failed, HitGun, HitGear
	end
end

function DTTE.GetArmorRecurse(Start, End, ShellType, Caliber, Filter)
	if tonumber(Caliber) == nil then return 0, NULL, 0, 0, 0 end
	local Armor, Ent, FirstPenPos, HeatShattered, HeatFailed, HitGun, HitGear = DTTE.GetEffArmor(Start, End, ShellType, Caliber, Filter, nil, true)
	local Recurse = 1
	local NewFilter = Filter
	NewFilter[#NewFilter + 1] = Ent
	-- local newEnt = Ent
	-- local newArmor = 0
	local Go = 1
	-- local LastPenPos = FirstPenPos
	local Shatters = HeatShattered
	local Fails = HeatFailed
	local Rico = 0
	local Thickest = Armor
	local SpallLiner = 0
	local SpallLinerOnCrit = 0
	local LinerThickness = 0

	while Go == 1 and Recurse < 25 do
		local newArmor, newEnt, LastPenPos, Shattered, Failed, newHitGun, newHitGear = DTTE.GetEffArmor(Start, End, ShellType, Caliber, NewFilter, nil, true)
		local newValid = false
		local newEntClass
		if newEnt:IsValid() then
			newEntClass = newEnt:GetClass()
			newValid = true
		end
		if newHitGun == 1 then HitGun = 1 end
		if newHitGear == 1 then HitGear = 1 end
		if Armor == 0 or newArmor == 0 then
			if Armor == 0 then
				HeatShattered = Shattered
				HeatFailed = Failed
				FirstPenPos = LastPenPos
			end
		end
		if newArmor >= Thickest then
			Thickest = newArmor
			SpallLiner = 0
			LinerThickness = 0
		else
			if newValid then
				if newEntClass == "prop_physics" then
					LinerThickness = LinerThickness + newArmor
				end
			end
			if LinerThickness >= Thickest * 0.1 and Thickest > 0 then
				SpallLiner = 1
			end
		end
		Shatters = Shatters + Shattered
		Fails = Fails + Failed
		if newValid then
			if newEntClass == "dak_crew" or newEntClass == "dak_teammo" or newEntClass == "dak_teautoloadingmodule" or newEntClass == "dak_tefuel" or newEnt:IsWorld() then
				if newEntClass == "dak_teammo" then
					if newEnt.DakAmmo > 0 then
						Go = 0
						if SpallLiner == 1 then
							SpallLinerOnCrit = 1
						end
					end
				else
					Go = 0
					if SpallLiner == 1 then
						SpallLinerOnCrit = 1
					end
				end
			end
		else
			Go = 0
		end
		if Go == 0 then
			if ShellType == "HEAT" or ShellType == "HEATFS" or ShellType == "ATGM" then
				Armor = Armor + (FirstPenPos:Distance(LastPenPos) * 2.54)
			end
			if ShellType == "HEAT" or ShellType == "HEATFS" or ShellType == "ATGM" or ShellType == "HESH" then
				if HeatFailed == 1 then Rico = 1 end
				Shatters = HeatShattered
			end
			if ShellType == "APDS" or ShellType == "APFSDS" then
				if Fails > 0 then Rico = 1 end
			end
			return Armor, newEnt, Shatters, Rico, HitGun, HitGear
		end
		NewFilter[#NewFilter + 1] = newEnt
		Armor = Armor + newArmor
		Recurse = Recurse + 1
	end
end

function DTTE.GetArmorRecurseNoStop(Start, End, Distance, ShellType, Caliber, Filter, core)
	if tonumber(Caliber) == nil then return 0, NULL, 0, 0, 0, 0, 0, Vector(0,0,0) end
	local Armor, Ent, FirstPenPos, HeatShattered, HeatFailed, HitGun, HitGear = DTTE.GetEffArmor(Start, End, ShellType, Caliber, Filter, core)
	if IsValid(Ent) and (Ent:GetClass() == "dak_tegearbox" or Ent:GetClass() == "dak_tegearboxnew" or Ent:GetClass() == "dak_temotor") then
		Armor = Armor * 0.25
	end
	if IsValid(Ent) and Ent.Controller ~= core then
		Armor = 0
	end
	local HitCrew = 0
	local CrewArmor = 0
	local LastCrew
	local HitCrit = 0
	local CritEnt = NULL
	local CrewArmors = {}
	local CrewHits = {}
	local ThickestPos = FirstPenPos
	local SpallLinerOnCrit
	if IsValid(Ent) and Ent.Controller == core then
		if Ent:GetClass() == "dak_crew" or Ent:GetClass() == "dak_teammo" or Ent:GetClass() == "dak_teautoloadingmodule" then
			if Ent:GetClass() == "dak_teammo" then
				if Ent.DakAmmo > 0 then
					HitCrit = 1
					CritEnt = Ent
					SpallLinerOnCrit = 0
					HitGun = 0
				end
			else
				HitCrit = 1
				CritEnt = Ent
				SpallLinerOnCrit = 0
				HitGun = 0
			end
			if Ent:GetClass() == "dak_crew" then
				HitCrew = 1
				LastCrew = Ent
				CrewArmor = Armor
				CrewArmors[#CrewArmors + 1] = Armor
				CrewHits[#CrewHits + 1] = Ent
				ThickestPos = FirstPenPos
				CritEnt = Ent
				HitCrit = 1
			end
		end
	end
	local Recurse = 1
	local NewFilter = Filter
	NewFilter[#NewFilter + 1] = Ent
	-- local newEnt = Ent
	-- local newArmor = 0
	local Go = 1
	-- local LastPenPos = FirstPenPos
	local Shatters = HeatShattered
	local Fails = HeatFailed
	local Rico = 0
	local Thickest = Armor
	if IsValid(Ent) and (Ent:GetClass() == "prop_physics" or Ent:GetClass() == "dak_crew") then
		ThickestPos = FirstPenPos
	end
	local SpallLiner = 0
	SpallLinerOnCrit = 0
	local LinerThickness = 0

	while Go == 1 and Recurse < 50 do
		local newArmor, newEnt, LastPenPos, Shattered, Failed, newHitGun, newHitGear = DTTE.GetEffArmor(Start, End, ShellType, Caliber, NewFilter, core)
		local newValid = false
		local newEntClass
		if newEnt:IsValid() then
			newEntClass = newEnt:GetClass()
			newValid = true
		end
		if newValid and (newEntClass == "dak_tegearbox" or newEntClass == "dak_tegearboxnew" or newEntClass == "dak_temotor") then
			newArmor = newArmor * 0.25
		end
		if newEnt.Controller == core then
			if newHitGun == 1 and HitCrit == 0 then HitGun = 1 end
			if newHitGear == 1 then HitGear = 1 end
			if Armor == 0 or newArmor == 0 then
				if Armor == 0 then
					HeatShattered = Shattered
					HeatFailed = Failed
					FirstPenPos = LastPenPos
				end
			end
			if newArmor >= Thickest then
				Thickest = newArmor
				if newEntClass == "prop_physics" and HitCrew == 0 then
					ThickestPos = LastPenPos
				end
				SpallLiner = 0
				LinerThickness = 0
			else
				if newValid then
					if newEntClass == "prop_physics" then
						LinerThickness = LinerThickness + newArmor
					end
				end
				if LinerThickness >= Thickest * 0.1 and Thickest > 0 then
					SpallLiner = 1
				end
			end
			Shatters = Shatters + Shattered
			Fails = Fails + Failed
			Armor = Armor + newArmor
		else
			newArmor = 0
		end
		if newValid then
			if newEnt.Controller == core then
				if newEntClass == "dak_crew" or newEntClass == "dak_teammo" or newEntClass == "dak_teautoloadingmodule" then
					if newEntClass == "dak_teammo" then
						if newEnt.DakAmmo > 0 then
							HitCrit = 1
							CritEnt = newEnt
							if SpallLiner == 1 then
								SpallLinerOnCrit = 1
							end
						end
					else
						HitCrit = 1
						CritEnt = newEnt
						if SpallLiner == 1 then
							SpallLinerOnCrit = 1
						end
					end
					if newEntClass == "dak_crew" then
						HitCrew = 1
						LastCrew = newEnt
						CrewArmor = Armor
						CrewArmors[#CrewArmors + 1] = Armor
						CrewHits[#CrewHits + 1] = newEnt
					end
				end
			end
		else
			Go = 0
		end
		if Recurse >= 50 then
			return math.huge, CritEnt, Shatters, Rico, HitGun, HitGear, HitCrit, FirstPenPos, SpallLinerOnCrit, CrewArmors, CrewHits, ThickestPos
		end
		if Go == 0 then
			if ShellType == "HEAT" or ShellType == "HEATFS" or ShellType == "ATGM" then
				Armor = Armor + (FirstPenPos:Distance(LastPenPos) * 2.54)
			end
			if ShellType == "HEAT" or ShellType == "HEATFS" or ShellType == "ATGM" or ShellType == "HESH" then
				if HeatFailed == 1 then Rico = 1 end
				Shatters = HeatShattered
			end
			if ShellType == "APDS" or ShellType == "APFSDS" then
				if Fails > 0 then Rico = 1 end
			end
			if HitCrew == 1 then
				return CrewArmor, LastCrew, Shatters, Rico, HitGun, HitGear, HitCrit, FirstPenPos, SpallLinerOnCrit, CrewArmors, CrewHits, ThickestPos
			else
				return Armor, CritEnt, Shatters, Rico, HitGun, HitGear, HitCrit, FirstPenPos, SpallLinerOnCrit, CrewArmors, CrewHits, ThickestPos
			end
		end

		NewFilter[#NewFilter + 1] = newEnt

		Recurse = Recurse + 1
	end
end

function DTTE.GetArmorRecurseDisplay(Start, End, depth, ShellType, Caliber, Filter, core, mark, respectmark)
	if tonumber(Caliber) == nil then return 0, NULL, 0, 0, 0, 0, 0, Vector(0,0,0) end
	local Armor, Ent, FirstPenPos, HeatShattered, HeatFailed, HitGun, HitGear = DTTE.GetEffArmor(Start, End, ShellType, Caliber, Filter, core)
	if IsValid(Ent) and Ent.Marked == true and respectmark == true then
		Armor = 0
	end
	if mark == true and IsValid(Ent) and Ent.Controller == core and Ent:GetClass() == "prop_physics" then Ent.Marked = true end
	if IsValid(Ent) and (Ent:GetClass() == "dak_tegearbox" or Ent:GetClass() == "dak_tegearboxnew" or Ent:GetClass() == "dak_temotor") then
		Armor = Armor * 0.25
	end
	local CritEnt = NULL
	if IsValid(Ent) and (Ent:GetClass() == "dak_crew" or Ent:GetClass() == "dak_teammo" or Ent:GetClass() == "dak_teautoloadingmodule" or Ent:GetClass() == "dak_tefuel") then
		Armor = 0
		CritEnt = Ent
	end
	if IsValid(Ent) and Ent.Controller ~= core then
		Armor = 0
	end
	local Recurse = 1
	local NewFilter = Filter
	NewFilter[#NewFilter + 1] = Ent
	-- local newEnt = Ent
	-- local newArmor = 0
	local Go = 1
	-- local LastPenPos = FirstPenPos
	local Shatters = HeatShattered
	local Fails = HeatFailed
	local Rico = 0
	local HitCrit = 0
	local Thickest = Armor
	local SpallLiner = 0
	local SpallLinerOnCrit = 0
	local LinerThickness = 0
	local ThickestPos = FirstPenPos
	if IsValid(Ent) and Ent:GetClass() == "prop_physics" then
		ThickestPos = FirstPenPos
	end

	while Go == 1 and Recurse < 25 do
		local newArmor, newEnt, LastPenPos, Shattered, Failed, newHitGun, newHitGear = DTTE.GetEffArmor(Start, End, ShellType, Caliber, NewFilter, core)
		if IsValid(newEnt) and newEnt.Marked == true and respectmark == true then
			newArmor = 0
		end
		if mark == true and IsValid(newEnt) and newEnt.Controller == core and newEnt:GetClass() == "prop_physics" then newEnt.Marked = true end
		local newValid = false
		local newEntClass
		if newEnt:IsValid() then
			newEntClass = newEnt:GetClass()
			newValid = true
		end
		if newValid and (newEntClass == "dak_tegearbox" or newEntClass == "dak_tegearboxnew" or newEntClass == "dak_temotor") then
			newArmor = newArmor * 0.25
		end
		if newValid and (newEntClass == "dak_crew" or newEntClass == "dak_teammo" or newEntClass == "dak_teautoloadingmodule" or newEntClass == "dak_tefuel") then
			newArmor = 0
		end
		if newEnt.Controller == core then
			if newHitGun == 1 and HitCrit == 0 then HitGun = 1 end
			if newHitGear == 1 then HitGear = 1 end
			if Armor == 0 or newArmor == 0 then
				if Armor == 0 then
					HeatShattered = Shattered
					HeatFailed = Failed
					FirstPenPos = LastPenPos
				end
			end
			if newArmor >= Thickest then
				if IsValid(newEnt) and newEnt:GetClass() == "prop_physics" then
					ThickestPos = FirstPenPos
				end
				Thickest = newArmor
				SpallLiner = 0
				LinerThickness = 0
			else
				if newValid then
					if newEntClass == "prop_physics" then
						LinerThickness = LinerThickness + newArmor
					end
				end
				if LinerThickness >= Thickest * 0.1 and Thickest > 0 then
					SpallLiner = 1
				end
			end
			Shatters = Shatters + Shattered
			Fails = Fails + Failed
			if FirstPenPos:Distance(LastPenPos) <= depth then
				if not(newEntClass == "dak_crew" or newEntClass == "dak_teammo" or newEntClass == "dak_teautoloadingmodule" or newEntClass == "dak_tefuel") then
					Armor = Armor + newArmor
				end
			end
		else
			newArmor = 0
		end
		if newValid then
			if CritEnt == NULL then
				if newEnt.Controller == core then
					if newEntClass == "dak_crew" or newEntClass == "dak_teammo" or newEntClass == "dak_teautoloadingmodule" or newEntClass == "dak_tefuel" or newEnt:IsWorld() then
						if newEntClass == "dak_teammo" then
							if newEnt.DakAmmo > 0 then
								HitCrit = 1
								CritEnt = newEnt
								if SpallLiner == 1 then
									SpallLinerOnCrit = 1
								end
							end
						else
							HitCrit = 1
							CritEnt = newEnt
							if SpallLiner == 1 then
								SpallLinerOnCrit = 1
							end
						end
					end
				end
			end
		else
			Go = 0
		end
		if Recurse >= 25 then
			return math.huge, CritEnt, Shatters, Rico, HitGun, HitGear, HitCrit, FirstPenPos, SpallLinerOnCrit, ThickestPos
		end
		if Go == 0 then
			if ShellType == "HEAT" or ShellType == "HEATFS" or ShellType == "ATGM" then
				Armor = Armor + (math.Min(FirstPenPos:Distance(LastPenPos),depth) * 2.54)
			end
			if ShellType == "HEAT" or ShellType == "HEATFS" or ShellType == "ATGM" or ShellType == "HESH" then
				if HeatFailed == 1 then Rico = 1 end
				Shatters = HeatShattered
			end
			if ShellType == "APDS" or ShellType == "APFSDS" then
				if Fails > 0 then Rico = 1 end
			end
			return Armor, CritEnt, Shatters, Rico, HitGun, HitGear, HitCrit, FirstPenPos, SpallLinerOnCrit, ThickestPos
		end

		NewFilter[#NewFilter + 1] = newEnt

		Recurse = Recurse + 1
	end
end