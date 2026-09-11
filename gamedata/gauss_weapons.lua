-- Shared Gauss classification, CEG, and deferred-light settings.
-- Weapon exceptions may disable detection with false or force a size class.
local settings = {
	classes = {
		Tiny = {
			cegTag = "gauss-trail-tiny",
			light = { radius = 44, a = 0.12 },
			trail = { interval = 3, chance = 0.65, backOffset = 7, jitter = 3, radius = 24, lifetime = 4 },
		},
		Small = {
			cegTag = "gauss-trail-small",
			light = { radius = 64, a = 0.16 },
			trail = { interval = 3, chance = 0.75, backOffset = 9, jitter = 4, radius = 32, lifetime = 5 },
		},
		Medium = {
			cegTag = "gauss-trail-medium",
			light = { radius = 90, a = 0.22 },
			trail = { interval = 2, chance = 0.80, backOffset = 11, jitter = 5, radius = 42, lifetime = 6 },
		},
		Big = {
			cegTag = "gauss-trail-big",
			light = { radius = 125, a = 0.30 },
			trail = { interval = 2, chance = 0.90, backOffset = 14, jitter = 7, radius = 56, lifetime = 7 },
		},
	},
	damageThresholds = {
		Tiny = 100,
		Small = 250,
		Medium = 600,
	},
	weaponExceptions = {
		armprowl_armmech_cannon = "Small",
		armmar_armmech_cannon = "Small",
		armmeatball_armmech_cannon = "Small",
		armmav_armmav_weapon = "Medium",
		armcroc_arm_triton = "Small",
		armkraken_armmech_cannon = "Small",
		armpb_armpb_weapon = "Big",
		corvipe_vipersabot = "Big",
		corkorg_corkorg_fire = "Small",
		armrattet4_arm_bosscannon = "Big",
	},
}

function settings.GetSize(generatedName, displayName, cegTag, customParams, damage)
	generatedName = string.lower(generatedName or "")
	local baseGeneratedName = string.gsub(generatedName, "_scav_", "_", 1)
	local exception = settings.weaponExceptions[generatedName]
	if exception == nil then
		exception = settings.weaponExceptions[baseGeneratedName]
	end
	if exception ~= nil then
		return exception or nil
	end

	customParams = customParams or {}
	if customParams.gauss_light ~= nil then
		local value = tostring(customParams.gauss_light):lower()
		if value == "0" or value == "false" then
			return nil
		end
	end
	if customParams.gauss_size and settings.classes[customParams.gauss_size] then
		return customParams.gauss_size
	end

	displayName = string.lower(displayName or "")
	cegTag = string.lower(cegTag or "")
	local isGauss = string.find(generatedName, "gauss", 1, true)
		or string.find(displayName, "gauss", 1, true)
		or string.find(cegTag, "gauss", 1, true)
	if not isGauss then
		return nil
	end

	damage = tonumber(damage) or 0
	if damage <= settings.damageThresholds.Tiny then
		return "Tiny"
	elseif damage <= settings.damageThresholds.Small then
		return "Small"
	elseif damage <= settings.damageThresholds.Medium then
		return "Medium"
	end
	return "Big"
end

return settings
