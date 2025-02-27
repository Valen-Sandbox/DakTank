local DTTE = DTTE
DTTE.Classes = DTTE.Classes or {}
DTTE.Classes.FuelTanks = DTTE.Classes.FuelTanks or {}
local FuelTanks = DTTE.Classes.FuelTanks

FuelTanks["Micro Fuel Tank"] = {
    Description = "Tiny fuel tank to run light tanks and tankettes.",
    Mass = 65,
    Fuel = 45,
    MaxHealth = 10,
    Model = "models/daktanks/fueltank1.mdl",
}
FuelTanks["Small Fuel Tank"] = {
    Description = "Small fuel tank for light tanks and weak engined mediums.",
    Mass = 120,
    Fuel = 90,
    MaxHealth = 20,
    Model = "models/daktanks/fueltank2.mdl",
}
FuelTanks["Standard Fuel Tank"] = {
    Description = "Standard medium tank fuel tank.",
    Mass = 240,
    Fuel = 180,
    MaxHealth = 30,
    Model = "models/daktanks/fueltank3.mdl",
}
FuelTanks["Large Fuel Tank"] = {
    Description = "Large fuel tanks for heavies running mid sized engines.",
    Mass = 475,
    Fuel = 360,
    MaxHealth = 40,
    Model = "models/daktanks/fueltank4.mdl",
}
FuelTanks["Huge Fuel Tank"] = {
    Description = "Huge fuel tank for heavies running large gas guzzlers.",
    Mass = 950,
    Fuel = 720,
    MaxHealth = 50,
    Model = "models/daktanks/fueltank5.mdl",
}
FuelTanks["Ultra Fuel Tank"] = {
    Description = "Massive fuel tank designed for super heavy tanks running the largest of engines.",
    Mass = 1900,
    Fuel = 1440,
    MaxHealth = 60,
    Model = "models/daktanks/fueltank6.mdl",
}