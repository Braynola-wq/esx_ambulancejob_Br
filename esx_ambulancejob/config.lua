Config                            = {}

Config.DrawDistance               = 50.0

Config.Marker                     = { type = 1, x = 1.5, y = 1.5, z = 0.5, r = 102, g = 0, b = 102, a = 100, rotate = false }

Config.ReviveReward               = 700  -- revive reward, set to 0 if you don't want it enabled
Config.HealReward 				  = 250
Config.BodyReward 				  = 350
Config.DeathReward				  = 350
Config.SocietyReward              = 3500
Config.AntiCombatLog              = true -- enable anti-combat logging?
Config.LoadIpl                    = false -- disable if you're using fivem-ipl or other IPL loaders



Config.BloodPrizes = {
    ["O-"] = 3500,
    ["O+"] = 3000,
    ["A-"] = 2500,
    ["A+"] = 2500,
    ["B-"] = 2500,
    ["B+"] = 2500,
    ["AB-"] = 3500,
    ["AB+"] = 3000
}

Config.BodyMission = {
	personal = 5000,
	society = 1500,
	morgue = vector3(306.16, -594.99, 43.28),
	missions = {
		{coords = vector3(-528.23, -321.87, 35.19)},
		{coords = vector3(-736.89, -416.32, 35.48)},
		{coords = vector3(-603.22, -607.38, 34.68)},
		{coords = vector3(-493.48, -960.36, 23.74)},
		{coords = vector3(-708.72, -1407.25, 5.0)},
		{coords = vector3(-1084.49, -1346.45, 5.08)},
		{coords = vector3(-1377.52, -517.08, 30.94)},
		{coords = vector3(-1280.02, -124.0, 45.76)},
		{coords = vector3(-1393.7, 61.78, 53.56)},
		{coords = vector3(-1496.24, 1513.47, 115.21)},
		{coords = vector3(-1285.44, 2526.98, 19.6)},
		{coords = vector3(-468.6, 2860.02, 34.45)},
		{coords = vector3(-111.2, 2802.18, 53.08)},
		{coords = vector3(180.24, 3059.53, 43.18)},
		{coords = vector3(344.5, 3424.44, 36.22)},
		{coords = vector3(916.13, 3588.18, 33.41)},
		{coords = vector3(1372.71, 3594.47, 34.86)},
		{coords = vector3(1702.93, 3597.41, 35.44)},
		{coords = vector3(1911.44, 3707.0, 32.72)},
		{coords = vector3(1974.17, 3746.47, 32.22)},
		{coords = vector3(2493.11, 4116.56, 38.34)},
		{coords = vector3(2148.96, 4760.18, 41.15)},
	}
}


Config.Locale                     = 'en'

local second = 1000
local minute = 60 * second

Config.EarlyRespawnTimer          = 4 * minute  -- Time til respawn is available
Config.BleedoutTimer              = 10 * minute -- Time til the player bleeds out

Config.EnablePlayerManagement     = true

Config.RemoveWeaponsAfterRPDeath  = true
Config.RemoveCashAfterRPDeath     = true
Config.RemoveItemsAfterRPDeath    = true

-- Let the player pay for respawning early, only if he can afford it.
Config.EarlyRespawnFine           = false
Config.EarlyRespawnFineAmount     = 5000


Config.RespawnPoint = { 
	{coords = vector3(315.16, -590.72, 43.28), heading = 48.5},
	{coords = vector3(357.08, -596.94, 28.78), heading = 255.5},
	{coords = vector3(340.57, -1396.05, 33.00), heading = 44.5},
	{coords = vector3(-496.89, -335.9, 34.5), heading = 258.5},
}

Config.RespawnAnimations = {
	"shakeoff",
	"adjusttie",
	"adjust",
	"damn",
}

Config.DonutPrice = 100
Config.ColaPrice = 80

Config.Hospitals = {

	CentralLosSantos = {

		Blip = {
			coords = vector3(302.34, -586.85, 43.28),
			sprite = 61,
			scale  = 1.3,
			color  = 0
		},

		AmbulanceActions = {
			vector3(298.68, -598.12, 42.28)
		},

		Pharmacies = {
			vector3(306.76, -601.84, 42.28)
		},

		Kitchen = {
			vector3(304.36, -599.84, 43.28)
		},

		FastTravels = {
			{
				name = "hospitalbottom",
				label = "בית חולים למטה",
				jobs = {["police"]=0,["ambulance"]=0},
				From = vector4(325.65, -603.44, 42.60, 136.0),
				Arrival = vector4(327.45, -603.16, 42.28, 341.64),
				To = {
					[1] = {name = "hospitalroof"},
					[2] = {name = "hospitalgarage"}
				}
			},
			{
				name = "hospitalroof",
				label = "בית חולים למעלה",
				jobs = {["police"]=0,["ambulance"]=0},
				From = vector4(338.65, -583.88, 73.16, 74.1),
				To = {
					[1] = {name = "hospitalbottom"},
					[2] = {name = "hospitalgarage"}
				}
			},
			{
				name = "hospitalgarage",
				label = "גראז בית חולים",
				jobs = {["police"]=0,["ambulance"]=0},
				From = vector4(341.06, -582.50, 28.10, 249.1),
				Arrival = vector4(343.38, -581.65, 27.8, 70.25),
				To = {
					[1] = {name = "hospitalroof"},
					[2] = {name = "hospitalbottom"}
				}
			},
			{
				name = "policeroof",
				label = "גג תחנת משטרה",
				jobs = {["police"]=0},
				From = vector4(-577.79, -131.16, 51.02, 116.0),
				Arrival = vector4(-579.93, -131.11, 51.02, 293.83),
				To = {
					[1] = {name = "policekitchen"},
					[2] = {name = "policemiddle"},
					[3] = {name = "policebottom"}
				}
			},
			{
				name = "policekitchen",
				label = "מטבח תחנת משטרה",
				jobs = {["police"]=0},
				From = vector4(-574.96, -135.83, 47.12, 288.0),
				Arrival = vector4(-572.95, -135.89, 46.92, 114.48),
				To = {
					[1] = {name = "policeroof"},
					[2] = {name = "policemiddle"},
					[3] = {name = "policebottom"}
				}
			},
			{
				name = "policemiddle",
				label = "תחנת משטרה משרדים",
				jobs = {["police"]=0},
				From = vector4(-574.64, -135.63, 42.00, 293.0),
				Arrival = vector4(-572.88, -135.81, 41.86, 112.9),
				To = {
					[1] = {name = "policeroof"},
					[2] = {name = "policekitchen"},
					[3] = {name = "policebottom"}
				}
			},
			{
				name = "policebottom",
				label = "תחנת משטרה למטה",
				jobs = {["police"]=0},
				From = vector4(-570.95, -129.1, 37.55, 111.0),
				Arrival = vector4(-573.21, -129.23, 37.45, 280.25),
				To = {
					[1] = {name = "policeroof"},
					[2] = {name = "policemiddle"},
					[3] = {name = "policekitchen"}
				}
			}
			

			
		}
	},
	-- SandyHospital = {

		-- Blip = {
		-- 	coords = vector3(1830.76, 3682.32, 34.27),
		-- 	sprite = 61,
		-- 	scale  = 1.3,
		-- 	color  = 0
		-- },

		-- AmbulanceActions = {
		-- 	vector3(1838.72, 3673.23, 33.28)
		-- },

		-- Pharmacies = {
		-- 	vector3(1835.95, 3671.85, 33.28)
		-- },

		-- Kitchen = {
		-- 	vector3(1832.73, 3691.59, 34.27)
		-- },
		

	-- }
}
