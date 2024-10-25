include("shared.lua")

function ENT:Draw()
	if LocalPlayer():GetPos():DistToSqr(self:GetPos()) < 1600000 then
		self:DrawModel()
	end
end

net.Receive( "daktankcoredetail", function()
	local core = net.ReadFloat()
	if core == nil then return end
	local DetailInfoTable = util.JSONToTable(net.ReadString())
	local locPly = LocalPlayer()
	if locPly[tostring( core )] == nil then locPly[tostring( core )] = {} end
	if locPly[tostring( core )].Detail == nil then locPly[tostring( core )].Detail = {} end
	local cur
	local Detailplate
	local parentent
	for i=1, #DetailInfoTable do
		cur = DetailInfoTable[i]
		Detailplate = ents.CreateClientProp( cur.Model )
		parentent = ents.GetByIndex( cur.Parent )
		if parentent:IsValid() then --Not sure why this was commented out, given not having it can cause a lua error
			Detailplate:SetPos(parentent:LocalToWorld(cur.LocalPos))
			Detailplate:SetAngles(parentent:LocalToWorldAngles(cur.LocalAng))
			Detailplate:SetMaterial(cur.Mat)
			Detailplate:SetBodyGroups(cur.Bodygroups)
			Detailplate:SetSkin(cur.Skin)
			for j=0, 31 do
				Detailplate:SetSubMaterial( j, cur.SubMaterials[j] )
			end
			Detailplate:SetRenderMode(cur.RenderMode)
			Detailplate:SetColor(cur.Col)
			Detailplate:SetParent(parentent)
			Detailplate:SetMoveType(MOVETYPE_NONE)
			if cur.ClipData ~= nil then
				for j=1, #cur.ClipData do
					ProperClipping.AddVisualClip(Detailplate, cur.ClipData[j].n:Forward(), cur.ClipData[j].d, cur.ClipData[j].inside, false)
				end
			end
			if locPly[tostring( core )].Detail ~= nil then
				locPly[tostring( core )].Detail[#locPly[tostring( core )].Detail+1] = Detailplate
			end
		end
	end
end )

net.Receive( "daktankcoredetailremove", function()
	local core = net.ReadFloat()
	if core == nil then return end

	local locPly = LocalPlayer()

	if locPly[tostring( core )] ~= nil and locPly[tostring( core )].Detail ~= nil then
		if #locPly[tostring( core )].Detail > 0 then
			for i=1, #locPly[tostring( core )].Detail do
				if locPly[tostring( core )].Detail[i]:IsValid() then locPly[tostring( core )].Detail[i]:Remove() end
			end
			locPly[tostring( core )].Detail = {}
		end
	end
end )

net.Receive( "daktankcoredie", function()
	local core = net.ReadFloat()
	if core == nil then return end

	local locPly = LocalPlayer()

	if locPly[tostring( core )] ~= nil and locPly[tostring( core )].Detail ~= nil then
		if #locPly[tostring( core )].Detail > 0 then
			for i=1, #locPly[tostring( core )].Detail do
				if locPly[tostring( core )].Detail[i]:IsValid() then
					locPly[tostring( core )].Detail[i]:SetMaterial("models/props_buildings/plasterwall021a")
					locPly[tostring( core )].Detail[i]:SetColor(Color(100,100,100,255))
				end
			end
		end
	end
end )

function ENT:OnRemove()
	if self == nil then return end
	local locPly = LocalPlayer()

	if locPly[tostring( self:EntIndex() )] ~= nil and locPly[tostring( self:EntIndex() )].Detail ~= nil then
		if #locPly[tostring( self:EntIndex() )].Detail > 0 then
			for i=1, #locPly[tostring( self:EntIndex() )].Detail do
				if locPly[tostring( self:EntIndex() )].Detail[i]:IsValid() then locPly[tostring( self:EntIndex() )].Detail[i]:Remove() end
			end
			locPly[tostring( self:EntIndex() )].Detail = {}
		end
	end
end
