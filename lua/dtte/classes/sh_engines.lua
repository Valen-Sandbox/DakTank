local DTTE = DTTE
DTTE.Classes = DTTE.Classes or {}
DTTE.Classes.Engines = DTTE.Classes.Engines or {}
local Engines = DTTE.Classes.Engines

Engines["Micro Engine"] = {
    Description = "Tiny engine for tiny tanks.",
    MaxHealth = 5,
    Armor = 5,
    Mass = 80,
    Speed = 0.4444,
    ExampleSpeed = 13,
    Model = "models/daktanks/engine1.mdl",
    Sound = "daktanks/engine/enginemicro.wav",
    FuelReq = 24,
    HP = 40,
}
Engines["Small Engine"] = {
    Description = "Small engine for light tanks and slow mediums.",
    MaxHealth = 20,
    Armor = 20,
    Mass = 265,
    Speed = 1.3888,
    ExampleSpeed = 42,
    Model = "models/daktanks/engine2.mdl",
    Sound = "daktanks/engine/enginesmall.wav",
    FuelReq = 75,
    HP = 125,
}
Engines["Standard Engine"] = {
    Description = "Standard sized engine for medium tanks or slow heavies.",
    MaxHealth = 45,
    Armor = 45,
    Mass = 625,
    Speed = 3.3333,
    ExampleSpeed = 100,
    Model = "models/daktanks/engine3.mdl",
    Sound = "daktanks/engine/enginestandard.wav",
    FuelReq = 180,
    HP = 300,
}
Engines["Large Engine"] = {
    Description = "Large engine for heavy tanks.",
    MaxHealth = 90,
    Armor = 90,
    Mass = 1225,
    Speed = 6.6666,
    ExampleSpeed = 200,
    Model = "models/daktanks/engine4.mdl",
    Sound = "daktanks/engine/enginelarge.wav",
    FuelReq = 360,
    HP = 600,
}
Engines["Huge Engine"] = {
    Description = "Huge engine for heavy tanks that want to move fast.",
    MaxHealth = 150,
    Armor = 150,
    Mass = 2120,
    Speed = 11.1111,
    ExampleSpeed = 333,
    Model = "models/daktanks/engine5.mdl",
    Sound = "daktanks/engine/enginehuge.wav",
    FuelReq = 600,
    HP = 1000,
}
Engines["Ultra Engine"] = {
    Description = "Ultra engine for use in super heavy tanks.",
    MaxHealth = 360,
    Armor = 360,
    Mass = 5020,
    Speed = 26.6666,
    ExampleSpeed = 800,
    Model = "models/daktanks/engine6.mdl",
    Sound = "daktanks/engine/engineultra.wav",
    FuelReq = 1440,
    HP = 2400,
}