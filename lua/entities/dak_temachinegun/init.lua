AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

ENT.DakOwner = NULL
ENT.DakName = "Base Gun"
ENT.DakModel = "models/daktanks/cannon25mm.mdl"
ENT.DakCooldown = 1
ENT.DakMaxHealth = 1
ENT.DakHealth = 1
ENT.DakAmmo = 0
ENT.DakMass = 1
ENT.DakAmmoType = ""
ENT.DakFireEffect = ""
ENT.DakFirePitch = 100
ENT.DakPellets = 1
--shell definition
ENT.DakShellTrail = "a"
ENT.DakShellVelocity = 1
ENT.DakShellDamage = 1
ENT.DakShellPenSounds = {}
ENT.DakShellMass = 1
ENT.DakShellSplashDamage = 1
ENT.DakShellPenetration = 1
ENT.DakShellExplosive = false
ENT.DakShellBlastRadius = 100
ENT.DakPenLossPerMeter = 0.0005
ENT.DakPooled = 0
ENT.DakArmor = 1
ENT.DakTankCore = nil
ENT.HasCrew = 0
ENT.BasicVelocity = 29527.6
ENT.muzzle = NULL

function ENT:Initialize()
	--self:SetModel(self.DakModel)
	self.DakHealth = self.DakMaxHealth

	self:PhysicsInit(SOLID_VPHYSICS)
	--self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)

	self.timer = CurTime()

	self.Inputs = Wire_CreateInputs(self, { "Fire", "FuzeDelay" })
	self.Outputs = WireLib.CreateOutputs( self, { "Cooldown" , "CooldownPercent", "MaxCooldown", "Ammo", "AmmoType [STRING]", "MuzzleVel", "ShellMass", "Penetration" } )
	self.Held = false
	self.Soundtime = CurTime()
	self.SlowThinkTime = 0
	self.MidThinkTime = CurTime()
	self.LastFireTime = CurTime()
	self.CurrentAmmoType = 1
	self.DakBurnStacks = 0
	self.BasicVelocity = 29527.6
	self.truefire = false

	function self:SetupDataTables()
		self:NetworkVar("Bool",0,"Firing")
		self:NetworkVar("Float",0,"Timer")
		self:NetworkVar("Float",1,"Cooldown")
		self:NetworkVar("String",0,"Model")
	end
	self:SetNWFloat("Caliber",self.DakCaliber)
	self.FireRateMod = math.Clamp(self:GetRateOfFire(),0,1)

	self.muzzle = ents.Create("prop_physics")
	self.muzzle:SetAngles(self:GetForward():Angle()+Angle(0,-90,0))
	self.muzzle:SetPos(self:GetPos())
	self.muzzle:SetMoveType(MOVETYPE_NONE)
	self.muzzle:PhysicsInit(SOLID_NONE)
	self.muzzle:SetParent(self)
	self.muzzle:SetModel( "models/daktanks/smokelauncher40mm.mdl" )
	self.muzzle:DrawShadow(false)
	self.muzzle:SetColor( Color(255, 255, 255, 0) )
	self.muzzle:SetRenderMode( RENDERMODE_TRANSCOLOR )
	self.muzzle:Spawn()
	self.muzzle:Activate()
	self.muzzle:SetMoveType(MOVETYPE_NONE)
	self.muzzle:PhysicsInit(SOLID_NONE)
end

function ENT:Think()
	self.FuzeDelay = self.Inputs.FuzeDelay.Value

	if self.ScaleSet == true then
		if self.DakGunType == nil then self:Remove() end

		if self:GetModel() ~= self.DakModel then
			self:SetModel(self.DakModel)
			--self:PhysicsInit(SOLID_VPHYSICS)
			self:SetMoveType(MOVETYPE_VPHYSICS)
			self:SetSolid(SOLID_VPHYSICS)
		end

		if self.DakCaliber ~= nil and self.ScalingFinished == nil then
			self.ScalingFinished = true
			local muzzlepos1
			local muzzlepos2
			muzzlepos1, muzzlepos2 = self:GetModelBounds()
			local length = math.Max(math.abs(muzzlepos1.x),math.abs(muzzlepos1.y),math.abs(muzzlepos1.z),math.abs(muzzlepos2.x),math.abs(muzzlepos2.y),math.abs(muzzlepos2.z))*(self.DakCaliber/100)
			self.muzzle:SetPos(self:GetPos()+self:GetForward()*length)
			if IsValid(self.Controller) and self.Controller.DakFinishedPasting == 1 then
				if self:GetParent():IsValid() == false then
					self.DakOwner:ChatPrint("Parenting Error on "..self.DakName..". Please reparent, make sure the gate is parented to the aimer prop and the gun is parented to the gate.")
				else
					if self:GetParent():GetParent():IsValid() == false then
						self.DakOwner:ChatPrint("Parenting Error on "..self.DakName..". Please reparent, make sure the gate is parented to the aimer prop and the gun is parented to the gate.")
					end
				end
			end
		end

		if CurTime() >= self.MidThinkTime + 0.33 and self.BaseDakShellDamage ~= nil then
			self:DakTEAmmoCheck()

			WireLib.TriggerOutput(self, "Cooldown", math.Clamp((self.LastFireTime+self.DakCooldown)-CurTime(),0,10000))
			WireLib.TriggerOutput(self, "CooldownPercent", 100*(math.Clamp((self.LastFireTime+self.DakCooldown)-CurTime(),0,100)/self.DakCooldown))
			WireLib.TriggerOutput(self, "MaxCooldown",self.DakCooldown)
			self.MidThinkTime = CurTime()
		end
	end

	if CurTime() >= self.SlowThinkTime + 1 then
		--Machine Guns
		if self.DakGunType == "MG" then
			self.DakName = self.DakCaliber.."mm Machine Gun"
			self.DakCooldown = math.Round((self.DakCaliber/13 + self.DakCaliber/100)*0.1,2)
			self.DakMaxHealth = self.DakCaliber
			self.DakArmor = self.DakCaliber*5
			self.DakMass = math.Round(5+(2*math.Round(((((self.DakCaliber*6.5)*(self.DakCaliber*3)*(self.DakCaliber*3))+(math.pi*(self.DakCaliber^2)*(self.DakCaliber*50))-(math.pi*((self.DakCaliber/2)^2)*(self.DakCaliber*50)))*0.001*7.8125)/1000)))

			self.DakAP = math.Round(self.DakCaliber,2).."mmMGAPAmmo"

			self.BaseDakShellDamage = (math.pi*((self.DakCaliber*0.02*0.5)^2)*(self.DakCaliber*0.02*6.5))*25
			--get the volume of shell and multiply by density of steel
			--pi*radius^2 * height * density
			--Shell length ratio: Cannon - 6.5, Howitzer - 4, Mortar - 2.75
			self.BaseDakShellMass = (math.pi*((self.DakCaliber*0.001*0.5)^2)*(self.DakCaliber*0.001*6.5))*7700
			self.DakShellSplashDamage = self.DakCaliber*0.0375
			self.BaseDakShellPenetration = (self.DakCaliber*2)*(50/50)
			--self.DakShellExplosive = false
			self.ShellLengthMult = 50/50
			self.DakShellBlastRadius = (((self.DakCaliber/155)*50)*39)*(-0.005372093*(self.ShellLengthMult*50)+1.118186)
			self.DakBaseShellFragPen = (2.137015-0.1086095*self.DakCaliber+0.002989107*self.DakCaliber^2)*(-0.005372093+1.118186)

			self.DakFireEffect = "dakteballisticfire"
			self.DakShellTrail = "dakteballistictracer"
			self.BaseDakShellVelocity = self.BasicVelocity

			if self.DakCaliber <= 75 then
				self.DakShellPenSounds = {"daktanks/daksmallpen1.mp3","daktanks/daksmallpen2.mp3","daktanks/daksmallpen3.mp3","daktanks/daksmallpen4.mp3"}
				self.ReloadSound = "daktanks/dakreloadlight.mp3"
			end
			if self.DakCaliber > 75 and self.DakCaliber < 120 then
				self.DakShellPenSounds = {"daktanks/dakmedpen1.mp3","daktanks/dakmedpen2.mp3","daktanks/dakmedpen3.mp3","daktanks/dakmedpen4.mp3","daktanks/dakmedpen5.mp3"}
				self.ReloadSound = "daktanks/dakreloadmedium.mp3"
			end
			if self.DakCaliber >= 120 then
				self.DakShellPenSounds = {"daktanks/dakhevpen1.mp3","daktanks/dakhevpen2.mp3","daktanks/dakhevpen3.mp3","daktanks/dakhevpen4.mp3","daktanks/dakhevpen5.mp3"}
				self.ReloadSound = "daktanks/dakreloadheavy.mp3"
			end

			if self.DakFireSound1 == nil then
				if self.DakCaliber < 7.62 then
					self.DakFireSound1 = "daktanks/5mm.mp3"
				end
				if self.DakCaliber >= 7.62 and self.DakCaliber < 9 then
					self.DakFireSound1 = "daktanks/7mm.mp3"
				end
				if self.DakCaliber >= 9 and self.DakCaliber < 12.7 then
					self.DakFireSound1 = "daktanks/9mm.mp3"
				end
				if self.DakCaliber >= 12.7 and self.DakCaliber < 14.5 then
					self.DakFireSound1 = "daktanks/12mm.mp3"
				end
				if self.DakCaliber >= 14.5 then
					self.DakFireSound1 = "daktanks/14mm.mp3"
				end
			end
		end

		--SmokeLauncher
		if self.DakGunType == "Smoke Launcher" then
			self.DakName = self.DakCaliber.."mm Smoke Launcher"
			self.DakCooldown = 30
			self.DakMaxHealth = self.DakCaliber
			self.DakArmor = self.DakCaliber*5
			self.DakMass = math.Round(1+(0.1*math.Round(((((self.DakCaliber*0.5)*(self.DakCaliber*3)*(self.DakCaliber*3))+(math.pi*(self.DakCaliber^2)*(self.DakCaliber*3))-(math.pi*((self.DakCaliber/2)^2)*(self.DakCaliber*3)))*0.001*7.8125)/1000)))

			self.DakSM = math.Round(self.DakCaliber,2).."mmSLSMAmmo"

			self.BaseDakShellDamage = (math.pi*((self.DakCaliber*0.02*0.5)^2)*(self.DakCaliber*0.02*0.5))*25
			--get the volume of shell and multiply by density of steel
			--pi*radius^2 * height * density
			--Shell length ratio: Cannon - 6.5, Howitzer - 4, Mortar - 2.75, SL - 0.5
			self.BaseDakShellMass = (math.pi*((self.DakCaliber*0.001*0.5)^2)*(self.DakCaliber*0.001*0.5))*7700
			self.DakShellSplashDamage = self.DakCaliber*5
			self.BaseDakShellPenetration = (self.DakCaliber*2)*(3/50)
			--self.DakShellExplosive = false
			self.ShellLengthMult = 3/50
			self.DakShellBlastRadius = (((self.DakCaliber/155)*50)*39)*(-0.005372093*(self.ShellLengthMult*50)+1.118186)
			self.DakBaseShellFragPen = (2.137015-0.1086095*self.DakCaliber+0.002989107*self.DakCaliber^2)*(-0.005372093+1.118186)

			self.DakFireEffect = "dakteballisticfire"
			self.DakShellTrail = "dakteballistictracer"
			self.BaseDakShellVelocity = self.BasicVelocity*3/50

			if self.DakCaliber <= 75 then
				self.DakShellPenSounds = {"daktanks/daksmallpen1.mp3","daktanks/daksmallpen2.mp3","daktanks/daksmallpen3.mp3","daktanks/daksmallpen4.mp3"}
				self.ReloadSound = "daktanks/dakreloadlight.mp3"
			end
			if self.DakCaliber > 75 and self.DakCaliber < 120 then
				self.DakShellPenSounds = {"daktanks/dakmedpen1.mp3","daktanks/dakmedpen2.mp3","daktanks/dakmedpen3.mp3","daktanks/dakmedpen4.mp3","daktanks/dakmedpen5.mp3"}
				self.ReloadSound = "daktanks/dakreloadmedium.mp3"
			end
			if self.DakCaliber >= 120 then
				self.DakShellPenSounds = {"daktanks/dakhevpen1.mp3","daktanks/dakhevpen2.mp3","daktanks/dakhevpen3.mp3","daktanks/dakhevpen4.mp3","daktanks/dakhevpen5.mp3"}
				self.ReloadSound = "daktanks/dakreloadheavy.mp3"
			end

			if self.DakFireSound1 == nil then
				self.DakFireSound1 = "daktanks/new/cannons/misc/grenade_launcher_01.mp3"
			end
		end
		--Flamethrower
		if self.DakGunType == "Flamethrower" then
			self.DakName = "Flamethrower"
			self.DakCooldown = 1 / 66
			self.DakMaxHealth = 10
			self.DakArmor = 50
			self.DakMass = 50
			self.DakCaliber = 100 --keep this here for scaling purposes

			self.DakAP = "Flamethrower Fuel"

			self.BaseDakShellDamage = 0.75
			self.BaseDakShellMass = 1
			self.DakShellSplashDamage = 0.2
			self.BaseDakShellPenetration = 0.0001
			--self.DakShellExplosive = false
			self.DakShellBlastRadius = 15

			self.DakFireEffect = "dakteflamefire"
			self.DakShellTrail = "dakteflametrail"
			self.BaseDakShellVelocity = 5000

			self.DakShellPenSounds = {"daktanks/daksmallpen1.mp3","daktanks/daksmallpen2.mp3","daktanks/daksmallpen3.mp3","daktanks/daksmallpen4.mp3"}
			self.ReloadSound = "daktanks/dakreloadlight.mp3"

			if self.DakFireSound1 == nil then
				self.DakFireSound1 = "daktanks/flamerfire.mp3"
			end
		end

		self.DakFirePitch = 100
		self.DakPellets = 10

		if self.ScaleSet == true then
			self.DakCooldown = self.DakCooldown * (1 / self.FireRateMod)

			if self.DakHealth > self.DakMaxHealth then
				self.DakHealth = self.DakMaxHealth
			end

			if self.DakFireSound2 == nil then
				self.DakFireSound2 = self.DakFireSound1
			end

			if self.DakFireSound3 == nil then
				self.DakFireSound3 = self.DakFireSound1
			end
		end

		local physObj = self:GetPhysicsObject()

		if physObj:IsValid() then
			if physObj:GetMass() ~= self.DakMass then
				physObj:SetMass(self.DakMass)
			end

			self.DakArmor = 3.90625 * (physObj:GetMass() / 4.6311781) * (288 / physObj:GetSurfaceArea()) - self.DakBurnStacks * 0.25
		end

		self.SlowThinkTime = CurTime()
	end

	self:NextThink(CurTime() + 0.1)

	return true
end

function ENT:DakTEAmmoCheck()
	if self.CurrentAmmoType == 1 then
		if self.DakName == "Flamethrower" then
			WireLib.TriggerOutput(self, "AmmoType", "Fuel")
			self.DakAmmoType = self.DakAP
			self.DakShellAmmoType = "AP"
			self.DakShellVelocity = self.BaseDakShellVelocity
			self.DakShellExplosive = false
			self.DakShellDamage = self.BaseDakShellDamage
			self.DakShellPenetration = self.BaseDakShellPenetration
		elseif self.DakGunType == "Smoke Launcher" then
			WireLib.TriggerOutput(self, "AmmoType", "Smoke")
			self.DakAmmoType = self.DakSM
			self.DakShellAmmoType = "SM"
			self.DakShellExplosive = true
			if self.BaseDakShellDamage~= nil then self.DakShellDamage = self.BaseDakShellDamage/4 end
			self.DakShellPenetration = self.DakMaxHealth*0.1
			if self.BaseDakShellVelocity~= nil then self.DakShellVelocity = self.BaseDakShellVelocity*0.42 end
			self.DakPenLossPerMeter = 0.001
			self.DakShellFragPen = 0
		else
			WireLib.TriggerOutput(self, "AmmoType", "Armor Piercing")
			self.DakAmmoType = self.DakAP
			self.DakShellAmmoType = "AP"
			self.DakShellVelocity = self.BaseDakShellVelocity
			self.DakShellExplosive = false
			self.DakShellDamage = self.BaseDakShellDamage
			self.DakShellPenetration = self.BaseDakShellPenetration
		end

		self.DakShellMass = self.BaseDakShellMass
		self.DakPenLossPerMeter = 0.0005

		WireLib.TriggerOutput(self, "MuzzleVel", self.DakShellVelocity)
		WireLib.TriggerOutput(self, "ShellMass", self.DakShellMass)
		WireLib.TriggerOutput(self, "Penetration", self.DakShellPenetration)
	end

	if IsValid(self.DakTankCore) then
		self.AmmoCount = 0
		if not(self.DakTankCore.Ammoboxes == nil) then
			for i = 1, #self.DakTankCore.Ammoboxes do
				if IsValid(self.DakTankCore.Ammoboxes[i]) then
					if self.DakTankCore.Ammoboxes[i].DakAmmoType == self.DakAmmoType then
						self.AmmoCount = self.AmmoCount + self.DakTankCore.Ammoboxes[i].DakAmmo
					end
				end
			end
		end
		WireLib.TriggerOutput(self, "Ammo", self.AmmoCount)
	end
end

function ENT:DakTEFire()
	if ( self.Firing and self.DakDead ~= true) then
		if IsValid(self.DakTankCore) then
			self.AmmoCount = 0
			if not(self.DakTankCore.Ammoboxes == nil) then
				for i = 1, #self.DakTankCore.Ammoboxes do
					if IsValid(self.DakTankCore.Ammoboxes[i]) then
						if self.DakTankCore.Ammoboxes[i].DakAmmoType == self.DakAmmoType then
							self.AmmoCount = self.AmmoCount + self.DakTankCore.Ammoboxes[i].DakAmmo
						end
					end
				end
			end
		end
		if self.AmmoCount > 0 then
			if CurTime() > (self.timer + self.DakCooldown) or self.truefire then
				--AMMO CHECK HERE
				for i = 1, #self.DakTankCore.Ammoboxes do
					if IsValid(self.DakTankCore.Ammoboxes[i]) then
						if self.DakTankCore.Ammoboxes[i].DakAmmoType == self.DakAmmoType then
							if self.DakTankCore.Ammoboxes[i].DakAmmo > 0 then
								self.DakTankCore.Ammoboxes[i].DakAmmo = self.DakTankCore.Ammoboxes[i].DakAmmo-1
							break end
						end
					end
				end
				--FIREBULLETHERE
				self.LastFireTime = CurTime()
				local shootOrigin = self:GetPos()
				local shootAngles = (self:GetForward()*self.DakShellVelocity):GetNormalized():Angle()
				local initvel = self.DakTankCore:GetVelocity()
				if self.DakTankCore:GetParent():IsValid() then
					initvel = self.DakTankCore:GetParent():GetVelocity()
					if self.DakTankCore:GetParent():GetParent():IsValid() then
						initvel = self.DakTankCore:GetParent():GetParent():GetVelocity()
					end
				end

				local Propellant = math.Clamp(self:GetPropellant(),10,100)*0.01
 				local Shell = {}
 				Shell.Pos = shootOrigin + ( self:GetForward() * 1 )
				Shell.DakTrail = self.DakShellTrail
				Shell.DakVelocity = ((self.DakShellVelocity * math.Rand( 0.99, 1.01 ) * Propellant) * (shootAngles + Angle(math.Rand(-0.1,0.1),math.Rand(-0.1,0.1),math.Rand(-0.1,0.1)) ):Forward()) + initvel
				Shell.DakBaseVelocity = self.DakShellVelocity * Propellant
				Shell.Propellant = Propellant
				Shell.DakDamage = self.DakShellDamage * math.Rand( 0.99, 1.01 )
				Shell.DakMass = self.DakShellMass
				Shell.DakIsPellet = false
				Shell.DakSplashDamage = self.DakShellSplashDamage * math.Rand( 0.99, 1.01 )
				Shell.DakPenetration = self.DakShellPenetration * math.Rand( 0.99, 1.01 )
				if self.DakShellAmmoType == "AP" or self.DakShellAmmoType == "HE" or self.DakShellAmmoType == "HVAP" or self.DakShellAmmoType == "APFSDS" or self.DakShellAmmoType == "APHE" or self.DakShellAmmoType == "APDS" or self.DakShellAmmoType == "SM" then
					Shell.DakPenetration = self.DakShellPenetration * math.Rand( 0.99, 1.01 ) * Propellant
				end
				Shell.DakExplosive = self.DakShellExplosive
				Shell.DakBlastRadius = self.DakShellBlastRadius
				Shell.DakPenSounds = self.DakShellPenSounds
				Shell.DakBasePenetration = self.BaseDakShellPenetration
				Shell.DakFragPen = self.DakBaseShellFragPen
				Shell.DakCaliber = self.DakMaxHealth
				Shell.DakFireSound = self.DakFireSound1
				Shell.DakFirePitch = self.DakFirePitch
				Shell.DakGun = self
				local Driver = nil
				for i=1, #self.DakTankCore.Seats do
					if Driver == nil then
						if IsValid(self.DakTankCore.Seats[i]:GetDriver()) then
							Driver = self.DakTankCore.Seats[i]:GetDriver()
						end
					end
				end
				Shell.DakGun.DakOwner = Driver
				Shell.Filter = table.Copy(self.DakTankCore.Contraption)
				Shell.LifeTime = 0
				Shell.Gravity = 0
				Shell.DakPenLossPerMeter = self.DakPenLossPerMeter
				Shell.DakShellType = self.DakShellAmmoType
				if self.DakShellAmmoType == "HESH" or self.DakShellAmmoType == "HEAT" or self.DakShellAmmoType == "HEATFS" or self.DakShellAmmoType == "APHE" then
					Shell.DakBlastRadius = self.DakShellBlastRadius * 0.5
					Shell.DakSplashDamage = self.DakShellSplashDamage * math.Rand( 0.99, 1.01 ) * 0.5
				end
				if self.DakShellAmmoType == "SM" then
					Shell.DakBlastRadius = self.DakShellBlastRadius
					Shell.DakSplashDamage = self.DakShellSplashDamage * math.Rand( 0.99, 1.01 ) * 0.1
				end
				if self.DakName == "Flamethrower" then
					Shell.DakIsFlame = 1
				end
				if self.FuzeOverride == true then
					Shell.FuzeDelay = self.FuzeOverrideDelay
				else
					Shell.FuzeDelay = self.FuzeDelay
				end
				DTTE.ShellList[#DTTE.ShellList+1] = Shell

				local FiringSound = {self.DakFireSound1,self.DakFireSound2,self.DakFireSound3}

				self:SetNWString("FireSound",FiringSound[math.random(1,3)])
				self:SetNWInt("FirePitch",self.DakFirePitch)
				self:SetNWFloat("Caliber",self.DakCaliber)

				if self.DakName == "Flamethrower" then
					if self.FlameFiring == nil then self.FlameFiring = 0 end
					if self.FlameFiring == 0 then
						self:EmitSound( "daktanks/flamethrower_start.wav", 100, 95, 1, 6)
						self:EmitSound( "daktanks/flamethrower_loop.wav", 100, 95, 1, 6)

						--weapons/flame_thrower_fire_hit.wav
						self.FlameFiring = 1
					end
				else
				net.Start( "daktankshotfired" )
				net.WriteVector( self:GetPos() )
				net.WriteFloat( self.DakCaliber )
				net.WriteString( FiringSound[math.random(1,3)] )
				net.Broadcast()
				end
				--if self.DakCaliber>=40 then
				--	self:SetNWBool("Firing",true)
				--	timer.Create( "ResoundTimer"..self:EntIndex(), 0.1, 1, function()
				--		self:SetNWBool("Firing",false)
				--	end)
				--else
				--	sound.Play( FiringSound[math.random(1,3)], self:GetPos(), 100, 100*math.Rand(0.95, 1.05), 1 )
				--end


				local effectdata = EffectData()
				local muzzlepos1
				local muzzlepos2
				muzzlepos1, muzzlepos2 = self:GetModelBounds()
				local length = math.Max(math.abs(muzzlepos1.x),math.abs(muzzlepos1.y),math.abs(muzzlepos1.z),math.abs(muzzlepos2.x),math.abs(muzzlepos2.y),math.abs(muzzlepos2.z))*(self.DakCaliber/100)
				effectdata:SetOrigin( self:GetPos()+self:GetForward()*length )
				effectdata:SetAngles( self:GetAngles() )
				effectdata:SetEntity(self.muzzle)
				effectdata:SetScale( self.DakMaxHealth*0.25 )
				util.Effect( self.DakFireEffect, effectdata, true, true )

				--self:EmitSound( self.DakFireSound1, 100, self.DakFirePitch, 1, 6)
				self.timer = CurTime()
				if (self:IsValid()) then
					if(self.DakTankCore:GetParent():IsValid()) then
						if(self.DakTankCore:GetParent():GetParent():IsValid()) then
							self.DakTankCore:GetParent():GetParent():GetPhysicsObject():ApplyForceOffset( self.DakTankCore:GetParent():GetParent():GetPhysicsObject():GetMass()*((-self:GetForward()*((self.BaseDakShellMass)*((self.DakShellVelocity*0.0254))))/self.DakTankCore.TotalMass) , self:GetPos() )
						end
					end
					if not(self.DakTankCore:GetParent():IsValid()) then
						self:GetPhysicsObject():ApplyForceCenter( self:GetPhysicsObject():GetMass()*((-self:GetForward()*((self.BaseDakShellMass)*((self.DakShellVelocity*0.0254))))/self.DakTankCore.TotalMass) )
					end
				end
			end
		else
			if self.FlameFiring == 1 then
				self.FlameFiring = 0
				self:StopSound( "daktanks/flamethrower_start.wav" )
				self:StopSound( "daktanks/flamethrower_loop.wav" )
				self:EmitSound( "daktanks/flamethrower_end.wav", 100, 95, 1, 6 )
			end
		end
	end
	if IsValid(self.DakTankCore) then
		self.AmmoCount = 0
		if not(self.DakTankCore.Ammoboxes == nil) then
			for i = 1, #self.DakTankCore.Ammoboxes do
				if IsValid(self.DakTankCore.Ammoboxes[i]) then
					if self.DakTankCore.Ammoboxes[i].DakAmmoType == self.DakAmmoType then
						self.AmmoCount = self.AmmoCount + self.DakTankCore.Ammoboxes[i].DakAmmo
					end
				end
			end
		end
		WireLib.TriggerOutput(self, "Ammo", self.AmmoCount)
	end
end

function ENT:TriggerInput(iname, value)
	if IsValid(self.DakTankCore) and hook.Run("DakTankCanFire", self) ~= false then
		self.Held = value
		if (iname == "Fire") then
			if value > 0 then
				self.Firing = value > 0
				self:DakTEFire()
				if self.Refiring then
					local ShotsFiredSinceLastCall = math.floor((CurTime() - self.LastFireTime) / self.DakCooldown)
					if ShotsFiredSinceLastCall > 0 then
						for _ = 1, ShotsFiredSinceLastCall do
							self.truefire = true
							self:DakTEFire()
						end
					end
				end
				timer.Create( "RefireTimer" .. self:EntIndex(), self.DakCooldown, 1, function()
					if IsValid(self) then
						self.Refiring = true
						self.truefire = true
						self:TriggerInput("Fire", value)
						--self:DakTEFire()
					end
				end)
			else
				timer.Remove( "RefireTimer" .. self:EntIndex() )
				self.Refiring = false
				self.truefire = false
				if self.FlameFiring == 1 then
					self.FlameFiring = 0
					self:StopSound( "daktanks/flamethrower_start.wav" )
					self:StopSound( "daktanks/flamethrower_loop.wav" )
					self:EmitSound( "daktanks/flamethrower_end.wav", 100, 95, 1, 6 )
				end
			end
		end
	end
end

function ENT:PreEntityCopy()
	local info = {}

	info.DakName = self.DakName
	info.DakMaxHealth = self.DakMaxHealth
	info.DakHealth = self.DakHealth
	info.DakModel = self.DakModel
	info.DakOwner = self.DakOwner
	info.DakColor = self:GetColor()
	info.DakCaliber = self.DakCaliber
	info.DakGunType = self.DakGunType
	info.DakFireSound1 = self.DakFireSound1
	info.DakFireSound2 = self.DakFireSound2
	info.DakFireSound3 = self.DakFireSound3
	info.DakMass = self.DakMass

	--Materials
	info.DakMat0 = self:GetSubMaterial(0)
	info.DakMat1 = self:GetSubMaterial(1)

	duplicator.StoreEntityModifier( self, "DakTek", info )

	-- Wire dupe info
	self.BaseClass.PreEntityCopy( self )
end

function ENT:PostEntityPaste( Player, Ent, CreatedEntities )
	if Ent.EntityMods and Ent.EntityMods.DakTek then
		self.DakName = Ent.EntityMods.DakTek.DakName
		self.DakMaxHealth = Ent.EntityMods.DakTek.DakMaxHealth
		self.DakHealth = self.DakMaxHealth
		self.DakModel = Ent.EntityMods.DakTek.DakModel
		self.DakCaliber = Ent.EntityMods.DakTek.DakCaliber
		self:SetNWFloat("Caliber",self.DakCaliber)
		self.DakGunType = Ent.EntityMods.DakTek.DakGunType
		if Ent.EntityMods.DakTek.DakFireSound and Ent.EntityMods.DakTek.DakFireSound1 == "" then
			self.DakFireSound1 = Ent.EntityMods.DakTek.DakFireSound
			self.DakFireSound2 = Ent.EntityMods.DakTek.DakFireSound
			self.DakFireSound3 = Ent.EntityMods.DakTek.DakFireSound
		else
			self.DakFireSound1 = Ent.EntityMods.DakTek.DakFireSound1
			self.DakFireSound2 = Ent.EntityMods.DakTek.DakFireSound2
			self.DakFireSound3 = Ent.EntityMods.DakTek.DakFireSound3
		end
		self.DakMass = Ent.EntityMods.DakTek.DakMass

		self.DakOwner = Player
		self:SetColor(Ent.EntityMods.DakTek.DakColor)
		self:SetSubMaterial( 0, Ent.EntityMods.DakTek.DakMat0 )
		self:SetSubMaterial( 1, Ent.EntityMods.DakTek.DakMat1 )

		self:Activate()

		Ent.EntityMods.DakTek = nil
	end

	self.BaseClass.PostEntityPaste( self, Player, Ent, CreatedEntities )
end