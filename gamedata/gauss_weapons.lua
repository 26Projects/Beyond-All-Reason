-- Shared Gauss classification and global-effect settings.
-- Used while processing WeaponDefs and by the deferred-light configuration.
return {
	cegTag = "gauss-trail",
	sizeMultiplier = 1.6,
	minimumRadius = 44,
	weaponExceptions = {
		["armprowl_armmech_cannon"] = true,
		["armmar_armmech_cannon"] = true,
		["armmeatball_armmech_cannon"] = true,
		["armmav_armmav_weapon"] = true,
		["armcroc_arm_triton"] = true,
		["armkraken_armmech_cannon"] = true,
		["armpb_armpb_weapon"] = true,
		["corvipe_vipersabot"] = true,
		["corkorg_corkorg_fire"] = true,
		["armrattet4_arm_bosscannon"] = true,
	},
}
