-- SENSEJv1.0 Units - Competitive sensor normalization tweakdef for Beyond All Reason.
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

-- T2 radar bots: Cortex baseline.
local t2RadarBot = {
	metalcost = 99,
	energycost = 1350,
	buildtime = 5000,
	radardistance = 2200,
	speed = 45,
	health = 390,
	sightdistance = 925,
	maxacc = 0.05635,
	maxdec = 0.2,
	turnrate = 670.45001,
}

applyUnitChanges("armmark", t2RadarBot)
applyUnitChanges("corvoyr", t2RadarBot)
applyUnitChanges("legaradk", t2RadarBot)

-- T2 jammer bots: Armada baseline, with speed reduced to 40.5.
local t2JammerBot = {
	metalcost = 78,
	energycost = 1400,
	buildtime = 6000,
	radardistancejam = 450,
	energyupkeep = 80,
	speed = 40.5,
	health = 340,
	sightdistance = 380,
	maxacc = 0.138,
	maxdec = 0.5175,
	turnrate = 1201.75,
}

applyUnitChanges("armaser", t2JammerBot)
applyUnitChanges("corspec", t2JammerBot)
applyUnitChanges("legajamk", t2JammerBot)

-- T2 radar vehicles: Armada baseline, with Cortex speed (48).
local t2RadarVehicle = {
	metalcost = 125,
	energycost = 2000,
	buildtime = 7500,
	radardistance = 2300,
	speed = 48,
	health = 980,
	sightdistance = 900,
	maxacc = 0.04878,
	maxdec = 0.1,
	turnrate = 605,
}

applyUnitChanges("armseer", t2RadarVehicle)
applyUnitChanges("corvrad", t2RadarVehicle)
applyUnitChanges("legavrad", t2RadarVehicle)

-- T2 jammer vehicles: Cortex baseline, with speed increased to 48.
local t2JammerVehicle = {
	metalcost = 105,
	energycost = 1900,
	buildtime = 7500,
	radardistancejam = 450,
	energyupkeep = 80,
	speed = 48,
	health = 580,
	sightdistance = 330,
	maxacc = 0.03583,
	maxdec = 0.1,
	turnrate = 619.29999,
}

applyUnitChanges("armjam", t2JammerVehicle)
applyUnitChanges("coreter", t2JammerVehicle)
applyUnitChanges("legavjam", t2JammerVehicle)

-- T1 air scouts: Cortex Fink baseline, with health increased to 126.
local t1AirScout = {
	metalcost = 51,
	energycost = 1450,
	buildtime = 2400,
	radardistance = 1120,
	sightdistance = 835,
	speed = 360,
	health = 126,
	cruisealtitude = 110,
	maxacc = 0.1825,
	maxdec = 0.0125,
	maxaileron = 0.0144,
	maxbank = 0.8,
	maxelevator = 0.01065,
	maxpitch = 0.625,
	maxrudder = 0.00615,
	speedtofront = 0.06125,
	turnradius = 64,
	wingangle = 0.06315,
	wingdrag = 0.06,
}

applyUnitChanges("armpeep", t1AirScout)
applyUnitChanges("corfink", t1AirScout)

-- T2 radar/sonar planes: Cortex Condor baseline.
local t2AirScout = {
	metalcost = 180,
	energycost = 8300,
	buildtime = 16000,
	radardistance = 2400,
	sonardistance = 1200,
	sightdistance = 1250,
	speed = 321,
	health = 990,
	cruisealtitude = 110,
	maxacc = 0.1575,
	maxdec = 0.0375,
	maxaileron = 0.01366,
	maxbank = 0.8,
	maxelevator = 0.00991,
	maxpitch = 0.625,
	maxrudder = 0.00541,
	speedtofront = 0.06417,
	turnradius = 64,
	wingangle = 0.06241,
	wingdrag = 0.11,
}

applyUnitChanges("armawac", t2AirScout)
applyUnitChanges("corawac", t2AirScout)

-- T2 naval jammer ships: Armada Bermuda baseline.
-- Legion's hybrid radar/jammer ship is intentionally excluded.
local t2JammerShip = {
	metalcost = 310,
	energycost = 5000,
	buildtime = 20000,
	radardistancejam = 980,
	energyupkeep = 90,
	speed = 45,
	health = 1350,
	sightdistance = 390,
	maxacc = 0.04059,
	maxdec = 0.04059,
	turnrate = 405,
}

applyUnitChanges("armsjam", t2JammerShip)
applyUnitChanges("corsjam", t2JammerShip)

-- T2 spy bots: Armada Ghost baseline, with Cortex health (380).
local t2SpyBot = {
	metalcost = 135,
	energycost = 8800,
	buildtime = 12000,
	health = 380,
	speed = 65.4,
	sightdistance = 550,
	cloakcost = 15,
	cloakcostmoving = 40,
	mincloakdistance = 75,
	maxacc = 0.276,
	maxdec = 0.69,
	turnrate = 1581.25,
	turninplacespeedlimit = 1.4388,
}

applyUnitChanges("armspy", t2SpyBot)
applyUnitChanges("corspy", t2SpyBot)
applyUnitChanges("legaspy", t2SpyBot)

-- Cortex Forge combat engineer: load the existing extra unit when necessary,
-- add it to the T2 vehicle plant, and give it Dragon's Maw weapon behavior.
local function configureCorForge()
	if not UnitDefs.corforge then
		local loaded = VFS.Include("units/Scavengers/Vehicles/corforge.lua")
		if type(loaded) == "table" then
			UnitDefs.corforge = loaded.corforge
		end
	end

	local forge = UnitDefs.corforge
	local dragonMaw = UnitDefs.cormaw
	local vehiclePlant = UnitDefs.coravp
	if not forge or not dragonMaw or not vehiclePlant then
		Spring.Echo("Sensor normalization tweakdef: unable to configure corforge")
		return
	end

	local dragonMawWeapon = dragonMaw.weapondefs and dragonMaw.weapondefs.dmaw
	if not dragonMawWeapon then
		Spring.Echo("Sensor normalization tweakdef: Dragon's Maw weapon is missing")
		return
	end

	forge.weapondefs = forge.weapondefs or {}
	forge.weapons = forge.weapons or {}
	local forgeWeapon = {}
	for field, value in pairs(dragonMawWeapon) do
		forgeWeapon[field] = value
	end
	forge.weapondefs.flamethrower_ce = forgeWeapon
	forgeWeapon.range = 325
	forgeWeapon.damage = {
		commanders = 16.2,
		default = 10.8,
		subs = 2.7,
	}

	forge.weapons[1] = forge.weapons[1] or {}
	forge.weapons[1].def = "flamethrower_ce"
	forge.weapons[1].onlytargetcategory = "SURFACE"

	vehiclePlant.buildoptions = vehiclePlant.buildoptions or {}
	for _, unitName in ipairs(vehiclePlant.buildoptions) do
		if unitName == "corforge" then
			return
		end
	end
	table.insert(vehiclePlant.buildoptions, "corforge")
end

configureCorForge()
