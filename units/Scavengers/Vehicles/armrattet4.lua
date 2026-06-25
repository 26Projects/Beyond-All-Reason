return {
	armrattet4 = {
		maxacc = 0.0138,
		maxdec = 0.08759,
		energycost = 250000,
		metalcost = 25000,
		buildpic = "scavengers/armrattet4.DDS",
		buildtime = 250000,
		canmove = true,
		collisionvolumeoffsets = "0 0 -2",
		collisionvolumescales = "80 51 98",
		collisionvolumetype = "Box",
		corpse = "DEAD",
		explodeas = "bantha",
		footprintx = 5,
		footprintz = 5,
		leavetracks = true,
		mass = 1000000,
		health = 83000,
		maxslope = 10,
		speed = 24.0,
		maxwaterdepth = 12,
		movementclass = "EPICVEH",
		nochasecategory = "VTOL",
		objectname = "Units/scavboss/armrattet4.s3o",
		script = "Units/scavboss/armrattet4.cob",
		seismicsignature = 0,
		selfdestructas = "banthaSelfd",
		sightdistance = 600,
		trackoffset = 3,
		trackstrength = 64,
		tracktype = "armstump_tracks",
		trackwidth = 104,
		turninplace = true,
		turninplaceanglelimit = 360,
		turninplacespeedlimit = 1,
		turnrate = 150,

		customparams = {
			unitgroup = 'weapon',
			basename = "base",
			firingceg = "barrelshot-large",
			kickback = "-0.4",
			lumamult = "1.2",
			model_author = "Flaka",
			normaltex = "unittextures/Arm_normal.dds",
			subfolder = "other/scavengers",
			techlevel = 3,
			weapon1turretx = 45,
			weapon1turrety = 80,
		},

		featuredefs = {
			dead = {
				blocking = true,
				category = "corpses",
				collisionvolumeoffsets = "-0.0399932861328 0.00128356933594 -0.564636230469",
				collisionvolumescales = "75.7996826172 57.2875671387 87.4318847656",
				collisionvolumetype = "Box",
				damage = 60000,
				footprintx = 5,
				footprintz = 5,
				height = 60,
				metal = 12500,
				object = "Units/scavboss/armrattet4_dead.s3o",
				reclaimable = true,
			},
		},

		sfxtypes = {
			explosiongenerators = {
				[1] = "custom:none",
				[2] = "custom:none",
			},
		},

		sounds = {
			canceldestruct = "cancel2",
			underattack = "warning1",
			cant = {
				[1] = "cantdo4",
			},
			count = {
				[1] = "count6",
				[2] = "count5",
				[3] = "count4",
				[4] = "count3",
				[5] = "count2",
				[6] = "count1",
			},
			ok = {
				[1] = "tarmmove",
			},
			select = {
				[1] = "tarmsel",
			},
		},

		weapondefs = {
			arm_bosscannon =  {
				alphadecay = 0.02,
				areaofeffect = 8,
				avoidfeature = false,
				burnblow = true,

				craterareaofeffect = 0,
				craterboost = 0,
				cratermult = 0,

				edgeeffectiveness = 0.9,

				explosiongenerator = "custom:laserhit-beamer",
				cegtag = "gauss-trail",

				gravityaffected = "false",

				impulsefactor = 1.5,
				impulseboost = 1.0,

				name = "Heavy Gauss Cannon",

				nogap = false,
				noselfdamage = true,

				range = 730,
				reloadtime = 1.6,

				separation = 1.8,

				size = 8,
				sizedecay = 0.01,

				soundhit = "xplosml2",
				soundhitwet = "splshbig",
				soundstart = "railgun",

				stages = 10,

				targetmoveerror = 0.05,  -- more accurate
				tolerance = 8000,
				turret = true,

				weapontype = "Cannon",
				turret = true,
				weaponvelocity = 450,

				customparams = {
					exclude_preaim = true,
					gauss_ground_ceg = "gauss-trail-groundhit",
					gauss_ground_interval = 2,
					gauss_ground_backoffset = 12,
				},

				damage = {
					default = 675,
					hvyboats = 472.5,
					subs = 300,
					vtol = 26,
				},
			},
		},
		weapons = {
			[1] = {
				badtargetcategory = "VTOL",
				def = "ARM_BOSSCANNON",
				onlytargetcategory = "NOTSUB",
				fastautoretargeting = true,
			},
		},
	},
}
