E2Lib.RegisterExtension("daktank", true)

local DTTE = DTTE
local gunClasses = {
	["dak_tegun"] = true,
	["dak_teautogun"] = true,
	["dak_temachinegun"] = true
}

-- E2 Functions
__e2setcost(1)
e2function number entity:daktankArmor()
	if not IsValid(this) then return 0 end
	if this.IsWorld() then return 0 end

	if this.DakArmor == nil then
		DTTE.SetupNewEnt(this)
	end
	local SA = -1
	if IsValid(this:GetPhysicsObject()) then
		SA = this:GetPhysicsObject():GetSurfaceArea()
	end
	if this.IsDakTekFutureTech == 1 then
		this.DakArmor = 1000
	else
		if SA == -1 or SA == nil then
			this.DakArmor = this:OBBMaxs().x/2
			this.DakIsTread = 1
		else
			if this:GetClass()=="prop_physics" then
				if this.DakBurnStacks then
					if not(this.DakArmor == 7.8125*(this:GetPhysicsObject():GetMass()/4.6311781)*(288/SA) - this.DakBurnStacks*0.25) then
						this.DakArmor = 7.8125*(this:GetPhysicsObject():GetMass()/4.6311781)*(288/SA) - this.DakBurnStacks*0.25
					end
				else
					if not(this.DakArmor == 7.8125*(this:GetPhysicsObject():GetMass()/4.6311781)*(288/SA)) then
						this.DakArmor = 7.8125*(this:GetPhysicsObject():GetMass()/4.6311781)*(288/SA)
					end
				end

			end
		end
	end
	if this.DakArmor == nil then
		return 1
	else
		return this.DakArmor
	end
end

e2function number entity:daktankHealth()
	if not IsValid(this) then return 0 end

	if this.DakArmor == nil then
		DTTE.SetupNewEnt(this)
	end

	if this.DakHealth == nil then
		return 1
	else
		return this.DakHealth
	end
end

e2function number entity:daktankMaxHealth()
	if not IsValid(this) then return 0 end

	if this.DakArmor == nil then
		DTTE.SetupNewEnt(this)
	end

	if this.DakMaxHealth == nil then
		return 1
	else
		return this.DakMaxHealth
	end
end

e2function string entity:daktankGetName()
	if not IsValid(this) then return "" end

	if this.DakName == nil then
		return ""
	else
		return this.DakName
	end
end

e2function string entity:daktankGetAmmoType()
	if not IsValid(this) then return "" end

	if gunClasses[this:GetClass()] then
		if this.DakName == nil then
			return ""
		else
			if this.DakName == "Flamethrower" then
				return "Fuel"
			elseif this.DakGunType == "Smoke Launcher" then
				return "SM"
			else
				if this.CurrentAmmoType == 1 then
					return "AP"
				end
				if this.CurrentAmmoType == 2 then
					return "HE"
				end
				if this.CurrentAmmoType == 3 then
					return "HEAT"
				end
				if this.CurrentAmmoType == 4 then
					return "HVAP"
				end
				if this.CurrentAmmoType == 5 then
					return "HESH"
				end
				if this.CurrentAmmoType == 6 then
					return "ATGM"
				end
				if this.CurrentAmmoType == 7 then
					return "HEATFS"
				end
				if this.CurrentAmmoType == 8 then
					return "APFSDS"
				end
				if this.CurrentAmmoType == 9 then
					return "APHE"
				end
				if this.CurrentAmmoType == 10 then
					return "APDS"
				end
				if this.CurrentAmmoType == 11 then
					return "SM"
				end
			end
		end
	else
		return ""
	end
end

e2function number entity:daktankGetCooldownPerc()
	if not IsValid(this) then return 0 end

	if this:GetClass() == "dak_tegun" or this:GetClass() == "dak_temachinegun" then
		if this.ShellLoaded == 1 then
			return 0
		else
			if this.LastFireTime == nil or this.DakCooldown == nil then
				return 1
			else
				return 100*(math.Clamp((this.LastFireTime+this.DakCooldown)-CurTime(),0,100)/this.DakCooldown)
			end
		end
	end
	if this:GetClass() == "dak_teautogun" then
		if this.LastFireTime == nil or this.DakCooldown == nil or this.DakLastReload == nil or this.DakReloadTime == nil then
			return 1
		else
			if this.DakIsReloading == 0 then
				if this.ShellLoaded == 1 then
					return 0
				else
					if this.NoLoad == 1 then
						return 100
					else
						return 100*(math.Clamp((this.LastFireTime+this.DakCooldown)-CurTime(),0,100)/this.DakCooldown)
					end
				end
			else
				return 100*(math.Clamp((this.DakLastReload+this.DakReloadTime)-CurTime(),0,100)/this.DakReloadTime)
			end
		end
	end
	return 0
end

e2function number entity:daktankGetAmmoCount()
	if not IsValid(this) then return 1 end

	if gunClasses[this:GetClass()] then
		if this.AmmoCount == nil then
			return 1
		else
			return this.AmmoCount
		end
	end
	return 1
end

e2function number entity:daktankGetShellPenetration()
	if not IsValid(this) then return 0 end

	if gunClasses[this:GetClass()] then
		if this.DakShellPenetration == nil then
			return 1
		else
			if this.CurrentAmmoType == 1 or this.CurrentAmmoType == 2 or this.CurrentAmmoType == 4 or this.CurrentAmmoType == 8 or this.CurrentAmmoType == 9 or this.CurrentAmmoType == 10 then
				local Propellant = this:GetPropellant()
				if Propellant == nil then
					return this.DakShellPenetration
				else
					return this.DakShellPenetration * (Propellant*0.01)
				end
			else
				return this.DakShellPenetration
			end
		end
	end
	return 0
end

e2function number entity:daktankGetShellVelocity()
	if not IsValid(this) then return 0 end

	if gunClasses[this:GetClass()] then
		if this.DakShellVelocity == nil then
			return 1
		else
			local Propellant = this:GetPropellant()
			if Propellant == nil then
				return this.DakShellVelocity
			else
				return this.DakShellVelocity * (Propellant*0.01)
			end
		end
	end
	return 0
end

e2function number entity:daktankGetShellMass()
	if not IsValid(this) then return 0 end

	if gunClasses[this:GetClass()] then
		if this.DakShellMass == nil then
			return 1
		else
			return this.DakShellMass
		end
	end
	return 0
end

e2function number entity:daktankGetShellDamage()
	if not IsValid(this) then return 0 end

	if gunClasses[this:GetClass()] then
		if this.DakShellDamage == nil then
			return 1
		else
			return this.DakShellDamage
		end
	end
	return 0
end

e2function number entity:daktankGetMaxCooldown()
	if not IsValid(this) then return 0 end

	if gunClasses[this:GetClass()] then
		if this.DakCooldown == nil then
			return 1
		else
			return this.DakCooldown
		end
	end
	return 0
end

e2function number entity:daktankGetGunLoaded()
	if not IsValid(this) then return 0 end
	if this:GetClass() == "dak_tegun" or this:GetClass() == "dak_teautogun" then
		if this.ShellLoaded == 1 or this.ShellLoaded2 == 1 then return 1 end
	end
	if this:GetClass() == "dak_temachinegun" then
		if CurTime() > (this.timer + this.DakCooldown) then return 1 end
	end
	return 0
end

e2function number daktankHitCrit(vector Start, vector End, string ShellType, number Caliber, array Filter)
	local ArmorVal, Ent = DTTE.GetArmorRecurse(Vector(Start[1],Start[2],Start[3]), Vector(End[1],End[2],End[3]), ShellType, Caliber, Filter)
	if Ent:IsWorld() and ArmorVal > 0 then
		ArmorVal = 1000000
	end
	if not(ArmorVal>-1) then return 1000000 end
	return ArmorVal
end

e2function number daktankRecurseArmor(vector Start, vector End, string ShellType, number Caliber, array Filter)
	local ArmorVal, Ent = DTTE.GetArmorRecurse(Vector(Start[1],Start[2],Start[3]), Vector(End[1],End[2],End[3]), ShellType, Caliber, Filter)
	if not(ArmorVal>-1) then return 1000000 end
	return ArmorVal
end

e2function number entity:daktankGetSpeed()
	if not IsValid(this) then return 0 end

	if this:GetClass() == "dak_tegearbox" then
		if this.Speed == nil then
			return 0
		else
			return this.Speed
		end
	end
	return 0
end

e2function number entity:daktankGetTopSpeed()
	if not IsValid(this) then return 0 end

	if this:GetClass() == "dak_tegearbox" then
		if this.TopSpeed == nil then
			return 0
		else
			return this.TopSpeed
		end
	end
	return 0
end

e2function number entity:daktankGetCrewCount()
	if not IsValid(this) then return 0 end

	if this:GetClass() == "dak_tankcore" then
		if this.LivingCrew == nil then
			return 0
		else
			return this.LivingCrew
		end
	end
	return 0
end

e2function number entity:daktankGetAPSShots()
	if not IsValid(this) then return 0 end

	if this:GetClass() == "dak_tankcore" then
		if this.APSShots == nil then
			return 0
		else
			return this.APSShots
		end
	end
	return 0
end