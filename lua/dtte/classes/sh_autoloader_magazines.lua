local DTTE = DTTE
DTTE.Classes = DTTE.Classes or {}
DTTE.Classes.AutoMags = DTTE.Classes.AutoMags or {}
local AutoMags = DTTE.Classes.AutoMags

AutoMags["Small Autoloader Magazine"] = {
    Description = "Small sized magazine required to load an autoloader.",
    Mass = 1000,
    MaxHealth = 50,
    Model = "models/daktanks/alclip1.mdl",
}
AutoMags["Medium Autoloader Magazine"] = {
    Description = "Medium sized magazine required to load an autoloader.",
    Mass = 2000,
    MaxHealth = 75,
    Model = "models/daktanks/alclip2.mdl",
}
AutoMags["Large Autoloader Magazine"] = {
    Description = "Large sized magazine required to load an autoloader.",
    Mass = 3000,
    MaxHealth = 100,
    Model = "models/daktanks/alclip3.mdl",
}