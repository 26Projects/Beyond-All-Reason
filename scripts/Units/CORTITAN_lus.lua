local base = piece "base"
local flare1 = piece "flare1"
local flare2 = piece "flare2"
local thrusta1 = piece "thrusta1"
local thrusta2 = piece "thrusta2"
local thrustb1 = piece "thrustb1"
local thrustb2 = piece "thrustb2"

function script.Create()
	Hide(flare1)
	Hide(flare2)
	Hide(thrusta1)
	Hide(thrusta2)
	Hide(thrustb1)
	Hide(thrustb2)
end

function script.Activate()
	Show(thrusta1)
	Show(thrusta2)
	Show(thrustb1)
	Show(thrustb2)
end

function script.Deactivate()
	Hide(thrusta1)
	Hide(thrusta2)
	Hide(thrustb1)
	Hide(thrustb2)
end

function script.AimFromWeapon1()
	return flare1
end

function script.QueryWeapon1()
	return flare1
end

function script.AimWeapon1()
	return true
end

function script.AimFromWeapon2()
	return flare2
end

function script.QueryWeapon2()
	return flare2
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
		Explode(flare1, SFX.BITMAPONLY + SFX.NO_HEATCLOUD)
		Explode(flare2, SFX.BITMAPONLY + SFX.NO_HEATCLOUD)
		Explode(thrusta1, SFX.BITMAPONLY + SFX.NO_HEATCLOUD)
		Explode(thrusta2, SFX.BITMAPONLY + SFX.NO_HEATCLOUD)
		Explode(thrustb1, SFX.BITMAPONLY + SFX.NO_HEATCLOUD)
		Explode(thrustb2, SFX.BITMAPONLY + SFX.NO_HEATCLOUD)
		return 1
	elseif severity <= 0.5 then
		Explode(base, SFX.BITMAPONLY + SFX.NO_HEATCLOUD)
		Explode(flare1, SFX.FALL + SFX.NO_HEATCLOUD)
		Explode(flare2, SFX.FALL + SFX.NO_HEATCLOUD)
		Explode(thrusta1, SFX.BITMAPONLY + SFX.NO_HEATCLOUD)
		Explode(thrusta2, SFX.BITMAPONLY + SFX.NO_HEATCLOUD)
		Explode(thrustb1, SFX.BITMAPONLY + SFX.NO_HEATCLOUD)
		Explode(thrustb2, SFX.BITMAPONLY + SFX.NO_HEATCLOUD)
		return 2
	elseif severity <= 0.99 then
		Explode(base, SFX.BITMAPONLY + SFX.NO_HEATCLOUD)
		Explode(flare1, SFX.EXPLODE_ON_HIT + SFX.SMOKE + SFX.FALL + SFX.NO_HEATCLOUD)
		Explode(flare2, SFX.FIRE + SFX.SMOKE + SFX.FALL + SFX.NO_HEATCLOUD)
		Explode(thrusta1, SFX.BITMAPONLY + SFX.NO_HEATCLOUD)
		Explode(thrusta2, SFX.BITMAPONLY + SFX.NO_HEATCLOUD)
		Explode(thrustb1, SFX.BITMAPONLY + SFX.NO_HEATCLOUD)
		Explode(thrustb2, SFX.BITMAPONLY + SFX.NO_HEATCLOUD)
		return 3
	else
		Explode(base, SFX.BITMAPONLY + SFX.NO_HEATCLOUD)
		Explode(flare1, SFX.EXPLODE_ON_HIT + SFX.FIRE + SFX.SMOKE + SFX.FALL + SFX.NO_HEATCLOUD)
		Explode(flare2, SFX.EXPLODE_ON_HIT + SFX.FIRE + SFX.SMOKE + SFX.FALL + SFX.NO_HEATCLOUD)
		Explode(thrusta1, SFX.BITMAPONLY + SFX.NO_HEATCLOUD)
		Explode(thrusta2, SFX.BITMAPONLY + SFX.NO_HEATCLOUD)
		Explode(thrustb1, SFX.BITMAPONLY + SFX.NO_HEATCLOUD)
		Explode(thrustb2, SFX.BITMAPONLY + SFX.NO_HEATCLOUD)
		return 3
	end
end
