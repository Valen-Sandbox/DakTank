include("shared.lua")

function ENT:Draw()
	self:DrawModel()
end

function ENT:Initialize()
	if LocalPlayer():GetPos():Distance(self:GetPos()) > 2500 then
		sound.Play( "daktanks/distexp1.mp3", LocalPlayer():GetPos(), 100, 100, math.Clamp(math.pow( 0.5,LocalPlayer():GetPos():Distance(self:GetPos()) / 5000 ),0,0.1) )
	end
end