local animDict = 'missfbi5ig_0'
local animName = 'lyinginpain_loop_steve'
local inBedDicts = "anim@gangops@morgue@table@"
local inBedAnims = "ko_front"
local PickUpObject = nil
local isSitting = false
local PickingUp = false
local ForceGetUp = false
local ForcedToBed = false
local lastbed
local lastwheelchair

RegisterNetEvent("ambulance:client:deleteObject")
AddEventHandler("ambulance:client:deleteObject", function()
	local bed = GetClosestObjectOfType(GetEntityCoords(cache.ped), 10.0, GetHashKey('v_med_emptybed'))
	local wheelchair = GetClosestObjectOfType(GetEntityCoords(cache.ped), 10.0, GetHashKey('prop_wheelchair_01'))

	if DoesEntityExist(bed) then
		ESX.Game.DeleteObject(bed)
		lastbed = nil
		ESX.ShowRGBNotification("success","מחקת את המיטה")
		return
	elseif DoesEntityExist(wheelchair) then
		ESX.Game.DeleteObject(wheelchair)
		lastwheelchair = nil
		ESX.ShowRGBNotification("success","מחקת את הכיסא גלגלים")
		return
	end

	ESX.ShowRGBNotification("error","לא נמצא משהו למחוק")
end)

RegisterNetEvent("esx_ambulancejob:client:medbag")
AddEventHandler("esx_ambulancejob:client:medbag", function()
	Wait(50)
	ExecuteCommand("e medbag")
	ESX.ShowRGBNotification("success","שולף תיק")
end)

RegisterNetEvent("esx_ambulancejob:client:bed")
AddEventHandler("esx_ambulancejob:client:bed", function()
	if(lastbed and (GetTimeDifference(GetGameTimer(), lastbed) < 30000)) then
		ESX.ShowRGBNotification("error","נא להמתין בין כל שיגור מיטה")
		ESX.ShowRGBNotification("error","שימו לב: הספמת מיטות עלולה להסתיים בבאן")
		return
	end
    lastbed = GetGameTimer()
	local playerPed = cache.ped
	local coords  = GetEntityCoords(playerPed)
	local forward = GetEntityForwardVector(playerPed)
	local x, y, z = table.unpack(coords + forward * 1.0)
	local model = GetHashKey('v_med_emptybed')
	ESX.ShowRGBNotification("success","😏 מוציא מיטה")
	LoadModel(model)	

	local obj = CreateObject(model, x, y + 1.0, z - 1.0, true, true,true)
	while not DoesEntityExist(obj) do
		Wait(200)
	end
	SetModelAsNoLongerNeeded(model)
	SetEntityHeading(obj, GetEntityHeading(playerPed))
	PlaceObjectOnGroundProperly(obj)
	SetEntityCollision(obj, true, true)
end)

RegisterNetEvent("esx_ambulancejob:client:wheelchair")
AddEventHandler("esx_ambulancejob:client:wheelchair", function()

	if(lastwheelchair and (GetTimeDifference(GetGameTimer(), lastwheelchair) < 30000)) then
		ESX.ShowRGBNotification("error","נא להמתין בין כל שיגור כיסא גלגלים")
		ESX.ShowRGBNotification("error","שימו לב: הספמת כיסאות עלולה להסתיים בבאן")
		return
	end
    lastwheelchair = GetGameTimer()

	local playerPed = cache.ped
	local coords  = GetEntityCoords(playerPed)
	local forward = GetEntityForwardVector(playerPed)
	local x, y, z = table.unpack(coords + forward * 1.0)
	local model = GetHashKey('prop_wheelchair_01')
	ESX.ShowRGBNotification("success","מוציא כיסא גלגלים")
	LoadModel(model)	

	local obj = CreateObject(model, x, y + 1.0, z - 1.0, true, true,true)
	while not DoesEntityExist(obj) do
		Wait(200)
	end
	SetEntityHeading(obj, GetEntityHeading(playerPed))
	PlaceObjectOnGroundProperly(obj)
	SetEntityCollision(obj, true, true)
end)

CreateThread(function()

	while true do
		local sleep = 1000

		local ped = cache.ped
		local pedCoords = GetEntityCoords(ped)

        local closestBed = GetClosestObjectOfType(pedCoords, 3.0, GetHashKey("v_med_emptybed"), false)
		local closestChair = GetClosestObjectOfType(pedCoords, 3.0, GetHashKey("prop_wheelchair_01"), false)
		if(not isSitting) then
			if DoesEntityExist(closestBed) and IsEntityAMissionEntity(closestBed) then
				sleep = 0

				local stretcherCoords = GetEntityCoords(closestBed)
				local stretcherForward = GetEntityForwardVector(closestBed)
				local sitCoords = (stretcherCoords + stretcherForward * - 0.5)
				local pickupCoords = (stretcherCoords + stretcherForward * 1.2)

				if GetDistanceBetweenCoords(pedCoords, sitCoords, true) <= 1.5 then
					DrawText3Ds(sitCoords, "[G] Lay down")

					if IsDisabledControlJustPressed(0, 47) then
						LayOut(closestBed)
						Wait(1000)
					end
				end


				if not IsEntityAttached(closestBed) and GetDistanceBetweenCoords(pedCoords, pickupCoords, true) <= 2.5 and ESX ~= nil and ESX.PlayerData.job.name == 'ambulance' then
					DrawText3Ds(pickupCoords, "[H] Grab")

					if IsControlJustPressed(0, 74) then
						PickUp(closestBed)
						Wait(1000)
					end
				end
			elseif DoesEntityExist(closestChair) and IsEntityAMissionEntity(closestChair) then
				sleep = 0

				local wheelChairCoords = GetEntityCoords(closestChair)
				local wheelChairForward = GetEntityForwardVector(closestChair)
				
				local sitCoords = (wheelChairCoords + wheelChairForward * - 0.5)
				local pickupCoords = (wheelChairCoords + wheelChairForward * 0.3)

				if GetDistanceBetweenCoords(pedCoords, sitCoords, true) <= 1.0 then
					DrawText3Ds(sitCoords, "[E] Sit", 0.4)

					if IsControlJustPressed(0, 38) then
						ChairSit(closestChair)
						Wait(1000)
					end
				end

				if GetDistanceBetweenCoords(pedCoords, pickupCoords, true) <= 1.0 then
					DrawText3Ds(pickupCoords, "[E] Pick up", 0.4)

					if IsControlJustPressed(0, 38) then
						ChairPickUp(closestChair)
						Wait(1000)
					end
				end
			end
		end

		Wait(sleep)
	end
end)


local LayOutObject = nil
LayOut = function(stretcherObject)
	local closestPlayer, closestPlayerDist = GetClosestPlayer()

	if closestPlayer ~= nil and closestPlayer ~= 0 then
		if IsEntityPlayingAnim(GetPlayerPed(closestPlayer), 'dead', 'dead_a', 3) then
			ESX.ShowHDNotification("ERROR","Somebody is already using the stretcher!", 'ambulance')
			return
		end
	end

	LoadAnim("dead")

	AttachEntityToEntity(cache.ped, stretcherObject, 0, 0, 0.0, 1.3, 0.0, 0.0, 180.0, 0.0, false, false, false, false, 2, true)

	local heading = GetEntityHeading(stretcherObject)

	LayOutObject = stretcherObject
	TriggerEvent('canUseInventoryAndHotbar:toggle', false)
	while LayOutObject and DoesEntityExist(LayOutObject) do
		Wait(0)


		if IsDisabledControlJustPressed(0, 47) or cache.vehicle or ForceGetUp then
			if(not ForcedToBed or ForceGetUp) then
				break
			end
		end

		-- local interior = GetInteriorAtCoords(GetEntityCoords(cache.ped))
		-- if(interior ~= 0) then
		-- 	if not IsInteriorReady(interior) then
		-- 		RefreshInterior(interior)
		-- 	end
		-- end

		if not IsEntityPlayingAnim(cache.ped, 'dead', 'dead_a', 1) then
			TaskPlayAnim(cache.ped, "dead", "dead_a", 1.0, 1.0, -1, 33, 0, 0, 0, 0)
		end

		DisablePlayerFiring(cache.playerId, true)
		DisableControlAction(0, 47, true)  -- Disable weapon
		DisableControlAction(0, 264, true) -- Disable melee
		DisableControlAction(0, 257, true) -- Disable melee
		DisableControlAction(0, 140, true) -- Disable melee
		DisableControlAction(0, 141, true) -- Disable melee
		DisableControlAction(0, 142, true) -- Disable melee
		DisableControlAction(0, 143, true) -- Disable melee
		DisableControlAction(0, 24, true) -- Attack
		DisableControlAction(0, 257, true) -- Attack 2
		DisableControlAction(0, 25, true) -- Aim
		DisableControlAction(0, 263, true) -- Melee Attack 1
	end

	if(not IsPedInAnyVehicle(cache.ped,false)) then
		DetachEntity(cache.ped, true, true)
		SetEntityCoords(cache.ped, GetEntityCoords(cache.ped))
	end
	LayOutObject = nil
	if(LocalPlayer.state.down) then
		TriggerEvent('canUseInventoryAndHotbar:toggle', true)
	end
end
 
PickUp = function(stretcherObject)
	local tries = 10
	NetworkRequestControlOfEntity(stretcherObject)
	while not NetworkHasControlOfEntity(stretcherObject) do
		Wait(500)
		NetworkRequestControlOfEntity(stretcherObject)
		tries = tries - 1
		if(tries <= 0) then
			break
		end
	end

	LoadAnim("anim@heists@box_carry@")

	AttachEntityToEntity(stretcherObject, cache.ped, GetPedBoneIndex(cache.ped,  28422), -0.0, -1.2, -1.0, 195.0, 180.0, 180.0, 0.0, false, false, true, false, 2, true)

	PickUpObject = stretcherObject
	exports['qb-target']:AddGlobalVehicle({
		options = {
		  {
			type = "client",
			icon = 'fas fa-ambulance', 
			label = "הכנס את הפצוע לרכב",
			action = function(entity)
			  if IsPedAPlayer(entity) then return false end 
			  local playerPed = cache.ped
			  local coords, forward = GetEntityCoords(playerPed), GetEntityForwardVector(playerPed)
			  local patientCoords = (coords + forward * 0.7)
			  local closestPlayer, closestPlayerDist = GetClosestPlayer(patientCoords)
			  if closestPlayer ~= nil and closestPlayer ~= 0 then
				if(closestPlayerDist < 3.0) then
					ESX.SEvent('esx_ambulancejob:putInVehicle', GetPlayerServerId(closestPlayer))
				else
					ESX.ShowHDNotification("Ambulance","לא נמצא פצוע","ambulance")
				end
			  else
				ESX.ShowHDNotification("Ambulance","לא נמצא פצוע","ambulance")
			  end
			end,
			job = "ambulance"
		  }
		},
		distance = 2.5,
	  })

	while PickUpObject and DoesEntityExist(PickUpObject) do
		Wait(0)
		SetPedConfigFlag(cache.ped, 104, false)
		
		if not IsEntityPlayingAnim(cache.ped, 'anim@heists@box_carry@', 'idle', 3) then
			TaskPlayAnim(cache.ped, 'anim@heists@box_carry@', 'idle', 8.0, 8.0, -1, 50, 0, false, false, false)
		end

		if IsControlJustPressed(0, 74) or IsPedDeadOrDying(cache.ped) or LocalPlayer.state.down or IsPedInAnyVehicle(cache.ped,false) then
			DetachEntity(stretcherObject, true, true)
			break
		end

		DisablePlayerFiring(cache.playerId, true)
		DisableControlAction(0, 47, true)  -- Disable weapon
		DisableControlAction(0, 264, true) -- Disable melee
		DisableControlAction(0, 257, true) -- Disable melee
		DisableControlAction(0, 140, true) -- Disable melee
		DisableControlAction(0, 141, true) -- Disable melee
		DisableControlAction(0, 142, true) -- Disable melee
		DisableControlAction(0, 143, true) -- Disable melee
		DisableControlAction(0, 24, true) -- Attack
		DisableControlAction(0, 257, true) -- Attack 2
		DisableControlAction(0, 25, true) -- Aim
		DisableControlAction(0, 263, true) -- Melee Attack 1
	end
	SetPedConfigFlag(cache.ped, 104, true)
	exports['qb-target']:RemoveGlobalVehicle("הכנס את הפצוע לרכב")

	PickUpObject = nil
	ClearPedSecondaryTask(cache.ped)
end

DrawText3Ds = function(coords, text)
	local x,y,z = coords.x, coords.y, coords.z
    local onScreen,_x,_y=World3dToScreen2d(x,y,z)
    local px,py,pz=table.unpack(GetGameplayCamCoords())
    
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x,_y)
    local factor = (string.len(text)) / 370
    DrawRect(_x,_y+0.0125, 0.015+ factor, 0.03, 41, 11, 41, 68)
end



GetClosestPlayer = function(coords)
	local players = GetActivePlayers()
	local closestDistance = -1
	local closestPlayer = -1
	local ply = GetPlayerPed(PlayerId())
	local plyCoords = coords or GetEntityCoords(ply, 0)
	
	for index,value in ipairs(players) do
		local target = GetPlayerPed(value)
		if(target ~= ply) then
			local targetCoords = GetEntityCoords(GetPlayerPed(value), 0)
			local distance = Vdist(targetCoords["x"], targetCoords["y"], targetCoords["z"], plyCoords["x"], plyCoords["y"], plyCoords["z"])
			if(closestDistance == -1 or closestDistance > distance) then
				closestPlayer = value
				closestDistance = distance
			end
		end
	end
	
	return closestPlayer, closestDistance
end

LoadAnim = function(dict)
	while not HasAnimDictLoaded(dict) do
		RequestAnimDict(dict)
		
		Wait(1)
	end
end

LoadModel = function(model)
	while not HasModelLoaded(model) do
		RequestModel(model)
		
		Wait(1)
	end
end

ChairSit = function(wheelchairObject)
	local closestPlayer, closestPlayerDist = GetClosestPlayer()

	if closestPlayer ~= nil and closestPlayerDist <= 1.5 then
		if IsEntityPlayingAnim(GetPlayerPed(closestPlayer), 'missfinale_c2leadinoutfin_c_int', '_leadin_loop2_lester', 3) then
			ESX.ShowHDNotification("ERROR","Somebody is already using the wheelchair!", 'ambulance')
			return
		end
	end

	if(PickingUp) then
		ESX.ShowHDNotification("ERROR","אתה לא יכול לשבת על הכיסא בזמן שאתה מרים אותו","ambulance")
		return
	end

	if(isSitting) then
		return
	end


	isSitting = true
	LoadAnim("missfinale_c2leadinoutfin_c_int")

	AttachEntityToEntity(cache.ped, wheelchairObject, 0, 0, 0.0, 0.4, 0.0, 0.0, 180.0, 0.0, false, false, false, false, 2, true)

	local heading = GetEntityHeading(wheelchairObject)
	TriggerEvent('canUseInventoryAndHotbar:toggle', false)
	while IsEntityAttachedToEntity(cache.ped, wheelchairObject) do
		Wait(0)

		if(IsPedInAnyVehicle(cache.ped,false)) then
			break
		end

		if not IsEntityPlayingAnim(cache.ped, 'missfinale_c2leadinoutfin_c_int', '_leadin_loop2_lester', 3) then
			TaskPlayAnim(cache.ped, 'missfinale_c2leadinoutfin_c_int', '_leadin_loop2_lester', 8.0, 8.0, -1, 69, 1, false, false, false)
		end

		--[[if IsControlPressed(0, 32) then
			local x, y, z  = table.unpack(GetEntityCoords(wheelchairObject) + GetEntityForwardVector(wheelchairObject) * -0.03)
			SetEntityCoords(wheelchairObject, x,y,z)
			PlaceObjectOnGroundProperly(wheelchairObject)
		end--]]

		if IsControlPressed(1,  34) then
			heading = heading + 0.4

			if heading > 360 then
				heading = 0
			end

			SetEntityHeading(wheelchairObject,  heading)
		end

		if IsControlPressed(1,  9) then
			heading = heading - 0.4

			if heading < 0 then
				heading = 360
			end

			SetEntityHeading(wheelchairObject,  heading)
		end

		if IsControlJustPressed(0, 38) then
			TriggerEvent('esx_ambulancejob:CheckFall')
			break
		end

		if(IsPedDeadOrDying(cache.ped)) then
			break
		end

		if(not DoesEntityExist(wheelchairObject)) then
			break
		end

		DisablePlayerFiring(PlayerId(), true)
		DisableControlAction(0, 47, true)  -- Disable weapon
		DisableControlAction(0, 264, true) -- Disable melee
		DisableControlAction(0, 257, true) -- Disable melee
		DisableControlAction(0, 140, true) -- Disable melee
		DisableControlAction(0, 141, true) -- Disable melee
		DisableControlAction(0, 142, true) -- Disable melee
		DisableControlAction(0, 143, true) -- Disable melee
		DisableControlAction(0, 24, true) -- Attack
		DisableControlAction(0, 257, true) -- Attack 2
		DisableControlAction(0, 25, true) -- Aim
		DisableControlAction(0, 263, true) -- Melee Attack 1
	end
	if(LocalPlayer.state.down) then
		TriggerEvent('canUseInventoryAndHotbar:toggle', true)
	end
	isSitting = false
	local ped = cache.ped
	DetachEntity(ped, true, true)
	if(not IsPedInAnyVehicle(ped,false)) then
		local x, y, z = table.unpack(GetEntityCoords(ped))

		SetEntityCoords(ped, x,y,z)
	end
	ClearPedSecondaryTask(ped)

end

ChairPickUp = function(wheelchairObject)
	local closestPlayer, closestPlayerDist = GetClosestPlayer()

	if closestPlayer ~= nil and closestPlayerDist <= 1.5 then
		if IsEntityPlayingAnim(GetPlayerPed(closestPlayer), 'anim@heists@box_carry@', 'idle', 3) then
			ESX.ShowHDNotification("ERROR","מישהו כבר מחזיק את הכיסא גלגלים", 'ambulance')
			return
		end
	end


	if(isSitting) then
		ESX.ShowHDNotification("ERROR","אתה לא יכול להרים את הכיסא גלגלים בזמן שאתה יושב עליו","ambulance")
		return
	end

	if(PickingUp) then
		return
	end

	PickingUp = true
	NetworkRequestControlOfEntity(wheelchairObject)
	local tries = 10
	while not NetworkHasControlOfEntity(wheelchairObject) do
		Wait(500)
		NetworkRequestControlOfEntity(wheelchairObject)
		tries = tries - 1
		if(tries <= 0) then
			break
		end
	end


	LoadAnim("anim@heists@box_carry@")

	TaskPlayAnim(cache.ped, 'anim@heists@box_carry@', 'idle', 8.0, 8.0, -1, 50, 0, false, false, false)
	AttachEntityToEntity(wheelchairObject, cache.ped, GetPedBoneIndex(cache.ped,  28422), -0.00, -0.3, -0.73, 195.0, 180.0, 180.0, 0.0, false, false, true, false, 2, true)

	exports['qb-target']:AddGlobalVehicle({
		options = {
		  {
			type = "client",
			icon = 'fas fa-ambulance', 
			label = "הכנס את הפצוע לרכב",
			action = function(entity)
			  if IsPedAPlayer(entity) then return false end 
			  local playerPed = cache.ped
			  local coords, forward = GetEntityCoords(playerPed), GetEntityForwardVector(playerPed)
			  local patientCoords = (coords + forward * 0.7)
			  local closestPlayer, closestPlayerDist = GetClosestPlayer(patientCoords)
			  if closestPlayer ~= nil and closestPlayer ~= 0 then
				if(closestPlayerDist < 3.0) then
					ESX.SEvent('esx_ambulancejob:putInVehicle', GetPlayerServerId(closestPlayer))
				else
					ESX.ShowHDNotification("Ambulance","לא נמצא פצוע","ambulance")
				end
			  else
				ESX.ShowHDNotification("Ambulance","לא נמצא פצוע","ambulance")
			  end
			end,
			job = "ambulance"
		  }
		},
		distance = 2.5,
	  })

	while IsEntityAttachedToEntity(wheelchairObject, cache.ped) do
		Wait(0)

		SetPedConfigFlag(cache.ped, 104, false)
		if IsControlJustPressed(0, 38) or IsPedInAnyVehicle(cache.ped,false) then
			break
		end

		if IsPedDeadOrDying(cache.ped) then
			break
		end

		if not IsEntityPlayingAnim(cache.ped, 'anim@heists@box_carry@', 'idle', 3) then
			TaskPlayAnim(cache.ped, 'anim@heists@box_carry@', 'idle', 8.0, 8.0, -1, 50, 0, false, false, false)
		end



		DisablePlayerFiring(PlayerId(), true)
		DisableControlAction(0, 47, true)  -- Disable weapon
		DisableControlAction(0, 264, true) -- Disable melee
		DisableControlAction(0, 257, true) -- Disable melee
		DisableControlAction(0, 140, true) -- Disable melee
		DisableControlAction(0, 141, true) -- Disable melee
		DisableControlAction(0, 142, true) -- Disable melee
		DisableControlAction(0, 143, true) -- Disable melee
		DisableControlAction(0, 24, true) -- Attack
		DisableControlAction(0, 257, true) -- Attack 2
		DisableControlAction(0, 25, true) -- Aim
		DisableControlAction(0, 263, true) -- Melee Attack 1
	end
	exports['qb-target']:RemoveGlobalVehicle("הכנס את הפצוע לרכב")
	PickingUp = false
	DetachEntity(wheelchairObject, true, true)
	ClearPedSecondaryTask(cache.ped)
	RemoveAnimDict("anim@heists@box_carry@")
	SetPedConfigFlag(cache.ped, 104, true)
end

RegisterNetEvent('esx_ambulancejob:CheckFall')
AddEventHandler('esx_ambulancejob:CheckFall',function()


	Wait(1500)

	local ped = cache.ped

	if(IsPedFalling(ped)) then

		local mathradiusx = math.random(-20, 20)
		local mathradiusy = math.random(-20, 20)
		if(mathradiusx < 2 and mathradiusx > 0) then
			mathradiusx = 2
		end

		if(mathradiusy > -2 and mathradiusy < 0) then
			mathradiusy = -2
		end


		if(mathradiusy < 2 and mathradiusy > 0) then
			mathradiusy = 2
		end

		if(mathradiusy > -2 and mathradiusy < 0) then
			mathradiusy = -2
		end
		
		local coords = GetEntityCoords(ped) 
		local x = coords.x + mathradiusx
		local y = coords.y + mathradiusy

		local spawnOnPavement = false
		
		local foundSafeCoords, safeCoords = GetSafeCoordForPed(x, y, coords.z, spawnOnPavement , 16)

		if not foundSafeCoords then 

			local safeZ = 0


			repeat
				Wait(250)
				local onGround, safeZ = GetGroundZFor_3dCoord(x, y,999.0,true)
				if not onGround then
					safeZ = safeZ + 0.1
				end

			until onGround

			

			safeCoords = vector3(x, y, safeZ)
		end

		SetEntityCoords(ped,safeCoords)
	end


end)




RegisterNetEvent("esx_ambulancejob:ToggleBed",function(bedNet)
	local ped = cache.ped
	if not LocalPlayer.state.down and not IsEntityDead(ped) then return end
	
	-- local closestBed = GetClosestObjectOfType(pedCoords, 3.0, GetHashKey("v_med_emptybed"), false)
	if(not ForcedToBed) then
		local closestBed = NetToObj(bedNet)
		if DoesEntityExist(closestBed) and IsEntityAMissionEntity(closestBed) then
			local stretcherCoords = GetEntityCoords(closestBed)
			local stretcherForward = GetEntityForwardVector(closestBed)
			local sitCoords = (stretcherCoords + stretcherForward * - 0.5)
			local pedCoords = GetEntityCoords(ped)
			if #(pedCoords - sitCoords) <= 6.5 then
				ForcedToBed = true
				LayOut(closestBed)
			end
		end
	else
		ForceGetUp = true
		Wait(20)
		ForceGetUp = false
		ForcedToBed = false
	end

end)