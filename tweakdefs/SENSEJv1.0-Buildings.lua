-- SENSEJv1.0 Buildings - Competitive sensor normalization tweakdef for Beyond All Reason.
-- Paste a base64-encoded copy of this file into the `tweakdefs` modoption.

local function applyUnitChanges(unitName, changes)
	local unitDef = UnitDefs[unitName]
	if not unitDef then
		Spring.Echo("Sensor normalization tweakdef: missing UnitDef " .. unitName)
		return
	end

	for field, value in pairs(changes) do
		unitDef[field] = value
	end
end

-- T1 jammer towers: Armada baseline.
local t1JammerTower = {
	metalcost = 240,
	energycost = 8500,
	buildtime = 9950,
	radardistancejam = 500,
	energyupkeep = 40,
}

applyUnitChanges("armjamt", t1JammerTower)
applyUnitChanges("corjamt", t1JammerTower)
applyUnitChanges("legjam", t1JammerTower)

-- T1 floating radar/sonar towers: Armada baseline.
local t1FloatingRadar = {
	metalcost = 130,
	energycost = 1000,
	buildtime = 1800,
	radardistance = 2100,
	sonardistance = 900,
	health = 110,
	sightdistance = 760,
}

applyUnitChanges("armfrad", t1FloatingRadar)
applyUnitChanges("corfrad", t1FloatingRadar)
applyUnitChanges("legfrad", t1FloatingRadar)

-- T1 standalone sonar structures: Armada baseline.
local t1Sonar = {
	metalcost = 20,
	energycost = 450,
	buildtime = 910,
	sonardistance = 1200,
	health = 56,
	sightdistance = 515,
}

applyUnitChanges("armsonar", t1Sonar)
applyUnitChanges("corsonar", t1Sonar)

-- T2 land radar towers: Cortex baseline.
local t2RadarTower = {
	metalcost = 400,
	energycost = 14000,
	buildtime = 8000,
	radardistance = 3500,
	radaremitheight = 87,
	health = 500,
	sightdistance = 1000,
}

applyUnitChanges("armarad", t2RadarTower)
applyUnitChanges("corarad", t2RadarTower)
applyUnitChanges("legarad", t2RadarTower)

-- T2 land jammer towers: Armada Veil baseline, normalized to a 2x2 footprint.
local t2JammerTower = {
	metalcost = 125,
	energycost = 19000,
	buildtime = 9100,
	radardistancejam = 760,
	energyupkeep = 125,
	health = 830,
	sightdistance = 155,
	footprintx = 2,
	footprintz = 2,
	yardmap = "oooo",
}

applyUnitChanges("armveil", t2JammerTower)
applyUnitChanges("corshroud", t2JammerTower)
applyUnitChanges("legajam", t2JammerTower)

-- Juno structures and stockpiled missiles: reduced entry and operating costs.
local junoStructure = {
	metalcost = 500,
	energycost = 12000,
	buildtime = 20000,
}

local function applyJunoChanges(unitName)
	applyUnitChanges(unitName, junoStructure)

	local unitDef = UnitDefs[unitName]
	local weaponDef = unitDef and unitDef.weapondefs and unitDef.weapondefs.juno_pulse
	if not weaponDef then
		Spring.Echo("Sensor normalization tweakdef: missing Juno weapon for " .. unitName)
		return
	end

	weaponDef.metalpershot = 150
	weaponDef.energypershot = 8000
	weaponDef.stockpiletime = 75
	weaponDef.customparams = weaponDef.customparams or {}
	weaponDef.customparams.stockpilelimit = 5
end

applyJunoChanges("armjuno")
applyJunoChanges("corjuno")
applyJunoChanges("legjuno")

-- T2 advanced sonar towers: Cortex baseline, including 3x3 placement footprint.
local t2SonarTower = {
	metalcost = 160,
	energycost = 2400,
	buildtime = 6100,
	sonardistance = 1600,
	health = 2400,
	sightdistance = 210,
	footprintx = 3,
	footprintz = 3,
	yardmap = "ooooooooo",
	minwaterdepth = 24,
}

applyUnitChanges("armason", t2SonarTower)
applyUnitChanges("corason", t2SonarTower)
applyUnitChanges("leganavalsonarstation", t2SonarTower)

