ENT.Type = "anim"
ENT.Base = "base_wire_entity"

ENT.Spawnable = true
ENT.AdminOnly = false

ENT.Editable = true

function ENT:SetupDataTables()
	self:NetworkVar( "Float", 	0, "Propellant", 	{ KeyName = "propellant", 	Edit = { type = "Float", order = 1, min = 10, max = 100 } } )
	self:NetworkVar("Bool", 0, "Firing")
	self:NetworkVar("Float", 0, "Timer")
	self:NetworkVar("Float", 1, "Cooldown")
	self:NetworkVar("String", 0, "Model")
	self:SetPropellant( 100 )
end