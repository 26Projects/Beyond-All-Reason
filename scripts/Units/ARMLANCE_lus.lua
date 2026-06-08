local base = piece "base"
local cockpit = piece "cockpit"
local rwing = piece "rwing"
local rventblade = piece "rventblade"
local rbwing = piece "rbwing"
local lwing = piece "lwing"
local lventblade = piece "lventblade"
local lbwing = piece "lbwing"
local bombdrop = piece "bombdrop"
local thrust1 = piece "thrust1"

local function setupFolded()
	Move(lwing, x_axis, 6, 1000)
	Move(rwing, x_axis, -6, 1000)
	Turn(lwing, y_axis, math.rad(45), 1000)
	Turn(rwing, y_axis, math.rad(-45), 1000)
end

function script.Create()
	Hide(thrust1)
	Hide(bombdrop)
	setupFolded()
end

function script.Activate()
	Show(thrust1)
	Spin(rventblade, y_axis, math.rad(540), math.rad(5))
	Spin(lventblade, y_axis, math.rad(540), math.rad(5))

	Turn(lwing, y_axis, 0, math.rad(45))
	Turn(rwing, y_axis, 0, math.rad(45))
	Move(lwing, x_axis, 0, 10)
	Move(rwing, x_axis, 0, 10)
end

function script.Deactivate()
	Move(lwing, x_axis, 6, 10)
	Move(rwing, x_axis, -6, 10)
	WaitForMove(lwing, x_axis)

	Turn(lwing, y_axis, math.rad(45), math.rad(45))
	Turn(rwing, y_axis, math.rad(-45), math.rad(45))
	WaitForTurn(lwing, y_axis)

	StopSpin(lventblade, y_axis, math.rad(1))
	StopSpin(rventblade, y_axis, math.rad(1))
end

function script.AimFromWeapon1()
	return bombdrop
end

function script.QueryWeapon1()
	return bombdrop
end

function script.AimWeapon1()
	return true
end

function script.AimFromWeapon2()
	return bombdrop
end

function script.QueryWeapon2()
	return bombdrop
end

function script.AimWeapon2()
	return true
end

function script.BlockShot2()
	local targetType, _, target = Spring.GetUnitWeaponTarget(unitID, 2)

	if targetType == 1 and target then
		local x, _, z = Spring.GetUnitPosition(target)
		return x and Spring.GetGroundHeight(x, z) < 0
	elseif targetType == 2 and target then
		return Spring.GetGroundHeight(target[1], target[3]) < 0
	end

	return false
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth

	if severity <= 0.25 then
		Explode(base, SFX.BITMAPONLY + SFX.NO_HEATCLOUD)
		Explode(cockpit, SFX.BITMAPONLY + SFX.NO_HEATCLOUD)
		Explode(lwing, SFX.BITMAPONLY + SFX.NO_HEATCLOUD)
		Explode(lbwing, SFX.BITMAPONLY + SFX.NO_HEATCLOUD)
		Explode(rwing, SFX.BITMAPONLY + SFX.NO_HEATCLOUD)
		Explode(rbwing, SFX.BITMAPONLY + SFX.NO_HEATCLOUD)
		Explode(bombdrop, SFX.SMOKE + SFX.FALL + SFX.NO_HEATCLOUD)
		Explode(lventblade, SFX.BITMAPONLY + SFX.NO_HEATCLOUD)
		Explode(rventblade, SFX.BITMAPONLY + SFX.NO_HEATCLOUD)
		return 1
	elseif severity <= 0.5 then
		Explode(base, SFX.BITMAPONLY + SFX.NO_HEATCLOUD)
		Explode(cockpit, SFX.BITMAPONLY + SFX.NO_HEATCLOUD)
		Explode(lwing, SFX.FIRE + SFX.SMOKE + SFX.FALL + SFX.NO_HEATCLOUD)
		Explode(lbwing, SFX.BITMAPONLY + SFX.NO_HEATCLOUD)
		Explode(rwing, SFX.FIRE + SFX.SMOKE + SFX.FALL + SFX.NO_HEATCLOUD)
		Explode(rbwing, SFX.BITMAPONLY + SFX.NO_HEATCLOUD)
		Explode(bombdrop, SFX.BITMAPONLY + SFX.NO_HEATCLOUD)
		Explode(lventblade, SFX.BITMAPONLY + SFX.NO_HEATCLOUD)
		Explode(rventblade, SFX.BITMAPONLY + SFX.NO_HEATCLOUD)
		return 2
	elseif severity <= 0.99 then
		Explode(base, SFX.BITMAPONLY + SFX.NO_HEATCLOUD)
		Explode(cockpit, SFX.BITMAPONLY + SFX.NO_HEATCLOUD)
		Explode(lwing, SFX.BITMAPONLY + SFX.NO_HEATCLOUD)
		Explode(lbwing, SFX.SMOKE + SFX.FALL + SFX.NO_HEATCLOUD)
		Explode(rwing, SFX.BITMAPONLY + SFX.NO_HEATCLOUD)
		Explode(rbwing, SFX.SMOKE + SFX.FALL + SFX.NO_HEATCLOUD)
		Explode(bombdrop, SFX.EXPLODE_ON_HIT + SFX.FIRE + SFX.SMOKE + SFX.FALL + SFX.NO_HEATCLOUD)
		Explode(lventblade, SFX.BITMAPONLY + SFX.NO_HEATCLOUD)
		Explode(rventblade, SFX.BITMAPONLY + SFX.NO_HEATCLOUD)
		return 3
	else
		Explode(base, SFX.BITMAPONLY + SFX.NO_HEATCLOUD)
		Explode(cockpit, SFX.BITMAPONLY + SFX.NO_HEATCLOUD)
		Explode(lwing, SFX.EXPLODE_ON_HIT + SFX.FIRE + SFX.SMOKE + SFX.FALL + SFX.NO_HEATCLOUD)
		Explode(lbwing, SFX.BITMAPONLY + SFX.NO_HEATCLOUD)
		Explode(rwing, SFX.BITMAPONLY + SFX.NO_HEATCLOUD)
		Explode(rbwing, SFX.EXPLODE_ON_HIT + SFX.FIRE + SFX.FALL + SFX.NO_HEATCLOUD)
		Explode(bombdrop, SFX.BITMAPONLY + SFX.NO_HEATCLOUD)
		Explode(lventblade, SFX.BITMAPONLY + SFX.NO_HEATCLOUD)
		Explode(rventblade, SFX.EXPLODE_ON_HIT + SFX.FIRE + SFX.FALL + SFX.NO_HEATCLOUD)
		return 3
	end
end
