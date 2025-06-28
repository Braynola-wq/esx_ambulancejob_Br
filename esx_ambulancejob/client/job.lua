local isBusy = false

local var2
	
RegisterNetEvent('ElFatahKuds')
AddEventHandler('ElFatahKuds', function(variable)
    var2 = variable
end)

function OpenAmbulanceActionsMenu()
	local elements = {
		{label = "Outfits", value = "outfits"},
		{label = _U('cloakroom'), value = 'cloakroom'},
		{label = "לוקר אישי", value = "personalstash"}
	}

	if Config.EnablePlayerManagement and ESX.PlayerData.job.grade_name == 'boss' then
		table.insert(elements, {label = _U('boss_actions'), value = 'boss_actions'})
		if(ESX.GetInventoryItem("bloodbag")) then
			table.insert(elements, {label = "מכירת שקיות דם", value = 'sell_bags'})
		end
	end

	ESX.UI.Menu.CloseAll()

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'ambulance_actions', {
		title    = _U('ambulance'),
		align    = 'top-left',
		elements = elements
	}, function(data, menu)
		if data.current.value == 'outfits' then
			ESX.TriggerServerCallback('esx_property:getPlayerDressing', function(dressing)
				local elements = {}

				for i=1, #dressing, 1 do
					table.insert(elements, {
						label = dressing[i],
						value = i
					})
				end

				ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'player_mdressing', {
					title    = 'חדר לבוש מד"א' .. ' - ' .. 'בגדים שלך',
					align    = 'top-left',
					elements = elements
				}, function(data2, menu2)
					TriggerEvent('skinchanger:getSkin', function(skin)
						ESX.TriggerServerCallback('esx_property:getPlayerOutfit', function(clothes)
							TriggerEvent('skinchanger:loadClothes', skin, clothes)
							TriggerEvent('esx_skin:setLastSkin', skin)

							TriggerEvent('skinchanger:getSkin', function(skin)
								TriggerServerEvent('esx_skin:save', skin)
							end)
						end, data2.current.value)
					end)
				end, function(data2, menu2)
					menu2.close()
				end)
			end)
		elseif data.current.value == 'cloakroom' then
			OpenCloakroomMenu()
		elseif data.current.value == 'personalstash' then
			menu.close()
			local identifier = ESX.PlayerData.identifier
			if identifier then
				ESX.SEvent("esx_ambulancejob:AccessLocker")
			else
				ESX.ShowRGBNotification("error",".הפרטים שלך לא נמצאו, נסה מאוחר יותר")
			end
		elseif data.current.value == 'boss_actions' then
			menu.close()
			TriggerEvent('esx_society:openBossMenu', 'ambulance', function(data, menu)
				menu.close()
			end, {wash = false})
		elseif data.current.value == "sell_bags" then
			menu.close()
			if(ESX.PlayerData.job.name == "ambulance") then
				ESX.SEvent("esx_ambulancejob:server:sellbloodbags")
			end
		end
	end, function(data, menu)
		menu.close()
	end)
end

local lastscan

function OpenMobileAmbulanceActionsMenu()

	ESX.UI.Menu.CloseAll()
	local elements = {}
	table.insert(elements, {label = "תפריט החייאות ->", value = "rmenu", hint = "תפריט עם אפשרויות החייאה"})
	table.insert(elements, {label = _U('ems_menu_small'), value = 'small', hintImage = GetConvar("inventory:imagepath","nui://ox_inventory/web/images").."/bandage.png"})
	table.insert(elements, {label = _U('ems_menu_big'), value = 'big', hintImage = GetConvar("inventory:imagepath","nui://ox_inventory/web/images").."/medikit.png"})
	table.insert(elements, {label = _U('ems_menu_putincar'), value = 'put_in_vehicle', hint = "מכניס גופה לרכב"})
	table.insert(elements, {label = "בקשת תשלום", value = "custom_bill", hint = "(לרוב משמש תשלום לניתוחים) נתינת קבלה"})
	table.insert(elements, {label = "הזמנת אמבולנס ->", value = 'call_nayedet', hint = "מזמין אמבולנס אליך בתשלום"})
	table.insert(elements, {label = 'תגבורת מד"א', value = 'backup', hint = 'שולח את המיקום שלך לשאר המד"א ובמוקדן שלהם'})

	if #(GetEntityCoords(PlayerPedId()) - Config.Hospitals.CentralLosSantos.Blip.coords) < 30.0 then
		table.insert(elements, {label = "משימת גופות", value = 'body_mission', hint = "מתחיל משימת גופה"})
	end


	if(ESX.PlayerData.job.grade_name == 'doctor' or ESX.PlayerData.job.grade_name == 'boss') then
		table.insert(elements, {label = '<strong><span style="color:cyan;">בדיקת ניידת</strong>', value = "scanveh", hint = ".פיקוד בלבד, בודק למי שייכת ניידת שמולך"})
	end
	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'citizen_interaction', {
		title    = _U('ems_menu_title'),
		align    = 'top-left',
		elements = elements
	}, function(data, menu)
		if isBusy then return end

		local action = data.current.value
		if(action == 'call_nayedet') then
			ESX.UI.Menu.CloseAll()
			TriggerEvent('esx_ambulancejob:callnayedet')
			return
		elseif action == 'scanveh' then
			ScanVeh()
			return
		elseif action == 'rmenu' then
			revivemenu()
			return
		elseif action == 'backup' then
			ExecuteCommand("callbackup")
			return
		elseif action == "body_mission" then
			if #(GetEntityCoords(PlayerPedId()) - Config.Hospitals.CentralLosSantos.Blip.coords) < 30.0 then
				EMSBodyMission()
			end
			return
		end

		local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
		if closestPlayer == -1 or closestDistance > 2.0 then
			ESX.ShowRGBNotification("error",_U('no_players'))
		else
			if action == 'small' or action == 'big' then
				HealClosestPlayer(closestPlayer,action)
			elseif action == 'put_in_vehicle' then
				if ESX.PlayerData.job.name == "ambulance" then
					TriggerServerEvent('esx_ambulancejob:putInVehicle', GetPlayerServerId(closestPlayer))
				else
					ESX.ShowRGBNotification("error",".אתה לא בעבודה יותר, הפעולה נכשלה")
			   	end
			elseif action == 'custom_bill' then
				DoCustomBill()
			end
		end
	end, function(data, menu)
		menu.close()
	end)
end

function FastTravel(coords, heading)
	if(ESX.PlayerData.job) then
		if(ESX.PlayerData.job.name == 'ambulance' or ESX.PlayerData.job.name == 'police') then

			local playerPed = PlayerPedId()

			DoScreenFadeOut(800)

			while not IsScreenFadedOut() do
				Citizen.Wait(500)
			end

			ESX.Game.Teleport(playerPed, coords, function()
				DoScreenFadeIn(800)

				if heading then
					SetEntityHeading(playerPed, heading)
				end
			end)
			PlaySoundFrontend(-1, "FAKE_ARRIVE", "MP_PROPERTIES_ELEVATOR_DOORS", true);
		else
			ESX.ShowRGBNotification("error",'רק שוטרים ומד"א יכולים להשתמש במעליות האלה')
		end
	end
end

-- Draw markers & Marker logic
CreateThread(function()

	for hospitalNum,hospital in pairs(Config.Hospitals) do
		for k,v in ipairs(hospital.AmbulanceActions) do
			exports.ox_target:addSphereZone({
				name = "AmbulanceActions"..k,
				coords = v + vector3(0.0,0.0,1.0),
				rotation = vector3(0.0,0.0,0.0),
				radius = 1.2,
				drawSprite = true,
				options = {
					{
						label = 'ארון לבוש מד"א',
						icon = "fa-solid fa-shirt",
						iconColor = "red",
						onSelect = OpenAmbulanceActionsMenu,
						distance = 2.5,
						groups = "ambulance",
					}
				}
			})
		end
		for k,v in ipairs(hospital.Pharmacies) do
			exports.ox_target:addSphereZone({
				name = "Pharmacy"..k,
				coords = v + vector3(0.0,0.0,1.0),
				rotation = vector3(0.0,0.0,0.0),
				radius = 1.2,
				drawSprite = true,
				options = {
					{
						label = 'ארון תרופות',
						icon = "fa-solid fa-prescription-bottle-medical fa-bounce",
						iconColor = "red",
						onSelect = OpenPharmacyMenu,
						distance = 2.5,
						groups = "ambulance",
					}
				}
			})
		end

		if hospital.Kitchen then
			for k,v in ipairs(hospital.Kitchen) do
				exports.ox_target:addSphereZone({
					name = "Kitchen"..k,
					coords = v + vector3(0.0,0.0,0.0),
					rotation = vector3(0.0,0.0,0.0),
					radius = 1.2,
					drawSprite = true,
					options = {
						{
							label = 'מטבח מד"א',
							icon = "fa-solid fa-kitchen-set",
							iconColor = "red",
							onSelect = OpenKitchenMenu,
							distance = 2.5,
							groups = "ambulance",
						}
					}
				})

			end
		end
	end
end)

local function GetElevatorByName(name)
	if not name then return end

	for hospitalNum,hospital in pairs(Config.Hospitals) do
		if(hospital.FastTravels) then
			for k,v in pairs(hospital.FastTravels) do
				if v.name == name then
					return v
				end
			end
		end
	end
end

local function showElevator(elevator)
	if not elevator then return end
	local elements = {}

	elements[#elements+1] = {unselectable = true, icon = "fa-solid fa-elevator", title = "תפריט מעליות", description = "בחר לאן ללכת"}
	for k,v in pairs(elevator.To) do
		local ele = GetElevatorByName(v.name)
        elements[#elements+1] = {icon = "fa-solid fa-elevator", title = ele.label, value = "travel", elevator = ele}
    end

	ESX.OpenContext("right", elements, function(menu,element)
        if element.value == "travel" then
			local ele = element.elevator
			if ele then
				ESX.CloseContext()
				if ele.Arrival then
					FastTravel(vector3(ele.Arrival.x,ele.Arrival.y,ele.Arrival.z),ele.Arrival.w)
				else
					FastTravel(vector3(ele.From.x,ele.From.y,ele.From.z),ele.From.w)
				end
			end
		end
	end, function(menu)
		ESX.CloseContext()
	end)
end


CreateThread(function()

	exports['qb-target']:AddGlobalPed({
		options = {
		  {
			type = "client",
			icon = 'fas fa-ambulance', 
			label = "שק גופה",
			action = function(entity)
				if IsPedAPlayer(entity) then return false end 
			  	if(not IsEntityDead(entity)) then return false end
				if(GetPedType(entity) == 28) then return false end
			  	BodyBag(entity)
			end,
			canInteract = function(entity, distance, data)
				if IsPedAPlayer(entity) then return false end
				if(not IsEntityDead(entity)) then return false end
				if(GetPedType(entity) == 28) then return false end
				return true
			end,
			job = "ambulance"
		  }
		},
		distance = 2.5,
	  })

	for hospitalNum,hospital in pairs(Config.Hospitals) do
		if(hospital.FastTravels) then
			for k,v in ipairs(hospital.FastTravels) do
				exports["qb-target"]:AddBoxZone("ambulance:teleport"..k, vector3(v.From.x, v.From.y, v.From.z), 1.1, 1.1, {
					name = "ambulance:teleport"..k,
					heading = v.From.w,
					minZ = v.From.z - 1,
					maxZ = v.From.z + 1,
					debugPoly = false
				}, {
					options = {
					{
						icon = "fa-solid fa-elevator",
						label = "מעלית",
						action = function()
							if(v.jobs[ESX.PlayerData.job.name]) then

								showElevator(v)
							else
								ESX.ShowHDNotification("","No Access to this elevator.","error")
							end
						end,
						job = v.jobs,
					},
					},
					distance = 2.5
				})
			end


		end
	end
end)

RegisterKeyMapping("EMSKEY","Ems F6 Key","keyboard","F6")

RegisterCommand("EMSKEY",function()
	if ESX.PlayerData.job.name == 'ambulance' and not isDead then
		OpenMobileAmbulanceActionsMenu()
	end
end)

function OpenKitchenMenu()
	exports.ox_inventory:openInventory('stash', 'Ambulance_Fridge')
end

RegisterNetEvent('esx_ambulancejob:putInVehicle')
AddEventHandler('esx_ambulancejob:putInVehicle', function()


	local vehicle = ESX.Game.GetClosestVehicle()
	if DoesEntityExist(vehicle) then
		local playerPed = PlayerPedId()
		local coords    = GetEntityCoords(playerPed)
		local maxSeats, freeSeat = GetVehicleMaxNumberOfPassengers(vehicle)

		for i=maxSeats - 1, 0, -1 do
			if IsVehicleSeatFree(vehicle, i) then
				freeSeat = i
				break
			end
		end

		if freeSeat then
			if(GetEntityAttachedTo(playerPed) ~= 0) then
				DetachEntity(playerPed, true, true)
				Wait(50)
				ClearPedTasks(playerPed)
			end
			SetPedIntoVehicle(playerPed, vehicle, freeSeat)
		end
	end
end)

local ArmorToggle = nil

function OpenCloakroomMenu()
	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'cloakroom', {
		title    = _U('cloakroom'),
		align    = 'top-left',
		elements = {
			{label = _U('ems_clothes_civil'), value = 'citizen_wear'},
			{label = _U('ems_clothes_ems'), value = 'ambulance_wear'},
			{label = 'ווסט פרמדיק', value = 'paramedic_wear'},
		}
	}, function(data, menu)
		if data.current.value == 'citizen_wear' then
			ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
				TriggerEvent('skinchanger:loadSkin', skin)
			end)
			SetPedArmour(PlayerPedId(),0)
		elseif data.current.value == 'ambulance_wear' then
			ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
				if skin.sex == 0 then
					TriggerEvent('skinchanger:loadClothes', skin, jobSkin.skin_male)
				else
					TriggerEvent('skinchanger:loadClothes', skin, jobSkin.skin_female)
				end
			end)
		elseif data.current.value == "paramedic_wear" then

			ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
				if skin.sex == 0 then
					if(ArmorToggle == nil) then
						ArmorToggle = true
						SetPedArmour(PlayerPedId(),100)
						SetPedComponentVariation(PlayerPedId(), 9, 49, 0, 2)
					else
						ArmorToggle = nil
						SetPedArmour(PlayerPedId(),0)
						SetPedComponentVariation(PlayerPedId(), 9, 0, 0, 2)
					end
				else
					if(ArmorToggle == nil) then
						ArmorToggle = true
						SetPedArmour(PlayerPedId(),100)
						SetPedComponentVariation(PlayerPedId(), 9, 16, 0, 2)
					else
						ArmorToggle = nil
						SetPedArmour(PlayerPedId(),0)
						SetPedComponentVariation(PlayerPedId(), 9, 0, 0, 2)
					end
				end
			end)
		end

		menu.close()
	end, function(data, menu)
		menu.close()
	end)
end


function OpenPharmacyMenu()
	ESX.UI.Menu.CloseAll()

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'pharmacy', {
		title    = _U('pharmacy_menu_title'),
		align    = 'top-left',
		elements = {
			{label = _U('pharmacy_take', _U('medikit')), item = 'medikit', type = 'slider', value = 1, min = 1, max = 10},
			{label = _U('pharmacy_take', _U('bandage')), item = 'bandage', type = 'slider', value = 1, min = 1, max = 10},
			{label = _U('pharmacy_take', "חוסם עורקים"), item = 'orakim', type = 'slider', value = 1, min = 1, max = 10},
			{label = _U('pharmacy_take', "מזרק אפי-פן"), item = 'epipen', type = 'slider', value = 1, min = 1, max = 10},
			{label = "מכשיר קשר", item = 'radio', type = 'slider', value = 1, min = 1, max = 100},
		}
	}, function(data, menu)
		ESX.SEvent('esx_ambulancejob:giveItem', data.current.item, data.current.value)
	end, function(data, menu)
		menu.close()
	end)
end

function WarpPedInClosestVehicle(ped)
	local coords = GetEntityCoords(ped)

	local vehicle, distance = ESX.Game.GetClosestVehicle(coords)

	if distance ~= -1 and distance <= 5.0 then
		local maxSeats, freeSeat = GetVehicleMaxNumberOfPassengers(vehicle)

		for i=maxSeats - 1, 0, -1 do
			if IsVehicleSeatFree(vehicle, i) then
				freeSeat = i
				break
			end
		end

		if freeSeat then
			SetPedIntoVehicle(ped, vehicle, freeSeat)
		end
	else
		ESX.ShowNotification(_U('no_vehicles'))
	end
end

RegisterNetEvent('esx_ambulancejob:heal')
AddEventHandler('esx_ambulancejob:heal', function(healType, quiet)
	if(ESX.HitRecently()) then ESX.ShowRGBNotification("error","אתה נפצעת לאחרונה ולא יכול לקבל טיפול רפואי") return end
	local playerPed = PlayerPedId()
	local maxHealth = GetEntityMaxHealth(playerPed)

	if healType == 'small' then
		local health = GetEntityHealth(playerPed)
		local newHealth = math.min(maxHealth, math.floor(health + maxHealth / 8))
		SetEntityHealth(playerPed, newHealth)
	elseif healType == 'big' then
		SetEntityHealth(playerPed, maxHealth)
	end

	if not quiet then
		ESX.ShowNotification(_U('healed'))
	end
end)




RegisterNetEvent('esx_ambulancejob:callnayedet')
AddEventHandler('esx_ambulancejob:callnayedet', function()
	if ESX.PlayerData.job.name == "ambulance" then

		ESX.UI.Menu.CloseAll()

		local AmbulanceVehicles = {
			{ model = 'ambulance22', label = 'אמבולנס', price = 0 },
			{ model = 'emsb_gi', label = 'אופנוע מדא', price = 0 },
			{ model = 'bcsspd2', label = 'גיפ  שטח', price = 0 },
			{ model = 'EMSfpiunSLK', label = 'גיפ שטח 2', price = 0 },
			{ model = 'polgs350', label = 'ניידת פיקוד', price = 0 },
			{ model = 'emsnspeedo', label = "אמבולנס 2", price = 0 },
			{ model = 'emsf', label = 'גיפ שודים', price = 0 },
			{ model = 'durango', label = "ניידת פיקוד 2", price = 0 },
			{ model = 'vc_polmustang24', label = 'הנהלת מדא', price = 0 },
			{ model = 'M5RB_VV', label = '2 הנהלת מדא', price = 0 },
		}

		local elements = {}

		for k,v in pairs(AmbulanceVehicles) do
			if IsModelValid(GetHashKey(v.model)) then
				table.insert(elements,{label = v.label, model = v.model})
			end
		end
		ESX.UI.Menu.Open('default', GetCurrentResourceName(), "adsfasdfs",
		{
			title    = "הזמנת אמבולנס",
			align    = "center",
			elements = elements
		},
		function(data, menu)
			ESX.UI.Menu.CloseAll()
			SpawnVehicle(data.current.model)
		end, function(data, menu)
			menu.close()
		end, function(data, menu)
		end)
	end
end)

inVehicle = false
left = false
local lastcar
local fizzPed = nil
local spawnRadius = 80.0



function SpawnVehicle(vehhash)

	if(lastcar and (GetTimeDifference(GetGameTimer(), lastcar) < 600000)) then
		ESX.ShowNotification('אתה יכול להזמין לאמבולנס כל עשר דקות')	
		return
	end

	local vehhash = joaat(vehhash)

	

	lastcar = GetGameTimer()
	local text = "מזמין אמבולנס"
	TriggerEvent("gi-3dme:network:mecmd",text)
	RequestAnimDict("random@arrests");
	while not HasAnimDictLoaded("random@arrests") do
		Wait(5);
	end
	local playerPed = PlayerPedId()
	TaskPlayAnim(playerPed,"random@arrests","generic_radio_chatter", 8.0, 0.0, -1, 49, 0, 0, 0, 0);
	ESX.SEvent('InteractSound_SV:PlayWithinDistance', 1.5, 'backup', 0.9)
	exports['progressBars']:startUI(1000, "מזמין אמבולנס")
	Citizen.Wait(1000)
	StopAnimTask(playerPed, "random@arrests","generic_radio_chatter", -4.0)
	RemoveAnimDict("random@arrests")
	ESX.ShowNotification('אמבולנס בדרך')

	local driverhash = joaat("s_m_m_paramedic_01")
	RequestModel(vehhash)
	RequestModel(driverhash)
	while not HasModelLoaded(vehhash) and not HasModelLoaded(driverhash) do
		Citizen.Wait(0)
	end 

	ESX.TriggerServerCallback("esx_policejob:server:SpawnNayedet",function(netid,pednet)
		if not netid or type(netid) == "boolean" then
			lastcar = nil
			SetModelAsNoLongerNeeded(vehhash)
			SetModelAsNoLongerNeeded(driverhash)
			xPlayer.showHDNotification("Delivery Failed","הזמנת הניידת נכשלה, נסה שוב","warning")
			return
		end
		local callback_vehicle = ESX.Game.VerifyEnt(netid)
		if not callback_vehicle then 
			SetModelAsNoLongerNeeded(vehhash)
			SetModelAsNoLongerNeeded(driverhash)
			ESX.ShowRGBNotification("error","שיגור הרכב כשל") 
		end
		fizzPed = ESX.Game.VerifyEnt(pednet)
		if(not DoesEntityExist(fizzPed)) then
			ESX.ShowRGBNotification("error","שיגור הרכב כשל 2") 
			return
		end
		SetEntityLoadCollisionFlag(callback_vehicle,true)
		SetVehRadioStation(callback_vehicle, "OFF")			
		ESX.SEvent('esx_policejob:paymoney',500)
		SetModelAsNoLongerNeeded(vehhash)
		SetModelAsNoLongerNeeded(driverhash)
		local pedid = pednet
		SetNetworkIdCanMigrate(pedid,false)
		SetBlockingOfNonTemporaryEvents(fizzPed, true)
		SetPedCanRagdollFromPlayerImpact(fizzPed,false)
		SetEntityAsMissionEntity(fizzPed, true, true)
		SetEntityInvincible(fizzPed, true)
		SetVehicleDoorsLocked(callback_vehicle, 2)
		SetVehicleSiren(callback_vehicle,true)
		carblip = AddBlipForEntity(callback_vehicle)
		SetBlipSprite(carblip, 42)
		SetBlipScale(carblip, 0.8)
		BeginTextCommandSetBlipName('STRING')
		AddTextComponentString("Ambulance Delivery")
		EndTextCommandSetBlipName(carblip)
		local plate = exports['okokVehicleShop']:GeneratePlate()
		SetVehicleNumberPlateText(callback_vehicle,plate)
		TriggerEvent('cl_carlock:givekey',plate,false)
		ESX.SEvent("esx_policejob:CacheVeh",ESX.Math.Trim(GetVehicleNumberPlateText(callback_vehicle)))
		ClearAreaOfVehicles(GetEntityCoords(callback_vehicle), 4.0, false, false, false, false, false);  
		SetVehicleOnGroundProperly(callback_vehicle)
		inVehicle = true
		TaskVehicle(callback_vehicle)
		RemoveBlip(carblip)

	end,var2,vehhash)

end

function TaskVehicle(vehicle)
	while inVehicle do
		Citizen.Wait(250)
		local pedcoords = GetEntityCoords(PlayerPedId())
		local plycoords = GetEntityCoords(fizzPed)
		local dist = GetDistanceBetweenCoords(plycoords, pedcoords.x,pedcoords.y,pedcoords.z, false)
		
		if dist <= 25.0 then
			SetVehicleMaxSpeed(vehicle,2.5)
			TaskVehicleDriveToCoord(fizzPed, vehicle, pedcoords.x, pedcoords.y, pedcoords.z, 10.0, 1, vehhash, 2883621, 5.0, 1)
			SetVehicleFixed(vehicle)
			if dist <= 14.5 then
				LeaveIt(vehicle)
			else
				Citizen.Wait(250)
			end
		else
			TaskVehicleDriveToCoord(fizzPed, vehicle, pedcoords.x, pedcoords.y, pedcoords.z, 20.0, 1, vehhash, 2883621, 5.0, 1)
			Citizen.Wait(250)
		end
		while left do
			Citizen.Wait(250)
			local Xpedcoords = GetEntityCoords(PlayerPedId())
			local Ypedcoords = GetEntityCoords(fizzPed)
			local distPed = GetDistanceBetweenCoords(Xpedcoords, Ypedcoords, false)
			TaskGoToCoordAnyMeans(fizzPed, Xpedcoords.x, Xpedcoords.y, Xpedcoords.z, 1.0, 0, 0, 786603, 1.0)
			if distPed <= 2.3 then
				left = false
				GiveKeysTakeMoney()
			end
		end
	end
end

function LeaveIt(vehicle)
	TaskLeaveVehicle(fizzPed, vehicle, 14)
	inVehicle = false
	while IsPedInAnyVehicle(fizzPed, false) do
		Citizen.Wait(0)
	end 
	SetVehicleMaxSpeed(vehicle,0.0)
	
	Citizen.Wait(500)
	TaskWanderStandard(fizzPed, 10.0, 10)
	left = true
end

function GiveKeysTakeMoney()
	TaskStandStill(fizzPed, 2250)
	TaskTurnPedToFaceEntity(fizzPed, PlayerPedId(), 1.0)
	PlayAmbientSpeech1(fizzPed, "Generic_Hi", "Speech_Params_Force")
	Citizen.Wait(500)
	startPropAnim(fizzPed, "mp_common", "givetake1_a")
	Citizen.Wait(1500)
	stopPropAnim(fizzPed, "mp_common", "givetake1_a")
	left = false
end

function playAnim(ped, animDict, animName, duration)
	RequestAnimDict(animDict)
	while not HasAnimDictLoaded(animDict) do Citizen.Wait(0) end
	TaskPlayAnim(ped, animDict, animName, 1.0, -1.0, duration, 49, 1, false, false, false)
	RemoveAnimDict(animDict)
end

function startPropAnim(ped, dictionary, anim)
	Citizen.CreateThread(function()
	  RequestAnimDict(dictionary)
	  while not HasAnimDictLoaded(dictionary) do
		Citizen.Wait(0)
	  end
		TaskPlayAnim(ped, dictionary, anim ,8.0, -8.0, -1, 50, 0, false, false, false)
	end)
end

function stopPropAnim(ped, dictionary, anim)
	StopAnimTask(ped, dictionary, anim ,8.0, -8.0, -1, 50, 0, false, false, false)
	Citizen.Wait(100)
	while not NetworkHasControlOfEntity(fizzPed) and DoesEntityExist(fizzPed) do
		Citizen.Wait(1)
		NetworkRequestControlOfEntity(fizzPed)
	end
    DeletePed(fizzPed)
    fizzPed = nil
end

RegisterCommand('mmivhan',function()

	local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()

	if closestPlayer == -1 or closestDistance > 3.0 then
		ESX.ShowNotification("לא נמצא שחקן באיזור")
		return
	end

	if ESX.PlayerData.job.name == "ambulance" then
		if(ESX.PlayerData.job.grade_name == 'boss' or string.match(ESX.PlayerData.job.grade_label,"מפקד") or string.match(ESX.PlayerData.job.grade_label,"קצין")) then

			TaskStartScenarioInPlace(PlayerPedId(), "WORLD_HUMAN_CLIPBOARD", 0, true)
			local AGEO = "גיל אוסי"
			local AGEI = "גיל אייסי"
			local ONAME = "שם אוסי"
			local DNAME = "שם דיסקורד"
			local PASS = "?האם עבר"
			local DERUG = "דירוג בחינה מ 1 עד 10"

			local keyboard, var1, var2, var3 , var4, var5 = exports["nh-keyboard"]:Keyboard({
				header = "הגשת טופס בחינה", 
				rows = {AGEO,AGEI,ONAME,PASS,DERUG}
			})
			
			if keyboard then

				ClearPedTasksImmediately(PlayerPedId())
				if var1 and var2 and var3 and var4 and var5 then
					local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()

					if closestPlayer == -1 or closestDistance > 3.0 then
						ESX.ShowNotification("לא נמצא שחקן באיזור")
					else
						ESX.SEvent('esx_ambulancejob:SendTest',GetPlayerServerId(closestPlayer),var1,var2,var3,var4,var5)
						ESX.ShowHDNotification("SUCCESS","הדוח נשלח בהצלחה",'success')
					end
				else
					ESX.ShowNotification('יש למלא את כל הפרטים')
				end
			end
		end
	end

end)

function BodyBag(entity)
	if(not DoesEntityExist(entity)) then
		ESX.ShowHDNotification("מגן דוד אדום","לא נמצא הגופה","ambulance")
		return
	end
	local ped = PlayerPedId()
	local entcoords = GetEntityCoords(entity)
	if #(GetEntityCoords(ped) - GetEntityCoords(entity)) > 3.0 then
		ESX.ShowHDNotification("מגן דוד אדום","הגופה רחוקה מדי","ambulance")
		return
	end
	TaskStartScenarioInPlace(ped, 'CODE_HUMAN_MEDIC_TEND_TO_DEAD', 0, true)

	local model = GetHashKey('xm_prop_body_bag')
	LoadModel(model)
	local heading = GetEntityHeading(entity)
	local obj = CreateObject(model, entcoords.x, entcoords.y, entcoords.z, true, true)
	SetModelAsNoLongerNeeded(model)
	PlaceObjectOnGroundProperly(obj)
	SetEntityHeading(obj,heading)
	
	local Minigame = ESX.SpamBar({
		centermsg = "Spam [E] To Bag Up The Body",
		score = math.random(1400,1600),
		color = {r = 255, g = 0, b = 10},
		button = 51,
		canCancel = false,
		timeOut = 12000,
		reducer = 2,
	})
	
	if(Minigame) then
		if(DoesEntityExist(entity)) then
			if(#GetActivePlayers() ~= 1) then
				ESX.Game.DeleteObject(entity,true)
				SetEntityAsMissionEntity(entity, false, true)
				DeletePed(entity)
			else
				SetEntityAsMissionEntity(entity, false, true)
				DeletePed(entity)
			end
			ESX.Game.DeleteObject(obj)
			ESX.ShowHDNotification("מגן דוד אדום","כיסית את הגופה בהצלחה","ambulance")
			if(var2) then
				if ESX.PlayerData.job.name == "ambulance" then            
					ESX.SEvent("esx_ambulancejob:BodyBag",var2)
				else
					ESX.ShowRGBNotification("error",".אתה לא בעבודה יותר, הפעולה נכשלה")
				end
			else
				ESX.ShowNotification(".תקלה, נסה שוב","error")
			end
		else
			ESX.Game.DeleteObject(obj)
			ESX.ShowHDNotification("מגן דוד אדום","לא נמצא הגופה","ambulance")
		end
	else
		ESX.Game.DeleteObject(obj)
		ESX.ShowHDNotification("מגן דוד אדום","נכשלת בלכסות את הגופה","ambulance")
	end

end

function HealClosestPlayer(closestPlayer,type)

	if(IsPedInAnyVehicle(PlayerPedId(),false)) then
		ESX.ShowHDNotification('מד"א',"אתה לא יכול לבצע פעולה זו כשאתה ברכב","ambulance")
		return
	end
	local item = type == "small" and "bandage" or "medikit"
	local neededitem = ESX.GetInventoryItem(item)
	if(neededitem and neededitem.count > 0) then
		
		local closestPlayerPed = GetPlayerPed(closestPlayer)
		if not IsPedDeadOrDying(closestPlayerPed) and not LocalPlayer.state.down then
			local playerPed = PlayerPedId()

			isBusy = true
			ESX.ShowRGBNotification("info",_U('heal_inprogress'))
			TaskStartScenarioInPlace(playerPed, 'CODE_HUMAN_MEDIC_TEND_TO_DEAD', 0, true)
			TriggerEvent("gi-3dme:network:mecmd","חובש פצעים")
			Citizen.Wait(10000)
			ClearPedTasks(playerPed)

			if ESX.PlayerData.job.name == "ambulance" then
				TriggerServerEvent('esx_ambulancejob:removeItem', item)
				TriggerServerEvent('esx_ambulancejob:heal', GetPlayerServerId(closestPlayer), type)
				ESX.ShowRGBNotification("success",_U('heal_complete', GetPlayerName(closestPlayer)))
			else
				ESX.ShowRGBNotification("error",".אתה לא בעבודה יותר, הפעולה נכשלה")
			end
			isBusy = false
		else
			ESX.ShowRGBNotification("error",_U('player_not_conscious'))
		end
	else
		ESX.ShowRGBNotification("error",_U('not_enough_medikit'))
	end


end

function ReviveClosestPlayer(closestPlayer)
	if(IsPedInAnyVehicle(PlayerPedId(),false)) then
		ESX.ShowHDNotification('מד"א',"אתה לא יכול לבצע פעולה זו כשאתה ברכב","ambulance")
		return
	end
	isBusy = true

	local revivedict = "mini@cpr@char_a@cpr_str"
	local reviveanim = "cpr_pumpchest"

	if IsEntityPlayingAnim(PlayerPedId(), revivedict, reviveanim, 3) then
		ESX.ShowRGBNotification("error","אתה כבר מבצע החייאה")
		isBusy = false
		return
	end
	local medkit = ESX.GetInventoryItem("medikit")
	if(medkit and medkit.count > 0) then
		ESX.UI.Menu.CloseAll()

		local closestPlayerPed = GetPlayerPed(closestPlayer)
		if IsPedDeadOrDying(closestPlayerPed, 1) or Player(GetPlayerServerId(closestPlayer)).state.down then
			ESX.ShowHelpNotification("Press ~INPUT_CONTEXT~ To ~y~Revive~w~ This ~r~Person~w~")
			local Minigame = ESX.SpamBar({
				centermsg = "Spam [E] To Revive This Person",
				score = math.random(1500,2000),
				color = {r = 255, g = 0, b = 10},
				button = 51,
				canCancel = false,
				timeOut = 12000,
				reducer = 2,
				animdict = revivedict,
				playanim = reviveanim,
				keepanim = true,
			})
		
			if(Minigame) then
				ESX.ShowHDNotification("מגן דוד אדום","ביצעת את ההחייאה בהצלחה","ambulance")
				local playerPed = PlayerPedId()

				ESX.ShowNotification(_U('revive_inprogress'))
				TriggerEvent("gi-3dme:network:mecmd","מבצע החייאה")


				ESX.Game.Progress("esx_ambulancejobRollRevive", "מחייאה את האזרח", 5000, false, false, {
					disableMovement = true,
					disableCarMovement = true,
					disableMouse = false,
					disableCombat = true,
				}, {
					animDict = revivedict,
					anim = reviveanim,
					flag = -1,
				}, {},{}, function()
					if IsPedDeadOrDying(closestPlayerPed, 1) or Player(GetPlayerServerId(closestPlayer)).state.down then
						ClearPedTasksImmediately(playerPed)
						if ESX.PlayerData.job.name == "ambulance" then
							TriggerServerEvent('esx_ambulancejob:removeItem', 'medikit')
							TriggerServerEvent('esx_ambulancejob:revive', GetPlayerServerId(closestPlayer))
						else
							ESX.ShowRGBNotification("error",".אתה לא בעבודה יותר, הפעולה נכשלה")
						end

						if Config.ReviveReward > 0 then
							ESX.ShowNotification(_U('revive_complete_award', GetPlayerName(closestPlayer), Config.ReviveReward))
						else
							ESX.ShowNotification(_U('revive_complete', GetPlayerName(closestPlayer)))
						end
					else
						ESX.ShowHDNotification("מגן דוד אדום","האזרח לא פצוע יותר","ambulance")
					end
					ClearPedTasksImmediately(playerPed)
				end, function()
					ClearPedTasksImmediately(playerPed)
				end)
			else
				ESX.ShowHDNotification("מגן דוד אדום","נכשלת בהחייאה","ambulance")
			end
		else
			ESX.ShowRGBNotification("error",_U('player_not_conscious'))
		end
	else
		ESX.ShowRGBNotification("error",_U('not_enough_medikit'))
	end

	isBusy = false

end

function DoCustomBill()
	if(ESX.PlayerData.job.grade >= 3) then

		local keyboard, reason, amount = exports["nh-keyboard"]:Keyboard({
			header = "דוח ניהולי", 
			rows = {"סיבת דוח", "כמות כסף"}
		})
		
		if keyboard then

			local amount = tonumber(amount)

			if reason and amount then
				if amount == nil then
					ESX.ShowNotification("כמות שגויה")
				elseif amount > 60000 then
					ESX.ShowNotification('הסכום המקסימלי הוא 60,000 שקל בלבד')
				else
					ESX.UI.Menu.CloseAll()
					local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
					if closestPlayer == -1 or closestDistance > 3.0 then
						ESX.ShowNotification(_U('no_players'))
					else
						local invoice = {}
						invoice.invoice_notes = reason
						invoice.invoice_item = "דוח מגן דוד אדום"
						invoice.invoice_value = tonumber(amount)
						invoice.target = GetPlayerServerId(closestPlayer)
						invoice.action = "createInvoice"
						invoice.society = "society_ambulance"
						invoice.society_name = 'מד"א'
		
						TriggerServerEvent("esx_billing:CreateInvoice", invoice)
					end
				end
			else
				ESX.ShowNotification('יש לציין את סכום הדוח וסיבת הדוח')
			end
		end

		
	else
		ESX.ShowNotification('רק דרגת מג"ר ומעלה יכולים לבצע פעולה זו')
	end

end

function ScanVeh()
	local playerPed = PlayerPedId()
	local coords    = GetEntityCoords(playerPed)

	if IsAnyVehicleNearPoint(coords, 5.0) then
		local vehicle = GetClosestVehicle(coords, 5.0, 0, 71)

		if DoesEntityExist(vehicle) then
			if(GetVehicleClass(vehicle) == 18) then

				if(not lastscan or (GetTimeDifference(GetGameTimer(), lastscan) > 5000)) then
					lastscan = GetGameTimer()
					TriggerServerEvent('esx_policejob:ScanVeh',ESX.Math.Trim(GetVehicleNumberPlateText(vehicle)))
				else
					ESX.ShowHDNotification("ERROR","נא להמתין 5 שניות בין כל סריקה",'error')
				end
			else
				ESX.UI.Menu.CloseAll()
				ESX.ShowHDNotification("ERROR","הרכב שנבחר אינו משטרתי",'error')
			end
		end
	else
		ESX.ShowHDNotification("ERROR","לא נמצא שום רכב באיזור",'error')
	end
end

function revivemenu()

	local elements = {}
	table.insert(elements, {label = _U('ems_menu_revive'), value = 'revive', hint = "החייאה לשחקן הכי קרוב"})
	table.insert(elements, {label = "בדיקת מדדים", value = 'checkmeds', hint = "בודק מדדים למי שהכי קרוב אליך"})
	table.insert(elements, {label = "קביעת מוות", value = 'deathan', hint = "(בהתאם לשעון של המחשב שלך) קובע שעת מוות"})
	if(ESX.PlayerData.job.grade >= 2) then
		table.insert(elements, {label = "(Force Respawn) קביעת מוות", value = 'deathan2', hint = "(בהתאם לשעון של המחשב שלך) קובע שעת מוות ועושה ריספאון לשחקן"})
	end
	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'ems_revive_menu', {
		title = "תפריט החייאות",
		align = 'top-left',
		elements = elements
	}, function(data, menu)
		local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
		if closestPlayer == -1 or closestDistance > 2.0 then
			ESX.ShowRGBNotification("error",_U('no_players'))
		else
			local action = data.current.value
			if action == "revive" then
				ReviveClosestPlayer(closestPlayer)
			elseif action == "checkmeds" then
				CheckMeds(closestPlayer)
			elseif action == "deathan" then
				menu.close()
				CreateThread(function()
					ExecuteCommand("e checkwatch")
					Wait(200)
					local year,month,day,hour,minute,second = GetLocalTime()
					TriggerEvent("gi-3dme:network:mecmd","קובע שעת מוות - "..hour..":"..minute..":"..second)
					Wait(3500)
					ExecuteCommand("e c")
				end)
			elseif action == "deathan2" then
				menu.close()
				CreateThread(function()
					local forcerespawn = lib.alertDialog({
						header = '?האם אתה בטוח שאתה רוצה לעשות ריספאון לשחקן הזה',
						content = 'נא לבדוק שזה לא פוגע בסיטואציה אייסי לפני שאתם מבצעים פעולה זו',
						centered = true,
						cancel = true
					})
					forcerespawn = forcerespawn == "confirm" or false
					if(forcerespawn) then
						ExecuteCommand("e checkwatch")
					Wait(200)
					local year,month,day,hour,minute,second = GetLocalTime()
					TriggerEvent("gi-3dme:network:mecmd","קובע שעת מוות מיידית - "..hour..":"..minute..":"..second)
					Wait(3500)
					ESX.SEvent("esx_ambulancejob:server:dorespawn",GetPlayerServerId(closestPlayer))
					ExecuteCommand("e c")
					end
					
				end)
			end
		end
	end, function(data, menu)
		menu.close()
	end)

end

function CheckMeds(player)
	ExecuteCommand("med "..GetPlayerServerId(player))
	local targetPed = GetPlayerPed(player)
	if(not DoesEntityExist(targetPed)) then return end
	Citizen.SetTimeout(7000,function()
		targetPed = nil
	end)

	CreateThread(function()
		while DoesEntityExist(targetPed) do
			Wait(0)
			if(targetPed) then
				local tcoords = GetEntityCoords(targetPed)

				DrawMarker(20, tcoords.x,tcoords.y,tcoords.z + 1.5, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.8, 0.8, 1.2, 255, 0, 0, 120, false, false, 2, true, false, false, false)
			else
				break
			end
		end
	end)
end


RegisterNetEvent("esx_ambulancejob:syncclearblood",function(area)
	if not area or not area.x then return end
	RemoveDecalsInRange(area.x,area.y,area.z,3.0)
end)

local helibed = false

AddEventHandler("esx_ambulancejob:HeliBed",function()
	local playerPed = PlayerPedId()
	local helicopter = GetVehiclePedIsIn(playerPed,false)
	if(helicopter == 0 or not IsPedInAnyHeli(playerPed)) then
		ESX.ShowRGBNotification("error","אתה לא בתוך מסוק")
		return
	end
	if(GetPedInVehicleSeat(helicopter,-1) ~= playerPed) then
		ESX.ShowRGBNotification("error",".אתה חייב להיות הטייס בשביל להוציא מיטה")
		return
	end
	if(helibed) then
		ESX.ShowRGBNotification("error","כבר הוצאת מיטה עם חבל מהמסוק")
		return
	end
	if(GetEntityHeightAboveGround(helicopter) < 10.0) then
		ESX.ShowRGBNotification("error","אתה חייב להיות גבוהה באוויר כדי להוציא מיטה")
		return
	end
	TriggerEvent("chatMessage","כדי להעיף את המיטה יש ללחוץ G")
	TriggerEvent("chatMessage","כדי לייצב/לשחרר את המיטה יש ללחוץ H")
	TriggerEvent("chatMessage","L-Shift | L-Ctrl כדי לעלות או להוריד את המיטה")
	TriggerEvent("chatMessage","Y כדי לעלות או להוריד מישהו מהמיטה")
	helibed = true
	local coords  = GetEntityCoords(helicopter)
	local x, y, z = table.unpack(coords)
	local model = `v_med_emptybed`
	ESX.ShowRGBNotification("success","מוציא מיטה עם חבל מהמסוק")
	LoadModel(model)	

	local obj = CreateObject(model, x, y + 1.0, z - 4.0, true, true,true)
	while not DoesEntityExist(obj) do
		Wait(200)
	end
	local netid = ObjToNet(obj)
	SetNetworkIdCanMigrate(netid,true)
	SetNetworkIdExistsOnAllMachines(netid,true)
	SetEntityHeading(obj, GetEntityHeading(helicopter))
	SetEntityCollision(obj, true, true)
	local maxLength = 15.0
	local initlength = maxLength / 2
	local rope = AddRope(x,y,z,0.0,0.0,0.0,maxLength,1,maxLength,3.0,2.0,false,true,false,1.0,false,0)
	local bedCoords = GetEntityCoords(obj)
	AttachEntitiesToRope(rope, helicopter, obj, x, y, z, bedCoords.x, bedCoords.y, bedCoords.z, maxLength, false, false, nil, nil)
	local helimass = GetVehicleHandlingFloat(helicopter, 'CHandlingData', 'fMass')
	local objectmass = helimass * 0.22
	SetObjectPhysicsParams(obj,objectmass, 1, 1000, 1, 0,0, 0, 0, 0, 0, 0)
	SetActivateObjectPhysicsAsSoonAsItIsUnfrozen(obj, true)
	SetEntityLodDist(obj,200)
	local setlength = maxLength
	StopRopeWinding(rope)
	StopRopeUnwindingFront(rope)
	CreateThread(function()
		Wait(500)
		ESX.SEvent("esx_ambulancejob:server:helirope",VehToNet(helicopter),netid,true)
	end)
	
	local steady = false
	while true do
		Wait(0)
		SetEntityRotation(obj,0.0,0.0,GetEntityHeading(helicopter),0.0,false)
		SetEntityMaxSpeed(obj,GetEntitySpeed(helicopter) + 5.0)
		

		local heightabove = GetEntityHeightAboveGround(obj)
		if(heightabove < 1.0) then
			if(steady) then
				steady = false
			end
			local bedVelocity = GetEntityVelocity(obj)
			SetEntityVelocity(obj,0.0,0.0,bedVelocity.z)
		end

		if(heightabove > GetEntityHeightAboveGround(helicopter)) then
			local velocity = GetEntityVelocity(obj)
			SetEntityVelocity(obj,0.0,0.0,-4.0)
		end

		if(IsControlJustPressed(0,47)) then
			NetworkRequestControlOfEntity(obj)
			DetachRopeFromEntity(rope,obj)
			DeleteRope(rope)
			local objcoords = GetEntityCoords(obj)
			PlaySoundFromCoord(-1,"Drill_Pin_Break",objcoords.x,objcoords.y,objcoords.z,"DLC_HEIST_FLEECA_SOUNDSET",false,10.0,true)
			DeleteEntity(obj)
			break
		end


		if(IsControlJustPressed(0,246)) then
			local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer(GetEntityCoords(obj))
			if closestPlayer == -1 or closestDistance > 2.0 then
				ESX.ShowRGBNotification("error","לא נמצאו שחקנים ליד המיטה")
			else
				local playerid = GetPlayerServerId(closestPlayer)
				if playerid ~= 0 then
					if(Player(playerid).state.down) then
						if(ESX.PlayerData.job.name == "police" or ESX.PlayerData.job.name == "ambulance") then
							ESX.SEvent("esx_ambulancejob:LoadPlayerToBed",playerid,netid)
						end
					else
						ESX.ShowRGBNotification("error","השחקן שצמוד למיטה לא פצוע")
					end
				else
					ESX.ShowRGBNotification("error","לא נמצאו שחקנים ליד המיטה")
				end
			end
		end
		
		if(IsControlJustPressed(0,74)) then
			steady = not steady
			if(steady) then
				local helicoords = GetEntityCoords(helicopter)
				SetEntityCoords(obj,helicoords.x,helicoords.y,helicoords.z - setlength)
				SetEntityVelocity(obj,GetEntityVelocity(helicopter))
			else
				local velocity = GetEntityVelocity(helicopter)
				SetEntityVelocity(obj,velocity.x,velocity.y,0.0)
			end
			ESX.ShowRGBNotification("success",(steady and "מייצב מיטה") or "משחרר מיטה")
		end

		if(steady) then
			SetEntityVelocity(obj,GetEntityVelocity(helicopter))
		end

		if(IsControlPressed(0,341)) then
			start = true
			if(setlength < maxLength + 24.0) then
				setlength+= 0.05
				coords  = GetEntityCoords(helicopter)
				x, y, z = table.unpack(coords)
				bedCoords = GetEntityCoords(obj)
				AttachEntitiesToRope(rope, helicopter, obj, x, y, z, bedCoords.x, bedCoords.y, bedCoords.z, setlength, false, false, nil, nil)
				RopeForceLength(rope, setlength);
			end
		end

		if(IsControlPressed(0,340)) then
			if(setlength >= initlength + 1.0) then
				setlength-= 0.05
				coords  = GetEntityCoords(helicopter)
				x, y, z = table.unpack(coords)
				bedCoords = GetEntityCoords(obj)
				AttachEntitiesToRope(rope, helicopter, obj, x, y, z, bedCoords.x, bedCoords.y, bedCoords.z, setlength, false, false, nil, nil)
				RopeForceLength(rope, setlength);
			end
		end

		if(not DoesRopeExist(rope) or not DoesEntityExist(obj) or not DoesEntityExist(helicopter)) then
			if(DoesEntityExist(obj) and DoesRopeExist(rope)) then
				DetachRopeFromEntity(rope,obj)
			end
			if(DoesRopeExist(rope)) then
				DeleteRope(rope)
			end
			if(DoesEntityExist(obj)) then
				DeleteEntity(obj)
			end
			break
		end
	end
	ESX.SEvent("esx_ambulancejob:server:helirope",VehToNet(helicopter),nil,false)
	helibed = false
end)

CreateThread(function()
	while true do
		Wait(7000)
		local ped = PlayerPedId()
		local coords = GetEntityCoords(ped)
		local ropes = GetAllRopes()
		for i = 1,#ropes, 1 do
			local rope = ropes[i]
			if #(GetRopeVertexCoord(rope) - coords) > 424 then
				DeleteRope(rope)
			end
		end
	end
end)

local heliropes = {}
AddStateBagChangeHandler("bedrope", nil, function(bagName, key, value, _unused, replicated)
    if bagName:sub(1, 7) == "entity:" then
        local ent = GetEntityFromStateBagName(bagName)
        if ent == 0 then Wait(500) ent = GetEntityFromStateBagName(bagName) end
        if ent == 0 then return end -- Entity does not exist or not valid
		if(DoesEntityExist(ent)) then
			if(GetPedInVehicleSeat(ent,-1) == PlayerPedId()) then return end
			if(value) then
				local thebed = NetToObj(value)
				local maxLength = 15.0
				local initlength = maxLength / 2
				local coords  = GetEntityCoords(ent)
				local x, y, z = table.unpack(coords)
				local rope = AddRope(x,y,z,0.0,0.0,0.0,maxLength,1,maxLength,3.0,2.0,false,true,false,1.0,false,0)
				local bedCoords = GetEntityCoords(thebed)
				AttachEntitiesToRope(rope, ent, thebed, x, y, z, bedCoords.x, bedCoords.y, bedCoords.z, maxLength, false, false, nil, nil)
				local helimass = GetVehicleHandlingFloat(ent, 'CHandlingData', 'fMass')
				local objectmass = helimass * 0.22
				SetObjectPhysicsParams(thebed,objectmass, 1, 1000, 1, 0,0, 0, 0, 0, 0, 0)
				SetEntityLodDist(thebed,200)
				local setlength = maxLength
				StopRopeWinding(rope)
				StopRopeUnwindingFront(rope)
				heliropes[rope] = ent
			else
				local keys = {}
				for k,v in pairs(heliropes) do
					if(v == ent) then
						DeleteRope(k)
						table.insert(keys,k)
					end
				end

				for i = 1, #keys, 1 do
					if(keys[i]) then
						table.remove(heliropes,keys[i])
					end
				end
			end
		end
    end
end)

local bodymission = 0

local CoolDownTime = 3600000
local CoolDownMessage = "ניתן לבצע משימה זו כל "..((CoolDownTime / 1000) / 60).." דקות מההתחברות האחרונה או המשימה האחרונה"
local lastmission = GetGameTimer()

function EMSBodyMission()
	if(lastmission and (GetTimeDifference(GetGameTimer(), lastmission) < CoolDownTime)) then
		ESX.ShowRGBNotification("error",CoolDownMessage,7500)
		return
	end

	if(ESX.PlayerData.job.name ~= "ambulance") then
		ESX.ShowRGBNotification("error",'אתה לא במד"א אין לך גישה למשימה הזאת')
		return
	end

	local randIndex = math.random(1,#Config.BodyMission.missions)
	local randloc = Config.BodyMission.missions[randIndex]
    if(not randloc) then return end
	lastmission = GetGameTimer()
	local bodycoords = randloc.coords
    local ped = PlayerPedId()
	local targetblip = AddBlipForCoord(bodycoords.x,bodycoords.y,bodycoords.z)
    SetBlipSprite(targetblip,310)
    SetBlipColour(targetblip,1)
    SetBlipScale(targetblip,1.5)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString("Dead Body")
    EndTextCommandSetBlipName(targetblip)
    ESX.ShowHelpNotification("Go pickup the dead body at ~HUD_COLOUR_RED~~BLIP_310~~s~.")
	ESX.ShowRGBNotification("info","התחלת משימת גופות, תגיע לסימון האדום במפה ואז תקבל הנחיות נוספות.",10000)
    SetNewWaypoint(bodycoords.x,bodycoords.y)
	while #(GetEntityCoords(ped) - vector3(bodycoords)) > 100.0 do
        Wait(500)
        if IsPedInAnyHeli(PlayerPedId()) then
            PlaySoundFrontend(-1,"MP_Flash","WastedSounds",0)
            ESX.ShowNotification('המשימה נכשלה, אסור להשתמש במסוקים במשימה הזאת')
            if(DoesBlipExist(targetblip)) then
                RemoveBlip(targetblip)
                targetblip = nil
            end
            bodymission = 0
            return
        end

		if(ESX.PlayerData.job.name ~= "ambulance") then
            PlaySoundFrontend(-1,"MP_Flash","WastedSounds",0)
            ESX.ShowNotification('המשימה נכשלה, אתה לא במד"א יותר או שיצאת מתפקיד')
            if(DoesBlipExist(targetblip)) then
                RemoveBlip(targetblip)
                targetblip = nil
            end
            bodymission = 0
			return
		end
    end
	local models = exports['gi-ui2']:BodyModels()
	local randommodel = models[math.random(1,#models)]
    local pedModel = GetHashKey(randommodel)
    RequestModel(pedModel)
    while not HasModelLoaded(pedModel) do
        Citizen.Wait(50)
    end
	if(ESX.PlayerData.job.name ~= "ambulance") then
		PlaySoundFrontend(-1,"MP_Flash","WastedSounds",0)
		ESX.ShowNotification('המשימה נכשלה, אתה לא במד"א יותר או שיצאת מתפקיד')
		if(DoesBlipExist(targetblip)) then
			RemoveBlip(targetblip)
			targetblip = nil
		end
		bodymission = 0
		return
	end
    ESX.ShowNotification("הגעת לאיזור הגופה")
	local netid = lib.callback.await("esx_ambulancejob:server:CreateBody",false,pedModel,randIndex)
	local deadbody = ESX.Game.VerifyEnt(netid,true)
	if(not DoesEntityExist(deadbody)) then
		Citizen.CreateThreadNow(function()
			PlaySoundFrontend(-1,"MP_Flash","WastedSounds",0)
			ESX.ShowNotification('תקלה, לא הצלחנו לשגר את הגופה')
		end)
		if(DoesBlipExist(targetblip)) then
			RemoveBlip(targetblip)
			targetblip = nil
		end
		bodymission = 0
		return
	end
    local foundsafecoord, newpos = GetSafeCoordForPed(bodycoords.x, bodycoords.y, bodycoords.z, false, 16)
    if(foundsafecoord) then
        -- deadbody = CreatePed(4 , pedModel, newpos.x, newpos.y, newpos.z - 1.0 , bodycoords.w , true, true)
    else
        -- deadbody = CreatePed(4 , pedModel, bodycoords.x, bodycoords.y, bodycoords.z - 1.0 , bodycoords.w , true, true)
    end
    SetModelAsNoLongerNeeded(pedModel)
	if(DoesBlipExist(targetblip)) then
        RemoveBlip(targetblip)
        targetblip = nil
    end
	local id = PedToNet(deadbody)
    SetNetworkIdCanMigrate(id,false)
    targetblip = AddBlipForEntity(deadbody)
    
    SetBlipSprite(targetblip,84)
    SetBlipAsShortRange(targetblip, true)
    SetBlipColour(targetblip, 1)
    SetBlipHighDetail(targetblip, true)
    while not NetworkHasControlOfEntity(deadbody) do
        Wait(400)
        if(not DoesEntityExist(deadbody)) then 
            if(DoesBlipExist(targetblip)) then
                RemoveBlip(targetblip)
                targetblip = nil
            end
            exports['qb-target']:RemoveTargetEntity(deadbody)
            bodymission = 0
            return
        end
        NetworkRequestControlOfEntity(deadbody)
    end

	DisablePedPainAudio(deadbody, true)
    ApplyDamageToPed(deadbody,9999.0,false)
    SetPedSweat(deadbody,100.0)
    ApplyPedDamagePack(deadbody, "Fall", 100, 100)
	ESX.ShowHelpNotification("You have reached the ~r~Dead Body~w~, now carry it back to the ~r~Hospital~w~")
	bodymission = 1
    local carryingBody = 0

    CreateThread(function()
        while bodymission do
            local sleep = 1000

            if(LocalPlayer.state.down or IsEntityDead(PlayerPedId())) then
                Citizen.CreateThreadNow(function()
                    PlaySoundFrontend(-1,"MP_Flash","WastedSounds",0)
                    ESX.ShowNotification('.המשימה נכשלה, נהרגת')
                end)
                if(DoesBlipExist(targetblip)) then
                    RemoveBlip(targetblip)
                    targetblip = nil
                end
                exports['qb-target']:RemoveTargetEntity(deadbody)
                bodymission = 0
                return
            end

            if IsPedInAnyHeli(PlayerPedId()) then
                Citizen.CreateThreadNow(function()
                    PlaySoundFrontend(-1,"MP_Flash","WastedSounds",0)
                    ESX.ShowNotification('המשימה נכשלה, אסור להשתמש במסוקים במשימה הזאת')
                end)
                if(DoesBlipExist(targetblip)) then
                    RemoveBlip(targetblip)
                    targetblip = nil
                end
                exports['qb-target']:RemoveTargetEntity(deadbody)
                bodymission = 0
                return
            end

			if(ESX.PlayerData.job.name ~= "ambulance") then
				PlaySoundFrontend(-1,"MP_Flash","WastedSounds",0)
				ESX.ShowNotification('המשימה נכשלה, אתה לא במד"א יותר או שיצאת מתפקיד')
				if(DoesBlipExist(targetblip)) then
					RemoveBlip(targetblip)
					targetblip = nil
				end
				bodymission = 0
				return
			end

            if(IsPedCuffed(PlayerPedId())) then
                Citizen.CreateThreadNow(function()
                    PlaySoundFrontend(-1,"MP_Flash","WastedSounds",0)
                    ESX.ShowNotification('.המשימה נכשלה, נאזקת')
                end)
                if(DoesBlipExist(targetblip)) then
                    RemoveBlip(targetblip)
                    targetblip = nil
                end
                exports['qb-target']:RemoveTargetEntity(deadbody)
                bodymission = 0
                return
            end

            if(bodymission == 1) then
				if(not DoesEntityExist(deadbody)) then
                    Citizen.CreateThreadNow(function()
                        PlaySoundFrontend(-1,"MP_Flash","WastedSounds",0)
                        ESX.ShowNotification('.המשימה נכשלה, הגופה נעלמה')
                    end)
                    exports['qb-target']:RemoveTargetEntity(deadbody)
                    bodymission = 0
                    return
                end
                if(carryingBody and DoesEntityExist(carryingBody)) then
                    sleep = 0


                    while not IsEntityPlayingAnim(PlayerPedId(), 'missfinale_c2mcs_1', 'fin_c2_mcs_1_camman', 3) do
                        RequestAnimDict('missfinale_c2mcs_1')
                        while not HasAnimDictLoaded('missfinale_c2mcs_1') do
                            Wait(50)
                        end
                        TaskPlayAnim(PlayerPedId(), 'missfinale_c2mcs_1', 'fin_c2_mcs_1_camman', 8.0, -8.0, 100000, 49, 0, false, false, false)
                        RemoveAnimDict('missfinale_c2mcs_1')
                        Citizen.Wait(5)
                    end

                    if(IsControlJustPressed(0,51)) then
                        DetachEntity(deadbody,true,false)
                        carryingBody = 0
                        local playerPed = PlayerPedId()
                        StopAnimTask(playerPed, 'missfinale_c2mcs_1', 'fin_c2_mcs_1_camman', 8.0)
                        Wait(2000)
						local deadcoords = GetEntityCoords(deadbody)
                        if #(deadcoords - Config.BodyMission.morgue) < 20.0 then
							exports['qb-target']:RemoveTargetEntity(deadbody)
							bodymission = 0
							if(DoesBlipExist(targetblip)) then
								RemoveBlip(targetblip)
								targetblip = nil
							end
							while not NetworkHasControlOfEntity(deadbody) do
								Wait(400)
								if(not DoesEntityExist(deadbody)) then 
									return
								end
								NetworkRequestControlOfEntity(deadbody)
							end
							DeletePed(deadbody)
							if(var2) then
								if ESX.PlayerData.job.name == "ambulance" then            
									ESX.SEvent("esx_ambulancejob:server:BodyMission",var2)
									ESX.ShowRGBNotification("success","הפקדת את הגופה בהצלחה")
									PlayMissionCompleteAudio("FRANKLIN_BIG_01")
        							StartScreenEffect("SuccessMichael",  3000,  false)
								else
									ESX.ShowRGBNotification("error",".אתה לא בעבודה יותר, הפעולה נכשלה")
								end
							else
								ESX.ShowNotification(".תקלה, נסה שוב","error")
							end
							break
                        else
                            ESX.ShowRGBNotification("error","אתה צריך לזרוק את הגופה בקבלה של הבית חולים")
                        end
                    end

                end
			end



            Wait(sleep)
        end
    end)
    Wait(2000)
	local firstpickup = true
    exports['qb-target']:AddTargetEntity(deadbody, {
        options = {
            {
                icon = "fas fa-hand",
                label = "הרם את הגופה",
                action = function(entity)
                    local ped = PlayerPedId()
                    if(IsPedInAnyVehicle(ped,false)) then
                        ESX.ShowRGBNotification("error",".אתה לא יכול לבצע פעולה זו מתוך רכב")
                        return
                    end
                    ESX.Game.FaceEntity(ped,entity)
                    TriggerEvent('animations:client:EmoteCommandStart',{"medic"})
                    Wait(2000)
                
                    ESX.Game.Progress("pickupems_body", "מרים את הגופה", 5000, false, false, {
                        disableMovement = true,
                        disableCarMovement = true,
                        disableMouse = false,
                        disableCombat = true,
                    }, {}, {}, {}, function() -- Done
                        TriggerEvent('animations:client:EmoteCommandStart',{"c"})
						while not NetworkHasControlOfEntity(deadbody) do
							Wait(400)
							if(not DoesEntityExist(deadbody)) then 
								if(DoesBlipExist(targetblip)) then
									RemoveBlip(targetblip)
									targetblip = nil
								end
								exports['qb-target']:RemoveTargetEntity(deadbody)
								bodymission = 0
								return
							end
							NetworkRequestControlOfEntity(deadbody)
						end
                        carryingBody = entity
						OnesyncEnableRemoteAttachmentSanitization(false)
						SetTimeout(200, function()
							OnesyncEnableRemoteAttachmentSanitization(true)
						end)
                        AttachEntityToEntity(entity, ped, 0, 0.27, 0.15, 0.63, 0.5, 0.5, 0.0, false, false, false, false, 2, false)
                        RequestAnimDict('missfinale_c2mcs_1')
                        while not HasAnimDictLoaded('missfinale_c2mcs_1') do
                            Wait(50)
                        end
                        TaskPlayAnim(ped, 'missfinale_c2mcs_1', 'fin_c2_mcs_1_camman', 8.0, -8.0, 100000, 49, 0, false, false, false)
                        RemoveAnimDict('missfinale_c2mcs_1')
                        ESX.ShowHelpNotification("Press ~INPUT_CONTEXT~ To Drop The ~r~Body~w~.")
						if(firstpickup) then
							firstpickup = false
							RemoveBlip(targetblip)
							targetblip = AddBlipForCoord(Config.BodyMission.morgue.x,Config.BodyMission.morgue.y,Config.BodyMission.morgue.z)
							SetBlipSprite(targetblip,378)
							SetBlipColour(targetblip,1)
							SetBlipScale(targetblip,1.5)
							SetBlipPriority(targetblip,99)
							BeginTextCommandSetBlipName('STRING')
							AddTextComponentString("Drop Off Body")
							EndTextCommandSetBlipName(targetblip)
							SetNewWaypoint(Config.BodyMission.morgue.x,Config.BodyMission.morgue.y)
							ESX.ShowRGBNotification("info","!עכשיו תיקח את הגופה לקבלה של הבית חולים",12000)
						end
                    end, function()
                        TriggerEvent('animations:client:EmoteCommandStart',{"c"})
                    end,"fas fa-hand")
                end
            },
        },
        distance = 2.0
    })    
end

AddStateBagChangeHandler("IsDeadBody",nil,function(bagName,key,value,_,rep)
	if not value then return end
	local entity = ESX.Game.GetEntityFromStateBag(bagName)

    if not entity then return end
	local timer = GetGameTimer()
	while NetworkGetEntityOwner(entity) ~= cache.playerId do 
		Wait(0)
		if((GetGameTimer() - timer) > 15000) then
			return
		end
	end
	if(not IsPedAPlayer(entity)) then
		ApplyDamageToPed(entity,9999,false,GetHashKey("WEAPON_KNIFE"))
		DisablePedPainAudio(entity, true)
		ApplyDamageToPed(entity,9999.0,false)
		SetPedSweat(entity,100.0)
		ApplyPedDamagePack(entity, "Fall", 100, 100)
	end
	Entity(entity).state:set(key, nil, true)
end)

RegisterNetEvent("esx_ambulancejob:client:Useemptyblood",function()
	if(GetInvokingResource()) then return end
	-- if(ESX.PlayerData.job.name ~= "ambulance") then return end
	if(not ESX.GetInventoryItem("empty_bloodbag")) then return ESX.ShowRGBNotification("error","אין לך שקית דם עליך") end
	local ped = PlayerPedId()
	if(IsEntityDead(ped) or LocalPlayer.state.down) then return end
	local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
	-- closestPlayer = PlayerId()
	-- closestDistance = 0.1
	if closestPlayer == -1 or closestDistance > 2.0 then
		ESX.ShowRGBNotification("error","אין שחקן לידך")
	else
		-- if on bed else return
		local targetPed = GetPlayerPed(closestPlayer)
		if not DoesEntityExist(targetPed) then return end

		if(GetEntityModel(GetEntityAttachedTo(targetPed)) ~= `v_med_emptybed`) then
			ESX.ShowRGBNotification("error","השחקן חייב לשכב על מיטה כדי שתיקח ממנו דם")
			return
		end
		ESX.Game.FaceEntity(ped,targetPed)
		local Skillbar = exports['gi-skillbar']:GetSkillbarObject()
		Skillbar.Start({
			duration = 900, -- how long the skillbar runs for
			pos = math.random(5, 15), -- how far to the right the static box is
			width = math.random(11, 14), -- how wide the static box is
		}, function()
			local syringeProp = `prop_syringe_01`
		
			local syringeBone = 28422
			local syringeOffset = vector3(0, 0, 0)
			local syringeRot = vector3(50.0, -70.0, 0.0)
			RequestModel(syringeProp)

			while not HasModelLoaded(syringeProp) do
				Citizen.Wait(150)
			end

			local syringeObj = CreateObject(syringeProp, 0.0, 0.0, 0.0, true, true, false)
			local syringeBoneIndex = GetPedBoneIndex(ped, syringeBone)

			SetCurrentPedWeapon(ped, `weapon_unarmed`, true)
			AttachEntityToEntity(syringeObj, ped, syringeBoneIndex, syringeOffset.x, syringeOffset.y, syringeOffset.z, syringeRot.x, syringeRot.y, syringeRot.z, false, false, false, false, 2, true)
			SetModelAsNoLongerNeeded(syringeProp)

			local dict = 'melee@hatchet@streamed_core'
			RequestAnimDict(dict);
			while not HasAnimDictLoaded(dict) do
				Wait(5);
			end
			TaskPlayAnim(ped, dict, 'plyr_rear_takedown_b', 8.0, -8.0, -1, 2, 0, false, false, false)
			RemoveAnimDict(dict)
			exports['progressBars']:startUI(4000, "נועץ מזרק")
			Wait(4000)
			local coredict = "core"
			RequestNamedPtfxAsset(coredict)
			while not HasNamedPtfxAssetLoaded(coredict) do
				Wait(10)
			end
			SetPtfxAssetNextCall(coredict)
			StartParticleFxNonLoopedOnPedBone("bang_blood",targetPed, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,24818, 2.50, false, false, false)
			-- StartParticleFxNonLoopedOnEntity("blood_shark_attack",targetPed,0.0,0.0,0.0,0.0,0.0,0.0,2.0,false,false,false)
			RemoveNamedPtfxAsset(coredict)
			DeleteObject(syringeObj)
			StopAnimTask(ped,dict, 'plyr_rear_takedown_b',3.0)
			ShakeGameplayCam("MEDIUM_EXPLOSION_SHAKE",0.4)
			ApplyPedDamagePack(targetPed, "SCR_Torture", 1.0, 1.0)
			ESX.SEvent("esx_ambulancejob:server:bloodinjected",GetPlayerServerId(closestPlayer))
		end, function()
			ESX.ShowRGBNotification("error","נכשלת בזריקה")
		end)
	end
end)

RegisterNetEvent("esx_ambulancejob:client:onBloodBag",function()
	if(GetInvokingResource()) then return end
	local ped = PlayerPedId()

	RequestAnimSet("move_m@drunk@slightlydrunk")
	
	while not HasAnimSetLoaded("move_m@drunk@slightlydrunk") do
		Citizen.Wait(0)
	end
	SetPedMovementClipset(ped, "move_m@drunk@slightlydrunk", 0.0)
	RemoveAnimSet("move_m@drunk@slightlydrunk")
	local coredict = "core"
    RequestNamedPtfxAsset(coredict)
    while not HasNamedPtfxAssetLoaded(coredict) do
        Wait(10)
    end
	SetPtfxAssetNextCall(coredict)
	StartParticleFxNonLoopedOnPedBone("bang_blood",ped, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,24818, 2.50, false, false, false)
	TriggerEvent('InteractSound_CL:PlayOnOne', 'knocked', 1.0)
	ApplyPedDamagePack(ped, "SCR_Torture", 1.0, 1.0)
	RemoveNamedPtfxAsset(coredict)
	AnimpostfxPlay('DrugsMichaelAliensFightOut', 60000, true)
	ShakeGameplayCam("DRUNK_SHAKE", 1.0)
	local active = true
	CreateThread(function()
		while active do
			Wait(0)
			if(active) then
				SetAudioSpecialEffectMode(2)
			end
		end
	end)
	Wait(120000)
	active = false
	ShakeGameplayCam("DRUNK_SHAKE", 0.0)
	TriggerEvent('gi-emotes:RevertWalk')
end)
