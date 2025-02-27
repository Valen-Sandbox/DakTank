local DTTE = DTTE
DTTE.Classes = DTTE.Classes or {}
DTTE.Classes.Weapons = DTTE.Classes.Weapons or {}
local Weapons = DTTE.Classes.Weapons
-- TODO: These class definitions are not fully complete.
-- Fill in any missing info that you may find scattered throughout the addon.
local function setCannonSound(caliber)
	local entSound = ""

	if caliber < 37 then
		entSound = "daktanks/c25.mp3"
	end
	if caliber >= 37 and caliber < 50 then
		entSound = "daktanks/c37.mp3"
	end
	if caliber >= 50 and caliber < 75 then
		entSound = "daktanks/c50.mp3"
	end
	if caliber >= 75 and caliber < 100 then
		entSound = "daktanks/c75.mp3"
	end
	if caliber >= 100 and caliber < 120 then
		entSound = "daktanks/c100.mp3"
	end
	if caliber >= 120 and caliber < 152 then
		entSound = "daktanks/c120.mp3"
	end
	if caliber >= 152 and caliber < 200 then
		entSound = "daktanks/c152.mp3"
	end
	if caliber >= 200 then
		entSound = "daktanks/c200.mp3"
	end

	return entSound
end

local function setHowitzerSound(caliber)
	local entSound = ""

	if caliber < 75 then
		entSound = "daktanks/h50.mp3"
	end
	if caliber >= 75 and caliber < 105 then
		entSound = "daktanks/h75.mp3"
	end
	if caliber >= 105 and caliber < 122 then
		entSound = "daktanks/h105.mp3"
	end
	if caliber >= 122 and caliber < 155 then
		entSound = "daktanks/h122.mp3"
	end
	if caliber >= 155 and caliber < 203 then
		entSound = "daktanks/h155.mp3"
	end
	if caliber >= 203 and caliber < 420 then
		entSound = "daktanks/h203.mp3"
	end
	if caliber >= 420 then
		entSound = "daktanks/h420.mp3"
	end

	return entSound
end

local function setMortarSound(caliber)
	local entSound = ""

	if caliber < 90 then
		entSound = "daktanks/m60.mp3"
	end
	if caliber >= 90 and caliber < 120 then
		entSound = "daktanks/m90.mp3"
	end
	if caliber >= 120 and caliber < 150 then
		entSound = "daktanks/m120.mp3"
	end
	if caliber >= 150 and caliber < 240 then
		entSound = "daktanks/m150.mp3"
	end
	if caliber >= 240 and caliber < 280 then
		entSound = "daktanks/m240.mp3"
	end
	if caliber >= 280 and caliber < 420 then
		entSound = "daktanks/m280.mp3"
	end
	if caliber >= 420 and caliber < 600 then
		entSound = "daktanks/m420.mp3"
	end
	if caliber >= 600 then
		entSound = "daktanks/m600.mp3"
	end

	return entSound
end

local function setATGMSound()
	return "daktanks/new/cannons/misc/tank_rocket_shot_1.mp3"
end

local function setRecoillessRifleSound(caliber)
	local entSound = ""

	if caliber < 50 then
		entSound = "daktanks/new/cannons/37mm/cannon_37mm_kwk36_shot_01.mp3"
	end
	if caliber >= 50 and caliber < 70 then
		entSound = "daktanks/new/cannons/57mm/cannon_57mm_zis4_shot_01.mp3"
	end
	if caliber >= 70 and caliber < 90 then
		entSound = "daktanks/new/cannons/85mm/cannon_85mm_zis_c53_shot_01.mp3"
	end
	if caliber >= 90 and caliber < 110 then
		entSound = "daktanks/new/cannons/105mm/cannon_105mm_m4_shot_01.mp3"
	end
	if caliber >= 110 then
		entSound = "daktanks/new/cannons/120mm/cannon_120mm_rh120_shot_01.mp3"
	end

	return entSound
end

local function setLauncherSound()
	return "daktanks/new/cannons/misc/grenade_launcher_01.mp3"
end

local function setAutocannonSound(caliber)
	local entSound = ""

	if caliber < 37 then
		entSound = "daktanks/ac25.mp3"
	end
	if caliber >= 37 and caliber < 50 then
		entSound = "daktanks/ac37.mp3"
	end
	if caliber >= 50 then
		entSound = "daktanks/ac50.mp3"
	end

	return entSound
end

local function setMGSound(caliber)
	local entSound = ""

	if caliber < 7.62 then
		entSound = "daktanks/5mm.mp3"
	end
	if caliber >= 7.62 and caliber < 9 then
		entSound = "daktanks/7mm.mp3"
	end
	if caliber >= 9 and caliber < 12.7 then
		entSound = "daktanks/9mm.mp3"
	end
	if caliber >= 12.7 and caliber < 14.5 then
		entSound = "daktanks/12mm.mp3"
	end
	if caliber >= 14.5 then
		entSound = "daktanks/14mm.mp3"
	end

	return entSound
end

local function setHMGSound(caliber)
	local entSound = ""

	if caliber < 30 then
		entSound = "daktanks/hmg20.mp3"
	end
	if caliber >= 30 and caliber < 40 then
		entSound = "daktanks/hmg30.mp3"
	end
	if caliber >= 40 then
		entSound = "daktanks/hmg40.mp3"
	end

	return entSound
end

Weapons["Short Cannon"] = {
	ShortName = "SC",
	Description = "L/40 cannon with weaker penetration but better HE performance and higher rate of fire. Its shortened breech makes it relatively easy to mount. Additional space around the breech, ignoring crew, ammo, details, and seats, will lead to faster reload times along with keeping the ammo close to the breech.",
	ShellLengthMult = 40 / 50,
	ShellLengthExact = 5,
	SetSound = setCannonSound,
	MinCaliber = 25,
	MaxCaliber = 200,
	Model = "models/daktanks/shortcannon100mm2.mdl",
	EntType = "dak_tegun",
	AmmoTypes = { "Armor Piercing", "High Explosive", "Armor Piercing High Explosive", "High Explosive Anti Tank", "High Explosive Anti Tank Fin Stabilized", "High Velocity Armor Piercing", "Armor Piercing Discarding Sabot", "High Explosive Squash Head", "Anti Tank Guided Missile", "Armor Piercing Fin Stabilized Discarding Sabot", "Smoke" },
}
Weapons["Cannon"] = {
	ShortName = "C",
	Description = "L/50 cannon that provides a good performance without being too painful to mount in a vehicle, overall solid choice for a well rounded vehicle. Additional space around the breech, ignoring crew, ammo, details, and seats, will lead to faster reload times along with keeping the ammo close to the breech.",
	ShellLengthMult = 50 / 50,
	ShellLengthExact = 6.5,
	SetSound = setCannonSound,
	MinCaliber = 25,
	MaxCaliber = 200,
	Model = "models/daktanks/cannon100mm2.mdl",
	EntType = "dak_tegun",
	AmmoTypes = { "Armor Piercing", "High Explosive", "Armor Piercing High Explosive", "High Explosive Anti Tank", "High Explosive Anti Tank Fin Stabilized", "High Velocity Armor Piercing", "Armor Piercing Discarding Sabot", "High Explosive Squash Head", "Anti Tank Guided Missile", "Armor Piercing Fin Stabilized Discarding Sabot", "Smoke" },
}
Weapons["Long Cannon"] = {
	ShortName = "LC",
	Description = "L/70 cannon firing long projectiles at high speed to get the best KE performance. It can be hard to fit one of these in a tank and give it ample room to load, best used on open tank destroyers. Additional space around the breech, ignoring crew, ammo, details, and seats, will lead to faster reload times along with keeping the ammo close to the breech.",
	ShellLengthMult = 70 / 50,
	ShellLengthExact = 9,
	SetSound = setCannonSound,
	MinCaliber = 25,
	MaxCaliber = 200,
	Model = "models/daktanks/longcannon100mm2.mdl",
	EntType = "dak_tegun",
	AmmoTypes = { "Armor Piercing", "High Explosive", "Armor Piercing High Explosive", "High Explosive Anti Tank", "High Explosive Anti Tank Fin Stabilized", "High Velocity Armor Piercing", "Armor Piercing Discarding Sabot", "High Explosive Squash Head", "Anti Tank Guided Missile", "Armor Piercing Fin Stabilized Discarding Sabot", "Smoke" },
}
Weapons["Howitzer"] = {
	ShortName = "H",
	Description = "L/30 gun with good HE performance though its KE penetration is rather lacking. It is rather easy to mount and loads quickly. Additional space around the breech, ignoring crew, ammo, details, and seats, will lead to faster reload times along with keeping the ammo close to the breech.",
	ShellLengthMult = 30 / 50,
	ShellLengthExact = 4,
	SetSound = setHowitzerSound,
	MinCaliber = 50,
	MaxCaliber = 240,
	Model = "models/daktanks/howitzer100mm2.mdl",
	EntType = "dak_tegun",
	AmmoTypes = { "Armor Piercing", "High Explosive", "Armor Piercing High Explosive", "High Explosive Anti Tank", "High Explosive Anti Tank Fin Stabilized", "High Explosive Squash Head", "Anti Tank Guided Missile", "Smoke" },
}
Weapons["Mortar"] = {
	ShortName = "M",
	Description = "L/15 gun with great HE performance for its size and weight but nearly useless kinetic penetration. It can reload extremely quick for its caliber and takes little space to load. Additional space around the breech, ignoring crew, ammo, details, and seats, will lead to faster reload times along with keeping the ammo close to the breech.",
	ShellLengthMult = 15 / 50,
	ShellLengthExact = 2.75,
	SetSound = setMortarSound,
	MinCaliber = 40,
	MaxCaliber = 420,
	Model = "models/daktanks/mortar100mm2.mdl",
	EntType = "dak_tegun",
	AmmoTypes = { "Armor Piercing", "High Explosive", "Armor Piercing High Explosive", "High Explosive Anti Tank", "High Explosive Anti Tank Fin Stabilized", "High Explosive Squash Head", "Anti Tank Guided Missile", "Smoke"},
}
Weapons["ATGM Launcher"] = {
	ShortName = "L",
	Description = "Lightweight and simple ATGM launcher.",
	ShellLengthMult = 50 / 50,
	ShellLengthExact = 6.5,
	SetSound = setATGMSound,
	MinCaliber = 40,
	MaxCaliber = 180,
	Model = "models/daktanks/launcher100mm2.mdl",
	EntType = "dak_tegun",
	AmmoTypes = { "Anti Tank Guided Missile" },
	SizeMult = 0.0125,
}
Weapons["Dual ATGM Launcher"] = {
	ShortName = "L",
	Description = "Two tube ATGM launcher, capable of reloading while still keeping a missile ready.",
	ShellLengthMult = 50 / 50,
	ShellLengthExact = 6.5,
	SetSound = setATGMSound,
	MinCaliber = 40,
	MaxCaliber = 180,
	Model = "models/daktanks/duallauncher100mm2.mdl",
	EntType = "dak_tegun",
	AmmoTypes = { "Anti Tank Guided Missile" },
	SizeMult = 0.02,
	ReadyRounds = 2,
}
Weapons["Recoilless Rifle"] = {
	ShortName = "RR",
	Description = "Very light weight, low recoil gun, great on light vehicles but limited to explosive ammunition only.",
	ShellLengthMult = 25 / 50,
	ShellLengthExact = 6.5,
	SetSound = setRecoillessRifleSound,
	MinCaliber = 20,
	MaxCaliber = 150,
	Model = "models/daktanks/recoillessrifle100mm2.mdl",
	EntType = "dak_tegun",
	AmmoTypes = { "High Explosive", "High Explosive Anti Tank", "High Explosive Anti Tank Fin Stabilized", "High Explosive Squash Head", "Smoke" },
	SizeMult = 0.2,
	Recoilless = true,
}
Weapons["MG"] = {
	Name = "Machine Gun",
	ShortName = "MG",
	Description = "Light and rapid fire anti infantry guns with very little penetration power and only AP rounds, its best to not waste them on heavily armored targets.",
	ShellLengthMult = 50 / 50,
	ShellLengthExact = 6.5,
	SetSound = setMGSound,
	MinCaliber = 5,
	MaxCaliber = 25,
	Model = "models/daktanks/machinegun100mm.mdl",
	EntType = "dak_temachinegun",
	AmmoTypes = { "Armor Piercing" },
}
Weapons["Smoke Launcher"] = {
	Description = "Lightweight tube built to fire low velocity smoke grenades to conceal the vehicle's movement.",
	ShellLengthMult = 3 / 50,
	ShellLengthExact = 0.5,
	SetSound = setLauncherSound,
	MinCaliber = 40,
	MaxCaliber = 100,
	Model = "models/daktanks/smokelauncher100mm.mdl",
	EntType = "dak_temachinegun",
	AmmoTypes = { "Smoke" },
}
Weapons["Grenade Launcher"] = {
	Description = "Automatic grenade launcher great for infantry support. Cold war and modern versions are belt fed directly from ammo boxes while WWII versions reload based off a set magazine size. A loader can help speed up the reloading time. Ammo for this gun must be in the turret if it is in the turret or hull if it is hull mounted.",
	ShellLengthMult = 27 / 50,
	ShellLengthExact = 3.5,
	SetSound = setLauncherSound,
	MinCaliber = 20,
	MaxCaliber = 45,
	Model = "models/daktanks/grenadelauncher100mm.mdl",
	EntType = "dak_teautogun",
	AmmoTypes = { "High Explosive", "High Explosive Anti Tank", "High Explosive Squash Head", "Smoke" },
}
Weapons["Autoloader"] = {
	Description = "Cannon with automated loading system, in cold war and modern eras it may be setup with a carousel loading system while WWII is required to use a magazine. Magazines boast a faster time between shots but must reload after a set amount of shots. Mags must be in the same compartment as the gun, ammo boxes count as the mags for carousel loaders. Ample space is required behind the breech to load the round.",
	ShellLengthMult = 50 / 50,
	ShellLengthExact = 6.5,
	SetSound = setCannonSound,
	MinCaliber = 25,
	MaxCaliber = 200,
	Model = "models/daktanks/cannon100mm2.mdl",
	EntType = "dak_teautogun",
	AmmoTypes = { "Armor Piercing", "High Explosive", "Armor Piercing High Explosive", "High Explosive Anti Tank", "High Explosive Anti Tank Fin Stabilized", "High Velocity Armor Piercing", "Armor Piercing Discarding Sabot", "High Explosive Squash Head", "Anti Tank Guided Missile", "Armor Piercing Fin Stabilized Discarding Sabot", "Smoke" },
}
Weapons["Long Autoloader"] = {
	Description = "Long cannon with automated loading system, in cold war and modern eras it may be setup with a carousel loading system while WWII is required to use a magazine. Magazines boast a faster time between shots but must reload after a set amount of shots. Mags must be in the same compartment as the gun, ammo boxes count as the mags for carousel loaders. Ample space is required behind the breech to load the round.",
	ShellLengthMult = 70 / 50,
	ShellLengthExact = 9,
	SetSound = setCannonSound,
	MinCaliber = 25,
	MaxCaliber = 200,
	Model = "models/daktanks/longcannon100mm2.mdl",
	EntType = "dak_teautogun",
	AmmoTypes = { "Armor Piercing", "High Explosive", "Armor Piercing High Explosive", "High Explosive Anti Tank", "High Explosive Anti Tank Fin Stabilized", "High Velocity Armor Piercing", "Armor Piercing Discarding Sabot", "High Explosive Squash Head", "Anti Tank Guided Missile", "Armor Piercing Fin Stabilized Discarding Sabot", "Smoke" },
}
Weapons["Short Autoloader"] = {
	Description = "Short cannon with automated loading system, in cold war and modern eras it may be setup with a carousel loading system while WWII is required to use a magazine. Magazines boast a faster time between shots but must reload after a set amount of shots. Mags must be in the same compartment as the gun, ammo boxes count as the mags for carousel loaders. Ample space is required behind the breech to load the round.",
	ShellLengthMult = 40 / 50,
	ShellLengthExact = 5,
	SetSound = setCannonSound,
	MinCaliber = 25,
	MaxCaliber = 200,
	Model = "models/daktanks/shortcannon100mm2.mdl",
	EntType = "dak_teautogun",
	AmmoTypes = { "Armor Piercing", "High Explosive", "Armor Piercing High Explosive", "High Explosive Anti Tank", "High Explosive Anti Tank Fin Stabilized", "High Velocity Armor Piercing", "Armor Piercing Discarding Sabot", "High Explosive Squash Head", "Anti Tank Guided Missile", "Armor Piercing Fin Stabilized Discarding Sabot", "Smoke" },
}
Weapons["Autoloading Howitzer"] = {
	Description = "Howitzer with automated loading system, in cold war and modern eras it may be setup with a carousel loading system while WWII is required to use a magazine. Magazines boast a faster time between shots but must reload after a set amount of shots. Mags must be in the same compartment as the gun, ammo boxes count as the mags for carousel loaders. Ample space is required behind the breech to load the round.",
	ShellLengthMult = 30 / 50,
	ShellLengthExact = 4,
	SetSound = setHowitzerSound,
	MinCaliber = 50,
	MaxCaliber = 240,
	Model = "models/daktanks/howitzer100mm2.mdl",
	EntType = "dak_teautogun",
	AmmoTypes = { "Armor Piercing", "High Explosive", "Armor Piercing High Explosive", "High Explosive Anti Tank", "High Explosive Anti Tank Fin Stabilized", "High Explosive Squash Head", "Anti Tank Guided Missile", "Smoke" },
}
Weapons["Autoloading Mortar"] = {
	Description = "Mortar with automated loading system, in cold war and modern eras it may be setup with a carousel loading system while WWII is required to use a magazine. Magazines boast a faster time between shots but must reload after a set amount of shots. Mags must be in the same compartment as the gun, ammo boxes count as the mags for carousel loaders. Ample space is required behind the breech to load the round.",
	ShellLengthMult = 15 / 50,
	ShellLengthExact = 2.75,
	SetSound = setMortarSound,
	MinCaliber = 40,
	MaxCaliber = 420,
	Model = "models/daktanks/mortar100mm2.mdl",
	EntType = "dak_teautogun",
	AmmoTypes = { "Armor Piercing", "High Explosive", "Armor Piercing High Explosive", "High Explosive Anti Tank", "High Explosive Anti Tank Fin Stabilized", "High Explosive Squash Head", "Anti Tank Guided Missile", "Smoke" },
}
Weapons["Autoloading ATGM Launcher"] = {
	ShortName = "L",
	Description = "Simple autoloaded ATGM tube.",
	ShellLengthMult = 50 / 50,
	ShellLengthExact = 6.5,
	SetSound = setATGMSound,
	MinCaliber = 40,
	MaxCaliber = 180,
	Model = "models/daktanks/launcher100mm2.mdl",
	EntType = "dak_teautogun",
	AmmoTypes = { "Anti Tank Guided Missile" },
	SizeMult = 0.0125,
}
Weapons["Autoloading Dual ATGM Launcher"] = {
	ShortName = "L",
	Description = "Double barrel autoloaded ATGM launcher.",
	ShellLengthMult = 50 / 50,
	ShellLengthExact = 6.5,
	SetSound = setATGMSound,
	MinCaliber = 40,
	MaxCaliber = 180,
	Model = "models/daktanks/duallauncher100mm2.mdl",
	EntType = "dak_teautogun",
	AmmoTypes = { "Anti Tank Guided Missile" },
	SizeMult = 0.02,
	ReadyRounds = 2,
}
Weapons["Autoloading Recoilless Rifle"] = {
	Description = "Autoloaded, light weight, low recoil gun, great on light vehicles but limited to explosive ammunition only.",
	ShellLengthMult = 25 / 50,
	ShellLengthExact = 6.5,
	SetSound = setRecoillessRifleSound,
	MinCaliber = 20,
	MaxCaliber = 150,
	Model = "models/daktanks/recoillessrifle100mm2.mdl",
	EntType = "dak_teautogun",
	AmmoTypes = { "High Explosive", "High Explosive Anti Tank", "High Explosive Anti Tank Fin Stabilized", "High Explosive Squash Head", "Smoke" },
}
Weapons["Autocannon"] = {
	Description = "Fully automatic cannon limited to lower calibers for ease of loading. Cold war and modern versions are belt fed directly from ammo boxes while WWII versions reload based off a set magazine size. A loader can help speed up the reloading time. Ammo for this gun must be in the turret if it is in the turret or hull if it is hull mounted.",
	ShellLengthMult = 50 / 50,
	ShellLengthExact = 6.5,
	SetSound = setAutocannonSound,
	MinCaliber = 20,
	MaxCaliber = 90,
	Model = "models/daktanks/autocannon100mm2.mdl",
	EntType = "dak_teautogun",
	AmmoTypes = { "Armor Piercing", "High Explosive", "Armor Piercing High Explosive", "High Explosive Anti Tank", "High Explosive Anti Tank Fin Stabilized", "High Velocity Armor Piercing", "Armor Piercing Discarding Sabot", "Armor Piercing Fin Stabilized Discarding Sabot" },
}
Weapons["Flamethrower"] = {
	Description = "Flamethrower capable of igniting infantry, softening armor and stalling engines.",
	SetSound = function()
		return "daktanks/flamerfire.mp3"
	end,
	MinCaliber = 10,
	MaxCaliber = 10,
	Model = "models/daktanks/flamethrower.mdl",
	EntType = "dak_temachinegun",
	AmmoTypes = {},
}
Weapons["HMG"] = {
	Name = "Heavy Machine Gun",
	Description = "Short barreled autocannon with higher rate of fire but weaker KE performance. Cold war and modern versions are belt fed directly from ammo boxes while WWII versions reload based off a set magazine size. A loader can help speed up the reloading time. Ammo for this gun must be in the turret if it is in the turret or hull if it is hull mounted.",
	ShellLengthMult = 40 / 50,
	ShellLengthExact = 5,
	SetSound = setHMGSound,
	MinCaliber = 20,
	MaxCaliber = 75,
	Model = "models/daktanks/hmg100mm2.mdl",
	EntType = "dak_teautogun",
	AmmoTypes = { "Armor Piercing", "High Explosive", "Armor Piercing High Explosive", "High Explosive Anti Tank", "High Explosive Anti Tank Fin Stabilized", "High Velocity Armor Piercing", "Armor Piercing Discarding Sabot", "Armor Piercing Fin Stabilized Discarding Sabot" },
}