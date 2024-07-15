include("shared.lua")

function ENT:Draw()
	if LocalPlayer():GetPos():DistToSqr(self:GetPos()) < 1600000 then
		self:DrawModel()
	end
end