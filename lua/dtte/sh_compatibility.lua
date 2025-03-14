-- Traceline workaround for https://github.com/Facepunch/garrysmod-issues/issues/4142 brought over from ACF-3
-- Refer to that addon for any further info or changes to this workaround
-- Will not run if ACF-3 or ACE is installed in order to avoid overriding the function again

timer.Simple(0, function()
	if istable(ACF) then return end

	local Hull = util.TraceHull
	local Zero = Vector()

	-- Available for use, just in case
	if not util.LegacyTraceLine then
		util.LegacyTraceLine = util.TraceLine
	end

	function util.TraceLine(TraceData, ...)
		if istable(TraceData) then
			TraceData.mins = Zero
			TraceData.maxs = Zero
		end

		return Hull(TraceData, ...)
	end
end)