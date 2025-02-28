local DTTE = DTTE
DTTE.Classes = DTTE.Classes or {}
DTTE.Classes.TurretMotors = DTTE.Classes.TurretMotors or {}
local TurretMotors = DTTE.Classes.TurretMotors

TurretMotors["Small Turret Motor"] = {
    Description = "This small motor is useful for light turrets.",
    Mass = 250,
    RotMult = 0.1,
    PowerMult = 1,
    MaxHealth = 10,
    Model = "models/xqm/hydcontrolbox.mdl",
}
TurretMotors["Medium Turret Motor"] = {
    Description = "This small motor is useful for medium turrets.",
    Mass = 500,
    RotMult = 0.25,
    PowerMult = 2.5,
    MaxHealth = 20,
    Model = "models/props_c17/utilityconducter001.mdl",
}
TurretMotors["Large Turret Motor"] = {
    Description = "This small motor is useful for heavy turrets.",
    Mass = 1000,
    RotMult = 0.6,
    PowerMult = 6,
    MaxHealth = 50,
    Model = "models/props_c17/substation_transformer01d.mdl",
}