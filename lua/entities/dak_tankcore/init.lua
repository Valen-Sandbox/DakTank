AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
ENT.DakMaxHealth = 10
ENT.DakHealth = 10
ENT.DakName = "Tank Core"
ENT.HitBox = {}
ENT.DakActive = 0
ENT.DakFuel = nil
util.AddNetworkString("daktankcoreera")
util.AddNetworkString("daktankcoredetail")
util.AddNetworkString("daktankcoreeraremove")
util.AddNetworkString("daktankcoredetailremove")
util.AddNetworkString("daktankcoredie")
local DTTE = DTTE
concommand.Add("daktank_unmake", function()
	local cores = ents.FindByClass("dak_tankcore")
	for i = 1, #cores do
		local core = cores[i]
		core.Off = true
		core.BuildInfo = {}
		core.OldParent = core:GetParent()
		core:SetParent(nil)
		for j = 1, #core.Contraption do
			if core.Contraption[j] ~= core then
				core.BuildInfo[j] = {}
				core.BuildInfo[j].Pos = core.Contraption[j]:GetPos()
				core.BuildInfo[j].Ang = core.Contraption[j]:GetAngles()
				core.BuildInfo[j].Parent = core.Contraption[j]:GetParent()
				core.BuildInfo[j].Move = core.Contraption[j]:GetMoveType()
				core.Contraption[j].Pos = core.Contraption[j]:GetPos()
				core.Contraption[j].Ang = core.Contraption[j]:GetAngles()
				core.Contraption[j].OldParent = core.Contraption[j]:GetParent()
				core.Contraption[j].Move = core.Contraption[j]:GetMoveType()
				core.Contraption[j]:SetParent(nil)
				core.Contraption[j]:SetMoveType(MOVETYPE_NONE)
			end
		end

		for j = 1, #core.Contraption do
			core.Contraption[j]:SetPos(core:GetPos() + Vector(math.random(-500, 500), math.random(-500, 500), -500))
			core.Contraption[j]:SetAngles(AngleRand())
		end
	end
end)

local function AverageNoOutliers(Table)
	if #Table == 0 then return 0 end
	local Ave = 0
	local count = 0
	for i = 1, #Table do
		if i > #Table * 0.25 and i < #Table * 0.75 then
			Ave = Ave + Table[i]
			count = count + 1
		end
	end

	if count == 0 then return 0 end
	return Ave / count
end

local function InRange(x, min, max) -- how is this not standard???
	return (x > min and x < max) or (x < min and x > max)
end

local function MoveEntToPos(ent)
	ent:SetPos(ent:GetPos() + Vector(0, 0, math.random(400, 1000)))
	local num = math.random(1, 4)
	local scream = ""
	if num == 1 then scream = "ambient/halloween/female_scream_0" .. math.random(1, 9) .. ".wav" end
	if num == 2 then scream = "ambient/halloween/female_scream_10.wav" end
	if num == 3 then scream = "ambient/halloween/male_scream_0" .. math.random(3, 9) .. ".wav" end
	if num == 4 then scream = "ambient/halloween/male_scream_" .. math.random(10, 23) .. ".wav" end
	local tr = util.TraceLine({
		start = ent:GetPos() + Vector(0, 0, 10000),
		endpos = ent:GetPos() + Vector(0, 0, -10000),
		--filter = function( ent ) if ( ent:GetClass() == "prop_physics" ) then return true end end
		mask = MASK_NPCWORLDSTATIC
	})

	local effectdata = EffectData()
	effectdata:SetOrigin(tr.HitPos)
	effectdata:SetEntity(ent)
	effectdata:SetAttachment(1)
	effectdata:SetMagnitude(.5)
	effectdata:SetScale(math.random(5, 25))
	util.Effect("dakteshellimpact", effectdata, true, true)
	ent:EmitSound(scream, 100, 100 * math.Rand(0.9, 1.1), 1 * math.Rand(0.9, 1.1), CHAN_AUTO)
	timer.Create(ent:EntIndex() .. "ang", 0.01, 10000, function()
		local moveang = ent.Ang - ent:GetAngles()
		ent:SetAngles(ent:GetAngles() + Angle(math.Clamp(moveang.pitch, -1, 1), math.Clamp(moveang.yaw, -1, 1), math.Clamp(moveang.roll, -1, 1)))
		ent:SetMoveType(ent.Move)
		if math.Clamp(moveang.pitch, -1, 1) == moveang.pitch and math.Clamp(moveang.yaw, -1, 1) == moveang.yaw and math.Clamp(moveang.roll, -1, 1) == moveang.roll then timer.Stop(ent:EntIndex() .. "ang") end
	end)

	timer.Simple(math.random(1, 3), function()
		timer.Create(ent:EntIndex() .. "move", 0.01, 10000, function()
			local movevec = ent.Pos - ent:GetPos()
			ent:SetPos(ent:GetPos() + Vector(math.Clamp(movevec.x, -5, 5), math.Clamp(movevec.y, -5, 5), math.Clamp(movevec.z, -5, 5)))
			ent:SetMoveType(ent.Move)
			if math.Clamp(movevec.x, -5, 5) == movevec.x and math.Clamp(movevec.y, -5, 5) == movevec.y and math.Clamp(movevec.z, -5, 5) == movevec.z then
				if ent.soundplayed == nil then
					ent:EmitSound("doors/heavy_metal_stop1.wav", 100, 100 * math.Rand(0.9, 1.1), 1 * math.Rand(0.9, 1.1), CHAN_AUTO)
					ent.soundplayed = true
					timer.Stop(ent:EntIndex() .. "move")
					if ent.Controller.THETOLL == nil then ent.Controller.THETOLL = 0 end
					ent.Controller.THETOLL = ent.Controller.THETOLL + 1
					if ent.Controller.THETOLL >= #ent.Controller.Contraption - 1 then
						for i = 1, #ent.Controller.Contraption do
							ent.Controller.Contraption[i]:SetParent(ent.Controller.Contraption[i].OldParent)
							ent.Controller.Contraption[i]:SetMoveType(MOVETYPE_NONE)
						end
					end
				end
			end
		end)
	end)
end

concommand.Add("daktank_remake", function()
	local cores = ents.FindByClass("dak_tankcore")
	for i = 1, #cores do
		local core = cores[i]
		for j = 1, #core.Contraption do
			if core.Contraption[j] ~= core then timer.Create(core:EntIndex() .. core.Contraption[j]:EntIndex() .. "start", math.Rand(1, 15), 1, function() MoveEntToPos(core.Contraption[j]) end) end
		end
	end
end)

hook.Add("AdvDupe_FinishPasting", "daktank_tankcore_check", function(dupe)
	local ents = dupe[1].CreatedEntities
	for id, data in pairs(dupe[1].EntityList) do
		local ent = ents[id]
		if IsValid(ent) then
			if ent:GetClass() == "dak_tankcore" then timer.Simple(engine.TickInterval() + 1, function() ent.DakFinishedPasting = 1 end) end
			--also do guns while we're here
			if ent:GetClass() == "dak_tegun" or ent:GetClass() == "dak_teautogun" or ent:GetClass() == "dak_temachinegun" then
				ent.SlowThinkTime = 0
				local ScalingGun = 0
				if ent.DakModel == "models/daktanks/mortar100mm2.mdl" then ScalingGun = 1 end
				if ent.DakModel == "models/daktanks/grenadelauncher100mm.mdl" then ScalingGun = 1 end
				if ent.DakModel == "models/daktanks/smokelauncher100mm.mdl" then ScalingGun = 1 end
				if ent.DakModel == "models/daktanks/machinegun100mm.mdl" then ScalingGun = 1 end
				if ent.DakModel == "models/daktanks/cannon100mm2.mdl" then ScalingGun = 1 end
				if ent.DakModel == "models/daktanks/shortcannon100mm2.mdl" then ScalingGun = 1 end
				if ent.DakModel == "models/daktanks/longcannon100mm2.mdl" then ScalingGun = 1 end
				if ent.DakModel == "models/daktanks/autocannon100mm2.mdl" then ScalingGun = 1 end
				if ent.DakModel == "models/daktanks/hmg100mm2.mdl" then ScalingGun = 1 end
				if ent.DakModel == "models/daktanks/howitzer100mm2.mdl" then ScalingGun = 1 end
				if ent.DakModel == "models/daktanks/launcher100mm2.mdl" then ScalingGun = 1 end
				if ent.DakModel == "models/daktanks/duallauncher100mm2.mdl" then ScalingGun = 1 end
				if ent.DakModel == "models/daktanks/recoillessrifle100mm2.mdl" then ScalingGun = 1 end
				if ScalingGun == 1 then
					if IsValid(ent) then
						ent:PhysicsDestroy()
						--timer.Simple(2,function()
						if IsValid(ent) then
							local mins, maxs = ent:GetModelBounds()
							local CalMult = ent.DakCaliber / 100
							mins = mins * CalMult
							maxs = maxs * CalMult
							local x0 = mins[1] -- Define the min corner of the box
							local y0 = mins[2]
							local z0 = mins[3]
							local x1 = maxs[1] -- Define the max corner of the box
							local y1 = maxs[2]
							local z1 = maxs[3]
							ent:PhysicsInitConvex({Vector(x0, y0, z0), Vector(x0, y0, z1), Vector(x0, y1, z0), Vector(x0, y1, z1), Vector(x1, y0, z0), Vector(x1, y0, z1), Vector(x1, y1, z0), Vector(x1, y1, z1)})
							ent.ScaleSet = true
							ent:SetMoveType(MOVETYPE_VPHYSICS)
							ent:SetSolid(SOLID_VPHYSICS)
							ent:GetPhysicsObject():EnableMotion(false)
							ent:EnableCustomCollisions(true)
							local mins2, maxs2 = ent:GetHitBoxBounds(0, 0)
							ent:SetCollisionBounds(mins2 * CalMult, maxs2 * CalMult)
							--ent:Activate()
						end
						--end)
					end
				else
					ent.ScaleSet = true
				end
			end
		end
	end
end)

--cause self to delete self if not properly unfrozen
--have tank just keep rolling with gearbox on death (they aren't being added to contraption, find all axised to baseplate)
local PhysObj = FindMetaTable("PhysObj")
local O_Mass = PhysObj.SetMass
function PhysObj:SetMass(Mass)
	O_Mass(self, Mass)
	if IsValid(self:GetEntity().Controller) then self:GetEntity().Controller.MassUpdate = 1 end
end

local function SetMass(_, Entity, Data)
	if not SERVER then return end
	if not Data then return end

	if Data.Mass then
		local physobj = Entity:GetPhysicsObject()
		if physobj:IsValid() then physobj:SetMass(Data.Mass) end
	end

	duplicator.StoreEntityModifier(Entity, "mass", Data)
end

duplicator.RegisterEntityModifier("mass", SetMass)
local function DakTankCollisions(ent1, ent2, pos)
	if IsValid(ent1.Controller) and IsValid(ent2.Controller) then
		if ent1.Controller ~= ent2.Controller then
			local tmp = ent1.Controller.Base:GetPos() - ent2.Controller.Base:GetPos()
			local colspeed = -((ent1.Controller.Base:GetVelocity() - ent2.Controller.Base:GetVelocity()):Dot(tmp) / tmp:Length())
			if colspeed > 0 then
				local vec = ent1:GetPos() - ent2:GetPos()
				local force1 = 1 - (ent1.Controller.TotalMass / (ent2.Controller.TotalMass + ent1.Controller.TotalMass))
				local force2 = 1 - (ent2.Controller.TotalMass / (ent2.Controller.TotalMass + ent1.Controller.TotalMass))
				ent1.Controller.Base:GetPhysicsObject():ApplyForceCenter(ent1.Controller.PhysMass * vec:GetNormalized() * colspeed * force1 * 2, pos)
				ent2.Controller.Base:GetPhysicsObject():ApplyForceCenter(ent2.Controller.PhysMass * -vec:GetNormalized() * colspeed * force2 * 2, pos)
			end

			if colspeed * 0.09144 >= 10 then
				if ent1:CPPIGetOwner() ~= nil and ent1:CPPIGetOwner():HasGodMode() == false and not ent1:CPPIGetOwner():IsWorld() then ent1.Controller.DakHealth = ent1.Controller.DakHealth - (5 * colspeed * 0.09144 * (ent2.Controller.TotalMass / ent1.Controller.TotalMass)) end
				if ent2:CPPIGetOwner() ~= nil and ent2:CPPIGetOwner():HasGodMode() == false and not ent2:CPPIGetOwner():IsWorld() then ent2.Controller.DakHealth = ent2.Controller.DakHealth - (5 * colspeed * 0.09144 * (ent1.Controller.TotalMass / ent2.Controller.TotalMass)) end
				ent1:EmitSound("physics/metal/metal_large_debris2.wav")
				local effectdata = EffectData()
				effectdata:SetOrigin(pos)
				effectdata:SetEntity(ent1)
				effectdata:SetAttachment(1)
				effectdata:SetMagnitude(.5)
				effectdata:SetScale(math.min((colspeed * 0.09144) / 10, 10))
				util.Effect("dakteshellbounce", effectdata)
				--elseif colspeed*0.09144 > 1 and colspeed*0.09144 < 10 then
				--	local sounds = {"npc/dog/dog_destroy_door1.wav"}
				--	ent1:EmitSound( sounds[math.random(1,#sounds)] )
			end
		end
	end
end

local NameTable1 = {"Worm ", "Kinetic ", "Super ", "Ultra ", "Soul ", "Torment ", "Black ", "xXx_", "Shattered ", "Dead ", "Death ", "The ", "Thunder ", "Demon ", "Ash ", "Cinder ", "Blackened ", "Dark ", "Edge ", "Turbo ", "Punished ", "Ol' ", "Haunted ", "Compliance ", "Pain ", "Gun ", "Flame ", "El ", "Battle ", "War ", "Struggle ", "Ghost ", "Phantom ", "Blood ", "Angry ", "Electric ", "Electronic ", "Mobile ", "Tracked ", "Scrapped ", "Cruel ", "Massive ", "Big ", "Mangled ", "Cursed ", "Extreme ", "Power ", "White ", "Speed ", "Rapid ", "God ", "Flesh ", "Neo-", "Meta ", "Metal ", "Iron ", "Steel ", "Cyber ", "Pagan ", "Punishment ", "Shadow ", "Wicked ", "Visceral ", "Meat ", "Cold ", "Mega ", "Deth ", "Bleeding ", "Demonic ", "Kamikaze ", "Berserker ", "Martyred ", "Road ", "Wasted ", "Waste ", "Krieg ", "Panzer ", "Necro ", "Mechanical ", "Violent ", "Glorious ", "Ultimate ", "Xeno ", "Disgusting ", "Star ", "Sun ", "Perma", "Eternal ", "Unending ", "Nuclear ", "Hell's ", "Pale ", "God's ", "Industrial ", "Plague ", "Rolling ", "Baby ", "Infant ", "Vengeful ", "Screaming ", "Burning ", "Burnt ", "Weeping ", "Wailing ", "Final ", "Armored ", "Suicidal ", "Giga ", "Double ", "Fetus ", "Epic ", "Great ", "Blazing ", "Cast Iron ", "Cool ", "Aggressive ", "Toxic ", "Endless ", "Ballistic ", "Auto ", "Assault ", "Support ", "Attack ", "Fast ", "Strike ", "Kill ", "Atomic ", "Unstoppable ", "Restless ", "Dauntless ", "Ceaseless ", "Ford ", "Dodge ", "Lunar ", "Brutal ", "Sonic ", "Mecha ", "Desert ", "Dick Cheney's ", "Unholy ", "Master ", "Spicy ", "Silent ", "Warp ", "Warped ", "Warpfire ", "Doom ", "Murder ", "Ball ", "Blade ", "Bone ", "Sly ", "Growling ", "Jade ", "Gray ", "Dire ", "Hungry ", "Biting ", "Ravaging ", "Rogue ", "Mad ", "Laughing ", "Ashen ", "Brass ", "Night ", "Raging ", "Flaming ", "Howling ", "Divine ", "Crying ", "Intense ", "Intensified ", "Brave ", "Soulless ", "Sneaking ", "Awful ", "",}
local NameTable2 = {"Drinker", "Annihilator", "Reaver", "Render", "Death", "Killer", "Eliminator", "Edge", "Blade", "Stonewall", "Block", "Horror", "Tormentor", "Obliterator", "Prison", "Crusher", "Shooter", "Truck", "Hammer", "Combustor", "Bob", "Kyle", "Vulture", "Demon", "Cinderblock", "Darkness", "Void", "Spawn", "Bane", "Fire", "Blitz", "Purgatory", "Colossus", "Rascal", "Hell", "Inferno", "Covenant", "Assassin", "Hatred", "Duke", "Scoundrel", "Mutt", "Warrior", "Punisher", "Snake", "Shark", "Hunter", "Haunt", "Mulcher", "Whipper", "Engine", "Grinder", "Pain", "Tank", "Atrocidad", "Criminal", "Wagon", "Ghost", "Phantom", "Purge", "Dominator", "Oppressor", "Vegan", "Pirate", "Pillager", "Lightning", "Bunker", "Genocide", "Justice", "End", "Nightmare", "Torture", "Trauma", "Executioner", "Scrap", "Cruelty", "Smoke", "Raider", "Mangler", "Wrangler", "Curse", "Angst", "Terminator", "Revenge", "Avenger", "Assault", "Complex", "Gore", "Steel", "Pagan", "Inflicter", "Chopper", "Choppa", "Commando", "Deth", "Mauler", "Ravager", "Angel", "Kamikaze", "Berzerker", "Martyr", "Rover", "Wanderer", "Nomad", "Vagabond", "King", "Knight", "Suicide", "Murder", "Homocide", "Dissector", "Krieg", "Panzer", "Crusader", "Crusade", "Mech", "Dragoon", "Dragon", "Vendetta", "Violence", "Omen", "God", "Sacrifice", "Racist", "Xenophobe", "Black", "Creature", "Moon", "Daddy", "Torment", "Miasma", "Vengence", "Deceiver", "Deserter", "Eater", "Ripper", "Hellfire", "Brimstone", "Scream", "Hail", "Spewer", "Harvester", "Reaper", "Core", "Peacekeeper", "Peacemaker", "Obstruction", "Shredder", "Offering", "Dude", "Lord", "Golem", "Launcher", "Owen", "Butcher", "Rat", "Viper", "Abyss", "Jackal", "Brute", "Heart", "Toll", "Tax", "Monger", "Hawk", "Eagle", "Aggressor", "Chimera", "Thunder", "Mac", "Bull", "Bulldog", "Sky", "Storm", "Rhino", "Suffering", "Agony", "Agonizer", "Massacre", "Box", "Cat", "Dog", "Cart", "Struggle", "Beast", "Conflict", "Attack", "Strike", "Dozer", "Bus", "Force", "Mustang", "Charger", "Raptor", "Predator", "Surge", "Incinerator", "Fox", "Wolf", "Tyrant", "Delima", "Master", "Blaster", "Razor", "Retribution", "Wind", "Guardian", "Paladin", "Gatekeeper", "Ogre", "Cycle", "Breaker", "Heresy", "Trucker", "Terror", "Phoenix", "Salamander", "Buzzard", "Stallion", "Barracuda", "Harrier", "Basilisk", "Walker", "Bringer", "Intervention", "Behemoth", "Fool", "Coward", "Devastator", "Dagger", "Construct"}
local NameTable3 = {"", " II", " III", " IV", " V", " Ultra", " X", " Z", "_xXx", " Ultimate", " Alpha", " Beta", " Omega", " Gamma", " Sigma", " Rex", " 69", " 420", " 666", " 3000", " 9000", "-1", " Prime", " Extreme", "'s Creed", "'s Dogma", "'s Manifesto", " The Hedgehog", " Creature", " Mk. I", " Mk. II", " Mk. III", " Mk. IV", " Mk. V", "_64", "_83", "_91", "_97", "_99", "_01", "_05", "_11", " F-150", " Infinite",}
local AmNameExtras = {"IP", "HA", "HC", "D", " AIM", " FEP", "KVT", "M", " SEP", "S", " SEPv2", " SEPv3", "T", " SEPv4", " TTS", " SLEP", " USMC", " AOS", " ERA", " RISE", "E1", "E2", " AGS", "", "", "", "", "", "", "", "", "", ""}
local AmNameNames = {"Locust", "Chaffee", "Lee", "Sherman", "Stuart", "Scott", "Zippo", "Pershing", "Hellcat", "GMC", "Walker Bulldog", "Patton", "Sheridan", "Starship", "Ontos", "Abrams", "Jackson", "Washington", "Adams", "Jefferson", "Madison", "Monroe", "Pierce", "Lincoln", "Johnson", "Grant", "Roosevelt", "Wilson", "Hoover", "Truman", "Eisenhower", "Kennedy", "Ford", "Carter", "Bush", "Stryker", "Wolfhound", "Greyhound", "Bradley", "Linebacker", "Fox", "Hawk", "Cobra", "Wolverine", "Crusader", "Paladin"}
function ENT:Initialize()
	self:SetModel("models/bull/gates/logic.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self.DakHealth = self.DakMaxHealth
	self.DakArmor = 10
	--local phys = self:GetPhysicsObject()
	self.timer = CurTime()
	self.APSEnable = false
	self.APSFrontalArc = false
	self.APSSideArc = false
	self.APSRearArc = false
	self.APSShots = 0
	self.APSMinCaliber = 0
	self.Outputs = WireLib.CreateOutputs(self, {"Health", "HealthPercent", "Crew"})
	self.Soundtime = CurTime()
	self.SparkTime = CurTime()
	self.SlowThinkTime = CurTime()
	self.DakActive = 0
	self.CurMass = 0
	self.LastCurMass = 0
	self.HitBox = {}
	self.ERA = {}
	self.HitBoxMass = 0
	self.Hitboxthinktime = CurTime()
	self.LastRemake = CurTime()
	self.DakBurnStacks = 0
	self.SpawnTime = CurTime()
	self.FrontalArmor = 0
	self.RightArmor = 0
	self.LeftArmor = 0
	self.SideArmor = 0
	self.RearArmor = 0
	self.Modern = nil
	self.ColdWar = nil
	self.BoxSize = Vector(10000, 10000, 10000)
	self.BoxCenter = Vector(0, 0, 0)
	self.DakVolume = 1000000
	self.PenMult = 0
	self.DPSMult = 0
	self.TotalDPS = 0
	self.PhysEnabled = true
	self.LastPhysEnabled = true
	if self:GetTankName() == "" or self.TankName == nil then
		if self:GetAmerican() == true then
			local basedesignation = "M" .. tostring(math.random(1, 119))
			local variantdesignation
			if math.random(0, 1) == 1 then
				variantdesignation = ""
			else
				variantdesignation = "A" .. tostring(math.random(1, 5))
			end

			local hasname = true
			if math.random(0, 4) == 4 then hasname = false end
			local powerlevel = math.random(1, 10)
			local powerrating = ""
			if powerlevel >= 8 then powerrating = "Super " end
			if powerlevel == 10 then powerrating = "Super Duper " end
			if hasname == true then
				self:SetTankName(basedesignation .. variantdesignation .. AmNameExtras[math.random(1, #AmNameExtras)] .. " " .. powerrating .. AmNameNames[math.random(1, #AmNameNames)])
			else
				self:SetTankName(powerrating .. basedesignation .. variantdesignation .. AmNameExtras[math.random(1, #AmNameExtras)])
			end
		else
			self:SetTankName(NameTable1[math.random(1, #NameTable1)] .. NameTable2[math.random(1, #NameTable2)] .. NameTable3[math.random(1, #NameTable3)])
		end
	end

	self.Forward = self:GetForward()
end

local function GetPhysCons(ent, Results)
	Results = Results or {}
	if not IsValid(ent) then return end
	if Results[ent] then return end
	Results[ent] = ent
	local Constraints = constraint.GetTable(ent)
	for _, v in ipairs(Constraints) do
		if not (v.Type == "NoCollide") and not (v.Type == "Rope") and not ((v.Type == "AdvBallsocket") and v.onlyrotation == 1) then
			for _, Ent in pairs(v.Entity) do
				GetPhysCons(Ent.Entity, Results)
			end
		end
	end
	return Results
end

local function GetParents(ent, Results)
	Results = Results or {}
	local Parent = ent:GetParent()
	Results[ent] = ent
	if IsValid(Parent) then GetParents(Parent, Results) end
	return Results
end

local function GetPhysicalConstraints(Ent, Table)
	if not IsValid(Ent) then return end
	Table = Table or {}
	if Table[Ent] then return end
	Table[Ent] = true
	for _, V in ipairs(constraint.GetTable(Ent)) do
		if V.Type ~= "NoCollide" then
			for _, Ent in pairs(V.Entity) do
				GetPhysicalConstraints(Ent.Entity, Table)
			end
		end
	end
	return Table
end

local function DakKillNotSolid(ent)
	if not IsValid(ent.Controller) then return end
	if not IsValid(ent.Controller.Base) then return end
	if not ent.Controller.Base:GetPhysicsObject():IsMotionEnabled() then return end
	local isNotSolid = not ent:IsSolid() or ent.ClipData ~= nil
	if not isNotSolid then return end
	local isAlive = ent.Controller.DakHealth > 0 or #ent.Controller.Crew < 2 or ent.Controller.LivingCrew <= math.max(#ent.Controller.Crew - 3, 1)
	if not isAlive then return end
	if ent.Controller.Dead == 1 then return end
	if IsValid(ent.Controller.DakOwner) then
		for _, ply in ipairs(player.GetAll()) do
			if not ent:IsSolid() then
				ply:ChatPrint(ent.Controller.DakOwner:GetName() .. "'s vehicle has not solid components, solidifying...")
				ent:SetSolid(SOLID_VPHYSICS)
			elseif ent.ClipData ~= nil and ent:GetClass() ~= "dak_teammo" then
				ply:ChatPrint(ent.Controller.DakOwner:GetName() .. "'s vehicle exploded due to clipping components!")
			end
		end
	end

	if ent:GetClass() ~= "dak_teammo" then ent.Controller.DakHealth = -1 end
end

function ENT:Think() --converting self. calls into selfTbl. is going to take awhile here, because this is like 3000 lines, and converting every instance of self. breaks it somehow.
	local self = self
	local selfTbl = self:GetTable()

	if CurTime() - 1 >= selfTbl.SlowThinkTime then
		if self:GetTankName() == "" then
			if self:GetAmerican() == true then
				local basedesignation = "M" .. tostring(math.random(1, 119))
				local variantdesignation
				if math.random(0, 1) == 1 then
					variantdesignation = ""
				else
					variantdesignation = "A" .. tostring(math.random(1, 5))
				end

				local hasname = true
				if math.random(0, 4) == 4 then hasname = false end
				local powerlevel = math.random(1, 10)
				local powerrating = ""
				if powerlevel >= 8 then powerrating = "Super " end
				if powerlevel == 10 then powerrating = "Super Duper " end
				if hasname == true then
					self:SetTankName(basedesignation .. variantdesignation .. AmNameExtras[math.random(1, #AmNameExtras)] .. " " .. powerrating .. AmNameNames[math.random(1, #AmNameNames)])
				else
					self:SetTankName(powerrating .. basedesignation .. variantdesignation .. AmNameExtras[math.random(1, #AmNameExtras)])
				end
			else
				self:SetTankName(NameTable1[math.random(1, #NameTable1)] .. NameTable2[math.random(1, #NameTable2)] .. NameTable3[math.random(1, #NameTable3)])
			end
		end

		if IsValid(self) and selfTbl.Off ~= true then
			local selfParent = self:GetParent()
			if IsValid(selfParent) then
				selfParent = selfParent:GetParent()
				if IsValid(selfParent) then
					selfTbl.Base = selfParent
					if not selfTbl.PreCostTimerFirst then
						selfTbl.PreCostTimerFirst = CurTime()
						selfTbl.PreCostTimer = 0
					end

					selfTbl.PreCostTimer = CurTime() - selfTbl.PreCostTimerFirst
					if selfTbl.DakFinishedPasting == 1 and selfTbl.CanSpawn ~= true and (IsValid(selfTbl.Gearbox) or (selfTbl.TurretControls ~= nil and IsValid(selfTbl.TurretControls[1]))) then
						selfTbl.CanSpawn = true
						--First portion

						do
							--Get forced era setting
							if self:GetForceColdWar() == true then selfTbl.ColdWar = 1 end
							if self:GetForceModern() == true then selfTbl.Modern = 1 end
						end

						do
							--Get Active Protection System costs
							selfTbl.APSEnable = self:GetEnableAPS()
							selfTbl.APSFrontalArc = self:GetAPSFrontalArc()
							selfTbl.APSSideArc = self:GetAPSSideArc()
							selfTbl.APSRearArc = self:GetAPSRearArc()
							selfTbl.APSShots = math.Clamp(self:GetAPSShots(), 0, 20)
							selfTbl.APSMinCaliber = self:GetAPSMinCaliber()
							selfTbl.APSCost = 0
							if selfTbl.APSEnable == true then
								selfTbl.Modern = 1

								local roundcost = 0
								if selfTbl.APSFrontalArc == true then roundcost = roundcost + 1 end
								if selfTbl.APSSideArc == true then roundcost = roundcost + 1 end
								if selfTbl.APSRearArc == true then roundcost = roundcost + 1 end
								selfTbl.APSCost = selfTbl.APSShots * roundcost
							end
						end

						local forward
						local right
						local up
						do
							--Get orientation and forward entity
							if IsValid(selfTbl.TurretControls[1]) then
								selfTbl.MainTurret = selfTbl.TurretControls[1]
								if #selfTbl.TurretControls > 1 and selfTbl.MainTurret.GunMass ~= nil then
									for i = 1, #selfTbl.TurretControls do
										if selfTbl.TurretControls[i].GunMass ~= nil then if selfTbl.TurretControls[i].GunMass > selfTbl.MainTurret.GunMass then selfTbl.MainTurret = selfTbl.TurretControls[i] end end
									end
								end
							end

							if IsValid(selfTbl.Gearbox) then
								local yaw = selfTbl.Gearbox.ForwardEnt:GetAngles().yaw
								local angYaw = Angle(0, yaw, 0)
								forward = angYaw:Forward()
								right = angYaw:Right()
								up = angYaw:Up()
								selfTbl.ForwardEnt = selfTbl.Gearbox.ForwardEnt
							elseif IsValid(selfTbl.MainTurret) then
								local yaw = selfTbl.MainTurret:GetAngles().yaw
								local angYaw = Angle(0, yaw, 0)
								forward = angYaw:Forward()
								right = angYaw:Right()
								up = angYaw:Up()
								selfTbl.ForwardEnt = selfTbl.MainTurret
							end

							selfTbl.Forward = forward
						end

						do
							--Get basic hitbox done, note: this is full bounds of spawn, not real armor bounds
							if selfTbl.HitBoxMins == nil then selfTbl.HitBoxMins = Vector(-1, -1, -1) end
							if selfTbl.HitBoxMaxs == nil then selfTbl.HitBoxMaxs = Vector(1, 1, 1) end
							selfTbl.HitBoxMins = selfTbl.ForwardEnt:WorldToLocal(self:LocalToWorld(selfTbl.HitBoxMins))
							selfTbl.HitBoxMaxs = selfTbl.ForwardEnt:WorldToLocal(self:LocalToWorld(selfTbl.HitBoxMaxs))
							local temp
							if selfTbl.HitBoxMins.x > selfTbl.HitBoxMaxs.x then
								temp = selfTbl.HitBoxMaxs.x
								selfTbl.HitBoxMaxs.x = selfTbl.HitBoxMins.x
								selfTbl.HitBoxMins.x = temp
							end

							if selfTbl.HitBoxMins.y > selfTbl.HitBoxMaxs.y then
								temp = selfTbl.HitBoxMaxs.y
								selfTbl.HitBoxMaxs.y = selfTbl.HitBoxMins.y
								selfTbl.HitBoxMins.y = temp
							end

							if selfTbl.HitBoxMins.z > selfTbl.HitBoxMaxs.z then
								temp = selfTbl.HitBoxMaxs.z
								selfTbl.HitBoxMaxs.z = selfTbl.HitBoxMins.z
								selfTbl.HitBoxMins.z = temp
							end

							selfTbl.BoxSize = selfTbl.HitBoxMaxs - selfTbl.HitBoxMins
							selfTbl.BoxCenter = 0.5 * (selfTbl.HitBoxMaxs + selfTbl.HitBoxMins)
							selfTbl.DakVolume = math.Round(math.abs(selfTbl.BoxSize.x * selfTbl.BoxSize.y * selfTbl.BoxSize.z) * 0.005, 2)
							selfTbl.BestLength = selfTbl.BoxSize.x
							selfTbl.BestWidth = selfTbl.BoxSize.y
							selfTbl.BestHeight = selfTbl.BoxSize.z
							selfTbl.MaxSize = math.max(selfTbl.BestLength, selfTbl.BestWidth, selfTbl.BestHeight)
						end

						--Setup crew armor and bounds tables
						for _, crew in ipairs(selfTbl.Crew) do
							crew.FrontArmorTable = {}
							crew.RearArmorTable = {}
							crew.SideArmorTable = {}
							crew.FrontalAverage = {}
							crew.RearAverage = {}
							crew.SideAverage = {}
							crew.FrontBounds = {}
							crew.RearBounds = {}
							crew.LeftBounds = {}
							crew.RightBounds = {}
							crew.TopBounds = {}
							crew.BottomBounds = {}
						end

						--Check top and bottom bounds of vehicle for each crew position
						selfTbl.RealBounds = {}
						-- local ent, HitCrit, ThickestPos
						for _, crew in ipairs(selfTbl.Crew) do
							local mins = crew:OBBMins() * 0.9
							local maxs = crew:OBBMins() * 0.9

							local pos = crew:GetPos()
							crew.Heightaimpoints = {Vector(0,0,0),
							Vector(mins.x, 0, 0),
							Vector(maxs.x, 0, 0),
							Vector(0, mins.y, 0),
							Vector(0, maxs.y, 0),
							Vector(mins.x * 0.5, 0, 0),
							Vector(maxs.x * 0.5, 0, 0),
							Vector(0, mins.y * 0.5, 0),
							Vector(0, maxs.y * 0.5, 0)}

							for _, v in ipairs(crew.Heightaimpoints) do
								v:Add(pos)
							end
						end

						for i, crew in ipairs(selfTbl.Crew) do
							for j = i, #crew.Heightaimpoints do
								local crewTbl = crew:GetTable()
								local aimPoint = crewTbl.Heightaimpoints[j]

								local upVec = up * (selfTbl.BestHeight * 2)
								local downVec = up * 25

								local _, ent, _, _, _, _, HitCrit, _, _, _, _, ThickestPos = DTTE.GetArmorRecurseNoStop(aimPoint + upVec, aimPoint - downVec, selfTbl.MaxSize * 2, "AP", 75, player.GetAll(), self)
								if IsValid(ent) and ent.Controller == self and ent:GetClass() == "dak_crew" and HitCrit == 1 and (ThickestPos ~= aimPoint + upVec) then
									crewTbl.TopBounds[#crewTbl.TopBounds + 1] = ThickestPos
								end

								_, ent, _, _, _, _, HitCrit, _, _, _, _, ThickestPos = DTTE.GetArmorRecurseNoStop(aimPoint - upVec, aimPoint + downVec, selfTbl.MaxSize * 2, "AP", 75, player.GetAll(), self)
								if IsValid(ent) and ent.Controller == self and ent:GetClass() == "dak_crew" and HitCrit == 1 and (ThickestPos ~= aimPoint + upVec) then
									crewTbl.BottomBounds[#crewTbl.BottomBounds + 1] = ThickestPos
								end
							end
						end

						--Setup crew armor checking positions
						for i, crew in ipairs(selfTbl.Crew) do
							local mins = crew:OBBMins() * 0.9
							local maxs = crew:OBBMaxs() * 0.9
							local pos = crew:GetPos()
							crew.aimpoints = {
								Vector(0, 0, mins.z),
								Vector(mins.x, 0, mins.z),
								Vector(maxs.x, 0, mins.z),
								Vector(0, mins.y, mins.z),
								Vector(0, maxs.y, mins.z),
								Vector(mins.x * 0.5, 0, mins.z),
								Vector(maxs.x * 0.5, 0, mins.z),
								Vector(0, mins.y * 0.5, mins.z),
								Vector(0, maxs.y * 0.5, mins.z),
								Vector(0, 0, mins.z * 0.5),
								Vector(mins.x, 0, mins.z * 0.5),
								Vector(maxs.x, 0, mins.z * 0.5),
								Vector(0, mins.y, mins.z * 0.5),
								Vector(0, maxs.y, mins.z * 0.5),
								Vector(mins.x * 0.5, 0, mins.z * 0.5),
								Vector(maxs.x * 0.5, 0, mins.z * 0.5),
								Vector(0, mins.y * 0.5, mins.z * 0.5),
								Vector(0, maxs.y * 0.5, mins.z * 0.5),
								Vector(0,0,0),
								Vector(mins.x, 0, 0),
								Vector(maxs.x, 0, 0),
								Vector(0, mins.y, 0),
								Vector(0, maxs.y, 0),
								Vector(mins.x * 0.5, 0, 0),
								Vector(maxs.x * 0.5, 0, 0),
								Vector(0, mins.y * 0.5, 0),
								Vector(0, maxs.y * 0.5, 0),
								Vector(0, 0, maxs.z * 0.5),
								Vector(mins.x, 0, maxs.z * 0.5),
								Vector(maxs.x, 0, maxs.z * 0.5),
								Vector(0, mins.y, maxs.z * 0.5),
								Vector(0, maxs.y, maxs.z * 0.5),
								Vector(mins.x * 0.5, 0, maxs.z * 0.5),
								Vector(maxs.x * 0.5, 0, maxs.z * 0.5),
								Vector(0, mins.y * 0.5, maxs.z * 0.5),
								Vector(0, maxs.y * 0.5, maxs.z * 0.5),
								Vector(0, 0, maxs.z),
								Vector(mins.x, 0, maxs.z),
								Vector(maxs.x, 0, maxs.z),
								Vector(0, mins.y, maxs.z),
								Vector(0, maxs.y, maxs.z),
								Vector(mins.x * 0.5, 0, maxs.z),
								Vector(maxs.x * 0.5, 0, maxs.z),
								Vector(0, mins.y * 0.5, maxs.z),
								Vector(0, maxs.y * 0.5, maxs.z)
							}
							for j, v in ipairs(crew.aimpoints) do
								v:Add(pos)
							end
						end

						do
							--Frontal armor check
							local distance = selfTbl.MaxSize * 2
							local HitTable = {}
							local ArmorVal1 = 0
							local ent
							local HitCrit = 0
							local hitpos
							local SpallLiner = 0
							local Armors = {}
							local Crews = {}
							local ThickestPos
							local ArmorValTable = {}
							local SpallLinerCount = 0

							local fwVec = forward * selfTbl.BestLength * 2
							local bwVec = -forward * 25
							local allPlayers = player.GetAll()

							for i, crew in ipairs(selfTbl.Crew) do
								for j, aimpoint in ipairs(crew.aimpoints) do
									ArmorVal1, ent, _, _, gunhit, gearhit, HitCrit, hitpos, SpallLiner, Armors, Crews, ThickestPos = DTTE.GetArmorRecurseNoStop(aimpoint + fwVec, aimpoint + bwVec, distance, "AP", 75, allPlayers, self)
									if IsValid(ent) and ent.Controller == self and ent:GetClass() == "dak_crew" and HitCrit == 1 then
										for k = 1, #Crews do
											Crews[k].FrontArmorTable[#Crews[k].FrontArmorTable + 1] = Armors[k]
										end

										crew.FrontBounds[#crew.FrontBounds + 1] = ThickestPos
										ArmorValTable[#ArmorValTable + 1] = ArmorVal1
										if SpallLiner == 1 then SpallLinerCount = SpallLinerCount + 1 end

										HitTable[#HitTable + 1] = hitpos
									end
								end
							end

							for i = 1, #selfTbl.Crew do
								table.sort(selfTbl.Crew[i].FrontArmorTable)
								local Ave = 0
								local AveCount = 0
								for j = 1, #selfTbl.Crew[i].FrontArmorTable do
									if (j >= #selfTbl.Crew[i].FrontArmorTable / 4 and j <= (#selfTbl.Crew[i].FrontArmorTable / 4) * 3) or #selfTbl.Crew[i].FrontArmorTable < 4 then
										Ave = Ave + math.min(selfTbl.Crew[i].FrontArmorTable[j], 10000)
										AveCount = AveCount + 1
									end
								end

								selfTbl.Crew[i].FrontalAverage = Ave / AveCount
							end

							table.sort(selfTbl.Crew, function(a, b) return a.FrontalAverage > b.FrontalAverage end)
							if #selfTbl.Crew >= 2 then selfTbl.FrontalArmor = (selfTbl.Crew[1].FrontalAverage + selfTbl.Crew[2].FrontalAverage) * 0.5 end
							for i = 1, #selfTbl.Crew do
								local crewTbl = selfTbl.Crew[i]:GetTable()
								if i <= 2 or crewTbl.FrontalAverage >= selfTbl.Crew[1].FrontalAverage * 0.5 then
									for j = 1, #crewTbl.FrontBounds do
										selfTbl.RealBounds[#selfTbl.RealBounds + 1] = crewTbl.FrontBounds[j]
									end

									for j = 1, #crewTbl.TopBounds do
										selfTbl.RealBounds[#selfTbl.RealBounds + 1] = crewTbl.TopBounds[j]
									end

									for j = 1, #crewTbl.BottomBounds do
										selfTbl.RealBounds[#selfTbl.RealBounds + 1] = crewTbl.BottomBounds[j]
									end
								end
							end

							if selfTbl.FrontalArmor == 0 then selfTbl.FrontalArmor = 10000 end
							selfTbl.FrontalSpallLinerCoverage = SpallLinerCount / #ArmorValTable
							if #ArmorValTable == 0 then selfTbl.FrontalSpallLinerCoverage = 1 end
						end

						do
							--Rear armor check
							local distance = selfTbl.MaxSize * 2
							local HitTable = {}
							local ArmorVal1 = 0
							local ent
							local aimpos
							local HitCrit = 0
							local hitpos
							local SpallLiner = 0
							local Armors = {}
							local Crews = {}
							local ThickestPos
							local ArmorValTable = {}
							local SpallLinerCount = 0
							for i = 1, #selfTbl.Crew do
								for j = 1, #selfTbl.Crew[i].aimpoints do
									aimpos = selfTbl.Crew[i].aimpoints[j]
									ArmorVal1, ent, _, _, _, _, HitCrit, hitpos, SpallLiner, Armors, Crews, ThickestPos = DTTE.GetArmorRecurseNoStop(selfTbl.Crew[i].aimpoints[j] - forward * selfTbl.BestLength * 2, selfTbl.Crew[i].aimpoints[j] + forward * 25, distance, "AP", 75, player.GetAll(), self)
									if IsValid(ent) then
										if ent.Controller == self and ent:GetClass() == "dak_crew" and HitCrit == 1 then
											for k = 1, #Crews do
												Crews[k].RearArmorTable[#Crews[k].RearArmorTable + 1] = Armors[k]
											end

											selfTbl.Crew[i].RearBounds[#selfTbl.Crew[i].RearBounds + 1] = ThickestPos
											ArmorValTable[#ArmorValTable + 1] = ArmorVal1
											if SpallLiner == 1 then SpallLinerCount = SpallLinerCount + 1 end
										end

										HitTable[#HitTable + 1] = hitpos
									end
								end
							end

							for i = 1, #selfTbl.Crew do
								table.sort(selfTbl.Crew[i].RearArmorTable)
								local Ave = 0
								local AveCount = 0
								for j = 1, #selfTbl.Crew[i].RearArmorTable do
									if (j >= #selfTbl.Crew[i].RearArmorTable / 4 and j <= (#selfTbl.Crew[i].RearArmorTable / 4) * 3) or #selfTbl.Crew[i].RearArmorTable < 4 then
										Ave = Ave + math.min(selfTbl.Crew[i].RearArmorTable[j], 10000)
										AveCount = AveCount + 1
									end
								end

								selfTbl.Crew[i].RearAverage = Ave / AveCount
							end

							table.sort(selfTbl.Crew, function(a, b) return a.RearAverage > b.RearAverage end)
							if #selfTbl.Crew >= 2 then selfTbl.RearArmor = (selfTbl.Crew[1].RearAverage + selfTbl.Crew[2].RearAverage) * 0.5 end
							for i = 1, 2 do
								if i <= 2 or selfTbl.Crew[i].RearAverage >= selfTbl.Crew[1].RearAverage * 0.5 then
									for j = 1, #selfTbl.Crew[i].RearBounds do
										selfTbl.RealBounds[#selfTbl.RealBounds + 1] = selfTbl.Crew[i].RearBounds[j]
									end

									for j = 1, #selfTbl.Crew[i].TopBounds do
										selfTbl.RealBounds[#selfTbl.RealBounds + 1] = selfTbl.Crew[i].TopBounds[j]
									end

									for j = 1, #selfTbl.Crew[i].BottomBounds do
										selfTbl.RealBounds[#selfTbl.RealBounds + 1] = selfTbl.Crew[i].BottomBounds[j]
									end
								end
							end

							if selfTbl.RearArmor == 0 then selfTbl.RearArmor = 10000 end
							selfTbl.RearSpallLinerCoverage = SpallLinerCount / #ArmorValTable
							if #ArmorValTable == 0 then selfTbl.RearSpallLinerCoverage = 1 end
						end

						do
							--Side armor check
							--LEFT
							local distance = selfTbl.MaxSize * 2
							local HitTable = {}
							local ArmorVal1 = 0
							local ent
							local aimpos
							local HitCrit = 0
							local hitpos
							local SpallLiner = 0
							local Armors = {}
							local Crews = {}
							local ThickestPos
							local ArmorValTable = {}
							local SpallLinerCount = 0
							for i = 1, #selfTbl.Crew do
								for j = 1, #selfTbl.Crew[i].aimpoints do
									aimpos = selfTbl.Crew[i].aimpoints[j]
									ArmorVal1, ent, _, _, _, _, HitCrit, hitpos, SpallLiner, Armors, Crews, ThickestPos = DTTE.GetArmorRecurseNoStop(selfTbl.Crew[i].aimpoints[j] - right * selfTbl.BestWidth * 2, selfTbl.Crew[i].aimpoints[j] + right * 25, distance, "AP", 75, player.GetAll(), self)
									if IsValid(ent) then
										if ent.Controller == self and ent:GetClass() == "dak_crew" and HitCrit == 1 then
											for k = 1, #Crews do
												Crews[k].SideArmorTable[#Crews[k].SideArmorTable + 1] = Armors[k]
											end

											selfTbl.Crew[i].LeftBounds[#selfTbl.Crew[i].LeftBounds + 1] = ThickestPos
											ArmorValTable[#ArmorValTable + 1] = ArmorVal1
											if SpallLiner == 1 then SpallLinerCount = SpallLinerCount + 1 end
										end

										HitTable[#HitTable + 1] = hitpos
									end
								end
							end

							selfTbl.LeftSpallLinerCoverage = SpallLinerCount / #ArmorValTable
							if #ArmorValTable == 0 then selfTbl.LeftSpallLinerCoverage = 1 end
							--RIGHT
							ArmorValTable = {}
							SpallLinerCount = 0
							for i = 1, #selfTbl.Crew do
								for j = 1, #selfTbl.Crew[i].aimpoints do
									aimpos = selfTbl.Crew[i].aimpoints[j]
									ArmorVal1, ent, _, _, _, _, HitCrit, hitpos, SpallLiner, Armors, Crews, ThickestPos = DTTE.GetArmorRecurseNoStop(selfTbl.Crew[i].aimpoints[j] + right * selfTbl.BestWidth * 2, selfTbl.Crew[i].aimpoints[j] - right * 25, distance, "AP", 75, player.GetAll(), self)
									if IsValid(ent) then
										if ent.Controller == self and ent:GetClass() == "dak_crew" and HitCrit == 1 then
											for k = 1, #Crews do
												Crews[k].SideArmorTable[#Crews[k].SideArmorTable + 1] = Armors[k]
											end

											selfTbl.Crew[i].RightBounds[#selfTbl.Crew[i].RightBounds + 1] = ThickestPos
											ArmorValTable[#ArmorValTable + 1] = ArmorVal1
											if SpallLiner == 1 then SpallLinerCount = SpallLinerCount + 1 end
										end

										HitTable[#HitTable + 1] = hitpos
									end
								end
							end

							selfTbl.RightSpallLinerCoverage = SpallLinerCount / #ArmorValTable
							if #ArmorValTable == 0 then selfTbl.RightSpallLinerCoverage = 1 end
							for i = 1, #selfTbl.Crew do
								table.sort(selfTbl.Crew[i].SideArmorTable)
								local Ave = 0
								local AveCount = 0
								for j = 1, #selfTbl.Crew[i].SideArmorTable do
									if (j >= #selfTbl.Crew[i].SideArmorTable / 4 and j <= (#selfTbl.Crew[i].SideArmorTable / 4) * 3) or #selfTbl.Crew[i].SideArmorTable < 4 then
										Ave = Ave + math.min(selfTbl.Crew[i].SideArmorTable[j], 10000)
										AveCount = AveCount + 1
									end
								end

								selfTbl.Crew[i].SideAverage = Ave / AveCount
							end

							table.sort(selfTbl.Crew, function(a, b) return a.RearAverage > b.RearAverage end)
							if #selfTbl.Crew >= 2 then selfTbl.SideArmor = (selfTbl.Crew[1].SideAverage + selfTbl.Crew[2].SideAverage) * 0.5 end
							for i = 1, 2 do
								if i <= 2 or selfTbl.Crew[i].SideAverage >= selfTbl.Crew[1].SideAverage * 0.5 then
									for j = 1, #selfTbl.Crew[i].RightBounds do
										selfTbl.RealBounds[#selfTbl.RealBounds + 1] = selfTbl.Crew[i].RightBounds[j]
									end

									for j = 1, #selfTbl.Crew[i].LeftBounds do
										selfTbl.RealBounds[#selfTbl.RealBounds + 1] = selfTbl.Crew[i].LeftBounds[j]
									end

									for j = 1, #selfTbl.Crew[i].TopBounds do
										selfTbl.RealBounds[#selfTbl.RealBounds + 1] = selfTbl.Crew[i].TopBounds[j]
									end

									for j = 1, #selfTbl.Crew[i].BottomBounds do
										selfTbl.RealBounds[#selfTbl.RealBounds + 1] = selfTbl.Crew[i].BottomBounds[j]
									end
								end
							end

							if selfTbl.SideArmor == 0 then selfTbl.SideArmor = 10000 end
							selfTbl.SideSpallLinerCoverage = 0.5 * (selfTbl.RightSpallLinerCoverage + selfTbl.LeftSpallLinerCoverage)
						end

						do
							--Get crew bounds
							local CrewMeshs = {}
							for i = 1, #selfTbl.Crew do
								local crewMesh = selfTbl.Crew[i]:GetPhysicsObject():GetMesh()
								for j = 1, #crewMesh do
									for _, v in pairs(crewMesh[j]) do
										CrewMeshs[#CrewMeshs + 1] = selfTbl.Crew[i]:LocalToWorld(v)
									end
								end
							end

							local crewxs = {}
							local crewys = {}
							local crewzs = {}
							for i = 1, #CrewMeshs do
								crewxs[#crewxs + 1] = CrewMeshs[i].x
								crewys[#crewys + 1] = CrewMeshs[i].y
								crewzs[#crewzs + 1] = CrewMeshs[i].z
							end

							table.sort(crewxs)
							table.sort(crewys)
							table.sort(crewzs)
							selfTbl.CrewMins = selfTbl.ForwardEnt:WorldToLocal(Vector(crewxs[1], crewys[1], crewzs[1]))
							selfTbl.CrewMaxs = selfTbl.ForwardEnt:WorldToLocal(Vector(crewxs[#crewxs], crewys[#crewys], crewzs[#crewzs]))
						end

						do
							--Link guns to their appropriate ammo
							for i = 1, #selfTbl.Guns do
								selfTbl.Guns[i].AmmoBoxes = {}
								local ammoBoxes = selfTbl.Guns[i].AmmoBoxes
								local gunType = selfTbl.Guns[i].DakGunType
								for j = 1, #selfTbl.Ammoboxes do
									if selfTbl.Ammoboxes[j].DakAmmoType ~= "Flamethrower Fuel" then
										local splitString = string.Split(selfTbl.Ammoboxes[j].DakName, "m")[3]
										if gunType == "Short Cannon" or gunType == "Short Autoloader" then
											if splitString[1] == "S" and splitString[2] == "C" then table.insert(ammoBoxes, selfTbl.Ammoboxes[j]) end
										elseif gunType == "Cannon" or gunType == "Autoloader" then
											if splitString[1] == "C" then table.insert(ammoBoxes, selfTbl.Ammoboxes[j]) end
										elseif gunType == "Long Cannon" or gunType == "Long Autoloader" then
											if splitString[1] == "L" and splitString[2] == "C" then table.insert(ammoBoxes, selfTbl.Ammoboxes[j]) end
										elseif gunType == "Howitzer" or gunType == "Autoloading Howitzer" then
											if splitString[1] == "H" and splitString[2] ~= "M" then table.insert(ammoBoxes, selfTbl.Ammoboxes[j]) end
										elseif gunType == "Mortar" or gunType == "Autoloading Mortar" then
											if splitString[1] == "M" and splitString[2] ~= "G" then table.insert(ammoBoxes, selfTbl.Ammoboxes[j]) end
										elseif gunType == "Smoke Launcher" then
											if splitString[1] == "S" and splitString[2] == "L" then table.insert(ammoBoxes, selfTbl.Ammoboxes[j]) end
										elseif gunType == "Flamethrower" then
											if selfTbl.Ammoboxes[j].DakAmmoType == "Flamethrower Fuel" then table.insert(ammoBoxes, selfTbl.Ammoboxes[j]) end
										elseif gunType == "MG" then
											if splitString[1] == "M" and splitString[2] == "G" then table.insert(ammoBoxes, selfTbl.Ammoboxes[j]) end
										elseif gunType == "Grenade Launcher" then
											if splitString[1] == "G" and splitString[2] == "L" then table.insert(ammoBoxes, selfTbl.Ammoboxes[j]) end
										elseif gunType == "HMG" then
											if splitString[1] == "H" and splitString[2] == "M" and splitString[3] == "G" then table.insert(ammoBoxes, selfTbl.Ammoboxes[j]) end
										elseif gunType == "Autocannon" then
											if splitString[1] == "A" and splitString[2] == "C" then table.insert(ammoBoxes, selfTbl.Ammoboxes[j]) end
										elseif gunType == "Recoilless Rifle" or gunType == "Autoloading Recoilless Rifle" then
											if splitString[1] == "R" and splitString[2] == "R" then table.insert(ammoBoxes, selfTbl.Ammoboxes[j]) end
										elseif gunType == "ATGM Launcher" or gunType == "Dual ATGM Launcher" or gunType == "Autoloading ATGM Launcher" or gunType == "Autoloading Dual ATGM Launcher" then
											if splitString[1] == "L" and splitString[2] ~= "C" then table.insert(ammoBoxes, selfTbl.Ammoboxes[j]) end
										else
											if splitString[1] == "C" then table.insert(ammoBoxes, selfTbl.Ammoboxes[j]) end
										end
									end
								end
							end
						end

						do
							--Find max penetration
							local MaxPen = 0
							for i = 1, #selfTbl.Guns do
								for j = 1, #selfTbl.Guns[i].AmmoBoxes do
									if selfTbl.Guns[i].DakCaliber == selfTbl.Guns[i].AmmoBoxes[j].DakCaliber then
										local boxname = string.Split(selfTbl.Guns[i].AmmoBoxes[j].DakAmmoType, "")
										local name6 = boxname[#boxname - 9] .. boxname[#boxname - 8] .. boxname[#boxname - 7] .. boxname[#boxname - 6] .. boxname[#boxname - 5] .. boxname[#boxname - 4]
										local name4 = boxname[#boxname - 7] .. boxname[#boxname - 6] .. boxname[#boxname - 5] .. boxname[#boxname - 4]
										local name2 = boxname[#boxname - 5] .. boxname[#boxname - 4]
										local name
										if name6 == "APFSDS" or name6 == "HEATFS" then
											name = name6
										elseif name4 == "HVAP" or name4 == "APDS" or name4 == "HEAT" or name4 == "HESH" or name4 == "ATGM" or name4 == "APHE" then
											name = name4
										elseif name2 == "AP" or name2 == "HE" or name2 == "SM" then
											name = name2
										end

										if name == "APFSDS" then
											if selfTbl.Guns[i].BaseDakShellPenetration * 7.8 * 0.5 > MaxPen then MaxPen = selfTbl.Guns[i].BaseDakShellPenetration * 7.8 * 0.5 end
										elseif name == "APDS" then
											if selfTbl.Guns[i].BaseDakShellPenetration * 1.67 > MaxPen then MaxPen = selfTbl.Guns[i].BaseDakShellPenetration * 1.67 end
										elseif name == "HVAP" then
											if selfTbl.Guns[i].BaseDakShellPenetration * 1.5 > MaxPen then MaxPen = selfTbl.Guns[i].BaseDakShellPenetration * 1.5 end
										elseif name == "AP" then
											if selfTbl.Guns[i].BaseDakShellPenetration > MaxPen then MaxPen = selfTbl.Guns[i].BaseDakShellPenetration end
										elseif name == "APHE" then
											if selfTbl.Guns[i].BaseDakShellPenetration * 0.825 > MaxPen then MaxPen = selfTbl.Guns[i].BaseDakShellPenetration * 0.825 end
										elseif name == "ATGM" then
											selfTbl.Guns[i].HasATGM = true
											if selfTbl.Modern == 1 then
												if selfTbl.Guns[i].DakMaxHealth * 6.40 > MaxPen then MaxPen = selfTbl.Guns[i].DakMaxHealth * 6.40 end
											else
												if selfTbl.Guns[i].DakMaxHealth * 6.40 * 0.45 > MaxPen then MaxPen = selfTbl.Guns[i].DakMaxHealth * 6.40 * 0.45 end
											end
										elseif name == "HEATFS" then
											if selfTbl.Modern == 1 then
												if selfTbl.Guns[i].DakMaxHealth * 5.4 > MaxPen then MaxPen = selfTbl.Guns[i].DakMaxHealth * 5.4 end
											else
												if selfTbl.Guns[i].DakMaxHealth * 5.40 * 0.658 > MaxPen then MaxPen = selfTbl.Guns[i].DakMaxHealth * 5.40 * 0.658 end
											end
										elseif name == "HEAT" then
											if selfTbl.ColdWar == 1 or selfTbl.Modern == 1 then
												if selfTbl.Guns[i].DakMaxHealth * 5.4 * 0.431 > MaxPen then MaxPen = selfTbl.Guns[i].DakMaxHealth * 5.4 * 0.431 end
											else
												if selfTbl.Guns[i].DakMaxHealth * 1.20 > MaxPen then MaxPen = selfTbl.Guns[i].DakMaxHealth * 1.20 end
											end
										elseif name == "HESH" then
											if selfTbl.Guns[i].DakMaxHealth * 1.25 > MaxPen then MaxPen = selfTbl.Guns[i].DakMaxHealth * 1.25 end
										elseif name == "HE" then
											if selfTbl.Guns[i].DakBaseShellFragPen > MaxPen then MaxPen = selfTbl.Guns[i].DakBaseShellFragPen end
										elseif name == "SM" then
											if selfTbl.Guns[i].DakMaxHealth * 0.1 > MaxPen then MaxPen = selfTbl.Guns[i].DakMaxHealth * 0.1 end
										end
									end
								end
							end

							selfTbl.MaxPen = MaxPen
						end


						do
							--Scan for armor display
							selfTbl.RawFrontalTable = {}
							selfTbl.RawSideTable = {}
							selfTbl.RawRearTable = {}
							selfTbl.FrontalPosTable = {}
							selfTbl.SidePosTable = {}
							selfTbl.RearPosTable = {}
							local basepos = selfTbl.Base:GetPos()
							selfTbl.BoxVolume = selfTbl.BestLength * selfTbl.BestWidth * selfTbl.BestHeight
							--local biggestsize = math.max(math.min(selfTbl.BestLength, selfTbl.BestWidth) * 1.1, selfTbl.BestHeight * 0.5 * 1.1) * 2
							local pixels = 40
							--local splits = 40
							--local delay = pixels / splits
							local startpos
							local curarmor = 0
							local thickestpos
							local ent
							local aspectratio = selfTbl.BoxSize.y / selfTbl.BoxSize.z
							selfTbl.frontarmortable = {}
							local addpos
							local distance = selfTbl.MaxSize * 2

							local scanforward
							local scanright
							local scanup
							if IsValid(selfTbl.Gearbox) then
								local fwEnt = selfTbl.Gearbox.ForwardEnt
								scanforward = fwEnt:GetForward()
								scanright = fwEnt:GetRight()
								scanup = fwEnt:GetUp()
							elseif IsValid(selfTbl.MainTurret) then
								scanforward = selfTbl.MainTurret:GetForward()
								scanright = selfTbl.MainTurret:GetRight()
								scanup = selfTbl.MainTurret:GetUp()
							end

							local allPlayers = player.GetAll()


							if IsValid(self) then
								--FRONT
								for i = 1, pixels do
									for j = 1, pixels do
										if selfTbl.BoxSize.y > selfTbl.BoxSize.z then
											aspectratio = selfTbl.BoxSize.y / selfTbl.BoxSize.z
											local xstart = -scanright * selfTbl.HitBoxMaxs.y * 1.1
											local ystart = scanup * selfTbl.HitBoxMaxs.z * 1.1
											local xcur = (j / pixels * 1.1) * -scanright * -selfTbl.BoxSize.y
											local ycur = (i / pixels * 1.1) * scanup * -selfTbl.BoxSize.z
											startpos = basepos + xstart + ystart * aspectratio
											addpos = xcur + ycur * aspectratio
										else
											aspectratio = selfTbl.BoxSize.z / selfTbl.BoxSize.y
											local xstart = -scanright * selfTbl.HitBoxMaxs.y * 1.1
											local ystart = scanup * selfTbl.HitBoxMaxs.z * 1.1
											local xcur = (j / pixels * 1.1) * -scanright * -selfTbl.BoxSize.y
											local ycur = (i / pixels * 1.1) * scanup * -selfTbl.BoxSize.z
											startpos = basepos + xstart * aspectratio + ystart
											addpos = xcur * aspectratio + ycur
										end

										local ForwardHit = DTTE.FilterRecurseTrace(startpos + addpos + scanforward * distance, startpos + addpos - scanforward * distance, allPlayers, self)
										local BackwardHit = DTTE.FilterRecurseTrace(startpos + addpos - scanforward * distance, startpos + addpos + scanforward * distance, allPlayers, self)

										local depth = math.Max(ForwardHit:Distance(BackwardHit) * 0.5, 50)
										if ForwardHit == startpos + addpos + scanforward * distance or BackwardHit == startpos + addpos - scanforward * distance then depth = 0 end
										local TraceStart = ForwardHit
										local TraceEnd = (ForwardHit + BackwardHit) / 2
										curarmor, ent, _, _, _, _, _, _, _, thickestpos = DTTE.GetArmorRecurseDisplay(TraceStart, TraceEnd, depth, "AP", 75, allPlayers, self, true, false)
										local addval = 0
										if IsValid(ent) then
											local entclass = ent:GetClass()
											if entclass == "dak_crew" then addval = 70000 end
											if entclass == "dak_teammo" or entclass == "dak_teautoloadingmodule" then addval = 80000 end
											if entclass == "dak_tefuel" then addval = 90000 end
										end

										if curarmor ~= nil then
											selfTbl.frontarmortable[#selfTbl.frontarmortable + 1] = math.Round(curarmor) + addval
											if curarmor ~= 0 and depth ~= 0 then
												selfTbl.RawFrontalTable[#selfTbl.RawFrontalTable + 1] = math.Round(curarmor)
												selfTbl.FrontalPosTable[#selfTbl.FrontalPosTable + 1] = thickestpos
											end
										else
											selfTbl.frontarmortable[#selfTbl.frontarmortable + 1] = 0
										end
									end
								end

								timer.Simple(1, function()
									if selfTbl.frontarmortable ~= nil then selfTbl.frontarmortable[#selfTbl.frontarmortable + 1] = selfTbl.FrontalArmor end
								end)

								--SIDE
								selfTbl.sidearmortable = {}
								for i = 1, pixels do
									for j = 1, pixels do
										if selfTbl.BoxSize.x > selfTbl.BoxSize.z then
											aspectratio = selfTbl.BoxSize.x / selfTbl.BoxSize.z
											local xstart = scanforward * selfTbl.HitBoxMaxs.x * 1.1 - scanforward * selfTbl.ForwardEnt:WorldToLocal(basepos).x
											local ystart = scanup * selfTbl.HitBoxMaxs.z * 1.1 + scanup * selfTbl.ForwardEnt:WorldToLocal(basepos).z
											local xcur = (j / pixels * 1.1) * scanforward * -selfTbl.BoxSize.x
											local ycur = (i / pixels * 1.1) * scanup * -selfTbl.BoxSize.z
											startpos = basepos + xstart + ystart * aspectratio
											addpos = xcur + ycur * aspectratio
										else
											aspectratio = selfTbl.BoxSize.z / selfTbl.BoxSize.x
											local xstart = scanforward * selfTbl.HitBoxMaxs.x * 1.1 - scanforward * selfTbl.ForwardEnt:WorldToLocal(basepos).x
											local ystart = scanup * selfTbl.HitBoxMaxs.z * 1.1 + scanup * selfTbl.ForwardEnt:WorldToLocal(basepos).z
											local xcur = (j / pixels * 1.1) * scanforward * -selfTbl.BoxSize.x
											local ycur = (i / pixels * 1.1) * scanup * -selfTbl.BoxSize.z
											startpos = basepos + xstart * aspectratio + ystart
											addpos = xcur * aspectratio + ycur
										end

										-- SpallLiner = 0
										local ForwardHit = DTTE.FilterRecurseTrace(startpos + addpos - scanright * distance, startpos + addpos + scanright * distance, allPlayers, self)
										local BackwardHit = DTTE.FilterRecurseTrace(startpos + addpos + scanright * distance, startpos + addpos - scanright * distance, allPlayers, self)
										local depth = math.Max(ForwardHit:Distance(BackwardHit) * 0.5, 50)
										if ForwardHit == startpos + addpos - scanright * distance or BackwardHit == startpos + addpos + scanright * distance then depth = 0 end
										local TraceStart = ForwardHit
										local TraceEnd = (ForwardHit + BackwardHit) / 2
										curarmor, ent, _, _, _, _, _, _, _, thickestpos = DTTE.GetArmorRecurseDisplay(TraceStart, TraceEnd, depth, "AP", 75, allPlayers, self, false, false)
										local addval = 0
										if IsValid(ent) then
											local entclass = ent:GetClass()
											if entclass == "dak_crew" then addval = 70000 end
											if entclass == "dak_teammo" or entclass == "dak_teautoloadingmodule" then addval = 80000 end
											if entclass == "dak_tefuel" then addval = 90000 end
										end

										if curarmor ~= nil then
											selfTbl.sidearmortable[#selfTbl.sidearmortable + 1] = math.Round(curarmor) + addval
											if curarmor ~= 0 and depth ~= 0 then
												selfTbl.RawSideTable[#selfTbl.RawSideTable + 1] = math.Round(curarmor)
												selfTbl.SidePosTable[#selfTbl.SidePosTable + 1] = thickestpos
											end
										else
											selfTbl.sidearmortable[#selfTbl.sidearmortable + 1] = 0
										end
									end
								end

								timer.Simple(1, function()
									if selfTbl.sidearmortable ~= nil then selfTbl.sidearmortable[#selfTbl.sidearmortable + 1] = selfTbl.SideArmor end
								end)

								--Rear
								selfTbl.reararmortable = {}
								for i = 1, pixels do
									for j = 1, pixels do
										if selfTbl.BoxSize.y > selfTbl.BoxSize.z then
											aspectratio = selfTbl.BoxSize.y / selfTbl.BoxSize.z
											local xstart = -scanright * selfTbl.HitBoxMaxs.y * 1.1
											local ystart = scanup * selfTbl.HitBoxMaxs.z * 1.1
											local xcur = (j / pixels * 1.1) * -scanright * -selfTbl.BoxSize.y
											local ycur = (i / pixels * 1.1) * scanup * -selfTbl.BoxSize.z
											startpos = basepos + xstart + ystart * aspectratio
											addpos = xcur + ycur * aspectratio
										else
											aspectratio = selfTbl.BoxSize.z / selfTbl.BoxSize.y
											local xstart = -scanright * selfTbl.HitBoxMaxs.y * 1.1
											local ystart = scanup * selfTbl.HitBoxMaxs.z * 1.1
											local xcur = (j / pixels * 1.1) * -scanright * -selfTbl.BoxSize.y
											local ycur = (i / pixels * 1.1) * scanup * -selfTbl.BoxSize.z
											startpos = basepos + xstart * aspectratio + ystart
											addpos = xcur * aspectratio + ycur
										end

										-- SpallLiner = 0
										local ForwardHit = DTTE.FilterRecurseTrace(startpos + addpos - scanforward * distance, startpos + addpos + scanforward * distance, allPlayers, self)
										local BackwardHit = DTTE.FilterRecurseTrace(startpos + addpos + scanforward * distance, startpos + addpos - scanforward * distance, allPlayers, self)
										local depth = math.Max(ForwardHit:Distance(BackwardHit) * 0.5, 50)
										if ForwardHit == startpos + addpos - scanforward * distance or BackwardHit == startpos + addpos + scanforward * distance then depth = 0 end
										local TraceStart = ForwardHit
										local TraceEnd = (ForwardHit + BackwardHit) / 2
										curarmor, ent, _, _, _, _, _, _, _, thickestpos = DTTE.GetArmorRecurseDisplay(TraceStart, TraceEnd, depth, "AP", 75, allPlayers, self, false, true)
										local addval = 0
										if IsValid(ent) then
											local entclass = ent:GetClass()
											if entclass == "dak_crew" then addval = 70000 end
											if entclass == "dak_teammo" or entclass == "dak_teautoloadingmodule" then addval = 80000 end
											if entclass == "dak_tefuel" then addval = 90000 end
										end

										if curarmor ~= nil then
											selfTbl.reararmortable[#selfTbl.reararmortable + 1] = math.Round(curarmor) + addval
											if curarmor ~= 0 and depth ~= 0 then
												selfTbl.RawRearTable[#selfTbl.RawRearTable + 1] = math.Round(curarmor)
												selfTbl.RearPosTable[#selfTbl.RearPosTable + 1] = thickestpos
											end
										else
											selfTbl.reararmortable[#selfTbl.reararmortable + 1] = 0
										end
									end
								end

								timer.Simple(1, function()
									if selfTbl.reararmortable ~= nil then selfTbl.reararmortable[#selfTbl.reararmortable + 1] = selfTbl.RearArmor end
								end)
							end
						end

						do
							--Get main armor bounds of vehicle
							selfTbl.ZPosTable = {}
							for i = 1, #selfTbl.Crew do
								for j = 1, #selfTbl.Crew[i].TopBounds do
									selfTbl.ZPosTable[#selfTbl.ZPosTable + 1] = selfTbl.Crew[i].TopBounds[j]
								end

								for j = 1, #selfTbl.Crew[i].BottomBounds do
									selfTbl.ZPosTable[#selfTbl.ZPosTable + 1] = selfTbl.Crew[i].BottomBounds[j]
								end
							end

							local xs = {}
							local ys = {}
							local zs = {}
							local localbound
							for i = 1, #selfTbl.FrontalPosTable do
								localbound = selfTbl.ForwardEnt:WorldToLocal(selfTbl.FrontalPosTable[i])
								xs[#xs + 1] = localbound.x
							end

							for i = 1, #selfTbl.RearPosTable do
								localbound = selfTbl.ForwardEnt:WorldToLocal(selfTbl.RearPosTable[i])
								xs[#xs + 1] = localbound.x
							end

							for i = 1, #selfTbl.SidePosTable do
								localbound = selfTbl.ForwardEnt:WorldToLocal(selfTbl.SidePosTable[i])
								ys[#ys + 1] = localbound.y
							end

							for i = 1, #selfTbl.ZPosTable do
								localbound = selfTbl.ForwardEnt:WorldToLocal(selfTbl.ZPosTable[i])
								zs[#zs + 1] = localbound.z
							end

							table.sort(xs)
							table.sort(ys)
							table.sort(zs)
							selfTbl.RealMins = Vector(xs[1], ys[1], zs[1])
							selfTbl.RealMaxs = Vector(xs[#xs], ys[#ys], zs[#zs])

							local YHalfAve = AverageNoOutliers(ys)
							local XAve = math.abs(xs[1] - xs[#xs])
							local YAve = math.abs(YHalfAve * 2)
							local ZAve = math.abs(zs[1] - zs[#zs])

							selfTbl.DakVolume = math.Round(XAve * YAve * ZAve * 0.005, 2) --0.03125 is just an arbitrary balance number, was 0.005 but new averaging system called for new number
						end

						local armormult
						local armormultfrontal
						do
							--Calculate armor multipliers
							table.sort(selfTbl.RawFrontalTable)
							table.sort(selfTbl.RawSideTable)
							table.sort(selfTbl.RawRearTable)

							selfTbl.FrontalArmor = math.max(AverageNoOutliers(selfTbl.RawFrontalTable), selfTbl.FrontalArmor)
							selfTbl.SideArmor = math.max(AverageNoOutliers(selfTbl.RawSideTable), selfTbl.SideArmor)
							selfTbl.RearArmor = math.max(AverageNoOutliers(selfTbl.RawRearTable), selfTbl.RearArmor)
							selfTbl.ArmorSideMult = math.max(selfTbl.SideArmor / 250, 0.1)
							selfTbl.ArmorRearMult = math.max(selfTbl.RearArmor / 250, 0.1)
							local Total = math.max(selfTbl.FrontalArmor, selfTbl.SideArmor, selfTbl.RearArmor)
							selfTbl.BestAveArmor = Total
							armormult = ((Total / 420) * (1 + (0.25 * selfTbl.FrontalSpallLinerCoverage))) * (((selfTbl.ArmorSideMult + selfTbl.ArmorSideMult + selfTbl.ArmorRearMult) / 3) * (1 + (0.25 * ((selfTbl.SideSpallLinerCoverage + selfTbl.SideSpallLinerCoverage + selfTbl.RearSpallLinerCoverage) / 3))))
							armormultfrontal = Total / 420
							selfTbl.ArmorMult = math.Round(math.max(0.01, armormult), 3)
							selfTbl.TotalArmorWeight = selfTbl.RHAWeight + selfTbl.CHAWeight + selfTbl.HHAWeight + selfTbl.NERAWeight + selfTbl.StillbrewWeight + selfTbl.TextoliteWeight + selfTbl.ConcreteWeight + selfTbl.ERAWeight
							local ArmorTypeMult = ( (1 * selfTbl.RHAWeight) + (0.75 * selfTbl.CHAWeight) + (1.25 * selfTbl.HHAWeight) + (1 * selfTbl.NERAWeight) + (1.1 * selfTbl.StillbrewWeight) + (0.9 * selfTbl.TextoliteWeight) + (0.5 * selfTbl.ConcreteWeight) + (1.25 * selfTbl.ERAWeight) ) / selfTbl.TotalArmorWeight

							selfTbl.ArmorMult = selfTbl.ArmorMult * math.max(ArmorTypeMult, 0.5)
						end

						do
							--Calculate flanking multiplier
							local speedmult = 1
							if IsValid(selfTbl.Gearbox) then
								local gearTbl = selfTbl.Gearbox:GetTable()
								if gearTbl.DakHP ~= nil and gearTbl.MaxHP ~= nil and gearTbl.TotalMass ~= nil and gearTbl.HPperTon ~= nil then
									if selfTbl.Gearbox:GetClass() == "dak_tegearboxnew" then
										local hp = math.Clamp(gearTbl.DakHP, 0, gearTbl.MaxHP)
										local t = (gearTbl.TotalMass + selfTbl.Gearbox:GetPhysicsObject():GetMass()) / 1000
										local hpt = hp / t
										speedmult = math.Max(math.Round(hpt / 30, 2), 0.125) * math.Max(0.01, -0.75 + math.log((armormultfrontal + 1) * 2, 2))
									else
										local hp = math.Clamp(gearTbl.DakHP, 0, gearTbl.MaxHP)
										local t = gearTbl.TotalMass / 1000
										local hpt = hp / t
										speedmult = math.Max(math.Round(hpt / 30, 2), 0.125) * math.Max(0.01, -0.75 + math.log((armormultfrontal + 1) * 2, 2))
									end

									for i = 1, #selfTbl.Crew do
										if selfTbl.Crew[i].Job == 2 then
											if selfTbl.Crew[i]:GetParent() ~= self:GetParent() then
												speedmult = speedmult * 1.25
												selfTbl.DakOwner:ChatPrint("Turret mounted driver detected, 25% cost increase added to flanking multiplier.")
											end
										end
									end
								else
									selfTbl.DakOwner:ChatPrint("Please finish setting up the gearbox to get a correct cost for your tank.")
								end

								selfTbl.SpeedMult = math.Round(math.max(0.15, speedmult), 2)
							else
								selfTbl.SpeedMult = 0.1
								selfTbl.DakOwner:ChatPrint("No gearbox detected, towed gun assumed.")
							end
						end

						--Delayed portion
						timer.Simple(1, function()
							do
								--Calculate total DPS
								local DPS = 0
								local ShotsPerSecond
								for g = 1, #self.Guns do
									local ShellDamage = self.Guns[g].BaseDakShellDamage
									if self.Guns[g].DakGunType == "Smoke Launcher" then ShellDamage = self.Guns[g].BaseDakShellDamage / 4 end
									if self.Guns[g].DakGunType == "Flamethrower" then ShellDamage = 0.75 end
									if self.Guns[g].DakGunType == "ATGM Launcher" or self.Guns[g].DakGunType == "Dual ATGM Launcher" or self.Guns[g].DakGunType == "Autoloading ATGM Launcher" or self.Guns[g].DakGunType == "Autoloading Dual ATGM Launcher" then ShellDamage = self.Guns[g].BaseDakShellDamage / 4 end
									--also have an exception here for flamethrower damage per shot
									if self.Guns[g]:GetClass() == "dak_teautogun" then
										self.Guns[g].FirstLoad = true
										if self.Guns[g].BaseMagazine ~= nil then
											ShotsPerSecond = 1 / ((self.Guns[g].DakCooldown * (1 / self.Guns[g].FireRateMod)) + ((1 / self.Guns[g].BaseMagazine) * self.Guns[g].DakReloadTime))
										else
											ShotsPerSecond = 1 / ((self.Guns[g].DakCooldown * (1 / self.Guns[g].FireRateMod)) + ((1 / self.Guns[g].DakMagazine) * self.Guns[g].DakReloadTime))
										end

										DPS = ShellDamage * ShotsPerSecond
										if self.Guns[g].ReadyRounds == 2 then DPS = DPS * 2 end
									end

									if self.Guns[g]:GetClass() == "dak_tegun" then
										if self.Guns[g].DakGunType == "ATGM Launcher" or self.Guns[g].DakGunType == "Dual ATGM Launcher" then
											ShotsPerSecond = 1 / (2 * 0.75 * (math.pi * ((self.Guns[g].DakCaliber * 0.001 * 0.5) ^ 2) * (self.Guns[g].DakCaliber * 0.001 * 6.5) * 3550))
										else
											ShotsPerSecond = 1 / (0.2484886 * (math.pi * ((self.Guns[g].DakCaliber * 0.001 * 0.5) ^ 2) * (self.Guns[g].DakCaliber * 0.001 * self.Guns[g].ShellLengthExact) * 5150) + 1.279318)
										end

										DPS = ShellDamage * ShotsPerSecond
										if self.Guns[g].ReadyRounds == 2 then DPS = DPS * 2 end
									end

									if self.Guns[g]:GetClass() == "dak_temachinegun" then
										self.Guns[g].ShellLengthExact = 6.5
										ShotsPerSecond = 1 / (self.Guns[g].DakCooldown * (1 / self.Guns[g].FireRateMod))
										DPS = ShellDamage * ShotsPerSecond
										if self.Guns[g].ReadyRounds == 2 then DPS = DPS * 2 end
									end

									self.TotalDPS = self.TotalDPS + DPS
								end
							end

							do
								--Calculate gun handling multiplier
								local GunHandlingMult = 0
								local MinHandling = 0.1
								if self.TurretControls[1] then
									local TotalTurretMass = 0
									for i = 1, #self.TurretControls do
										if self.TurretControls[i].GunMass ~= nil then TotalTurretMass = TotalTurretMass + self.TurretControls[i].GunMass end
									end

									self.MainTurret = self.TurretControls[1]

									for i = 1, #self.TurretControls do
										if IsValid(self.MainTurret) and self.TurretControls[i].GunMass ~= nil and self.MainTurret.GunMass ~= nil then
											local WeaponMass = 0
											local ATGMs = 0
											local Total = 0
											for j = 1, #self.Guns do
												if self.Guns[j]:GetParent():GetParent() == self.TurretControls[i].DakGun then WeaponMass = WeaponMass + self.Guns[j].DakMass end
												if self.Guns[j]:GetParent():GetParent() == self.TurretControls[i].DakGun then
													if self.Guns[j].HasATGM == true then
														ATGMs = ATGMs + 1 --ATGM CHECK
													end

													Total = Total + 1
												end
											end

											local CrewMins = self.CrewMins
											local CrewMaxs = self.CrewMaxs
											local AimerMins, AimerMaxs = self.TurretControls[i].DakGun:GetModelBounds()
											local GunMins, GunMaxs = self.TurretControls[i].Inputs.Gun.Value:GetModelBounds()
											local AimerMaxs = self.ForwardEnt:WorldToLocal(self.TurretControls[i].DakGun:LocalToWorld(AimerMaxs))
											local AimerMins = self.ForwardEnt:WorldToLocal(self.TurretControls[i].DakGun:LocalToWorld(AimerMins))
											local GunMaxs = self.ForwardEnt:WorldToLocal(self.TurretControls[i].Inputs.Gun.Value:LocalToWorld(GunMaxs * self.TurretControls[i].Inputs.Gun.Value.DakCaliber / 100))
											local GunMins = self.ForwardEnt:WorldToLocal(self.TurretControls[i].Inputs.Gun.Value:LocalToWorld(GunMins * self.TurretControls[i].Inputs.Gun.Value.DakCaliber / 100))
											local InCrewBounds = InRange(math.Min(GunMins.z, GunMaxs.z), CrewMins.z, CrewMaxs.z)												local RotationSpeed = self.TurretControls[i].RotationSpeed
											if not InCrewBounds then --and InVehicleBounds == false then
												self.TurretControls[i].RemoteWeapon = true
											end

											if self.TurretControls[i].GunMass > self.MainTurret.GunMass then self.MainTurret = self.TurretControls[i] end
											local TurretCost = math.log(RotationSpeed * 100, 100)
											if self.TurretControls[i].RemoteWeapon == true then
												self.TurretControls[i].CoreRemoteMult = math.Min(100 / WeaponMass, 1)
												TurretCost = TurretCost * 1.5
											end

											if self.TurretControls[i]:GetFCS() == true then
												self.ColdWar = 1
												TurretCost = TurretCost * 1.2
											end

											if self.TurretControls[i]:GetStabilizer() == true then
												self.ColdWar = 1
												TurretCost = TurretCost * 1.0
											elseif self.TurretControls[i]:GetShortStopStabilizer() == true then
												TurretCost = TurretCost * 0.8
											else
												TurretCost = TurretCost * 0.6
											end

											if self.TurretControls[i]:GetYawMin() + self.TurretControls[i]:GetYawMax() <= 90 then TurretCost = TurretCost * 0.5 end
											GunHandlingMult = GunHandlingMult + math.max(TurretCost, 0.1) * (self.TurretControls[i].GunMass / TotalTurretMass)
										end
									end

									for i = 1, #self.Guns do
										if self.Guns[i].HasATGM == true then
											MinHandling = 0.9 --ATGM gun handling mult should be 0.9, so set that as minimum if has atgm
										end
									end
								end

								self.GunHandlingMult = math.Round(math.max(MinHandling, GunHandlingMult), 2)
							end

							do
								--Get firepower costs
								local firepowermult = self.MaxPen / 840
								local altfirepowermult = 0.0025 * self.TotalDPS ^ 1
								math.max(0.1, firepowermult)
								self.PenMult = firepowermult * 0.5
								self.DPSMult = altfirepowermult * 0.5
								firepowermult = (altfirepowermult + firepowermult) * 0.5
								firepowermult = math.max(self.DakVolume / 250000, firepowermult)
								self.FirepowerMult = math.Round(math.max(self.DakVolume / 250000, firepowermult), 2)
							end
						end)

						timer.Simple(2, function()
							--Finalize Costs and print readout
							local armorMult = self.ArmorMult or 1
							self.PreCost = armorMult * 50 + self.FirepowerMult * 50
							self.PreCost = self.PreCost * ((self.SpeedMult + self.GunHandlingMult) * 0.5)
							self.Cost = math.Round(self.PreCost + self.APSCost)
							local curera = "WWII"
							if self.ColdWar == 1 then curera = "Cold War" end
							if self.Modern == 1 then curera = "Modern" end
							hook.Run("DakTank_TankAnalysisComplete", self)
							self.DakOwner:ChatPrint("Tank Analysis Complete: " .. self.Cost .. " point " .. curera .. " tank. Right click tank core with spawner for detailed readout.")
						end)
					end

					if not selfTbl.Dead and (selfTbl.DakFinishedPasting == 1 or selfTbl.dupespawned == nil) then
						selfTbl.DakMaxHealth = selfTbl.DakMaxHealth or 10
						if table.Count(selfTbl.HitBox) == 0 and selfTbl.DakHealth > selfTbl.DakMaxHealth then
							selfTbl.DakHealth = selfTbl.DakMaxHealth
						end
						if selfTbl.recheckmass == nil then
							local Mass = 0
							local ParentMass = 0
							local SA = 0
							selfTbl.Contraption = {selfTbl.Base}
							local turrets = {}
							for k, v in pairs(selfTbl.Base:GetChildren()) do
								table.insert(selfTbl.Contraption, v)
								for k2, v2 in pairs(v:GetChildren()) do
									table.insert(selfTbl.Contraption, v2)
									if v2:GetClass() == "dak_turretcontrol" then table.insert(turrets, v2) end
								end
							end

							--This is done like 3 times. It should be a local function. I can't be bothered to fix that right now though.
							local turrets2 = {}
							for i, turret in ipairs(turrets) do
								local TurEnts = {}
								if turret.WiredTurret ~= NULL then
									table.insert(selfTbl.Contraption, turret.WiredTurret)
									table.insert(TurEnts, turret.WiredTurret)
									for k, v in pairs(turret.WiredTurret:GetChildren()) do
										table.insert(selfTbl.Contraption, v)
										table.insert(TurEnts, v)
										for k2, v2 in pairs(v:GetChildren()) do
											table.insert(selfTbl.Contraption, v2)
											table.insert(TurEnts, v2)
											if v2:GetClass() == "dak_turretcontrol" then table.insert(turrets2, v2) end
										end
									end
								end

								if turret.WiredGun ~= NULL then
									if turret.WiredGun:GetClass() == "dak_tegun" or turret.WiredGun:GetClass() == "dak_teautogun" or turret.WiredGun:GetClass() == "dak_temachinegun" then
										if IsValid(turret.WiredGun) and IsValid(turret.WiredGun:GetParent()) and IsValid(turret.WiredGun:GetParent():GetParent()) then
											local gunParent = turret.WiredGun:GetParent():GetParent()
											table.insert(selfTbl.Contraption, gunParent)
											table.insert(TurEnts, gunParent)

											for k, v in pairs(gunParent:GetChildren()) do
												table.insert(selfTbl.Contraption, v)
												table.insert(TurEnts, v)
												for k2, v2 in pairs(v:GetChildren()) do
													table.insert(selfTbl.Contraption, v2)
													table.insert(TurEnts, v2)
													if v2:GetClass() == "dak_turretcontrol" then table.insert(turrets2, v2)  end
												end
											end
										end
									else
										selfTbl.DakOwner:ChatPrint(turret.DakName .. " #" .. turret:EntIndex() .. " must have gun wired to a daktank gun.")
									end
								end

								turret.Extra = TurEnts
							end

							local turrets3 = {}
							for i = 1, #turrets2 do
								local TurEnts = {}
								if turrets2[i].WiredTurret ~= NULL then
									self.Contraption[#self.Contraption + 1] = turrets2[i].WiredTurret
									TurEnts[#TurEnts + 1] = turrets2[i].WiredTurret
									for k, v in pairs(turrets2[i].WiredTurret:GetChildren()) do
										self.Contraption[#self.Contraption + 1] = v
										TurEnts[#TurEnts + 1] = v
										for k2, v2 in pairs(v:GetChildren()) do
											self.Contraption[#self.Contraption + 1] = v2
											TurEnts[#TurEnts + 1] = v2
											if v2:GetClass() == "dak_turretcontrol" then turrets3[#turrets3 + 1] = v2 end
										end
									end
								end

								if turrets2[i].WiredGun ~= NULL then
									local gunRoot = turrets2[i].WiredGun:GetParent():GetParent()

									if IsValid(gunRoot) then
										self.Contraption[#self.Contraption + 1] = gunRoot
										TurEnts[#TurEnts + 1] = gunRoot

										for _, v in pairs(gunRoot:GetChildren()) do
											self.Contraption[#self.Contraption + 1] = v
											TurEnts[#TurEnts + 1] = v
											for _, v2 in pairs(v:GetChildren()) do
												self.Contraption[#self.Contraption + 1] = v2
												TurEnts[#TurEnts + 1] = v2
												if v2:GetClass() == "dak_turretcontrol" then turrets3[#turrets3 + 1] = v2 end
											end
										end
									end
								end

								turrets2[i].Extra = TurEnts
							end

							--just gonna stop it right here, if people have turrets on their turrets on their turrets that's fine, but I'm not going a step further
							--local turrets4 = {}
							for i = 1, #turrets3 do
								local TurEnts = {}
								if turrets3[i].WiredTurret ~= NULL then
									self.Contraption[#self.Contraption + 1] = turrets3[i].WiredTurret
									TurEnts[#TurEnts + 1] = turrets3[i].WiredTurret
									for k, v in pairs(turrets3[i].WiredTurret:GetChildren()) do
										self.Contraption[#self.Contraption + 1] = v
										TurEnts[#TurEnts + 1] = v
										for k2, v2 in pairs(v:GetChildren()) do
											self.Contraption[#self.Contraption + 1] = v2
											TurEnts[#TurEnts + 1] = v2
											--if v2:GetClass() == "dak_turretcontrol" then
											--	turrets4[#turrets4+1] = v2
											--end
										end
									end
								end

								if turrets3[i].WiredGun ~= NULL then
									self.Contraption[#self.Contraption + 1] = turrets3[i].WiredGun:GetParent():GetParent()
									TurEnts[#TurEnts + 1] = turrets3[i].WiredGun:GetParent():GetParent()
									for k, v in pairs(turrets3[i].WiredGun:GetParent():GetParent():GetChildren()) do
										self.Contraption[#self.Contraption + 1] = v
										TurEnts[#TurEnts + 1] = v
										for k2, v2 in pairs(v:GetChildren()) do
											self.Contraption[#self.Contraption + 1] = v2
											TurEnts[#TurEnts + 1] = v2
											--if v2:GetClass() == "dak_turretcontrol" then
											--	turrets4[#turrets4+1] = v2
											--end
										end
									end
								end

								turrets3[i].Extra = TurEnts
							end

							table.Add(selfTbl.Contraption, GetPhysCons(selfTbl.Base))
							if table.Count(GetPhysCons(selfTbl.Base)) > 0 then
								for k, v in pairs(GetPhysCons(selfTbl.Base)) do
									for k2, v2 in pairs(v:GetChildren()) do
										selfTbl.Contraption[#selfTbl.Contraption + 1] = v2
										for k3, v3 in pairs(v2:GetChildren()) do
											selfTbl.Contraption[#selfTbl.Contraption + 1] = v3
										end
									end
								end
							end

							local hash = {}
							local res = {}
							for _, v in ipairs(selfTbl.Contraption) do
								if not hash[v] then
									res[#res + 1] = v
									hash[v] = true
								end
							end

							selfTbl.Contraption = {}
							selfTbl.Ammoboxes = {}
							selfTbl.TurretControls = {}
							selfTbl.Guns = {}
							selfTbl.Crew = {}
							selfTbl.Motors = {}
							selfTbl.Fuel = {}
							selfTbl.Tread = {}
							selfTbl.ERA = {}
							selfTbl.DETAIL = {}
							selfTbl.Seats = {}
							selfTbl.Components = {}
							selfTbl.GunCount = 0
							selfTbl.MachineGunCount = 0
							selfTbl.RHAWeight = 0
							selfTbl.CHAWeight = 0
							selfTbl.HHAWeight = 0
							selfTbl.NERAWeight = 0
							selfTbl.StillbrewWeight = 0
							selfTbl.TextoliteWeight = 0
							selfTbl.ConcreteWeight = 0
							selfTbl.ERAWeight = 0
							local CurrentRes
							selfTbl.Clips = {}
							for i = 1, #res do
								CurrentRes = res[i]
								if CurrentRes:IsValid() and CurrentRes:IsSolid() then
									CurrentRes.DakLegit = 1
									if IsValid(CurrentRes:GetPhysicsObject()) then CurrentRes.DakLegitMass = CurrentRes:GetPhysicsObject():GetMass() end

									if CurrentRes:GetClass() == "prop_physics" and CurrentRes:GetPhysicsObject():GetMass() <= 1 and CurrentRes.EntityMods and CurrentRes.EntityMods.CompositeType == nil then
										if table.Count(CurrentRes:GetChildren()) == 0 and CurrentRes:GetParent():IsValid() then
											table.insert(selfTbl.DETAIL, CurrentRes)
										else
											table.insert(selfTbl.Contraption, CurrentRes)
										end
									else
										table.insert(selfTbl.Contraption, CurrentRes)
									end

									if CurrentRes:GetClass() == "dak_tegearbox" or CurrentRes:GetClass() == "dak_tegearboxnew" then
										CurrentRes.DakTankCore = self
										CurrentRes.Controller = self
										selfTbl.Gearbox = CurrentRes
										table.insert(selfTbl.Components, CurrentRes)
									elseif CurrentRes:GetClass() == "dak_tefuel" then
										table.insert(selfTbl.Fuel, CurrentRes)
										table.insert(selfTbl.Components, CurrentRes)
									elseif CurrentRes:GetClass() == "dak_temotor" then
										table.insert(selfTbl.Motors, CurrentRes)
										table.insert(selfTbl.Components, CurrentRes)
									elseif CurrentRes:GetClass() == "dak_teammo" then --THIS IS AN ISSUE FOR ANOTHER TIME -- I wonder what dakota meant here - j
										local boxname = string.Split(CurrentRes.DakAmmoType, "")
										local name6 = boxname[#boxname - 9] .. boxname[#boxname - 8] .. boxname[#boxname - 7] .. boxname[#boxname - 6] .. boxname[#boxname - 5] .. boxname[#boxname - 4]
										local name4 = boxname[#boxname - 7] .. boxname[#boxname - 6] .. boxname[#boxname - 5] .. boxname[#boxname - 4]
										local name2 = boxname[#boxname - 5] .. boxname[#boxname - 4]
										--check longest to shortest names, with if then ifelse then else
										local name
										if name6 == "APFSDS" or name6 == "HEATFS" then
											name = name6
										elseif name4 == "HVAP" or name4 == "APDS" or name4 == "HEAT" or name4 == "HESH" or name4 == "ATGM" or name4 == "APHE" then
											name = name4
										elseif name2 == "AP" or name2 == "HE" or name2 == "SM" then
											name = name2
										end

										if name == "APFSDS" then selfTbl.Modern = 1 end
										if name == "HEATFS" or name == "ATGM" or name == "HESH" or name == "APDS" then selfTbl.ColdWar = 1 end
										table.insert(selfTbl.Ammoboxes, CurrentRes)
										table.insert(selfTbl.Components, CurrentRes)
									elseif CurrentRes:GetClass() == "dak_tegun" or CurrentRes:GetClass() == "dak_teautogun" or CurrentRes:GetClass() == "dak_temachinegun" then
										CurrentRes.DakTankCore = self
										CurrentRes.Controller = self
										selfTbl.GunCount = selfTbl.GunCount + 1
										table.insert(selfTbl.Guns, CurrentRes)
									elseif CurrentRes:GetClass() == "dak_turretcontrol" then
										table.insert(selfTbl.TurretControls, CurrentRes)
										table.insert(selfTbl.Components, CurrentRes)
										CurrentRes.DakContraption = res
										CurrentRes.DakCore = self
										CurrentRes.Controller = self
									elseif CurrentRes:GetClass() == "prop_vehicle_prisoner_pod" then
										table.insert(selfTbl.Seats, CurrentRes)
									elseif CurrentRes:GetClass() == "dak_crew" then
										table.insert(selfTbl.Crew, CurrentRes)
										table.insert(selfTbl.Components, CurrentRes)
										CurrentRes.Controller = self
									elseif CurrentRes:GetClass() == "prop_physics" then
										CurrentRes.Controller = self

										--clip conversion
										if CurrentRes.ClipData and #CurrentRes.ClipData > 0 and CurrentRes.ClipData[1].physics ~= true then
											DTTE.ArmorSanityCheck(CurrentRes)
											local CurArmor = CurrentRes.DakArmor
											for _, data in ipairs(CurrentRes.ClipData) do
												local tbl = {
													ent = CurrentRes,
													armor = CurArmor,
													n = data.n,
													d = data.d,
													inside = data.inside
												}
												table.insert(selfTbl.Clips, tbl)
											end

											ProperClipping.RemoveClips(CurrentRes)
											CurrentRes.ClipData = {}
										end

										if CurrentRes.IsComposite == 1 then
											if CurrentRes.EntityMods == nil then
												CurrentRes.EntityMods = {}
												CurrentRes.EntityMods.CompositeType = "NERA"
												CurrentRes.EntityMods.CompKEMult = 9.2
												CurrentRes.EntityMods.CompCEMult = 18.4
												CurrentRes.EntityMods.DakName = "NERA"
												selfTbl.Modern = 1
											elseif CurrentRes.EntityMods.CompositeType == nil then
												CurrentRes.EntityMods.CompositeType = "NERA"
												CurrentRes.EntityMods.CompKEMult = 9.2
												CurrentRes.EntityMods.CompCEMult = 18.4
												CurrentRes.EntityMods.DakName = "NERA"
												selfTbl.Modern = 1
											end
										end

										if CurrentRes.EntityMods then
											if CurrentRes.EntityMods.CompositeType == nil and CurrentRes.IsComposite == nil then
												local mass = CurrentRes:GetPhysicsObject():GetMass()
												if CurrentRes.EntityMods.ArmorType == nil then
													selfTbl.RHAWeight = selfTbl.RHAWeight + mass
												else
													if CurrentRes.EntityMods.ArmorType == "RHA" then
														CurrentRes.EntityMods.Density = 7.8125
														CurrentRes.EntityMods.ArmorMult = 1
														CurrentRes.EntityMods.Ductility = 1
														selfTbl.RHAWeight = selfTbl.RHAWeight + mass
													elseif CurrentRes.EntityMods.ArmorType == "CHA" then
														CurrentRes.EntityMods.Density = 7.8125
														CurrentRes.EntityMods.ArmorMult = 1
														CurrentRes.EntityMods.Ductility = 1.5
														selfTbl.CHAWeight = selfTbl.CHAWeight + mass
													elseif CurrentRes.EntityMods.ArmorType == "HHA" then
														CurrentRes.EntityMods.Density = 7.8125
														CurrentRes.EntityMods.ArmorMult = 1
														CurrentRes.EntityMods.Ductility = 1.5
														selfTbl.HHAWeight = selfTbl.HHAWeight + mass
													end
												end
											else
												if CurrentRes.EntityMods.CompositeType == "NERA" then
													self.Modern = 1
													local Density = 2000
													CurrentRes:GetPhysicsObject():SetMass(math.Round(CurrentRes:GetPhysicsObject():GetVolume() / 61023.7 * Density))
													CurrentRes.DakLegitMass = CurrentRes:GetPhysicsObject():GetMass()
													self.NERAWeight = self.NERAWeight + CurrentRes:GetPhysicsObject():GetMass()
												elseif CurrentRes.EntityMods.CompositeType == "Stillbrew" then
													self.Modern = 1
													local Density = 5750
													CurrentRes:GetPhysicsObject():SetMass(math.Round(CurrentRes:GetPhysicsObject():GetVolume() / 61023.7 * Density))
													CurrentRes.DakLegitMass = CurrentRes:GetPhysicsObject():GetMass()
													self.StillbrewWeight = self.StillbrewWeight + CurrentRes:GetPhysicsObject():GetMass()
												elseif CurrentRes.EntityMods.CompositeType == "Textolite" then
													self.ColdWar = 1
													local Density = 1850
													CurrentRes:GetPhysicsObject():SetMass(math.Round(CurrentRes:GetPhysicsObject():GetVolume() / 61023.7 * Density))
													CurrentRes.DakLegitMass = CurrentRes:GetPhysicsObject():GetMass()
													self.TextoliteWeight = self.TextoliteWeight + CurrentRes:GetPhysicsObject():GetMass()
												elseif CurrentRes.EntityMods.CompositeType == "Concrete" then
													local Density = 2400
													CurrentRes:GetPhysicsObject():SetMass(math.Round(CurrentRes:GetPhysicsObject():GetVolume() / 61023.7 * Density))
													CurrentRes.DakLegitMass = CurrentRes:GetPhysicsObject():GetMass()
													self.ConcreteWeight = self.ConcreteWeight + CurrentRes:GetPhysicsObject():GetMass()
												elseif CurrentRes.EntityMods.CompositeType == "ERA" then
													self.ColdWar = 1
													local Density = 1732
													CurrentRes:GetPhysicsObject():SetMass(math.Round(CurrentRes:GetPhysicsObject():GetVolume() / 61023.7 * Density))
													CurrentRes.DakLegitMass = CurrentRes:GetPhysicsObject():GetMass()
													self.ERAWeight = self.ERAWeight + CurrentRes:GetPhysicsObject():GetMass()
													self.ERA[#self.ERA + 1] = CurrentRes
												end
											end
										end
									end

									if CurrentRes:GetPhysicsObject():IsValid() then
										Mass = Mass + CurrentRes:GetPhysicsObject():GetMass()
										if IsValid(CurrentRes:GetParent()) then ParentMass = ParentMass + CurrentRes:GetPhysicsObject():GetMass() end
										if CurrentRes:GetPhysicsObject():GetSurfaceArea() then
											if CurrentRes:GetPhysicsObject():GetMass() > 1 then SA = SA + CurrentRes:GetPhysicsObject():GetSurfaceArea() end
										else
											self.Tread[#self.Tread + 1] = CurrentRes
										end
									end
								end
							end

							if self.Clips and #self.Clips > 0 then
								self.DakOwner:ChatPrint((#self.Clips) .. " visclips detected, they are now physical clips, please save your vehicle and respawn to finalize.")
								for i = 1, #self.Clips do
									if self.Clips ~= nil and self.Clips[i] ~= nil then
										ProperClipping.AddClip(self.Clips[i].ent, self.Clips[i].n:Forward(), self.Clips[i].d, self.Clips[i].inside, true)
										if self.Clips[i].armor ~= nil then
											local SA = self.Clips[i].ent:GetPhysicsObject():GetSurfaceArea()
											local mass = math.ceil(((self.Clips[i].armor / 1 / (288 / SA)) / 7.8125) * 4.6311781, 0)
											self.Clips[i].ent.EntityMods.DakClippedArmor = self.Clips[i].armor
											if mass > 0 then
												SetMass(self.DakOwner, self.Clips[i].ent, {
													Mass = mass
												})

												self.Clips[i].ent:GetPhysicsObject():SetMass(mass)
												self.Clips[i].ent.DakLegitMass = mass
											end
										end
									end
								end
							end

							if IsValid(self.Gearbox) then
								self.Gearbox.TotalMass = Mass
								self.Gearbox.ParentMass = ParentMass
								self.Gearbox.PhysicalMass = Mass - ParentMass
							end

							if IsValid(self.Tread[1]) then
								if self.Tread[1]:GetPhysicsObject():GetMaterial() ~= "jeeptire" then
									for i = 1, table.Count(self.Tread) do
										self.Tread[i]:GetPhysicsObject():SetMaterial("jeeptire")
									end
								end
							end

							self.TotalMass = Mass
							self.ParMass = ParentMass
							self.PhysMass = Mass - ParentMass
							self.SurfaceArea = SA
							self.SizeMult = (SA / Mass) * 0.18
						end

						if self.recheckmass == nil or (self.recheckmass >= 0 and self.MassUpdate == 1) then
							--print("secondary run")
							local CurrentRes
							local Mass = 0
							local ParentMass = 0
							local SA = 0
							for i = 1, #self.Contraption do
								CurrentRes = self.Contraption[i]
								if CurrentRes ~= NULL and CurrentRes ~= nil and CurrentRes:IsValid() then
									local physobj = CurrentRes:GetPhysicsObject()
									if physobj:IsValid() then
										local physmass = physobj:GetMass()
										Mass = Mass + physmass
										if IsValid(CurrentRes:GetParent()) then ParentMass = ParentMass + physmass end
									end
								end
							end

							if IsValid(self.Gearbox) then
								self.Gearbox.TotalMass = Mass
								self.Gearbox.ParentMass = ParentMass
								self.Gearbox.PhysicalMass = Mass - ParentMass
							end

							self.TotalMass = Mass
							self.ParMass = ParentMass
							self.PhysMass = Mass - ParentMass
							self.recheckmass = 0
							self.MassUpdate = 0
						end

						self.recheckmass = self.recheckmass + 1
						if table.Count(self.HitBox) == 0 then
							WireLib.TriggerOutput(self, "Health", self.DakHealth)
							WireLib.TriggerOutput(self, "HealthPercent", (self.DakHealth / self.DakMaxHealth) * 100)
						end

						--SETUP HEALTHPOOL
						if table.Count(self.HitBox) == 0 and self.Contraption and (IsValid(self.Gearbox) or (self.TurretControls ~= nil and IsValid(self.TurretControls[1]))) then
							if #self.Contraption >= 1 then
								self.Remake = 0
								self.DakPooled = 1
								self.DakEngine = self
								self.Controller = self
								if #self.Contraption > 0 then
									local ContraptionCurrent
									self.HitBox = {}
									self.ERA = {}
									for i = 1, #self.Contraption do
										ContraptionCurrent = self.Contraption[i]
										if ContraptionCurrent.Controller == nil or ContraptionCurrent.Controller == NULL or ContraptionCurrent.Controller == self then
											if IsValid(ContraptionCurrent) then
												if (ContraptionCurrent.DakName == "Armor" and ContraptionCurrent:GetClass() == "prop_physics") or (ContraptionCurrent.DakName == nil and (ContraptionCurrent.EntityMods and ContraptionCurrent.EntityMods.IsERA ~= 1)) then
													if ContraptionCurrent:IsSolid() then
														self.HitBox[#self.HitBox + 1] = ContraptionCurrent
														ContraptionCurrent.Controller = self
														ContraptionCurrent.DakOwner = self.DakOwner
														ContraptionCurrent.DakPooled = 1
													end
												else
													if ContraptionCurrent.EntityMods and ContraptionCurrent.EntityMods.IsERA == 1 then
														self.ERA[#self.ERA + 1] = ContraptionCurrent
														ContraptionCurrent.Controller = self
														ContraptionCurrent.DakOwner = self.DakOwner
														ContraptionCurrent.DakPooled = 1
														ContraptionCurrent.DakHealth = 5
														ContraptionCurrent.DakMaxHealth = 5
													end
												end

												ContraptionCurrent.Controller = self
											end
										end
									end
								end

								self.HitBoxMass = 0
								for i = 1, table.Count(self.HitBox) do
									self.HitBoxMass = self.HitBoxMass + self.HitBox[i]:GetPhysicsObject():GetMass()
								end

								self.CurrentHealth = self.DakVolume
								self.DakMaxHealth = self.DakVolume
								for i = 1, table.Count(self.HitBox) do
									DTTE.SetupNewEnt(self.HitBox[i])
									self.HitBox[i].DakHealth = self.CurrentHealth
									self.HitBox[i].DakMaxHealth = self.CurrentHealth
									self.HitBox[i].Controller = self
									self.HitBox[i].DakOwner = self.DakOwner
									self.HitBox[i].DakPooled = 1
								end

								self.LastRemake = CurTime()
							end
						end

						if table.Count(self.HitBox) ~= 0 then
							self.DakActive = 1
						else
							self.DakActive = 0
						end

						--####################OPTIMIZE ZONE START###################--
						if selfTbl.DakActive == 1 and table.Count(selfTbl.HitBox) ~= 0 and selfTbl.CurrentHealth and table.Count(selfTbl.HitBox) > 0 then
							selfTbl.LivingCrew = 0
							if selfTbl.Crew and table.Count(selfTbl.Crew) > 0 then
								for i = 1, table.Count(selfTbl.Crew) do
									if not IsValid(selfTbl.Crew[i]) then
										table.remove(selfTbl.Crew, i)
									elseif selfTbl.Crew[i].DakDead ~= true then
										selfTbl.LivingCrew = selfTbl.LivingCrew + 1
									end
								end
							end

							WireLib.TriggerOutput(self, "Crew", selfTbl.LivingCrew)
							if selfTbl.Composites and table.Count(selfTbl.Composites) > 0 then
								local compositeStats = {
									NERA = {
										Modern = 1, --Very obviously should be a boolean
										CompKEMult = 9.2,
										CompCEMult = 18.4,
										Density = 2000,
										DakName = "NERA" --Composite type should honestly just be used instead but I'm preserving the original structure.
									},
									Stillbrew = {
										Modern = 1,
										CompKEMult = 23,
										CompCEMult = 27.6,
										Density = 5750,
										DakName = "Stillbrew"
									},
									Textolite = {
										ColdWar = 1,
										CompKEMult = 10.4,
										CompCEMult = 14,
										Density = 1850,
										DakName = "Textolite"
									},
									Concrete = {
										CompKEMult = 2.8,
										CompCEMult = 2.8,
										Density = 2400,
										DakName = "Concrete"
									},
									ERA = {
										ColdWar = 1,
										CompKEMult = 2.5,
										CompCEMult = 88.9,
										Density = 1732,
										DakName = "ERA",
										IsEra = 1
									}
								}

								for i = 1, table.Count(selfTbl.Composites) do
									if not IsValid(selfTbl.Composites[i]) then table.remove(selfTbl.Composites, i) end
									if selfTbl.Composites[i] ~= nil then
										selfTbl.Composites[i].IsComposite = 1
										local Density = 2000
										local KE = 9.2

										--The way the old code was set up made it possible for composite types not in the list to get through. This maintains that.
										local entityMods = selfTbl.Composites[i].EntityMods
										local compositeData = (entityMods and compositeStats[entityMods.CompositeType]) or {}

										KE = compositeData.CompKEMult or KE
										Density = compositeData.Density or Density

										entityMods.CompKEMult = compositeData.CompKEMult
										entityMods.CompCEMult = compositeData.CompCEMult
										entityMods.DakName = compositeData.DakName
										entityMods.IsEra = compositeData.IsEra

										selfTbl.Modern = (compositeData.Modern == 1 and 1) or selfTbl.Modern
										selfTbl.ColdWar = (compositeData.ColdWar == 1 and 1) or selfTbl.ColdWar

										local physObj = selfTbl.Composites[i]:GetPhysicsObject()
										local weightvalcomp = math.Round(physObj:GetVolume() / 61023.7 * Density)
										if physObj:GetMass() ~= weightvalcomp then
											physObj:SetMass(weightvalcomp)
											selfTbl.Composites[i].DakLegitMass = weightvalcomp
										end

										selfTbl.Composites[i].DakArmor = 10 * KE
									end
								end
							end
							if selfTbl.ERA then
								selfTbl.PhysEnabled = not(selfTbl.Base:GetPhysicsObject():IsMotionEnabled())

								if selfTbl.PhysEnabled ~= selfTbl.LastPhysEnabled and false then
									if selfTbl.PhysEnabled then
										selfTbl.ERA = {}
										for i = 1, #selfTbl.ERAInfoTable do
											local cur = selfTbl.ERAInfoTable[i]
											local eraplate = ents.Create("prop_physics")
											local parentent = ents.GetByIndex(cur.Parent)
											eraplate:SetModel(cur.Model)
											eraplate:SetPos(parentent:LocalToWorld(cur.LocalPos))
											eraplate:SetAngles(parentent:LocalToWorldAngles(cur.LocalAng))
											eraplate:SetMaterial(cur.Mat)
											eraplate:SetColor(cur.Col)
											eraplate:SetParent(parentent)
											eraplate.EntityMods = cur.EntityMods
											eraplate.DakName = "ERA"
											eraplate.Controller = self
											eraplate.DakOwner = selfTbl.DakOwner
											eraplate.DakPooled = 1
											eraplate.DakHealth = 5
											eraplate.DakMaxHealth = 5
											eraplate:PhysicsInit(SOLID_VPHYSICS)
											--eraplate:SetMoveType(MOVETYPE_NONE)
											eraplate:SetSolid(SOLID_VPHYSICS)
											eraplate:CPPISetOwner(selfTbl.DakOwner)
											selfTbl.ERA[#selfTbl.ERA + 1] = eraplate
										end

										net.Start("daktankcoreeraremove")
										net.WriteEntity(self)
										net.Broadcast()
										for i = 1, #selfTbl.ERAHandlers do
											selfTbl.ERAHandlers[i]:SetMoveType(MOVETYPE_NONE)
											selfTbl.ERAHandlers[i]:PhysicsInit(SOLID_NONE)
											selfTbl.ERAHandlers[i]:Remove()
										end

										selfTbl.ERAHandlers = {}
									else
										selfTbl.ERAInfoTable = {}
										for i = 1, table.Count(selfTbl.ERA) do
											local cur = selfTbl.ERA[i]
											local currentERA = {}
											currentERA.Parent = cur:GetParent():EntIndex()
											if not IsValid(cur:GetParent().ERAHandler) then
												cur:GetParent().ERAHandler = ents.Create("prop_physics")
												cur:GetParent().ERAHandler:SetAngles(cur:GetParent():GetForward():Angle())
												cur:GetParent().ERAHandler:SetPos(cur:GetParent():GetPos())
												cur:GetParent().ERAHandler:SetMoveType(MOVETYPE_NONE)
												cur:GetParent().ERAHandler:PhysicsInit(SOLID_NONE)
												cur:GetParent().ERAHandler:SetParent(cur:GetParent())
												cur:GetParent().ERAHandler:SetModel("models/props_junk/PopCan01a.mdl")
												cur:GetParent().ERAHandler:DrawShadow(false)
												cur:GetParent().ERAHandler:SetColor(Color(255, 255, 255, 0))
												cur:GetParent().ERAHandler:SetRenderMode(RENDERMODE_TRANSCOLOR)
												cur:GetParent().ERAHandler:Spawn()
												cur:GetParent().ERAHandler:Activate()
												cur:GetParent().ERAHandler:SetMoveType(MOVETYPE_NONE)
												cur:GetParent().ERAHandler:PhysicsInit(SOLID_NONE)
												ERAHandler:CPPISetOwner(selfTbl.DakOwner)
												if selfTbl.ERAHandlers == nil then selfTbl.ERAHandlers = {} end
												selfTbl.ERAHandlers[#selfTbl.ERAHandlers + 1] = cur:GetParent().ERAHandler
											end

											currentERA.Model = cur:GetModel()
											currentERA.LocalPos = cur:GetParent():WorldToLocal(cur:GetPos())
											currentERA.LocalAng = cur:GetParent():WorldToLocalAngles(cur:GetAngles())
											currentERA.Mat = cur:GetMaterial()
											currentERA.Col = cur:GetColor()
											currentERA.Mass = cur:GetPhysicsObject():GetMass()
											currentERA.EntityMods = cur.EntityMods
											local a, b = cur:GetPhysicsObject():GetAABB()
											a:Rotate(cur:GetAngles())
											b:Rotate(cur:GetAngles())
											currentERA.mins = a
											currentERA.maxs = b
											cur:Remove()
											selfTbl.ERAInfoTable[#selfTbl.ERAInfoTable + 1] = currentERA
										end

										for j = 1, #selfTbl.ERAHandlers do
											local VectorTables = {}
											local Mass = 0
											for i = 1, #selfTbl.ERAInfoTable do
												Mass = Mass + selfTbl.ERAInfoTable[i].Mass
												if ents.GetByIndex(selfTbl.ERAInfoTable[i].Parent) == selfTbl.ERAHandlers[j]:GetParent() then
													local addition = selfTbl.ERAInfoTable[i].LocalPos
													local min = selfTbl.ERAInfoTable[i].mins + addition
													local max = selfTbl.ERAInfoTable[i].maxs + addition
													VectorTables[#VectorTables + 1] = {Vector(min.y, min.y, min.z), Vector(min.x, min.y, max.z), Vector(min.x, max.y, min.z), Vector(min.x, max.y, max.z), Vector(max.x, min.y, min.z), Vector(max.x, min.y, max.z), Vector(max.x, max.y, min.z), Vector(max.x, max.y, max.z)}
												end
											end

											selfTbl.ERAHandlers[j]:PhysicsDestroy()
											selfTbl.ERAHandlers[j]:PhysicsInitMultiConvex(VectorTables)
											selfTbl.ERAHandlers[j]:SetSolid(SOLID_VPHYSICS)
											selfTbl.ERAHandlers[j]:SetMoveType(MOVETYPE_NONE)
											selfTbl.ERAHandlers[j]:EnableCustomCollisions(true)
											selfTbl.ERAHandlers[j].IsEraHandler = true
											selfTbl.ERAHandlers[j].IsComposite = 1
											selfTbl.ERAHandlers[j].EntityMods = {}
											selfTbl.ERAHandlers[j].EntityMods.CompKEMult = 2.5
											selfTbl.ERAHandlers[j].EntityMods.CompCEMult = 88.9
											selfTbl.ERAHandlers[j].DakArmor = 10 * selfTbl.ERAHandlers[j].EntityMods.CompKEMult
											selfTbl.ERAHandlers[j].DakHealth = 9999999
											selfTbl.ERAHandlers[j].DakMaxHealth = 9999999
											selfTbl.ERAHandlers[j].EntityMods.IsERA = 1
											selfTbl.ERAHandlers[j].EntityMods.DakName = "ERA HANDLER"
											selfTbl.ERAHandlers[j]:GetPhysicsObject():SetMass(Mass)
											selfTbl.ERAHandlers[j].DakLegitMass = Mass
										end

										for i = 1, math.ceil(#selfTbl.ERAInfoTable / 50) do
											local tablesegment = {}
											for j = 1 + ((i - 1) * 50), 50 + ((i - 1) * 50) do
												tablesegment[#tablesegment + 1] = selfTbl.ERAInfoTable[j]
											end

											net.Start("daktankcoreera")
											net.WriteEntity(self)
											net.WriteString(util.TableToJSON(tablesegment))
											net.Broadcast()
										end

										selfTbl.ERA = {}
									end

									selfTbl.LastPhysEnabled = selfTbl.PhysEnabled
								end

								if table.Count(selfTbl.ERA) > 0 then
									local effectdata
									local ExpSounds = {"daktanks/eraexplosion.mp3"}
									local EntMod
									for i = 1, table.Count(selfTbl.ERA) do
										if not IsValid(selfTbl.ERA[i]) then table.remove(selfTbl.ERA, i) end
										if selfTbl.ERA[i] ~= nil and selfTbl.ERA[i] ~= NULL then
											EntMod = selfTbl.ERA[i].EntityMods
											if selfTbl.ERA[i].IsComposite ~= 1 then selfTbl.ERA[i].IsComposite = 1 end
											if EntMod.CompKEMult ~= 2.5 then EntMod.CompKEMult = 2.5 end
											if EntMod.CompCEMult ~= 88.9 then EntMod.CompCEMult = 88.9 end
											if selfTbl.ERA[i].DakName ~= "ERA" then selfTbl.ERA[i].DakName = "ERA" end
											if selfTbl.ERA[i].IsERA ~= 1 then selfTbl.ERA[i].IsERA = 1 end
											if selfTbl.ColdWar ~= 1 then selfTbl.ColdWar = 1 end
											if selfTbl.ERA[i].DakHealth == nil then selfTbl.ERA[i].DakHealth = 5 end
											if selfTbl.ERA[i].DakHealth <= 0 then
												effectdata = EffectData()
												effectdata:SetOrigin(selfTbl.ERA[i]:GetPos())
												effectdata:SetEntity(self)
												effectdata:SetAttachment(1)
												effectdata:SetMagnitude(.5)
												effectdata:SetScale(50)
												effectdata:SetNormal(Vector(0, 0, 0))
												util.Effect("daktescalingexplosionold", effectdata, true, true)
												sound.Play(ExpSounds[math.random(1, #ExpSounds)], selfTbl.ERA[i]:GetPos(), 100, 100, 1)
												selfTbl.ERA[i]:DTExplosion(selfTbl.ERA[i]:GetPos(), 25, 50, 40, 5, selfTbl.DakOwner)
												selfTbl.ERA[i]:Remove()
											end
										end
									end

									for i = 1, table.Count(selfTbl.ERA) do
										if IsValid(selfTbl.ERA[i]) and selfTbl.ERA[i].EntityMods then
											if selfTbl.ERA[i].EntityMods.CompositeType == "ERA" then
												selfTbl.ColdWar = 1
												selfTbl.ERA[i].EntityMods.CompKEMult = 2.5
												selfTbl.ERA[i].EntityMods.CompCEMult = 88.9
												selfTbl.ERA[i].EntityMods.DakName = "ERA"
												selfTbl.ERA[i].EntityMods.IsERA = 1
											end

											local physObj = selfTbl.ERA[i]:GetPhysicsObject()
											local weightval = math.Round(physObj:GetVolume() / 61023.7 * 1732)
											if physObj:GetMass() ~= weightval then
												physObj:SetMass(weightval)
												selfTbl.ERA[i].DakLegitMass = weightval
											end

											selfTbl.ERA[i].DakArmor = 2.5
										end
									end
								end
							end

							if selfTbl.DETAIL then
								selfTbl.PhysEnabled = not(self.Base:GetPhysicsObject():IsMotionEnabled())

								if selfTbl.PhysEnabled ~= selfTbl.LastPhysEnabled then
									if selfTbl.PhysEnabled then
										selfTbl.DETAIL = {}
										for i = 1, #selfTbl.DetailInfoTable do
											local cur = selfTbl.DetailInfoTable[i]
											local detailpiece = ents.Create("prop_physics")
											local parentent = ents.GetByIndex(cur.Parent)
											detailpiece:SetModel(cur.Model)
											detailpiece:SetPos(parentent:LocalToWorld(cur.LocalPos))
											detailpiece:SetAngles(parentent:LocalToWorldAngles(cur.LocalAng))
											detailpiece:SetMaterial(cur.Mat)
											detailpiece:SetBodyGroups(cur.Bodygroups)
											detailpiece:SetSkin(cur.Skin)
											for j = 1, #cur.SubMaterials do
												detailpiece:SetSubMaterial(j, cur.SubMaterials[j])
											end

											detailpiece:SetColor(cur.Col)
											detailpiece:SetRenderMode(cur.RenderMode)
											detailpiece:SetParent(parentent)
											detailpiece.EntityMods = cur.EntityMods
											--detailpiece.ClipData = cur.ClipData
											detailpiece:PhysicsInit(SOLID_VPHYSICS)
											--detailpiece:SetMoveType(MOVETYPE_NONE)
											detailpiece:SetSolid(SOLID_VPHYSICS)
											detailpiece:CPPISetOwner(selfTbl.DakOwner)
											if cur.ClipData ~= nil then
												for j = 1, #cur.ClipData do
													ProperClipping.AddClip(detailpiece, cur.ClipData[j].n:Forward(), cur.ClipData[j].d, cur.ClipData[j].inside, true)
												end
											end

											selfTbl.DETAIL[#selfTbl.DETAIL + 1] = detailpiece
										end

										net.Start("daktankcoredetailremove")
										net.WriteFloat(self:EntIndex())
										net.Broadcast()
									else
										--Crew checking
										local crewJobs = {"Gunner", "Driver", "Loader"}

										for i, crew in ipairs(selfTbl.Crew) do
											--get angle and kill if upwards direction is over 45 degrees from upwards compared to baseplate
											if crew:IsValid() and IsValid(selfTbl.ForwardEnt) then
												local crewang = selfTbl.ForwardEnt:WorldToLocalAngles(crew:GetAngles())
												local a = crewang:Up()
												local b = selfTbl.Forward:Angle():Up()
												local ans = math.acos(a:Dot(b) / (a:Length() * b:Length()))
												if math.Round(math.deg(ans), 2) > 45 then
													crew.DakHealth = 0
													if crew.DakOwner:IsPlayer() then
														crew.DakOwner:ChatPrint( (crewJobs[crew.Job] or "Passenger") .. " Angle Invalid, Ejecting!" )
													end

													crew:SetMaterial("models/flesh")
													crew.DakDead = true
													crew:Remove()
												end
											end

											--kill if clipping other crew

											--This doesn't appear to work, so i've commented it out for now.
											--[[
											if self.Crew[i]:IsValid() then
												local bounds = self.Crew[i]:GetModelBounds()
												bounds = math.min(math.abs(bounds.x), math.abs(bounds.y), math.abs(bounds.z)) * 1.9
												for j = 1, #self.Crew do
													if self.Crew[i] ~= self.Crew[j] then
														if self.Crew[i]:GetPos():Distance(self.Crew[j]:GetPos()) < bounds then
															self.Crew[i].DakHealth = 0
															if self.Crew[i].DakOwner:IsPlayer() then
																if self.Crew[i].Job == 1 then
																	self.Crew[i].DakOwner:ChatPrint("Gunner Clipping Crew, Ejecting!")
																elseif self.Crew[i].Job == 2 then
																	self.Crew[i].DakOwner:ChatPrint("Driver Clipping Crew, Ejecting!")
																elseif self.Crew[i].Job == 3 then
																	self.Crew[i].DakOwner:ChatPrint("Loader Clipping Crew, Ejecting!")
																else
																	self.Crew[i].DakOwner:ChatPrint("Passenger Clipping Crew, Ejecting!")
																end
															end

															self.Crew[i]:SetMaterial("models/flesh")
															self.Crew[i].DakDead = true
															self.Crew[i]:Remove()
														end
													end
												end
											end
											--]]
										end

										selfTbl.DetailInfoTable = {}
										for i = 1, table.Count(selfTbl.DETAIL) do
											local cur = selfTbl.DETAIL[i]
											if IsValid(cur) then
												local currentDetail = {}
												local curparent = cur
												if IsValid(cur:GetParent()) then
													curparent = cur:GetParent()
													if IsValid(cur:GetParent():GetParent()) then curparent = cur:GetParent():GetParent() end
												end

												currentDetail.Parent = curparent:EntIndex()
												currentDetail.Model = cur:GetModel()
												currentDetail.LocalPos = curparent:WorldToLocal(cur:GetPos())
												currentDetail.LocalAng = curparent:WorldToLocalAngles(cur:GetAngles())
												currentDetail.Mat = cur:GetMaterial()
												currentDetail.Col = cur:GetColor()
												currentDetail.RenderMode = cur:GetRenderMode()
												currentDetail.EntityMods = cur.EntityMods
												currentDetail.ClipData = cur.ClipData
												currentDetail.SubMaterials = {}
												local bodygroupstring = ""
												if #cur:GetBodyGroups() > 0 then
													for j = 0, #cur:GetBodyGroups() do
														bodygroupstring = bodygroupstring .. cur:GetBodygroup(j)
													end
												end

												currentDetail.Bodygroups = bodygroupstring
												currentDetail.Skin = cur:GetSkin()
												for j = 0, 31 do
													currentDetail.SubMaterials[j] = cur:GetSubMaterial(j)
												end

												cur:Remove()
												selfTbl.DetailInfoTable[#selfTbl.DetailInfoTable + 1] = currentDetail
											end
										end

										for i = 1, math.ceil(#selfTbl.DetailInfoTable / 50) do
											local tablesegment = {}
											for j = 1 + ((i - 1) * 50), 50 + ((i - 1) * 50) do
												tablesegment[#tablesegment + 1] = selfTbl.DetailInfoTable[j]
											end

											net.Start("daktankcoredetail")
											net.WriteFloat(self:EntIndex())
											net.WriteString(util.TableToJSON(tablesegment))
											net.Broadcast()
										end

										selfTbl.DETAIL = {}
									end

									selfTbl.LastPhysEnabled = selfTbl.PhysEnabled
								end
							end

							selfTbl.DamageCycle = 0
							selfTbl.LastDamagedBy = NULL
							if selfTbl.DakHealth < selfTbl.CurrentHealth then
								selfTbl.DamageCycle = selfTbl.DamageCycle + (selfTbl.CurrentHealth - selfTbl.DakHealth)
								selfTbl.DakLastDamagePos = selfTbl.DakLastDamagePos
							end

							selfTbl.Remake = 0
							selfTbl.LastCurMass = selfTbl.CurMass
							selfTbl.CurMass = 0
							for i = 1, table.Count(selfTbl.HitBox) do
								if selfTbl.HitBox[i].Controller ~= self then selfTbl.Remake = 1 end
								if selfTbl.Remake == 1 then
									if selfTbl.HitBox[i].Controller == self then
										selfTbl.HitBox[i].DakPooled = 0
										selfTbl.HitBox[i].Controller = nil
										selfTbl.HitBox[i].DakLegit = nil
									end
								end

								if selfTbl.LastCurMass > 0 then
									if selfTbl.HitBox[i].DakHealth then
										if selfTbl.HitBox[i].DakHealth < selfTbl.CurrentHealth then
											if selfTbl.HitBox[i].EntityMods.IsERA == 1 then
												table.RemoveByValue(selfTbl.Composites, NULL)
												table.RemoveByValue(selfTbl.HitBox, NULL)
											end

											selfTbl.DamageCycle = selfTbl.DamageCycle + (selfTbl.CurrentHealth - selfTbl.HitBox[i].DakHealth)
											selfTbl.DakLastDamagePos = selfTbl.HitBox[i].DakLastDamagePos
											selfTbl.LastDamagedBy = selfTbl.HitBox[i].LastDamagedBy
										end
									end
								end

								if selfTbl.Remake == 1 then
									selfTbl.HitBox = {}
									selfTbl.Remake = 0
									break
								end

								if selfTbl.HitBox[i] ~= NULL then if selfTbl.HitBox[i].Controller == self then if selfTbl.HitBox[i]:IsSolid() then selfTbl.CurMass = selfTbl.CurMass + selfTbl.HitBox[i]:GetPhysicsObject():GetMass() end end end
							end

							if selfTbl.CurMass <= selfTbl.LastCurMass and selfTbl.DamageCycle > 0 then
								if selfTbl.LastRemake + 3 > CurTime() then selfTbl.DamageCycle = 0 end
								selfTbl.CurrentHealth = selfTbl.CurrentHealth - selfTbl.DamageCycle
							end

							if selfTbl.CurrentHealth >= selfTbl.DakMaxHealth then
								selfTbl.DakMaxHealth = selfTbl.DakVolume
								selfTbl.CurrentHealth = selfTbl.DakVolume
							end

							for i = 1, #selfTbl.Components do
								DakKillNotSolid(selfTbl.Components[i])
							end

							for i = 1, table.Count(selfTbl.HitBox) do
								if selfTbl.CurrentHealth >= selfTbl.DakMaxHealth then selfTbl.HitBox[i].DakMaxHealth = selfTbl.DakVolume end
								selfTbl.HitBox[i].DakHealth = selfTbl.CurrentHealth
							end

							selfTbl.DakHealth = selfTbl.CurrentHealth
							local curvel = selfTbl.Base:GetVelocity()
							if selfTbl.LastVel == nil then selfTbl.LastVel = curvel end
							if math.abs(curvel:Length() - selfTbl.LastVel:Length()) > 1000 then
								local crewJobs = {"Gunner", "Driver", "Loader"}

								for _, crew in ipairs(selfTbl.Crew) do
									crew.DakHealth = crew.DakHealth - ((curvel:Distance(selfTbl.LastVel) - 1000) / 100)
									if crew.DakHealth <= 0 then
										if crew.DakOwner:IsPlayer() then
											crew.DakOwner:ChatPrint( (crewJobs[crew.Job] or "Passenger") .. "Killed!")
										end

										crew:SetMaterial("models/flesh")
										crew.DakDead = true
									end
								end
							end

							selfTbl.LastVel = curvel
							WireLib.TriggerOutput(self, "Health", selfTbl.DakHealth)
							WireLib.TriggerOutput(self, "HealthPercent", (selfTbl.DakHealth / selfTbl.DakMaxHealth) * 100)
							--####################OPTIMIZE ZONE END###################--
							if selfTbl.DakHealth then
								local hasdriver = false
								for _, seat in ipairs(selfTbl.Seats) do
									hasdriver = hasdriver or (IsValid(seat) and IsValid(seat:GetDriver()))
								end

								if (selfTbl.DakHealth <= 0 or #selfTbl.Crew < 2 or selfTbl.LivingCrew <= math.max(#selfTbl.Crew - 3, 1) or (gmod.GetGamemode().Name == "DakTank" and selfTbl.LegalUnfreeze ~= true)) and selfTbl.Base:GetPhysicsObject():IsMotionEnabled() or (gmod.GetGamemode().Name == "DakTank" and hasdriver and not selfTbl.Base:GetPhysicsObject():IsMotionEnabled()) then
									local DeathSounds = {"daktanks/closeexp1.mp3", "daktanks/closeexp2.mp3", "daktanks/closeexp3.mp3"}
									selfTbl.RemoveTurretList = {}
									if math.random(1, 100) <= self:GetTurretPop() then
										for j = 1, #self.TurretControls do
											if IsValid(self.TurretControls[j]) then
												table.RemoveByValue(self.Contraption, self.TurretControls[j].TurretBase)
												if IsValid(self.TurretControls[j].TurretBase) then
													self.TurretControls[j].TurretBase:SetMaterial("models/props_buildings/plasterwall021a")
													self.TurretControls[j].TurretBase:SetColor(Color(100, 100, 100, 255))
													--self.TurretControls[j]:SetCustomCollisionCheck( false )
													self.TurretControls[j].TurretBase:SetCollisionGroup(COLLISION_GROUP_WORLD)
													--self.TurretControls[j].TurretBase:EmitSound( DeathSounds[math.random(1,#DeathSounds)], 100, 100, 0.25, 3)
													sound.Play(DeathSounds[math.random(1, #DeathSounds)], self.TurretControls[j].TurretBase:GetPos(), 100, 100, 0.25)
													if math.random(0, 9) == 0 then self.TurretControls[j].TurretBase:Ignite(25, 1) end
													if IsValid(self) then if IsValid(self:GetParent()) then if IsValid(self.Base) then constraint.RemoveAll(self.Base) end end end
													for l = 1, #self.TurretControls[j].Turret do
														if self.TurretControls[j].Turret[l] ~= self.TurretControls[j].TurretBase and self.TurretControls[j].Turret[l] ~= self.TurretControls[j].turretaimer then
															if IsValid(self.TurretControls[j].Turret[l]) then
																table.RemoveByValue(self.Contraption, self.TurretControls[j].Turret[l])
																self.TurretControls[j].Turret[l]:SetParent(self.TurretControls[j].TurretBase, -1)
																self.TurretControls[j].Turret[l]:SetMoveType(MOVETYPE_NONE)
																self.TurretControls[j].Turret[l]:SetMaterial("models/props_buildings/plasterwall021a")
																self.TurretControls[j].Turret[l]:SetColor(Color(100, 100, 100, 255))
																--self.TurretControls[j].Turret[l]:SetCustomCollisionCheck( false )
																self.TurretControls[j].Turret[l]:SetCollisionGroup(COLLISION_GROUP_WORLD)
																if self.TurretControls[j].Turret[l]:GetModel() == "models/daktanks/machinegun100mm.mdl" then self.TurretControls[j].Turret[l]:Remove() end
																--self.TurretControls[j].Turret[l]:EmitSound( DeathSounds[math.random(1,#DeathSounds)], 100, 100, 0.25, 3)
																sound.Play(DeathSounds[math.random(1, #DeathSounds)], self.TurretControls[j].Turret[l]:GetPos(), 100, 100, 0.25)
																if self.TurretControls[j].Turret[l]:IsVehicle() then
																	if IsValid(self.TurretControls[j].Turret[l]:GetDriver()) then
																		self.TurretControls[j].Turret[l]:GetDriver():SetNoDraw(false)
																		self.TurretControls[j].Turret[l]:GetDriver():TakeDamage(1000000, self.LastDamagedBy, self)
																		--self.TurretControls[j].Turret[l]:GetDriver():Kill()
																	end

																	self.TurretControls[j].Turret[l]:Remove()
																end

																if math.random(0, 9) == 0 then self.TurretControls[j].Turret[l]:Ignite(25, 1) end
																if self.TurretControls[j].Turret[l]:GetClass() == "dak_teammo" then if math.random(0, 1) == 0 then self.TurretControls[j].Turret[l]:Ignite(25, 1) end end
																if self.TurretControls[j].Turret[l]:GetClass() == "sent_prop2mesh" then self.TurretControls[j].Turret[l]:Remove() end
															end
														end
													end

													local TurretPhys = ents.Create("prop_physics")
													TurretPhys:SetAngles(self.TurretControls[j].turretaimer:GetAngles())
													TurretPhys:SetPos(self.TurretControls[j].turretaimer:GetPos())
													TurretPhys:SetModel(self.TurretControls[j].TurretBase:GetModel())
													TurretPhys:SetParent(TurretPhys)
													TurretPhys:DrawShadow(false)
													TurretPhys:SetColor(Color(255, 255, 255, 0))
													TurretPhys:SetRenderMode(RENDERMODE_TRANSCOLOR)
													TurretPhys.DakIsTread = true
													TurretPhys:Spawn()
													TurretPhys:Activate()
													--TurretPhys:SetMoveType(MOVETYPE_VPHYSICS)
													--TurretPhys:PhysicsInit(SOLID_VPHYSICS)
													self.TurretControls[j].turretaimer:SetParent(TurretPhys)
													TurretPhys:SetAngles(self.TurretControls[j].turretaimer:GetAngles() + Angle(math.Rand(-15, 15), math.Rand(-15, 15), math.Rand(-15, 15)))
													TurretPhys:GetPhysicsObject():SetMass(self.TurretControls[j].GunMass)
													TurretPhys.DakLegitMass = self.TurretControls[j].GunMass
													TurretPhys:GetPhysicsObject():ApplyForceCenter(TurretPhys:GetUp() * 2500 * self:GetTurretPopForceMult() * TurretPhys:GetPhysicsObject():GetMass())
													TurretPhys:GetPhysicsObject():AddAngleVelocity(VectorRand() * 500 * self:GetTurretPopForceMult())
													self.RemoveTurretList[#self.RemoveTurretList + 1] = self.TurretControls[j].TurretBase
													self.RemoveTurretList[#self.RemoveTurretList + 1] = self.TurretControls[j].turretaimer
													self.RemoveTurretList[#self.RemoveTurretList + 1] = TurretPhys
												end
											end
										end
									end

									for i = 1, #self.Contraption do
										if IsValid(self.Contraption[i]) then
											if self.Contraption[i]:GetModel() == "models/daktanks/machinegun100mm.mdl" or self.Contraption[i]:GetClass() == "sent_prop2mesh" then
												self.Contraption[i]:Remove()
											else
												if self.Contraption[i].DakPooled == 0 or self.Contraption[i]:GetParent() == self:GetParent() or self.Contraption[i].Controller == self then
													self.Contraption[i].DakLastDamagePos = self.DakLastDamagePos
													if self.Contraption[i] ~= self.Base and self.Contraption[i] ~= self:GetParent() and self.Contraption[i] ~= self and self.Contraption[i].turretaimer ~= true then
														if math.random(1, 6) > 1 then
															if self.Contraption[i]:GetClass() == "dak_tegearbox" or self.Contraption[i]:GetClass() == "dak_tegearboxnew" or self.Contraption[i]:GetClass() == "dak_turretcontrol" or self.Contraption[i]:GetClass() == "gmod_wire_expression2" then
																self.salvage = ents.Create("dak_tesalvage")
																if not IsValid(self.salvage) then return end
																if self.Contraption[i]:GetClass() == "dak_crew" then
																	if self.Contraption[i].DakHealth <= 0 then
																		for i = 1, 15 do
																			util.Decal("Blood", self.Contraption[i]:GetPos(), self.Contraption[i]:GetPos() + (VectorRand() * 500), self.Contraption[i])
																		end
																	end
																end

																self.salvage.DakModel = self.Contraption[i]:GetModel()
																self.salvage:SetPos(self.Contraption[i]:GetPos())
																self.salvage:SetAngles(self.Contraption[i]:GetAngles())
																self.salvage:SetModelScale(self.Contraption[i]:GetModelScale())
																self.salvage:Spawn()
																self.Contraption[i]:Remove()
															else
																constraint.RemoveAll(self.Contraption[i])
																self.Contraption[i]:SetParent(self:GetParent(), -1)
																self.Contraption[i]:SetMoveType(MOVETYPE_NONE)
																self.Contraption[i]:SetMaterial("models/props_buildings/plasterwall021a")
																self.Contraption[i]:SetColor(Color(100, 100, 100, 255))
																--self.Contraption[i]:SetCustomCollisionCheck( false )
																self.Contraption[i]:SetCollisionGroup(COLLISION_GROUP_WORLD)
																--self.Contraption[i]:EmitSound( DeathSounds[math.random(1,#DeathSounds)], 100, 100, 0.25, 3)
																sound.Play(DeathSounds[math.random(1, #DeathSounds)], self.Contraption[i]:GetPos(), 100, 100, 0.25)
																if math.random(0, 9) == 0 then self.Contraption[i]:Ignite(25, 1) end
																if self.Contraption[i]:GetClass() == "dak_teammo" then if math.random(0, 1) == 0 then self.Contraption[i]:Ignite(25, 1) end end
															end
														else
															self.salvage = ents.Create("dak_tesalvage")
															if not IsValid(self.salvage) then return end
															self.salvage.launch = 1
															if self.Contraption[i]:GetClass() == "dak_crew" then
																if self.Contraption[i].DakHealth <= 0 then
																	for j = 1, 15 do
																		util.Decal("Blood", self.Contraption[i]:GetPos(), self.Contraption[i]:GetPos() + (VectorRand() * 500), self.Contraption[i])
																	end
																end
															end

															self.salvage.DakModel = self.Contraption[i]:GetModel()
															self.salvage:SetPos(self.Contraption[i]:GetPos())
															self.salvage:SetAngles(self.Contraption[i]:GetAngles())
															self.salvage:SetModelScale(self.Contraption[i]:GetModelScale())
															self.salvage:Spawn()
															self.Contraption[i]:Remove()
														end

														if self.Contraption[i]:IsVehicle() then
															if IsValid(self.Contraption[i]:GetDriver()) then
																self.Contraption[i]:GetDriver():SetNoDraw(false)
																self.Contraption[i]:GetDriver():TakeDamage(1000000, self.LastDamagedBy, self)
																--self.Contraption[i]:GetDriver():Kill()
															end

															self.Contraption[i]:Remove()
														end
													end
												end
											end
										end
									end

									self.Base:GetPhysicsObject():EnableGravity(true)
									self.Dead = 1
									hook.Run("DakTank_TankKilled", self, self.LastDamagedBy)
									self.DeathTime = CurTime()
									net.Start("daktankcoredie")
									net.WriteFloat(self:EntIndex())
									net.Broadcast()
									local effectdata = EffectData()
									effectdata:SetOrigin(self.Base:GetPos())
									effectdata:SetEntity(self)
									effectdata:SetAttachment(1)
									effectdata:SetMagnitude(.5)
									effectdata:SetNormal(Vector(0, 0, -1))
									effectdata:SetScale(math.Clamp(self.DakMaxHealth * 0.04, 100, 500))
									util.Effect("daktescalingexplosionold", effectdata)
								end
							else
								self:Remove()
							end
						end
					else
						if self.DeathTime then
							if self.DeathTime + 30 < CurTime() then
								self.AutoRemoved = true
								for j = 1, #self.RemoveTurretList do
									if IsValid(self.RemoveTurretList[j]) then self.RemoveTurretList[j]:Remove() end
								end

								if IsValid(self) then self:Remove() end
								if IsValid(self:GetParent():Remove()) then self:GetParent():Remove() end
								if IsValid(self.Base:Remove()) then self.Base:Remove() end
							end
						end
					end
				else
					if self.SpawnTime + 30 < CurTime() then self.DakOwner:PrintMessage(HUD_PRINTTALK, "Tank Core Error: Gate that tank core is parented to is not parented, please parent it to the baseplate.") end
				end
			else
				if self.SpawnTime + 30 < CurTime() then self.DakOwner:PrintMessage(HUD_PRINTTALK, "Tank Core Error: Tank core is not parented to anything, please parent it to a gate.") end
			end
		end

		selfTbl.SlowThinkTime = CurTime()
	end

	--do collisions
	if selfTbl.HitBoxMins ~= nil and selfTbl.HitBoxMaxs ~= nil then
		local smallest = math.min(math.abs(selfTbl.HitBoxMins.x), math.abs(selfTbl.HitBoxMins.y), math.abs(selfTbl.HitBoxMaxs.x), math.abs(selfTbl.HitBoxMaxs.y))
		if IsValid(selfTbl.Base) and IsValid(selfTbl.ForwardEnt) then
			local collisionstrace = util.TraceHull({
				start = selfTbl.ForwardEnt:GetPos(),
				endpos = selfTbl.ForwardEnt:GetPos() + (selfTbl.Base:GetPhysicsObject():GetVelocity() * 0.2),
				mins = Vector(-smallest, -smallest, selfTbl.HitBoxMins.z),
				maxs = Vector(smallest, smallest, selfTbl.HitBoxMaxs.z),
				mask = MASK_SOLID,
				filter = selfTbl.Contraption
			})

			DakTankCollisions(collisionstrace.Entity, selfTbl.Base, collisionstrace.HitPos)
		end
	end

	self:NextThink(CurTime() + 0.1)
	return true
end

function ENT:PreEntityCopy()
	local info = {}
	local CompositesIDs = {}
	if self.Composites ~= nil then
		if table.Count(self.Composites) > 0 then
			for i = 1, table.Count(self.Composites) do
				if self.Composites[i] ~= nil then table.insert(CompositesIDs, self.Composites[i]:EntIndex()) end
			end
		end

		info.CompositesCount = table.Count(self.Composites)
	end

	local ERAIDs = {}
	if self.ERA ~= nil then
		if table.Count(self.ERA) > 0 then
			for i = 1, table.Count(self.ERA) do
				if self.ERA[i] ~= nil then table.insert(ERAIDs, self.ERA[i]:EntIndex()) end
			end
		end

		info.ERACount = table.Count(self.ERA)
	end

	local DupeClips = {}
	if self.Contraption ~= nil then
		if table.Count(self.Contraption) > 0 then
			for i = 1, #self.Contraption do
				local CurrentRes = self.Contraption[i]
				if CurrentRes ~= NULL and CurrentRes ~= nil then
					local physobj = CurrentRes:GetPhysicsObject()
					if CurrentRes.EntityMods ~= nil then
						if CurrentRes.EntityMods.DakClippedArmor ~= nil then
							local clip = {}
							clip.ID = CurrentRes:EntIndex()
							clip.Armor = CurrentRes.DakArmor
							DupeClips[#DupeClips + 1] = clip
						else
							CurrentRes.EntityMods.DakClippedArmor = CurrentRes.DakArmor
							local clip = {}
							clip.ID = CurrentRes:EntIndex()
							clip.Armor = CurrentRes.DakArmor
							DupeClips[#DupeClips + 1] = clip
						end
					end
				end
			end
		end
	end

	info.DakName = self.DakName
	info.DakHealth = self.DakHealth
	info.DakMaxHealth = self.DakBaseMaxHealth
	info.DakMass = self.DakMass
	info.DakOwner = self.DakOwner
	duplicator.StoreEntityModifier(self, "DakTek", info)
	duplicator.StoreEntityModifier(self, "DTComposites", CompositesIDs)
	duplicator.StoreEntityModifier(self, "DTERA", ERAIDs)
	duplicator.StoreEntityModifier(self, "DTClips", DupeClips)
	--Wire dupe info
	self.BaseClass.PreEntityCopy(self)
end

function ENT:PostEntityPaste(Player, Ent, CreatedEntities)
	self.dupespawned = true
	if Ent.EntityMods and Ent.EntityMods.DakTek then
		if Ent.EntityMods.DakTek.CompositesCount == nil then
			self.NewComposites = {}
			if Ent.EntityMods.DTComposites then
				for i = 1, table.Count(Ent.EntityMods.DTComposites) do
					self.Ent = CreatedEntities[Ent.EntityMods.DTComposites[i]]
					if self.Ent and IsValid(self.Ent) then table.insert(self.NewComposites, self.Ent) end
				end
			end

			self.Composites = self.NewComposites
		else
			if Ent.EntityMods.DakTek.CompositesCount > 0 then
				self.NewComposites = {}
				if Ent.EntityMods.DTComposites then
					for i = 1, Ent.EntityMods.DakTek.CompositesCount do
						local hitEnt = CreatedEntities[Ent.EntityMods.DTComposites[i]]
						if IsValid(hitEnt) then table.insert(self.NewComposites, hitEnt) end
					end
				end

				self.Composites = self.NewComposites
			else
				self.Composites = {}
			end
		end

		if Ent.EntityMods.DakTek.ERACount == nil then
			self.NewERA = {}
			if Ent.EntityMods.DTERA then
				for i = 1, table.Count(Ent.EntityMods.DTERA) do
					self.Ent = CreatedEntities[Ent.EntityMods.DTERA[i]]
					if self.Ent and IsValid(self.Ent) then table.insert(self.NewERA, self.Ent) end
				end
			end

			self.ERA = self.NewERA
		else
			if Ent.EntityMods.DakTek.ERACount > 0 then
				self.NewERA = {}
				if Ent.EntityMods.DTERA then
					for i = 1, Ent.EntityMods.DakTek.ERACount do
						local hitEnt = CreatedEntities[Ent.EntityMods.DTERA[i]]
						if IsValid(hitEnt) then table.insert(self.NewERA, hitEnt) end
					end
				end

				self.ERA = self.NewERA
			else
				self.ERA = {}
			end
		end

		--[[
		if Ent.EntityMods.DTClips ~= nil then
			for i=1, #Ent.EntityMods.DTClips do
				local cur = CreatedEntities[ Ent.EntityMods.DTClips[i].ID ]
				if IsValid(cur) and cur.EntityMods.DakClippedArmor ~= nil then
					cur.EntityMods.DakClippedArmor = Ent.EntityMods.DTClips[i].Armor
					local SA = cur:GetPhysicsObject():GetSurfaceArea()
					local mass = math.ceil(((Ent.EntityMods.DTClips[i].Armor/1/(288/SA))/7.8125)*4.6311781,0)
					cur.EntityMods.DakClippedArmor = Ent.EntityMods.DTClips[i].Armor
					if mass > 0 then
						SetMass( self.DakOwner, cur, { Mass = mass } )
						cur:GetPhysicsObject():SetMass(mass)
					end
				end
			end
		end
		]]

		self.DakName = Ent.EntityMods.DakTek.DakName
		self.DakHealth = Ent.EntityMods.DakTek.DakHealth
		self.DakMaxHealth = Ent.EntityMods.DakTek.DakMaxHealth
		self.DakMass = Ent.EntityMods.DakTek.DakMass
		Ent.EntityMods.DakTek = nil
	end

	local mins
	local maxs
	local minx = {}
	local miny = {}
	local minz = {}
	local maxx = {}
	local maxy = {}
	local maxz = {}
	for _, v in pairs(CreatedEntities) do
		if IsValid(v) then
			if v:GetPhysicsObject() and v:GetPhysicsObject():GetSurfaceArea() ~= nil and v:GetPhysicsObject():GetMass() > 1 then --get surface area checks if not made spherical to avoid getting wheels in here
				mins = self:WorldToLocal(v:LocalToWorld(v:OBBMins()))
				maxs = self:WorldToLocal(v:LocalToWorld(v:OBBMaxs()))
				minx[#minx + 1] = mins.x
				miny[#miny + 1] = mins.y
				minz[#minz + 1] = mins.z
				maxx[#maxx + 1] = maxs.x
				maxy[#maxy + 1] = maxs.y
				maxz[#maxz + 1] = maxs.z
			end
		end
	end

	table.sort(minx)
	table.sort(miny)
	table.sort(minz)
	table.sort(maxx)
	table.sort(maxy)
	table.sort(maxz)
	self.HitBoxMins = Vector(minx[1], miny[1], minz[1])
	self.HitBoxMaxs = Vector(maxx[#maxx], maxy[#maxy], maxz[#maxz])

	self.PreCostTimerFirst = CurTime()
	self.DakOwner = Player
	self.BaseClass.PostEntityPaste(self, Player, Ent, CreatedEntities)
end

function ENT:OnRemove()
	if self.Contraption and #self.Contraption > 0 then
		for i = 1, #self.Contraption do
			if self.Contraption[i]:IsVehicle() then if IsValid(self.Contraption[i]) then if IsValid(self.Contraption[i]:GetDriver()) then self.Contraption[i]:GetDriver():SetNoDraw(false) end end end
		end
	end

	if table.Count(self.HitBox) > 0 then
		for i = 1, table.Count(self.HitBox) do
			self.HitBox[i].DakPooled = 0
			self.HitBox[i].DakController = nil
			self.HitBox[i].DakLegit = nil
		end
	end

	if self.Dead == nil or self.Dead == 0 then hook.Run("DakTank_TankDespawned", self) end
	if gmod.GetGamemode().Name == "DakTank" then
		if self.LastDamagedBy:IsValid() and self.AutoRemoved ~= true then
			if self.LastDamagedBy:Team() ~= self.DakOwner:Team() then
				local PointsGained
				if Era == "WWII" then
					PointsGained = 5
				elseif Era == "Cold War" then
					PointsGained = 10
				else
					PointsGained = 20
				end

				net.Start("DT_killnotification")
				net.WriteInt(2, 32)
				net.WriteInt(PointsGained, 32)
				net.Send(self.LastDamagedBy)
				if not self.LastDamagedBy:InVehicle() then self.LastDamagedBy:addPoints(PointsGained) end
				if self.DakOwner:Team() == 1 then
					SetGlobalFloat("DakTankRedResources", GetGlobalFloat("DakTankRedResources") - 5)
				elseif self.DakOwner:Team() == 2 then
					SetGlobalFloat("DakTankBlueResources", GetGlobalFloat("DakTankBlueResources") - 5)
				end
			end
		end
	end
end