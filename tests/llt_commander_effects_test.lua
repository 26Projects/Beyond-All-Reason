-- Run from the game root: lua tests/llt_commander_effects_test.lua
-- Standalone mocks verify the port without requiring a running Spring match.
local function near(actual, expected)
	assert(math.abs(actual - expected) < 0.00001, tostring(actual) .. " ~= " .. tostring(expected))
end

local function upvalue(fn, wanted, replacement)
	for i = 1, 100 do
		local name, value = debug.getupvalue(fn, i)
		if not name then break end
		if name == wanted then
			if replacement ~= nil then debug.setupvalue(fn, i, replacement) end
			return value
		end
	end
	error("Missing upvalue: " .. wanted)
end

local paths = {
	"units/ArmBuildings/LandDefenceOffence/armllt.lua",
	"units/CorBuildings/LandDefenceOffence/corllt.lua",
	"units/Legion/Defenses/leglht.lua",
}
local cp
for _, path in ipairs(paths) do
	local _, unit = next(dofile(path))
	local _, weapon = next(unit.weapondefs)
	cp = weapon.customparams
	assert(cp.beam_commander_color == "0.992 0.302 0.8")
	assert(cp.beam_commander_thickness_mult == 1.5)
	assert(cp.beam_commander_hit_ceg == "llt-commander-hit-pink")
	assert(weapon.soundstart == "")
	for _, sound in ipairs({cp.beam_default_sound, cp.beam_commander_sound}) do
		local file = assert(io.open(sound, "rb")); file:close()
	end
end
local effect = dofile("effects/llt_commander_hit.lua")[cp.beam_commander_hit_ceg]
assert(effect.inner_ring and effect.outer_ring and effect.white_sparks and effect.orange_sparks)
assert(effect.blowback_cone and effect.blowback_streaks)

local frame, fullView, los, paused = 100, false, true, false
local targetType, targetID = string.byte("u"), 10
local projectiles = {1000}
local sounds, splashes, markers = {}, {}, {}
Game = {armorTypes = {commanders = 1}, gameSpeed = 30, mapSizeX = 4096, mapSizeZ = 4096}
UnitDefs = {
	[1] = {armorType = 1, weapons = {}},
	[2] = {armorType = 0, weapons = {{weaponDef = 1}}},
}
WeaponDefs = {
	[1] = {type = "BeamLaser", customParams = cp, thickness = 2, reload = 0.46667,
		visuals = {colorR = 1, colorG = 0, colorB = 0}},
	[2] = {type = "BeamLaser", customParams = {}, visuals = {colorR = 0, colorG = 1, colorB = 0}},
}
Spring = {
	GetGameFrame = function() return frame end,
	GetLocalAllyTeamID = function() return 0 end,
	GetSpectatingState = function() return fullView, fullView end,
	GetGameSpeed = function() return 1, 1, paused end,
	GetFrameTimeOffset = function() return 0.5 end,
	GetUnitDefID = function(id) return id == 10 and 1 or 2 end,
	GetProjectileTarget = function() return targetType, targetID end,
	GetProjectilePosition = function() return 0, 10, 0 end,
	GetProjectileVelocity = function() return 100, 0, 0 end,
	GetProjectileDefID = function() return 1 end,
	GetProjectileTeamID = function() return 0 end,
	GetTeamAllyTeamID = function() return 0 end,
	GetProjectileOwnerID = function() return 20 end,
	GetProjectilesInRectangle = function() return projectiles end,
	IsPosInLos = function() return los end,
	IsPosInAirLos = function() return los end,
	IsUnitInLos = function() return los end,
	IsAABBInView = function() return true end,
	IsSphereInView = function() return true end,
	GetUnitPosition = function(id)
		if id == 10 then return 100, 0, 0, 100, 10, 0 end
		return 0, 0, 0, 0, 10, 0
	end,
	GetUnitRadius = function() return 20 end,
	GetUnitWeaponState = function() return 0.46667 end,
	PlaySoundFile = function(...) sounds[#sounds + 1] = {...} end,
	SpawnCEG = function(...) splashes[#splashes + 1] = {...} end,
}
GG = {}
GL = {SRC_ALPHA = 770, ONE_MINUS_SRC_ALPHA = 771}
local noOp = function() end
gl = {LuaShader = {}, InstanceVBOTable = {uploadAllElements = noOp}}
gadgetHandler = {IsSyncedCode = function() return false end}
gadget = {}
dofile("luarules/gadgets/gfx_beam_laser_gl4.lua")
local beam = gadget
local build = upvalue(beam.DrawWorld, "buildBeams")
local buffer = {instanceData = {}, maxElements = 64}
upvalue(build, "beamVBO", buffer)
beam:GameFramePost()
build()
assert(buffer.usedElements == 1)
near(buffer.instanceData[4], 0.9) -- 2 * 0.3 * 1.5
near(buffer.instanceData[13], 0.992)
near(buffer.instanceData[14], 0.302)
near(buffer.instanceData[15], 0.8)
assert(#sounds == 1 and sounds[1][1] == cp.beam_commander_sound)
beam:GameFramePost()
assert(#sounds == 1, "Same projectile must not repeat its sound")

-- Fading ghosts retain the commander variant.
projectiles = {}
frame = 101
beam:GameFramePost()
build()
assert(buffer.usedElements == 1)
near(buffer.instanceData[4], 0.9)
near(buffer.instanceData[15], 0.8)

-- Retargeting back to an ordinary unit restores the ordinary beam and sound.
targetID, projectiles, frame = 20, {1001}, 102
beam:GameFramePost()
build()
near(buffer.instanceData[4], 0.6)
near(buffer.instanceData[14], 0)
assert(#sounds == 2 and sounds[2][1] == cp.beam_default_sound)
targetType, projectiles = string.byte("g"), {1002}
beam:GameFramePost()
build()
near(buffer.instanceData[4], 0.6)

gadgetHandler.IsSyncedCode = function() return true end
SendToUnsynced = function(...) markers[#markers + 1] = {...} end
gadget = {}
dofile("luarules/gadgets/gfx_llt_commander_hit.lua")
local impact = gadget
frame = 200
impact:UnitDamaged(10, 1, 0, 20, false, 1, 1000, 20)
assert(#splashes == 1 and #markers == 1)
assert(markers[1][1] == "llt_commander_crit" and markers[1][7] == 14)
near(splashes[1][2], 98) -- Endpoint offset outward toward the shooter.
near(splashes[1][5], -1)
impact:UnitDamaged(20, 2, 0, 20, false, 1, 1000, 20)
impact:UnitDamaged(10, 1, 0, 0, false, 1, 1000, 20)
impact:UnitDamaged(10, 1, 0, 20, false, 2, 1000, 20)
assert(#splashes == 1 and #markers == 1)
frame = 206
impact:UnitDamaged(10, 1, 0, 20, false, 1, 1000, 20)
assert(#splashes == 2 and #markers == 1, "Damage ticks should not duplicate the marker")
frame = 214
impact:UnitDamaged(10, 1, 0, 20, false, 1, -1, 20)
assert(#markers == 2)
Spring.GetUnitWeaponState = function() return 1.1 end
frame = 250
impact:UnitDamaged(10, 1, 0, 20, false, 1, -1, 20)
assert(markers[3][7] == 33, "Use the firing weapon's current reload time")

local addIcon, quads, color, offset, texture, depthMask
gadgetHandler.IsSyncedCode = function() return false end
gadgetHandler.AddSyncAction = function(_, name, fn) assert(name == "llt_commander_crit"); addIcon = fn end
gadgetHandler.RemoveSyncAction = noOp
gl = {
	DepthTest = noOp, DepthMask = function(value) depthMask = value end, Blending = noOp,
	Texture = function(value) texture = value end,
	DeleteTexture = noOp, PushMatrix = noOp, PopMatrix = noOp, Billboard = noOp,
	Translate = function(x, y) if x == 0 then offset = y end end,
	Color = function(r, g, b, a) color = {r, g, b, a} end,
	TexRect = function(...)
		quads[#quads + 1] = {color = color, rise = offset, texture = texture, rect = {...}}
	end,
}
gadget = {}
dofile("luarules/gadgets/gfx_llt_crit_text.lua")
local icon = gadget
icon:Initialize()
los, quads, frame, paused = false, {}, 300, true
addIcon(nil, 10, 100, 10, 0, 300, 20)
icon:DrawWorld()
assert(#quads == 0, "Do not reveal hidden impacts")
los = true
addIcon(nil, 10, 100, 10, 0, 300, 20)
icon:DrawWorld()
assert(#quads == 1)
near(quads[1].color[4], 1)
near(quads[1].rise, 10)
local file = assert(io.open(quads[1].texture, "rb")); file:close()
frame = 310
icon:DrawWorld()
near(quads[2].rise, 30)
near(quads[2].color[4], 1)
frame = 315
icon:DrawWorld()
near(quads[3].rise, 40)
near(quads[3].color[4], 0.5)
assert(texture == false and depthMask == true)
frame = 320
icon:GameFrame(frame)
icon:DrawWorld()
assert(#quads == 3, "Marker must expire after one reload interval")
icon:Shutdown()
print("PASS: unit definitions, commander/normal/ground beams, ghost colors, sounds, impacts, reload timing, icon rise/fade/LOS/expiry")
