local DTTE = DTTE

function DTTE.GetArmor( Ent, ShellType, Caliber )
	local entTbl = Ent:GetTable()
	if entTbl.EntityMods ~= nil and entTbl.EntityMods.ArmorType ~= nil then
		if entTbl.EntityMods.ArmorType == "CHA" then
			if entTbl.DakArmor < 175 then
				return math.Clamp( -11.6506 + 1.072239 * entTbl.DakArmor + 0.0004415663 * entTbl.DakArmor ^ 2 - 0.000002624166 * entTbl.DakArmor ^ 3, entTbl.DakArmor * 0.5, entTbl.DakArmor )
			else
				return entTbl.DakArmor
			end
		elseif entTbl.EntityMods.ArmorType == "HHA" then
			if ShellType == "HE" or ShellType == "HESH" or ShellType == "HEAT" or ShellType == "HEATFS" or ShellType == "ATGM" then
				return entTbl.DakArmor
			end
			return entTbl.DakArmor * ( 9.7707 * Caliber ^ 0.06111 * ( entTbl.DakArmor / Caliber ) ^ 0.2821 * 450 ^ -0.4363 ) --hardness value of 450
		end
	end
	if entTbl.DakArmor == nil then entTbl.DakArmor = 1000 end

	return entTbl.DakArmor
end

function DTTE.ArmorSanityCheck(Ent)
	local physObj = Ent:GetPhysicsObject()
	local SA = physObj:GetSurfaceArea()
	local EntTbl = Ent:GetTable()
	if EntTbl.EntityMods == nil or EntTbl.EntityMods.Hardness == nil then EntTbl.ArmorMod = 7.8125 else EntTbl.ArmorMod = 7.8125 * EntTbl.EntityMods.Hardness end
	EntTbl.DakBurnStacks = EntTbl.DakBurnStacks or 0
	if SA ~= nil then
		local mass = physObj:GetMass()
		if EntTbl.DakArmor ~= 7.8125 * (mass / 4.6311781) * (288 / SA) - EntTbl.DakBurnStacks * 0.25 then
			EntTbl.DakArmor = 7.8125 * (mass / 4.6311781) * (288 / SA) - EntTbl.DakBurnStacks * 0.25
		end
		if EntTbl.DakArmor <= 0 then EntTbl.DakArmor = 0.001 end
	end
end

function DTTE.GetEffArmor(Start, End, ShellType, Caliber, Filter, core, nochecklegit)
	if tonumber(Caliber) == nil then return 0, NULL, Vector(0,0,0), 0, 0, 0 end
	local trace = {}
		trace.start = Start
		trace.endpos = End
		trace.filter = Filter
		trace.ignoreworld = true
	local ShellSimTrace = util.TraceLine( trace )

	if core ~= nil and core ~= NULL then
		if ShellSimTrace.Entity.Controller ~= nil and ShellSimTrace.Entity.Controller ~= core then
			return 0, ShellSimTrace.Entity, Vector(0,0,0), 0, 0, 0
		end
	end
	local HitEnt = ShellSimTrace.Entity
	local HitEntTbl = HitEnt:GetTable()
	local EffArmor = 0
	local Shatter = 0
	local Failed = 0
	local HitGun = 0
	local HitGear = 0

	if HitEnt.DakHealth == nil then
		DTTE.SetupNewEnt(HitEnt)
	end

	if (HitEnt:IsValid() and HitEnt:GetPhysicsObject():IsValid() and not(HitEnt:IsPlayer()) and not(HitEnt:IsNPC()) and not(HitEntTbl.Base == "base_nextbot") and (HitEntTbl.DakHealth ~= nil and HitEntTbl.DakHealth > 0)) then
		local normal = ShellSimTrace.HitNormal:Dot(-ShellSimTrace.Normal)
		local HitAng = math.deg(math.acos( normal ))
		local physobj = HitEnt:GetPhysicsObject()

		if not((DTTE.CheckClip(HitEnt,ShellSimTrace.HitPos,nochecklegit)) or (physobj:GetMass() <= 1 and not(HitEnt:IsVehicle()) and HitEntTbl.IsDakTekFutureTech ~= 1) or HitEntTbl.DakName == "Damaged Component") then

			local HitEntClass = HitEnt:GetClass()
			local SA = physobj:GetSurfaceArea()
			if HitEntTbl.DakArmor == nil or HitEntTbl.DakBurnStacks == nil then
				DTTE.SetupNewEnt(HitEnt)
			end
			HitEntTbl.DakBurnStacks = HitEntTbl.DakBurnStacks or 0

			if HitEntTbl.IsDakTekFutureTech == 1 then
				HitEntTbl.DakArmor = 1000
			else
				if SA == nil then
					HitEntTbl.DakArmor = HitEnt:OBBMaxs().x / 2
					HitEntTbl.DakIsTread = 1
				elseif HitEntClass == "prop_physics" then
						DTTE.ArmorSanityCheck(HitEnt)
				end
			end

			if HitEntClass == "dak_tegun" or HitEntClass == "dak_teautogun" or HitEntClass == "dak_temachinegun" then
				HitGun = 1
			elseif HitEntClass == "dak_tegearbox" or HitEntClass == "dak_tegearboxnew" then
				HitGear = 1
			end
			local TDRatio = HitEntTbl.DakArmor / Caliber
			if ShellType == "APFSDS" then
				TDRatio = HitEntTbl.DakArmor / (Caliber * 2.5)
			elseif ShellType == "APDS" then
				TDRatio = HitEntTbl.DakArmor / (Caliber * 1.75)
			end


			local owner = HitEnt:CPPIGetOwner()
			if HitEntTbl.IsComposite == 1 or (owner ~= nil and owner:IsWorld()) then

				EffArmor = DTTE.CompositesTrace( HitEnt, ShellSimTrace.HitPos, ShellSimTrace.Normal, Filter ) --This is incredibly expensive

				if HitEntTbl.EntityMods == nil then HitEntTbl.EntityMods = {} end
				if HitEntTbl.EntityMods.CompKEMult == nil then HitEntTbl.EntityMods.CompKEMult = 9.2 end
				if HitEntTbl.EntityMods.CompCEMult == nil then HitEntTbl.EntityMods.CompCEMult = 18.4 end
				if ShellType == "HEAT" or ShellType == "HEATFS" or ShellType == "ATGM" then
					EffArmor = EffArmor * HitEntTbl.EntityMods.CompCEMult
				else
					EffArmor = EffArmor * HitEntTbl.EntityMods.CompKEMult
				end
				if ShellType == "APFSDS" or ShellType == "APDS" then
					local calMult = (ShellType == "APFSDS" and 2.5) or 1.75
					if (EffArmor / 3) / (Caliber * calMult) >= 0.8 then
						Shatter = 1
					end

					if HitAng >= 70 and EffArmor >= Caliber * 0.85 then Shatter = 1 end
					if HitAng >= 80 and EffArmor >= Caliber * 0.85 then Failed = 1 end
				else
					if (EffArmor / 3) / Caliber >= 0.8 and not(ShellType == "HEAT" or ShellType == "HEATFS" or ShellType == "ATGM" or ShellType == "HESH") then
						Shatter = 1
					end
				end

			else

				local mathmax = math.max
				local mathpow = math.pow

				local armor = DTTE.GetArmor(HitEnt, ShellType, Caliber)

				if TDRatio >= 0.8 and not(ShellType == "HEAT" or ShellType == "HEATFS" or ShellType == "ATGM" or ShellType == "HESH") then
					Shatter = 1
				else
					if ShellType == "HESH" then
						EffArmor = armor
					else
						EffArmor = (armor / math.abs(normal) )
					end

					if HitAng >= 70 and EffArmor >= 5 then Shatter = 1 end
					if HitAng >= 80 and EffArmor >= 5 then Failed = 1 end
				end

				if ShellType == "AP" or ShellType == "APHE" or ShellType == "HE" or ShellType == "HVAP" or ShellType == "SM" then
					if HitAng > 24 then
						local angPow2 = HitAng ^ 2
						local angPow3 = HitAng ^ 3
						local angPow4 = angPow2 ^ 2
						local aVal = 2.251132 - 0.1955696 * HitAng + 0.009955601 * angPow2 - 0.0001919089 * angPow3 + 0.000001397442 * angPow4
						local bVal = 0.04411227 - 0.003575789 * HitAng + 0.0001886652 * angPow2 - 0.000001151088 * angPow3 + 1.053822e-9 * angPow4
						EffArmor = math.Clamp(armor * (aVal * mathpow( TDRatio, bVal )),armor,10000000000)
					else
						EffArmor = (armor / math.abs(normal) )
					end
				elseif (ShellType == "APFSDS" or ShellType == "APDS") and HitEntTbl.DakArmor >= Caliber * 0.85 then
					if HitAng >= 70 then Shatter = 1 end
					if HitAng >= 80 then Failed = 1 end
					EffArmor = armor * mathpow( 2.71828, mathpow( HitAng, 2.6 ) * 0.00003011 )
				end

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
	local NewFilter = table.Copy(Filter)
	NewFilter[#NewFilter + 1] = Ent
	local Go = 1
	local Shatters = HeatShattered
	local Fails = HeatFailed
	local Rico = 0
	local Thickest = Armor
	local SpallLiner = 0
	local SpallLinerOnCrit = 0
	local LinerThickness = 0

	while Go == 1 and Recurse < 25 do
		local newArmor, newEnt, LastPenPos, Shattered, Failed, newHitGun, newHitGear = DTTE.GetEffArmor(Start, End, ShellType, Caliber, NewFilter, nil, true)
		local newValid = newEnt:IsValid()
		local newEntClass
		if newValid then
			newEntClass = newEnt:GetClass()
		end
		if newHitGun == 1 then HitGun = 1 end
		if newHitGear == 1 then HitGear = 1 end
		if Armor == 0 then
			HeatShattered = Shattered
			HeatFailed = Failed
			FirstPenPos = LastPenPos
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
	local NewFilter = table.Copy(Filter)
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

	while Recurse < 50 do
		local newArmor, newEnt, LastPenPos, Shattered, Failed, newHitGun, newHitGear = DTTE.GetEffArmor(Start, End, ShellType, Caliber, NewFilter, core)
		local newValid = newEnt:IsValid()
		local newEntClass
		if newValid then
			newEntClass = newEnt:GetClass()
			if newEntClass == "dak_tegearbox" or newEntClass == "dak_tegearboxnew" or newEntClass == "dak_temotor" then
				newArmor = newArmor * 0.25
			end

			if newEnt.Controller == core then
				if newHitGun == 1 and HitCrit == 0 then HitGun = 1 end
				if newHitGear == 1 then HitGear = 1 end
				if Armor == 0 then
					HeatShattered = Shattered
					HeatFailed = Failed
					FirstPenPos = LastPenPos
				end
				if newArmor >= Thickest then
					Thickest = newArmor
					if newEntClass == "prop_physics" and HitCrew == 0 then
						ThickestPos = LastPenPos
					end
					SpallLiner = 0
					LinerThickness = 0
				else
					if newEntClass == "prop_physics" then
						LinerThickness = LinerThickness + newArmor
					end

					if LinerThickness >= Thickest * 0.1 and Thickest > 0 then
						SpallLiner = 1
					end
				end
				Shatters = Shatters + Shattered
				Fails = Fails + Failed
				Armor = Armor + newArmor

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
			else
				newArmor = 0
			end
		else
			if ShellType == "HEAT" or ShellType == "HEATFS" or ShellType == "ATGM" or ShellType == "HESH" then
				if ShellType == "HEAT" or ShellType == "HEATFS" or ShellType == "ATGM" then
					Armor = Armor + (FirstPenPos:Distance(LastPenPos) * 2.54)
				end
				if HeatFailed == 1 then Rico = 1 end
				Shatters = HeatShattered
			elseif ShellType == "APDS" or ShellType == "APFSDS" then
				if Fails > 0 then Rico = 1 end
			end
			if HitCrew == 1 then
				return CrewArmor, LastCrew, Shatters, Rico, HitGun, HitGear, HitCrit, FirstPenPos, SpallLinerOnCrit, CrewArmors, CrewHits, ThickestPos
			else
				return Armor, CritEnt, Shatters, Rico, HitGun, HitGear, HitCrit, FirstPenPos, SpallLinerOnCrit, CrewArmors, CrewHits, ThickestPos
			end
		end
		if Recurse >= 50 then
			return math.huge, CritEnt, Shatters, Rico, HitGun, HitGear, HitCrit, FirstPenPos, SpallLinerOnCrit, CrewArmors, CrewHits, ThickestPos
		end

		NewFilter[#NewFilter + 1] = newEnt

		Recurse = Recurse + 1
	end
end

function DTTE.GetArmorRecurseDisplay(Start, End, depth, ShellType, Caliber, Filter, core, mark, respectmark)
	if tonumber(Caliber) == nil then return 0, NULL, 0, 0, 0, 0, 0, Vector(0,0,0) end
	local Armor, Ent, FirstPenPos, HeatShattered, HeatFailed, HitGun, HitGear = DTTE.GetEffArmor(Start, End, ShellType, Caliber, Filter, core)
	local CritEnt = NULL
	if IsValid(Ent) then
		if Ent.Marked == true and respectmark == true then
			Armor = 0
		end
		local entClass = Ent:GetClass()
		if mark == true and Ent.Controller == core and entClass == "prop_physics" then Ent.Marked = true end
		if entClass == "dak_tegearbox" or entClass == "dak_tegearboxnew" or entClass == "dak_temotor" then
			Armor = Armor * 0.25
		end
		if (entClass == "dak_crew" or entClass == "dak_teammo" or entClass == "dak_teautoloadingmodule" or entClass == "dak_tefuel") then
			Armor = 0
			CritEnt = Ent
		end
		if Ent.Controller ~= core then
			Armor = 0
		end
	end
	local Recurse = 1
	local NewFilter = table.Copy(Filter)
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

	while Go == 1 and Recurse < 25 do
		local newArmor, newEnt, LastPenPos, Shattered, Failed, newHitGun, newHitGear = DTTE.GetEffArmor(Start, End, ShellType, Caliber, NewFilter, core)
		if newEnt:IsValid() then
			local newEntClass = newEnt:GetClass()
			if newEnt.Controller == core then
				if newEnt.Marked == true and respectmark == true then
					newArmor = 0
				end
				if mark == true and newEntClass == "prop_physics" then newEnt.Marked = true end

				if (newEntClass == "dak_tegearbox" or newEntClass == "dak_tegearboxnew" or newEntClass == "dak_temotor") then
					newArmor = newArmor * 0.25
				elseif(newEntClass == "dak_crew" or newEntClass == "dak_teammo" or newEntClass == "dak_teautoloadingmodule" or newEntClass == "dak_tefuel") then
					newArmor = 0
				end
				if newHitGun == 1 and HitCrit == 0 then HitGun = 1 end
				if newHitGear == 1 then HitGear = 1 end
				if Armor == 0 then
					HeatShattered = Shattered
					HeatFailed = Failed
					FirstPenPos = LastPenPos
				end
				if newArmor >= Thickest then
					if newEntClass == "prop_physics" then
						ThickestPos = FirstPenPos
					end
					Thickest = newArmor
					SpallLiner = 0
					LinerThickness = 0
				else
					if newEntClass == "prop_physics" then
						LinerThickness = LinerThickness + newArmor
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

				if CritEnt == NULL then
					if newEntClass == "dak_crew" or newEntClass == "dak_teammo" or newEntClass == "dak_teautoloadingmodule" or newEntClass == "dak_tefuel" then
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
			else
				newArmor = 0
			end
		else
			Go = 0
		end
		if Recurse >= 25 then
			return math.huge, CritEnt, Shatters, Rico, HitGun, HitGear, HitCrit, FirstPenPos, SpallLinerOnCrit, ThickestPos
		end

		if Go == 0 then
			if ShellType == "HEAT" or ShellType == "HEATFS" or ShellType == "ATGM" or ShellType == "HESH" then
				if not(ShellType == "HESH") then
					Armor = Armor + (math.Min(FirstPenPos:Distance(LastPenPos),depth) * 2.54)
				end
				if HeatFailed == 1 then Rico = 1 end
				Shatters = HeatShattered
			elseif ShellType == "APDS" or ShellType == "APFSDS" then
				if Fails > 0 then Rico = 1 end
			end
			return Armor, CritEnt, Shatters, Rico, HitGun, HitGear, HitCrit, FirstPenPos, SpallLinerOnCrit, ThickestPos
		end

		NewFilter[#NewFilter + 1] = newEnt

		Recurse = Recurse + 1
	end
end