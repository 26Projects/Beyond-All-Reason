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
local PARADROP_MAX_FALL_SPEED = -1.25
local MIN_PARADROP_HORIZONTAL_SPEED_SQ = 0.01
local PARACHUTE_UNIT_NAME = "paradrop_parachute"
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
local hasParadropAnimation = {}
local paradropPiece = {}
local isMineResistant = {}
local isStealthsTransport = {}
local isSelfOnlyAssist = {}
local fallingParatroopers = {}

local function DestroyParachute(data)
	if data and data.parachuteID then
		Spring.UnitDetach(data.parachuteID)
		Spring.DestroyUnit(data.parachuteID, false, true)
		data.parachuteID = nil
	end
end

local function StopParadropAnimation(unitID)
	local data = fallingParatroopers[unitID]
	if not data then
		return
	end

	fallingParatroopers[unitID] = nil
	DestroyParachute(data)
	Spring.CallCOBScript(unitID, "EndParadropPose", 0)
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
	if cp.paradrop_animation then
		hasParadropAnimation[udid] = true
		paradropPiece[udid] = cp.paradrop_piece
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
	local paradropData = fallingParatroopers[unitID]
	fallingParatroopers[unitID] = nil
	DestroyParachute(paradropData)
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
	if hasParadropAnimation[unitDefID] then
		local x, y, z = Spring.GetUnitPosition(unitID)
		if x and y - Spring.GetGroundHeight(x, z) > 5 then
			local _, yaw = Spring.GetUnitRotation(unitID)
			local data = {
				originalYaw = yaw or 0,
				yaw = yaw or 0,
			}
			fallingParatroopers[unitID] = data
			Spring.CallCOBScript(unitID, "StartParadropPose", 0)

			local pieceName = paradropPiece[unitDefID]
			local pieceMap = pieceName and Spring.GetUnitPieceMap(unitID)
			local pieceNum = pieceMap and pieceMap[pieceName]
			if pieceNum then
				local parachuteID = Spring.CreateUnit(PARACHUTE_UNIT_NAME, x, y, z, 0, teamID)
				if parachuteID then
					data.parachuteID = parachuteID
					Spring.SetUnitNeutral(parachuteID, true)
					Spring.SetUnitBlocking(parachuteID, false, false, false, false, false, false, false)
					Spring.SetUnitNoMinimap(parachuteID, true)
					Spring.SetUnitNoSelect(parachuteID, true)
					Spring.UnitAttach(unitID, parachuteID, pieceNum, true)
				end
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
		if not x or y - Spring.GetGroundHeight(x, z) <= 5 then
			if x then
				StopParadropAnimation(unitID)
			else
				fallingParatroopers[unitID] = nil
				DestroyParachute(data)
			end
		else
			local velocityX, velocityY, velocityZ = Spring.GetUnitVelocity(unitID)
			if velocityY < PARADROP_MAX_FALL_SPEED then
				velocityY = PARADROP_MAX_FALL_SPEED
				Spring.SetUnitVelocity(unitID, velocityX, velocityY, velocityZ)
			end
			if velocityX and ((velocityX * velocityX) + (velocityZ * velocityZ) > MIN_PARADROP_HORIZONTAL_SPEED_SQ) then
				data.yaw = math.atan2(velocityX, velocityZ)
			end
			Spring.SetUnitRotation(unitID, 0, data.yaw, 0)
		end
	end
end
