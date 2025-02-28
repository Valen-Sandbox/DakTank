ENT.Type = "anim"
ENT.Base = "dak_base"

ENT.Spawnable = true
ENT.AdminOnly = false

ENT.Editable = true

function ENT:SetupDataTables()
	self:NetworkVar( "Float", 	0, "HorsePowerMultiplier", 	{ KeyName = "horsepowermultiplier", 	Edit = { type = "Float", order = 1, min = 0, max = 1 } } )
	self:SetHorsePowerMultiplier( 1 )
end