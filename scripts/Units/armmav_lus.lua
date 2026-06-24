local rflare, lflare, body, pelvis, rthigh, lthigh, rleg, head,
	luparm, ruparm, lloarm, rloarm, lleg, lhipgun, rhipgun, lholster, rhandgun, lhandgun,
	rholster, rfoot, lfoot, aimy1, aimx1 = piece(
	"rflare", "lflare", "body", "pelvis", "rthigh", "lthigh", "rleg", "head",
	"luparm", "ruparm", "lloarm", "rloarm", "lleg", "lhipgun", "rhipgun", "lholster", "rhandgun", "lhandgun",
	"rholster", "rfoot", "lfoot", "aimy1", "aimx1")

local SIG_AIM = 1
local SIG_BUILD = 2
local currentBarrel = 1
local barrels = { rflare, lflare }
local nanoPieces = { body }

local function RestoreAfterDelay()
	SetSignalMask(SIG_AIM)
	Sleep(2000)
	Turn(aimy1, y_axis, 0, math.rad(200))
	Turn(aimx1, x_axis, 0, math.rad(150))
end

function script.Create()
	Hide(lflare)
	Hide(rflare)
	Hide(aimx1)
	Hide(aimy1)
	Hide(lhandgun)
	Hide(rhandgun)
	Turn(lflare, x_axis, math.rad(90))
	Turn(rflare, x_axis, math.rad(90))
	Spring.SetUnitNanoPieces(unitID, nanoPieces)
end

function script.StartMoving()
end

function script.StopMoving()
end

local function QueryCurrentBarrel()
	return barrels[currentBarrel]
end

function script.QueryWeapon1()
	return QueryCurrentBarrel()
end

function script.QueryWeapon(weaponID)
	return QueryCurrentBarrel()
end

function script.AimFromWeapon1()
	return body
end

function script.AimFromWeapon(weaponID)
	return body
end

function script.AimWeapon1(heading, pitch)
	Signal(SIG_AIM)
	SetSignalMask(SIG_AIM)
	Turn(aimy1, y_axis, heading, math.rad(250))
	Turn(aimx1, x_axis, -pitch, math.rad(150))
	WaitForTurn(aimy1, y_axis)
	WaitForTurn(aimx1, x_axis)
	StartThread(RestoreAfterDelay)
	return true
end

function script.AimWeapon(weaponID, heading, pitch)
	return script.AimWeapon1(heading, pitch)
end

function script.FireWeapon1()
	local flare = QueryCurrentBarrel()
	EmitSfx(flare, 1024)
	currentBarrel = 3 - currentBarrel
end

function script.FireWeapon(weaponID)
	script.FireWeapon1()
end

function script.StartBuilding(heading, pitch)
	Signal(SIG_BUILD)
	SetSignalMask(SIG_BUILD)
	Spring.SetUnitNanoPieces(unitID, nanoPieces)
	Turn(aimy1, y_axis, heading, math.rad(250))
	Turn(aimx1, x_axis, -pitch, math.rad(150))
	WaitForTurn(aimy1, y_axis)
	Spring.UnitScript.SetUnitValue(COB.INBUILDSTANCE, 1)
	return true
end

function script.StopBuilding()
	Signal(SIG_BUILD)
	SetSignalMask(SIG_BUILD)
	Spring.UnitScript.SetUnitValue(COB.INBUILDSTANCE, 0)
	StartThread(RestoreAfterDelay)
	return true
end

function script.QueryNanoPiece()
	return body
end

function script.QueryBuildInfo()
	return body
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if severity <= 0.25 then
		Explode(pelvis, SFX.NONE + SFX.NO_HEATCLOUD)
		Explode(body, SFX.NONE + SFX.NO_HEATCLOUD)
		Explode(lloarm, SFX.NONE + SFX.NO_HEATCLOUD)
		return 1
	elseif severity <= 0.5 then
		Explode(pelvis, SFX.SMOKE + SFX.FIRE + SFX.EXPLODE + SFX.NO_HEATCLOUD)
		Explode(body, SFX.SMOKE + SFX.FIRE + SFX.EXPLODE + SFX.NO_HEATCLOUD)
		Explode(luparm, SFX.SMOKE + SFX.FIRE + SFX.EXPLODE + SFX.NO_HEATCLOUD)
		Explode(lloarm, SFX.EXPLODE + SFX.NO_HEATCLOUD)
		return 2
	end

	Explode(pelvis, SFX.SMOKE + SFX.FIRE + SFX.EXPLODE + SFX.NO_HEATCLOUD)
	Explode(body, SFX.SMOKE + SFX.FIRE + SFX.EXPLODE + SFX.NO_HEATCLOUD)
	Explode(luparm, SFX.SMOKE + SFX.FIRE + SFX.EXPLODE + SFX.NO_HEATCLOUD)
	Explode(lloarm, SFX.SMOKE + SFX.FIRE + SFX.EXPLODE + SFX.NO_HEATCLOUD)
	return 3
end
