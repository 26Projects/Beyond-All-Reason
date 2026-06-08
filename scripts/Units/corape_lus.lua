local base = piece "base"
local body = piece "body"
local rjet = piece "rjet"
local rthrust = piece "rthrust"
local rwing = piece "rwing"
local rmissile = piece "rmissile"
local rflare = piece "rflare"
local ljet = piece "ljet"
local lthrust = piece "lthrust"
local lwing = piece "lwing"
local lmissile = piece "lmissile"
local lflare = piece "lflare"
local lhthrust1 = piece "lhthrust1"
local lhthrust2 = piece "lhthrust2"
local rhthrust1 = piece "rhthrust1"
local rhthrust2 = piece "rhthrust2"

local flares = { rflare, lflare }
local missiles = { rmissile, lmissile }
local gunIndex = 1
local postBarrageNudgePending = false
local barrageCooldownFrames = 30 * 30
local nextBarrageFrame = 0

local function currentFlare()
	return flares[gunIndex]
end

local function flashMissile(missile)
	Show(missile)
	Sleep(150)
	Hide(missile)
end

local function cycleLauncher()
	local missile = missiles[gunIndex]
	gunIndex = 3 - gunIndex
	StartThread(flashMissile, missile)
end

local function nudgeAfterBarrage()
	if postBarrageNudgePending then
		return
	end

	postBarrageNudgePending = true
	Sleep(450)

	local x, _, z = Spring.GetUnitPosition(unitID)
	if x then
		local heading = Spring.GetUnitHeading(unitID) or 0
		local radians = heading * (2 * math.pi / 65536)
		local nudgeDistance = 96
		local nx = x + math.sin(radians) * nudgeDistance
		local nz = z + math.cos(radians) * nudgeDistance
		local ny = Spring.GetGroundHeight(nx, nz)

		Spring.GiveOrderToUnit(unitID, CMD.FIGHT, { nx, ny, nz }, {})
	end

	postBarrageNudgePending = false
end

local function barrageTargetIsWater()
	local targetType, _, target = Spring.GetUnitWeaponTarget(unitID, 2)

	if targetType == 1 and target then
		local x, _, z = Spring.GetUnitPosition(target)
		return x and Spring.GetGroundHeight(x, z) < 0
	elseif targetType == 2 and target then
		return Spring.GetGroundHeight(target[1], target[3]) < 0
	end

	return false
end

function script.Create()
	Hide(lthrust)
	Hide(rthrust)
	Hide(lhthrust1)
	Hide(lhthrust2)
	Hide(rhthrust1)
	Hide(rhthrust2)
	Hide(rflare)
	Hide(lflare)

	Turn(rwing, z_axis, 0, math.rad(90))
	Turn(lwing, z_axis, 0, math.rad(90))
	Turn(rwing, x_axis, math.rad(90), math.rad(90))
	Turn(lwing, x_axis, math.rad(90), math.rad(90))
	Turn(rjet, x_axis, math.rad(-90), math.rad(90))
	Turn(ljet, x_axis, math.rad(-90), math.rad(90))
end

function script.Activate()
	Show(rthrust)
	Show(lthrust)
end

function script.Deactivate()
	Hide(rthrust)
	Hide(lthrust)
end

function script.AimFromWeapon1()
	return currentFlare()
end

function script.QueryWeapon1()
	return currentFlare()
end

function script.AimWeapon1()
	return true
end

function script.FireWeapon1()
	cycleLauncher()
end

function script.AimFromWeapon2()
	return currentFlare()
end

function script.QueryWeapon2()
	return currentFlare()
end

function script.AimWeapon2()
	return true
end

function script.BlockShot2()
	if Spring.GetGameFrame() < nextBarrageFrame then
		return true
	end

	return barrageTargetIsWater()
end

function script.FireWeapon2()
	cycleLauncher()
	StartThread(nudgeAfterBarrage)
end

function script.EndBurst2()
	nextBarrageFrame = Spring.GetGameFrame() + barrageCooldownFrames
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth

	if severity <= 0.25 then
		Explode(base, SFX.BITMAPONLY + SFX.NO_HEATCLOUD)
		Explode(rwing, SFX.FIRE + SFX.SMOKE + SFX.FALL + SFX.NO_HEATCLOUD)
		Explode(lwing, SFX.FIRE + SFX.SMOKE + SFX.FALL + SFX.NO_HEATCLOUD)
		Explode(body, SFX.BITMAPONLY + SFX.NO_HEATCLOUD)
		Explode(rjet, SFX.BITMAPONLY + SFX.NO_HEATCLOUD)
		Explode(ljet, SFX.BITMAPONLY + SFX.NO_HEATCLOUD)
		return 1
	elseif severity <= 0.5 then
		Explode(base, SFX.BITMAPONLY + SFX.NO_HEATCLOUD)
		Explode(rwing, SFX.FALL + SFX.NO_HEATCLOUD)
		Explode(lwing, SFX.FIRE + SFX.SMOKE + SFX.FALL + SFX.NO_HEATCLOUD)
		Explode(body, SFX.BITMAPONLY + SFX.NO_HEATCLOUD)
		Explode(rjet, SFX.BITMAPONLY + SFX.NO_HEATCLOUD)
		Explode(ljet, SFX.FIRE + SFX.SMOKE + SFX.FALL + SFX.NO_HEATCLOUD)
		return 2
	elseif severity <= 0.99 then
		Explode(base, SFX.BITMAPONLY + SFX.NO_HEATCLOUD)
		Explode(rwing, SFX.EXPLODE_ON_HIT + SFX.SMOKE + SFX.FALL + SFX.NO_HEATCLOUD)
		Explode(lwing, SFX.FIRE + SFX.SMOKE + SFX.FALL + SFX.NO_HEATCLOUD)
		Explode(body, SFX.BITMAPONLY + SFX.NO_HEATCLOUD)
		Explode(rjet, SFX.BITMAPONLY + SFX.NO_HEATCLOUD)
		Explode(ljet, SFX.EXPLODE_ON_HIT + SFX.FIRE + SFX.FALL + SFX.NO_HEATCLOUD)
		return 3
	else
		Explode(base, SFX.BITMAPONLY + SFX.NO_HEATCLOUD)
		Explode(rwing, SFX.EXPLODE_ON_HIT + SFX.FIRE + SFX.FALL + SFX.NO_HEATCLOUD)
		Explode(lwing, SFX.FIRE + SFX.FALL + SFX.NO_HEATCLOUD)
		Explode(body, SFX.EXPLODE_ON_HIT + SFX.FIRE + SFX.FALL + SFX.NO_HEATCLOUD)
		Explode(rjet, SFX.BITMAPONLY + SFX.NO_HEATCLOUD)
		Explode(ljet, SFX.EXPLODE_ON_HIT + SFX.FIRE + SFX.FALL + SFX.NO_HEATCLOUD)
		return 3
	end
end
