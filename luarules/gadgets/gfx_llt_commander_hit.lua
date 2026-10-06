function gadget:GetInfo()
	return {
		name = "LLT Commander Impact",
		desc = "Pink blowback on confirmed LLT hits against commander armor",
		author = "BAR contributors",
		layer = 0,
		enabled = true,
	}
end

if not gadgetHandler:IsSyncedCode() then
	return false
end

local hitEffects = {}
local commanders = {}
local lastImpact = {}
local nextCritText = {}
local IMPACT_INTERVAL = 6 -- Beam damage ticks every frame; limit overlapping splashes.

for weaponDefID, wd in pairs(WeaponDefs) do
	local ceg = wd.customParams and wd.customParams.beam_commander_hit_ceg
	if wd.type == "BeamLaser" and ceg then
		hitEffects[weaponDefID] = ceg
	end
end
for unitDefID, ud in pairs(UnitDefs) do
	commanders[unitDefID] = ud.armorType == Game.armorTypes.commanders
end

function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, projectileID, attackerID)
	local ceg = hitEffects[weaponDefID]
	if not ceg or not commanders[unitDefID] or damage <= 0 then
		return
	end

	local frame = Spring.GetGameFrame()
	local key = unitID .. ":" .. (attackerID or -1) .. ":" .. weaponDefID
	if lastImpact[key] and frame - lastImpact[key] < IMPACT_INTERVAL then
		return
	end

	local x, y, z, mx, my, mz = Spring.GetUnitPosition(unitID, true)
	if not x then return end
	x, y, z = mx or x, my or y, mz or z
	local dx, dy, dz = 0, 1, 0
	local hasBeamEndpoint = false
	-- Beam projectiles store their endpoint offset as velocity. Some damage
	-- callbacks have no live projectile, so retain a unit-surface fallback.
	if projectileID and projectileID >= 0 then
		local px, py, pz = Spring.GetProjectilePosition(projectileID)
		local vx, vy, vz = Spring.GetProjectileVelocity(projectileID)
		if px and vx and vx * vx + vy * vy + vz * vz > 0.0001 then
			x, y, z = px + vx, py + vy, pz + vz
			dx, dy, dz = -vx, -vy, -vz
			hasBeamEndpoint = true
		end
	end
	if not hasBeamEndpoint and attackerID then
		local ax, ay, az, amx, amy, amz = Spring.GetUnitPosition(attackerID, true)
		if ax then
			dx, dy, dz = (amx or ax) - x, (amy or ay) - y, (amz or az) - z
		end
	end
	local length = math.sqrt(dx * dx + dy * dy + dz * dz)
	if length > 0.0001 then
		dx, dy, dz = dx / length, dy / length, dz / length
	else
		dx, dy, dz = 0, 1, 0
	end
	-- Move just outside the contact surface so the model doesn't hide the flash.
	local offset = hasBeamEndpoint and 2 or (Spring.GetUnitRadius(unitID) or 20) * 0.75
	x, y, z = x + dx * offset, y + dy * offset, z + dz * offset
	Spring.SpawnCEG(ceg, x, y, z, dx, dy, dz)
	lastImpact[key] = frame
	-- A sustained beam deals damage in ticks: show one label per reload cycle.
	if not nextCritText[key] or frame >= nextCritText[key] then
		local reloadTime = WeaponDefs[weaponDefID].reload
		local attackerDefID = attackerID and Spring.GetUnitDefID(attackerID)
		local weapons = attackerDefID and UnitDefs[attackerDefID].weapons
		for weaponNum, weapon in ipairs(weapons or {}) do
			if weapon.weaponDef == weaponDefID then
				reloadTime = Spring.GetUnitWeaponState(attackerID, weaponNum, "reloadTime") or reloadTime
				break
			end
		end
		local lifetime = math.max(1, math.floor(reloadTime * Game.gameSpeed + 0.5))
		SendToUnsynced("llt_commander_crit", unitID, x, y, z, frame, lifetime)
		nextCritText[key] = frame + lifetime
	end
end

function gadget:GameFrame(frame)
	if frame % 30 ~= 0 then return end
	for key, lastFrame in pairs(lastImpact) do
		if frame - lastFrame >= IMPACT_INTERVAL then
			lastImpact[key] = nil
		end
	end
	for key, expiry in pairs(nextCritText) do
		if frame >= expiry then nextCritText[key] = nil end
	end
end
