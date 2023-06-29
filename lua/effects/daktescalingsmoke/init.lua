local math_Rand = math.Rand
local Vector = Vector
local Angle = Angle
local math_random = math.random
local math_pi = math.pi

function EFFECT:Init( data )
	local Pos = data:GetOrigin()
	local size = data:GetScale() / 78
	local emitter = ParticleEmitter( Pos )
	local normal = data:GetNormal()
	local dustsize = data:GetScale() / 10
	local dustspawns = math.min( dustsize, dustsize * 0.5 )

	if dustsize > 1 then
		local pregroundtrace = {}
		pregroundtrace.start = Pos
		pregroundtrace.endpos = Pos + Vector( 0, 0, -250 )
		pregroundtrace.mask = MASK_SOLID_BRUSHONLY
		local groundtrace = util.TraceLine( pregroundtrace )
		local dusttime = dustsize * 0.1

		if groundtrace.Hit then
			for i = 1, dustspawns * 0.75 do
				local ang = math_Rand( 0, 360 ) * math_pi / 180
				local vec = Vector( dustsize * math_Rand( 0, 2.5 ) * math.cos( ang ), dustsize * math_Rand( 0, 2.5 ) * math.sin( ang ), dustsize * 0.125 )
				vec:Rotate( Angle( normal:Angle().x - 90, normal:Angle().y, 0 ) )
				local particle = emitter:Add( "dak/smokey", groundtrace.HitPos + vec )

				if particle == nil then
					particle = emitter:Add( "dak/smokey", groundtrace.HitPos + Vector( math_Rand( -dustsize * 10, dustsize * 10 ), math_Rand( -dustsize * 10, dustsize * 10 ), -75 ) )
				end

				if particle then
					local power = math_Rand( 0.75, 1.25 )
					particle:SetVelocity( Vector( 0, 0, power * dustsize ) )
					particle:SetLifeTime( 0 )
					--particle:SetDieTime((dustsize/5)+math_Rand(0,5))
					particle:SetDieTime( dusttime )
					particle:SetStartAlpha( 255 )
					particle:SetEndAlpha( 0 )
					particle:SetStartSize( dustsize * 0.125 * math_Rand( 0.5, 2 ) )
					particle:SetEndSize( dustsize * 3 * math_Rand( 0.5, 2 ) )
					particle:SetAngles( Angle( 0, 0, 0 ) )
					particle:SetAngleVelocity( Angle( math_Rand( -0.5, 0.5 ), 0, 0 ) )
					particle:SetRoll( math_Rand( 0, 360 ) )
					particle:SetColor( math_random( 227, 227 ), math_random( 211, 211 ), math_random( 161, 161 ), math_random( 50, 50 ) )
					particle:SetGravity( Vector( 0, 0, 0 ) )
					particle:SetAirResistance( dustsize * 100 * power )
					particle:SetCollide( false )
					particle:SetBounce( 0 )
				end
			end

			for i = 1, dustspawns * 0.4 do
				local ang = math_Rand( 0, 360 ) * math_pi / 180
				local particle = emitter:Add( "dak/smokey", groundtrace.HitPos + Vector( dustsize * 3.5 * math.cos( ang ), dustsize * 3.5 * math.sin( ang ), -25 ) )

				if particle == nil then
					particle = emitter:Add( "dak/smokey", groundtrace.HitPos + Vector( math_Rand( -dustsize * 10, dustsize * 10 ), math_Rand( -dustsize * 10, dustsize * 10 ), -25 ) )
				end

				if particle then
					particle:SetVelocity( Vector( 0, 0, math_Rand( dustsize * 25, dustsize * 50 ) ) )
					particle:SetLifeTime( 0 )
					--particle:SetDieTime((dustsize/5)+math_Rand(0,5))
					particle:SetDieTime( dusttime )
					particle:SetStartAlpha( 255 )
					particle:SetEndAlpha( 0 )
					particle:SetStartSize( dustsize * 0.25 * math_Rand( 0.5, 2 ) )
					particle:SetEndSize( dustsize * 2.5 * math_Rand( 0.9, 1.1 ) )
					particle:SetAngles( Angle( 0, 0, 0 ) )
					particle:SetAngleVelocity( Angle( math_Rand( -0.5, 0.5 ), 0, 0 ) )
					particle:SetRoll( math_Rand( 0, 360 ) )
					particle:SetColor( math_random( 227, 227 ), math_random( 211, 211 ), math_random( 161, 161 ), math_random( 50, 50 ) )
					particle:SetGravity( Vector( 0, 0, dustsize * 35 * 1 * math_Rand( 0.9, 1.1 ) ) )
					particle:SetAirResistance( 100 * 25 * math_Rand( 0.9, 1.1 ) )
					particle:SetCollide( false )
					particle:SetBounce( 0 )
				end
			end
		end
	end

	local smoketime = size * 2

	for i = 1, 1.75 * size do
		local ang = math_Rand( 0, 360 ) * math_pi / 180
		local particle = emitter:Add( "dak/smokey", Pos + size * 1 * Vector( math_Rand( 0, 10 ) * math.cos( ang ), math_Rand( 0, 10 ) * math.sin( ang ), -math_random( -10, 10 ) ) )

		if particle == nil then
			particle = emitter:Add( "dak/smokey", Pos + size * Vector( math_random( 0, 0 ), math_random( 0, 0 ), math_random( 0, 0 ) ) )
		end

		if particle then
			particle:SetVelocity( size * 2.5 * Vector( math_random( -30, 30 ), math_random( -30, 30 ), math_random( -20, 20 ) ) )
			particle:SetLifeTime( 0 )
			particle:SetDieTime( smoketime * 0.8 )
			particle:SetStartAlpha( 200 )
			particle:SetEndAlpha( 0 )
			particle:SetStartSize( size * 10 )
			particle:SetEndSize( math_random( 1, 2 ) * size * 20 )
			particle:SetAngles( Angle( 0, 0, 0 ) )
			particle:SetAngleVelocity( Angle( 0, 0, 0 ) )
			particle:SetRoll( math_Rand( 0, 360 ) )
			local CVal = math_random( 175, 225 )
			particle:SetColor( CVal, CVal, CVal, math_random( 50, 50 ) )
			particle:SetGravity( Vector( 0, 0, 0 ) )
			particle:SetAirResistance( math_random( 0.9, 1.1 ) * 200 )
			particle:SetCollide( false )
			particle:SetBounce( 100 )
		end
	end

	for i = 1, 1.75 * size do
		local ang = math_Rand( 0, 360 ) * math_pi / 180
		local particle = emitter:Add( "dak/smokey", Pos + size * 1 * Vector( math_Rand( 0, 15 ) * math.cos( ang ), math_Rand( 0, 15 ) * math.sin( ang ), -math_random( -7.5, 7.5 ) ) )

		if particle == nil then
			particle = emitter:Add( "dak/smokey", Pos + size * Vector( math_random( 0, 0 ), math_random( 0, 0 ), math_random( 0, 0 ) ) )
		end

		if particle then
			particle:SetVelocity( size * 0.65 * Vector( math_random( -30, 30 ), math_random( -30, 30 ), math_random( -20, 20 ) ) )
			particle:SetLifeTime( 0 )
			particle:SetDieTime( smoketime )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 0 )
			particle:SetStartSize( size * 7.5 )
			particle:SetEndSize( math_random( 1, 2 ) * size * 50 )
			particle:SetAngles( Angle( 0, 0, 0 ) )
			particle:SetAngleVelocity( Angle( 0, 0, 0 ) )
			particle:SetRoll( math_Rand( 0, 360 ) )
			local CVal = math_random( 175, 225 )
			particle:SetColor( CVal, CVal, CVal, math_random( 50, 50 ) )
			particle:SetGravity( Vector( 0, 0, 10 ) )
			particle:SetAirResistance( math_random( 0.9, 1.1 ) * 25 )
			particle:SetCollide( false )
			particle:SetBounce( 100 )
			particle:SetNextThink( 0 ) -- Makes sure the think hook is used on all particles of the particle emitter
		end
	end

	for i = 1, size * 1.5 do
		local Debris = emitter:Add( "effects/fleck_tile" .. math_random( 1, 2 ), Pos )

		if Debris then
			Debris:SetVelocity( size * Vector( math_random( -250, 250 ), math_random( -250, 250 ), math_random( -250, 250 ) ) )
			Debris:SetLifeTime( 0 )
			Debris:SetDieTime( math_Rand( 0.5, 1.5 ) )
			Debris:SetStartAlpha( 255 )
			Debris:SetEndAlpha( 0 )
			Debris:SetStartSize( 2 )
			Debris:SetEndSize( 2 )
			Debris:SetRoll( math_Rand( 0, 360 ) )
			Debris:SetRollDelta( math_Rand( -3, 3 ) )
			Debris:SetAirResistance( 50 )
			Debris:SetGravity( Vector( 0, 0, math_Rand( -500, -250 ) ) )
			Debris:SetColor( 50, 50, 50 )
		end
	end

	for i = 1, size * 1.625 * 0.5 do
		local ang = math_Rand( 0, 360 ) * math_pi / 180
		local particle = emitter:Add( "effects/muzzleflash1.vtf", Pos + size * 0.4 * Vector( math_Rand( 0, 20 ) * math.cos( ang ), math_Rand( 0, 20 ) * math.sin( ang ), -math_random( -20, 20 ) ) )

		if particle == nil then
			particle = emitter:Add( "effects/muzzleflash1.vtf", Pos + size * Vector( math_random( 0, 0 ), math_random( 0, 0 ), math_random( 0, 0 ) ) )
		end

		if particle then
			particle:SetVelocity( size * Vector( math_random( -50, 50 ), math_random( -50, 50 ), math_random( -75, 75 ) ) )
			particle:SetLifeTime( 0.0 )
			particle:SetDieTime( 0.3 )
			particle:SetStartAlpha( 200 )
			particle:SetEndAlpha( 0 )
			local expsize = size * 30 * math_Rand( 0.9, 1.1 )
			particle:SetStartSize( expsize )
			particle:SetEndSize( expsize * 0.5 )
			particle:SetAngles( Angle( 0, 0, 0 ) )
			particle:SetAngleVelocity( Angle( 0, 0, 0 ) )
			particle:SetRoll( math_Rand( 0, 360 ) )
			particle:SetColor( 255, 150, 75, math_random( 150, 255 ) )
			particle:SetGravity( Vector( 0, 0, 0 ) )
			particle:SetAirResistance( 75 )
			particle:SetCollide( false )
			particle:SetBounce( 1000 )
		end
	end

	emitter:Finish()
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end