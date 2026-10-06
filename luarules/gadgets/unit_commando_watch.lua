--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local gadget = gadget ---@type Gadget

function gadget:GetInfo()
	return {
		name = "Commando Watch",
		desc = "Commando Watch",
		author = "TheFatController",
		date = "Aug 17, 2010",
		license = "GNU GPL, v2 or later",
		layer = 0,
		enabled = true,
	}
end

if not gadgetHandler:IsSyncedCode() then
	return false
end

local MAPSIZEX = Game.mapSizeX
local MAPSIZEZ = Game.mapSizeZ
local PARADROP_GROUND_CLEARANCE = 5
local PARADROP_MAX_FALL_SPEED = -1.25
local PARADROP_JET_FALL_SPEED = -0.75
local PARADROP_MIN_LANDING_SPEED = -0.25
local PARADROP_JET_START_FRACTION = 0.35
local PARADROP_TUMBLE_JET_DELAY = math.floor(Game.gameSpeed * 1.5 + 0.5)
local PARADROP_UPRIGHT_FRACTION = 0.16
local PARADROP_MIN_JET_START_HEIGHT = 18
local PARADROP_MIN_UPRIGHT_HEIGHT = 10
local PARADROP_JET_BRAKE_FRAMES = 8
local PARADROP_MIN_DRIFT_SECONDS = 2.5
local PARADROP_MAX_DRIFT_SECONDS = 4.5
local PARADROP_MIN_DRIFT_HEIGHT = 100
local PARADROP_MAX_DRIFT_HEIGHT = 200
local PARADROP_JET_EMIT_INTERVAL = 2
local MIN_PARADROP_HORIZONTAL_SPEED_SQ = 0.01
local CMD_GUARD = CMD.GUARD
local CMD_REPAIR = CMD.REPAIR
local mines = {}
local constructionBuilder = {}
local builderConstructions = {}
local MINE_BLAST = {}
MINE_BLAST[WeaponDefNames.mine_light.id] = true
MINE_BLAST[WeaponDefNames.mine_medium.id] = true
MINE_BLAST[WeaponDefNames.mine_heavy.id] = true

local function SetConstructionBuilder(unitID, builderID)
	constructionBuilder[unitID] = builderID
	if not builderConstructions[builderID] then
		builderConstructions[builderID] = {}
	end
	builderConstructions[builderID][unitID] = true
end

local function ClearConstructionBuilder(unitID)
	local builderID = constructionBuilder[unitID]
	if not builderID then
		return
	end

	constructionBuilder[unitID] = nil
	local constructions = builderConstructions[builderID]
	if constructions then
		constructions[unitID] = nil
		if not next(constructions) then
			builderConstructions[builderID] = nil
		end
	end
end

local isMine = {}
local isParatrooper = {}
local hasParadropController = {}
local hasParadropAnimation = {}
local hasParadropTumble = {}
local isMineResistant = {}
local isStealthsTransport = {}
local isSelfOnlyAssist = {}
local fallingParatroopers = {}

local function SpawnJumpJet(unitID, pieceNum, velocityX, velocityZ)
	if not pieceNum then
		return
	end

	local x, y, z = Spring.GetUnitPiecePosDir(unitID, pieceNum)
	if not x then
		return
	end

	local horizontalSpeed = math.sqrt((velocityX * velocityX) + (velocityZ * velocityZ))
	local directionX = 0
	local directionZ = 0
	if horizontalSpeed > 0.01 then
		directionX = -velocityX / horizontalSpeed
		directionZ = -velocityZ / horizontalSpeed
	end
	local directionY = -0.65
	local directionLength = math.sqrt((directionX * directionX) + (directionY * directionY) + (directionZ * directionZ))
	-- Team colors are a local display preference; tint the particles unsynced.
	SendToUnsynced(
		"paradrop_team_jet",
		unitID,
		Spring.GetUnitTeam(unitID),
		x,
		y,
		z,
		directionX / directionLength,
		directionY / directionLength,
		directionZ / directionLength
	)
end

local function StopParadropAnimation(unitID)
	local data = fallingParatroopers[unitID]
	if not data then
		return
	end

	fallingParatroopers[unitID] = nil
	if data.hasPoseAnimation then
		Spring.CallCOBScript(unitID, "EndParadropPose", 0)
	end
	Spring.SetUnitRotation(unitID, 0, data.originalYaw, 0)
end

for udid, ud in pairs(UnitDefs) do
	local cp = ud.customParams
	if cp.mine then
		isMine[udid] = true
	end
	if cp.paratrooper then
		isParatrooper[udid] = true
	end
	if cp.paradrop_animation or cp.paradrop_tumble then
		hasParadropAnimation[udid] = true
	end
	if cp.paradrop_tumble then
		hasParadropTumble[udid] = true
	end
	-- Jet effects and fall control do not require a unit-script pose animation.
	if cp.paradrop_animation or cp.paradrop_jumpjets then
		hasParadropController[udid] = true
	end
	if cp.mine_resistant then
		isMineResistant[udid] = true
	end
	if cp.stealths_transport then
		isStealthsTransport[udid] = true
	end
	if cp.self_only_assist then
		isSelfOnlyAssist[udid] = true
	end
end

function gadget:Initialize()
	gadgetHandler:RegisterAllowCommand(CMD_GUARD)
	gadgetHandler:RegisterAllowCommand(CMD_REPAIR)
	gadgetHandler:RegisterGlobal("GunslingerTumbleStarted", function(unitID)
		local data = fallingParatroopers[unitID]
		if data and data.hasTumble and not data.upright then
			local frame = Spring.GetGameFrame()
			data.jetIgnitionFrame = frame + PARADROP_TUMBLE_JET_DELAY
			-- Finish the short brake at the height-dependent drift deadline.
			data.brakeStartFrame = frame + data.driftFrames - PARADROP_JET_BRAKE_FRAMES
		end
	end)
end

function gadget:Shutdown()
	gadgetHandler:DeregisterGlobal("GunslingerTumbleStarted")
end

function gadget:UnitPreDamaged(
	unitID,
	unitDefID,
	unitTeam,
	damage,
	paralyzer,
	weaponID,
	projectileID,
	attackerID,
	attackerDefID,
	attackerTeam
)
	if isParatrooper[unitDefID] and weaponID < 0 then
		local x, y, z = Spring.GetUnitPosition(unitID)
		if x < 0 or z < 0 or x > MAPSIZEX or z > MAPSIZEZ then
			Spring.DestroyUnit(unitID)
			return damage, 1
		end
		x, y, z = Spring.GetUnitVelocity(unitID)
		Spring.AddUnitImpulse(unitID, x * -0.66, y * -0.66, z * -0.66)
		return damage * 0.12, 0
	elseif isMineResistant[unitDefID] and MINE_BLAST[weaponID] then
		return damage * 0.12, 0.24
	elseif mines[unitID] and (attackerID == mines[unitID]) then
		return 0, 0
	end
	return damage, 1
end

function gadget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
	if builderID and isMine[unitDefID] and isMineResistant[Spring.GetUnitDefID(builderID)] then
		mines[unitID] = builderID
	end
	if builderID and isSelfOnlyAssist[Spring.GetUnitDefID(builderID)] then
		SetConstructionBuilder(unitID, builderID)
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam, weaponDefID)
	mines[unitID] = nil
	fallingParatroopers[unitID] = nil
	ClearConstructionBuilder(unitID)

	local constructions = builderConstructions[unitID]
	if constructions then
		for constructionID in pairs(constructions) do
			constructionBuilder[constructionID] = nil
		end
		builderConstructions[unitID] = nil
	end
end

function gadget:UnitFinished(unitID, unitDefID, unitTeam)
	mines[unitID] = nil
end

function gadget:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams)
	if not isSelfOnlyAssist[unitDefID] then
		return true
	end

	if cmdID == CMD_GUARD then
		return false
	end

	if cmdID ~= CMD_REPAIR then
		return true
	end

	-- Area repair could select a unit made by another builder, so only permit
	-- direct repair commands targeting a unit this exact builder created.
	if #cmdParams ~= 1 and #cmdParams ~= 5 then
		return false
	end

	local targetID = cmdParams[1]
	return targetID ~= nil and constructionBuilder[targetID] == unitID
end

function gadget:AllowUnitBuildStep(builderID, builderTeam, unitID, unitDefID, part)
	if part <= 0 or not isSelfOnlyAssist[Spring.GetUnitDefID(builderID)] then
		return true
	end

	return constructionBuilder[unitID] == builderID
end

function gadget:UnitLoaded(unitID, unitDefID, unitTeam, transportID, transportTeam)
	StopParadropAnimation(unitID)
	if isStealthsTransport[unitDefID] then
		Spring.SetUnitStealth(transportID, true)
	end
end

function gadget:UnitUnloaded(unitID, unitDefID, teamID, transportID)
	if hasParadropController[unitDefID] then
		local x, y, z = Spring.GetUnitPosition(unitID)
		local clearance = x and y - Spring.GetGroundHeight(x, z)
		if clearance and clearance > PARADROP_GROUND_CLEARANCE then
			local _, yaw = Spring.GetUnitRotation(unitID)
			local pieceMap = Spring.GetUnitPieceMap(unitID)
			local uprightHeight = math.min(
				clearance - 0.5,
				math.max(PARADROP_MIN_UPRIGHT_HEIGHT, clearance * PARADROP_UPRIGHT_FRACTION)
			)
			local data = {
				driftFrames = math.floor(Game.gameSpeed * (
					PARADROP_MIN_DRIFT_SECONDS
					+ (PARADROP_MAX_DRIFT_SECONDS - PARADROP_MIN_DRIFT_SECONDS)
						* math.min(1, math.max(0, (clearance - PARADROP_MIN_DRIFT_HEIGHT)
							/ (PARADROP_MAX_DRIFT_HEIGHT - PARADROP_MIN_DRIFT_HEIGHT)))
				) + 0.5),
				hasPoseAnimation = hasParadropAnimation[unitDefID],
				hasTumble = hasParadropTumble[unitDefID],
				jetStartHeight = math.min(
					clearance - 0.25,
					math.max(PARADROP_MIN_JET_START_HEIGHT, clearance * PARADROP_JET_START_FRACTION)
				),
				leftFootPiece = pieceMap and pieceMap.lfoot,
				originalYaw = yaw or 0,
				rightFootPiece = pieceMap and pieceMap.rfoot,
				uprightHeight = uprightHeight,
				yaw = yaw or 0,
			}
			fallingParatroopers[unitID] = data
			if data.hasPoseAnimation then
				Spring.CallCOBScript(unitID, "StartParadropPose", 0)
			end
		end
	end
	if isStealthsTransport[unitDefID] then
		Spring.SetUnitStealth(transportID, false)
	end
end

function gadget:GameFrame(frame)
	for unitID, data in pairs(fallingParatroopers) do
		local x, y, z = Spring.GetUnitPosition(unitID)
		local clearance = x and y - Spring.GetGroundHeight(x, z)
		if not clearance or clearance <= PARADROP_GROUND_CLEARANCE then
			if x then
				StopParadropAnimation(unitID)
			else
				fallingParatroopers[unitID] = nil
			end
		else
			local velocityX, velocityY, velocityZ = Spring.GetUnitVelocity(unitID)
			-- Time Gunslinger jets from the actual roll, after tuck/holster setup.
			-- Low drops must still ignite in time for the final lowering phase.
			local igniteJets = clearance <= data.jetStartHeight
			if data.hasTumble then
				igniteJets = (data.jetIgnitionFrame and frame >= data.jetIgnitionFrame)
					or clearance <= data.uprightHeight
			end
			if not data.jetsActive and igniteJets then
				data.jetsActive = true
				data.jetStartFrame = frame
				data.jetStartVelocityX = velocityX
				data.jetStartVelocityZ = velocityZ
			end
			if
				data.jetsActive
				and not data.upright
				and clearance <= data.uprightHeight
			then
				data.upright = true
				if data.hasTumble then
					Spring.CallCOBScript(unitID, "EndParadropTumble", 0)
				end
			end

			local velocityChanged = false
			if data.upright then
				-- Hold directly over the landing point throughout final lowering.
				velocityX, velocityZ = 0, 0
				velocityChanged = true
			elseif data.jetsActive then
				local brakeStart = data.jetStartFrame
				if data.hasTumble then brakeStart = data.brakeStartFrame end
				if brakeStart and frame >= brakeStart then
					-- Capture the current momentum when braking actually begins,
					-- rather than restoring an old velocity recorded at jet ignition.
					if not data.brakeVelocityX then
						data.brakeVelocityX, data.brakeVelocityZ = velocityX, velocityZ
					end
					local brakeRatio = math.max(0, 1 - ((frame - brakeStart) / PARADROP_JET_BRAKE_FRAMES))
					velocityX = data.brakeVelocityX * brakeRatio
					velocityZ = data.brakeVelocityZ * brakeRatio
					velocityChanged = true
				end
			end

			local targetFallSpeed = PARADROP_MAX_FALL_SPEED
			if data.jetsActive then
				targetFallSpeed = PARADROP_JET_FALL_SPEED
			end
			if data.upright then
				local decelerationRange = math.max(data.uprightHeight - PARADROP_GROUND_CLEARANCE, 0.01)
				local landingRatio = math.min(
					1,
					math.max(0, (clearance - PARADROP_GROUND_CLEARANCE) / decelerationRange)
				)
				targetFallSpeed = PARADROP_MIN_LANDING_SPEED
					+ ((PARADROP_JET_FALL_SPEED - PARADROP_MIN_LANDING_SPEED) * landingRatio)
			end
			if velocityY < targetFallSpeed then
				velocityY = targetFallSpeed
				velocityChanged = true
			end
			if velocityChanged then
				Spring.SetUnitVelocity(unitID, velocityX, velocityY, velocityZ)
			end
			if velocityX and ((velocityX * velocityX) + (velocityZ * velocityZ) > MIN_PARADROP_HORIZONTAL_SPEED_SQ) then
				data.yaw = math.atan2(velocityX, velocityZ)
			end
			if data.jetsActive and (frame + unitID) % PARADROP_JET_EMIT_INTERVAL == 0 then
				SpawnJumpJet(unitID, data.leftFootPiece, data.jetStartVelocityX, data.jetStartVelocityZ)
				SpawnJumpJet(unitID, data.rightFootPiece, data.jetStartVelocityX, data.jetStartVelocityZ)
			end
			Spring.SetUnitRotation(unitID, 0, data.yaw, 0)
		end
	end
end
