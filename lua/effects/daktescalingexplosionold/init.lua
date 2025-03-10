function EFFECT:Init( data )
	local Pos = data:GetOrigin()
	local size = data:GetScale()/78
	local emitter = ParticleEmitter( Pos )

	local dustsize = data:GetScale()/10
	if dustsize > 1 then
		local pregroundtrace = {}
			pregroundtrace.start = Pos
			pregroundtrace.endpos = Pos + Vector(0,0,-250)
			pregroundtrace.mask = MASK_SOLID_BRUSHONLY
		local groundtrace = util.TraceLine(pregroundtrace)

		if groundtrace.Hit then
			for i = 1,dustsize*2 do

				local particle = emitter:Add( "dak/smokey", groundtrace.HitPos+Vector(math.Rand(-dustsize*10,dustsize*10),math.Rand(-dustsize*10,dustsize*10),-25))

				if particle == nil then particle = emitter:Add( "dak/smokey", groundtrace.HitPos+Vector(math.Rand(-dustsize*10,dustsize*10),math.Rand(-dustsize*10,dustsize*10),-25))  end

				if (particle) then
					particle:SetVelocity(Vector(0,0,math.Rand(dustsize*75,dustsize*125)))
					particle:SetLifeTime(0)
					particle:SetDieTime((dustsize/5)+math.Rand(0,5))
					particle:SetStartAlpha(50)
					particle:SetEndAlpha(0)
					particle:SetStartSize(15+dustsize*3)
					particle:SetEndSize((15+dustsize)*5)
					particle:SetAngles( Angle(0,0,0) )
					particle:SetAngleVelocity( Angle(0,0,0) )
					particle:SetRoll(math.Rand( 0, 360 ))
					particle:SetColor(math.random(227,227),math.random(211,211),math.random(161,161),math.random(50,50))
					particle:SetGravity( Vector(0,0,0) )
					particle:SetAirResistance(dustsize*75)
					particle:SetCollide(false)
					particle:SetBounce(0)
				end
			end
		end
	end

	for i = 1,30*size do

		local particle = emitter:Add( "dak/smokey", Pos + size*Vector( math.random(-10,10),math.random(-10,10),math.random(-10,10) ) )

		if particle == nil then particle = emitter:Add( "dak/smokey", Pos + size*Vector(   math.random(0,0),math.random(0,0),math.random(0,0) ) ) end

		if (particle) then
			particle:SetVelocity(size*Vector(math.random(-200,200),math.random(-200,200),math.random(-200,200)))
			particle:SetLifeTime(size*0.25)
			particle:SetDieTime(size*1)
			particle:SetStartAlpha(150)
			particle:SetEndAlpha(0)
			particle:SetStartSize(size*10)
			particle:SetEndSize(math.random(1,5)*size*25)
			particle:SetAngles( Angle(0,0,0) )
			particle:SetAngleVelocity( Angle(0,0,0) )
			particle:SetRoll(math.Rand( 0, 360 ))
			local CVal = math.random(40,60)
			particle:SetColor(CVal,CVal,CVal,math.random(50,50))
			particle:SetGravity( Vector(0,0,-50) )
			particle:SetAirResistance(math.random(1,5)*25)
			particle:SetCollide(false)
			particle:SetBounce(100)
		end
	end
	for i=1, size*20 do

		local Debris = emitter:Add( "effects/fleck_tile"..math.random(1,2), Pos )
		if (Debris) then
			Debris:SetVelocity (size*Vector(math.random(-250,250),math.random(-250,250),math.random(-250,250)))
			Debris:SetLifeTime( 0 )
			Debris:SetDieTime( math.Rand( 0.5 , 1.5 ) )
			Debris:SetStartAlpha( 255 )
			Debris:SetEndAlpha( 0 )
			Debris:SetStartSize( 2 )
			Debris:SetEndSize( 2 )
			Debris:SetRoll( math.Rand(0, 360) )
			Debris:SetRollDelta( math.Rand(-3, 3) )
			Debris:SetAirResistance( 50 )
			Debris:SetGravity( Vector( 0, 0, math.Rand(-500, -250) ) )
			Debris:SetColor( 50,50,50 )
		end
	end

	for i = 1,size*12.5 do

		local particle = emitter:Add( "effects/fire_cloud1.vtf", Pos + size*Vector( math.random(-20,20),math.random(-20,20),math.random(-20,20) ) )

		if particle == nil then particle = emitter:Add( "effects/fire_cloud1.vtf", Pos + size*Vector(   math.random(0,0),math.random(0,0),math.random(0,0) ) ) end

		if (particle) then
			particle:SetVelocity(size*Vector(math.random(-200,200),math.random(-200,200),math.random(-200,200)))
			particle:SetLifeTime(0.0)
			particle:SetDieTime(0.01+math.Rand(0,0.5))
			particle:SetStartAlpha(200)
			particle:SetEndAlpha(0)
			particle:SetStartSize(size*100*math.Rand(0.9,1.1))
			particle:SetEndSize(0)
			particle:SetAngles( Angle(0,0,0) )
			particle:SetAngleVelocity( Angle(0,0,0) )
			particle:SetRoll(math.Rand( 0, 360 ))
			particle:SetColor(255,255,255,math.random(150,255))
			particle:SetGravity( Vector(0,0,0) )
			particle:SetAirResistance(1500)
			particle:SetCollide(false)
			particle:SetBounce(1000)
		end
	end
	for i = 1,size*12.5 do

		local particle = emitter:Add( "effects/fire_cloud2.vtf", Pos + size*Vector( math.random(-20,20),math.random(-20,20),math.random(-20,20) ) )

		if particle == nil then particle = emitter:Add( "effects/fire_cloud2.vtf", Pos + size*Vector(   math.random(0,0),math.random(0,0),math.random(0,0) ) ) end

		if (particle) then
			particle:SetVelocity(size*Vector(math.random(-200,200),math.random(-200,200),math.random(-200,200)))
			particle:SetLifeTime(0.0)
			particle:SetDieTime(0.01+math.Rand(0,0.5))
			particle:SetStartAlpha(200)
			particle:SetEndAlpha(0)
			particle:SetStartSize(size*100*math.Rand(0.9,1.1))
			particle:SetEndSize(0)
			particle:SetAngles( Angle(0,0,0) )
			particle:SetAngleVelocity( Angle(0,0,0) )
			particle:SetRoll(math.Rand( 0, 360 ))
			particle:SetColor(255,255,255,math.random(150,255))
			particle:SetGravity( Vector(0,0,0) )
			particle:SetAirResistance(1500)
			particle:SetCollide(false)
			particle:SetBounce(1000)
		end
	end

	emitter:Finish()

end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end