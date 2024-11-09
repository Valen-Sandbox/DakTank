local DTTE = DTTE

local function DTWorldPenBackTrace(Start, End, Filter, Caliber)
	--print("backtracing")
	local trace = {}
		trace.start = Start
		trace.endpos = End
		trace.filter = Filter
		trace.mins = Vector(-Caliber * 0.02,-Caliber * 0.02,-Caliber * 0.02)
		trace.maxs = Vector(Caliber * 0.02,Caliber * 0.02,Caliber * 0.02)
		trace.mask = MASK_SOLID_BRUSHONLY
	local Back = util.TraceHull( trace )

	--debugoverlay.Line(Back.StartPos + Vector(0, 0, 1), Back.HitPos + Vector(0, 0, 1), 30, Color(0, 255, 255), true)
	--debugoverlay.Cross(Back.HitPos, 5, 30, Color(255, 0, 0), true)

	if Back.StartSolid then -- Started inside something
		--nopen, return start
		return false, Start
	elseif not Back.HitWorld or Back.HitTexture == "TOOLS/TOOLSNODRAW" then -- Did not hit anything on the way back
		--nopen, return start
		return false, Start
	else
		--penned, return exit
		return true, Back.HitPos
	end
end

function DTTE.WorldPen(Start, Dir, Pen, Filter, Caliber)
	--print("NEW")
	local penned = false
	local exitpos = Start
	local distance = 0
	local Penetration = Pen --Pen is in mm, penetration is in inches/source units and signifies world penetration, however 25.4mm is equal to 1 inch and fits the conversion
	local TraceData = {
		start = Start,
		endpos = Start + Dir * Pen,
		filter = Filter,
		mask = MASK_SOLID,
		mins = Vector(-Caliber * 0.02,-Caliber * 0.02,-Caliber * 0.02),
		maxs = Vector(Caliber * 0.02,Caliber * 0.02,Caliber * 0.02)
	}
	local Trace = util.TraceHull(TraceData)

	--debugoverlay.Line(TraceData.start, Trace.HitPos, 30, Color(0, 255, 0))
	--debugoverlay.Cross(Trace.HitPos, 5, 30, Color(120, 255, 75), true)

	if Trace.HitWorld then
		--print("Hit World")

		local Dig = util.TraceHull({
			start  = Trace.HitPos + Dir,
			endpos = Trace.HitPos + Dir * Penetration,
			mask   = MASK_SOLID_BRUSHONLY,
			mins = Vector(-Caliber * 0.02,-Caliber * 0.02,-Caliber * 0.02),
			maxs = Vector(Caliber * 0.02,Caliber * 0.02,Caliber * 0.02)
		})

		--debugoverlay.Line(Dig.StartPos, Dig.HitPos, 30, Color(255, 255, 0), true)

		if Dig.HitSky then
			--print("FAIL - HIT SKY")
			return penned, exitpos, distance
		end

		if Dig.StartSolid then
			--print("Solid")

			if Dig.Fraction == 0 then
				--print("Impermeable") -- Trees and boulders on gm_fork set this off. Various other parts of the map do as well
				penned, exitpos = DTWorldPenBackTrace(Trace.HitPos + Dir * Penetration, Start, Filter, Caliber) -- Just guess the starting position as the maximum penetration depth
				distance = Start:Distance(exitpos)
			elseif Dig.FractionLeftSolid ~= 1 then
				--print("SUCCESS")
				--print(Dig.FractionLeftSolid)
				--debugoverlay.Cross(Dig.StartPos, 5, 30, Color(255, 0, 0), true)
				penned = true
				exitpos = Dig.StartPos
				distance = Start:Distance(exitpos)
			end
		else
			--print("Hollow")
			penned, exitpos = DTWorldPenBackTrace(Dig.HitPos, Start, Filter, Caliber)
			distance = Start:Distance(exitpos)
		end
	end
	return penned, exitpos, distance
end

function DTTE.CheckClip(Ent, HitPos, nochecklegit)
	local entTbl = Ent:GetTable()
	if not (Ent:GetClass() == "prop_physics") or (entTbl.ClipData == nil) then return false end
	if nochecklegit ~= true then
		if entTbl.DakLegit ~= 1 then return true end

		local physObj = Ent:GetPhysicsObject()
		if IsValid(physObj) and physObj:GetMass() ~= entTbl.DakLegitMass then
			return true
		end
	end
	local HitClip = false
	local normal
	local origin
	for i = 1, #entTbl.ClipData do
		if entTbl.ClipData[i].physics == true then return false end
		normal = Ent:LocalToWorldAngles(entTbl.ClipData[i]["n"]):Forward()
		origin = Ent:LocalToWorld(entTbl.ClipData[i]["n"]:Forward() * entTbl.ClipData[i]["d"])
		HitClip = HitClip or normal:Dot((origin - HitPos):GetNormalized()) > 0
		if HitClip then return true end
	end

	return HitClip
end

local function DTSimpleTrace(Start, End, Caliber, Filter, Gun, ignoreworld)
	local trace = {}
		trace.start = Start
		trace.endpos = End
		trace.filter = Filter
		trace.mins = Vector(-Caliber * 0.02,-Caliber * 0.02,-Caliber * 0.02)
		trace.maxs = Vector(Caliber * 0.02, Caliber * 0.02, Caliber * 0.02)
		if ignoreworld == false then
			trace.ignoreworld = false
		else
			trace.ignoreworld = true
		end
	local SimpleTrace = util.TraceHull( trace )
	local Stop = 1
	local Ent = SimpleTrace.Entity
	local Pos = SimpleTrace.HitPos
	if Ent:IsValid() then
		local physObj = Ent:GetPhysicsObject()
		if DTTE.CheckClip(Ent,Pos) or (physObj:IsValid() and physObj:GetMass() <= 1) or Ent:IsVehicle() or Ent:GetClass() == "dak_crew" or Ent:GetClass() == "dak_teammo" or Ent.Controller ~= Gun.Controller then
			Stop = 0
		end
	end

	return Ent, Pos, Stop
end

function DTTE.SimpleRecurseTrace(Start, End, Caliber, Filter, Gun, ignoreworld)
	local Ent, Pos, Stop = DTSimpleTrace(Start, End, Caliber, Filter, Gun, ignoreworld)
	local Recurse = 1
	local NewFilter = Filter
	NewFilter[#NewFilter + 1] = Ent
	--instead of ignoring ent maybe ignore position in particular hit
	--also figure out what is going on with tube turrets
	local newEnt = Ent
	local LastPos = Pos
	if Stop == 1 then
		local Distance = Start:Distance(LastPos)
		--print(Distance)
		return Distance
	end
	while Stop == 0 and Recurse < 25 do
		newEnt, LastPos, Stop = DTSimpleTrace(Start, End, Caliber, NewFilter, Gun, ignoreworld)
		NewFilter[#NewFilter + 1] = newEnt
		Recurse = Recurse + 1
		if Stop == 1 then
			local Distance = Start:Distance(LastPos)
			--print(Distance)
			return Distance
		end
	end
end

local filtTraceMins = Vector(-0.01,-0.01,-0.01)
local filtTraceMaxs = -filtTraceMins
local function DTFilterTrace(Start, End, Filter, Core)
	local trace = {}
		trace.start = Start
		trace.endpos = End
		trace.filter = Filter
		trace.mins = filtTraceMins
		trace.maxs = filtTraceMaxs
		trace.ignoreworld = true
	local SimpleTrace = util.TraceHull( trace )
	local Stop = 0
	local Ent = SimpleTrace.Entity
	local Pos = SimpleTrace.HitPos
	if Ent:IsValid() then
		local entClass = Ent:GetClass()
		if Ent.Controller == Core.Controller and not(entClass == "dak_temachinegun" or entClass == "dak_teautogun" or entClass == "dak_tegun") then
			Stop = 1
		end
	else
		Pos = Start
		Stop = 1
	end

	return Ent, Pos, Stop
end

function DTTE.FilterRecurseTrace(Start, End, Filter, Core)
	local Recurse = 1
	local NewFilter = table.Copy(Filter)
	local LastPos

	while Recurse < 1000 do
		local newEnt, pos, Stop = DTFilterTrace(Start, End, NewFilter, Core)
		LastPos = pos

		if Stop == 1 then
			break
		end

		NewFilter[#NewFilter + 1] = newEnt
		Recurse = Recurse + 1
	end
	return LastPos
end

function DTTE.CompositesTrace( Ent, StartPos, Dir, Filter )
	local Phys = Ent:GetPhysicsObject()
	local Obj = Phys:GetMeshConvexes()

	for I in ipairs( Obj ) do
		local Mesh = Obj[ I ]
		local H1
		for K = 1, table.Count( Mesh ), 3 do
			local P1 = Ent:LocalToWorld( Mesh[ K ].pos )
			local P2 = Ent:LocalToWorld( Mesh[ K + 1 ].pos )
			local P3 = Ent:LocalToWorld( Mesh[ K + 2 ].pos )

			--Super hacky Vector optimizations -j
			--local S1 = P2 - P1
			--local S2 = P3 - P1
			--local Norm = S1:Cross( S2 ):GetNormalized()
			P2:Add(-P1)
			P3:Add(-P1)
			local Norm = P2:Cross(P3)
			local Pos = util.IntersectRayWithPlane( StartPos, Dir, P1, Norm ) --Thanks Garry

			if Pos then
				--Super hacky Vector optimizations -j
				--local S3 = Pos - P1
				--local D1 = S1:Dot(S1)
				--local D2 = S1:Dot(S2)
				--local D3 = S1:Dot(S3)
				--local D4 = S2:Dot(S2)
				--local D5 = S2:Dot(S3)

				P1:Negate() --This saves literally 1 milisecond total lol - j
				P1:Add(Pos)

				local D1 = P2:Dot(P2)
				local D2 = P2:Dot(P3)
				local D3 = P2:Dot(P1)
				local D4 = P3:Dot(P3)
				local D5 = P3:Dot(P1)

				local ID = 1 / ( D1 * D4 - D2 * D2 )
				local U = ( D4 * D3 - D2 * D5 ) * ID
				local V = ( D1 * D5 - D2 * D3 ) * ID
				if U >= 0 and V >= 0 and U + V < 1 then
					if H1 then
						--Only get the first example of entry/exit as the trace will be called again when the bullet hits the other side of the prop (thinking about it, the prop gets filtered out after first time touched, will revisit later)
						local checktrace = {}
							checktrace.start = StartPos
							checktrace.endpos = H1
							if Filter == nil then
								checktrace.filter = {Ent}
							else
								local checkfilter = table.Copy( Filter )
								checkfilter[#checkfilter + 1] = Ent
								checktrace.filter = checkfilter
							end
							local checkinternaltrace = util.TraceLine( checktrace )
						local distOld = Pos:Distance(H1)
						if IsValid(checkinternaltrace.Entity) then
							local distNew = Pos:Distance(checkinternaltrace.HitPos)
						 	if distNew < distOld then
								local physObj = checkinternaltrace.Entity:GetPhysicsObject()
								if (physObj:IsValid() and physObj:GetMass() > 1) then
									return distNew
								end
							end
						end
						return distOld
					else
						H1 = Pos
					end
				end
			end
		end
	end

	return 0
end