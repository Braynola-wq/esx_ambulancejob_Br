local firstSpawn = true

isDead = false
InLaststand = false
IsFinished = false
math.randomseed(GetGameTimer())
Citizen.CreateThread(function()
	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(100)
	end

	ESX.PlayerData = ESX.GetPlayerData()
end)

RegisterFontFile('out')
fontId = RegisterFontId('Rubik-Regular')


RegisterNetEvent('esx:onPlayerLogout')
AddEventHandler('esx:onPlayerLogout', function()
  ESX.PlayerLoaded = false
  --firstSpawn = true
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
	ESX.PlayerData = xPlayer
	ESX.PlayerLoaded = true
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	ESX.PlayerData.job = job
end)

AddEventHandler('playerSpawned', function()
	if(isDead) then
		isDead = false
	end
	

	if firstSpawn then
		exports.spawnmanager:setAutoSpawn(false) -- disable respawn
		firstSpawn = false
	end
end)

-- Create blips
CreateThread(function()
	for k,v in pairs(Config.Hospitals) do
		if(v.Blip) then
			local blip = AddBlipForCoord(v.Blip.coords)

			SetBlipSprite(blip, v.Blip.sprite)
			SetBlipScale(blip, v.Blip.scale)
			SetBlipColour(blip, v.Blip.color)
			SetBlipAsShortRange(blip, true)
			SetBlipHighDetail(blip,true)

			BeginTextCommandSetBlipName('STRING')
			AddTextComponentSubstringPlayerName("Hospital")
			EndTextCommandSetBlipName(blip)
		end
	end
end)

-- Disable most inputs when dead
CreateThread(function()
	while true do
		Wait(0)

		if isDead then
			DisableAllControlActions(0)
			EnableControlAction(0, 1, true)
			EnableControlAction(0, 2, true)
			EnableControlAction(0, 47, true)
			EnableControlAction(0, 245, true)
			EnableControlAction(0, 38, true)
			EnableControlAction(0, 322, true)
			EnableControlAction(0, 288, true)
			EnableControlAction(0, 200, true) -- Pause
			AllowPauseMenuWhenDeadThisFrame()

			if(GetFollowPedCamViewMode() == 4) then
				SetFollowPedCamViewMode(0)
			end

			if(IsPauseMenuActive()) then
				EnableControlAction(0, 187, true) -- חצים
				EnableControlAction(0, 188, true) -- חצים
				EnableControlAction(0, 189, true) -- חצים
				EnableControlAction(0, 190, true) -- חצים
				EnableControlAction(0, 201, true) -- Open Map
			end
		else
			Wait(500)
		end
	end
end)

local deathreason = ""

function OnPlayerDeath()
	if(not LocalPlayer.state.down) then
		isDead = true
		ESX.UI.Menu.CloseAll()
		ESX.SEvent('esx_ambulancejob:setDeathStatus', true)
		

		StartDeathTimer()
		StartDistressSignal()
		StartScreenEffect('DeathFailOut', 0, false)
		PlaySoundFrontend(-1, "MP_Flash", "WastedSounds", 1)
		if(not IsPedInAnyVehicle(PlayerPedId(),false)) then
			CreateThread(function()
				SetTimeScale(0.2)
				Wait(2000)
				SetTimeScale(0.5)
				Wait(400)
				SetTimeScale(0.7)
				Wait(200)
				SetTimeScale(1.0)
			end)
		end
		deathreason = exports['gi_logs']:GetDeathReason()
		SetLaststand(true)

		--while IsEntityDead(PlayerPedId()) do
			--Citizen.Wait(10)
		--end
		--TriggerServerEvent('esx_ambulancejob:setDeathStatus', false)
		--TriggerServerEvent('esx_gamersjob:GetPayment',amount)
	else
		if(IsFinished == false) then
			SetLaststand(false)
			OnDeath()
		end
	end

end

exports("GetDeathReason",function()
	return deathreason
end)

RegisterNetEvent('esx_ambulancejob:useItem')
AddEventHandler('esx_ambulancejob:useItem', function(itemName)
	ESX.UI.Menu.CloseAll()

	if itemName == 'medikit' then
		local lib, anim = 'anim@heists@narcotics@funding@gang_idle', 'gang_chatting_idle01'
		ESX.Game.Progress("medkiting", "שם עזרה ראשונה", 6000, false, true, {
			disableMovement = true,
			disableCarMovement = true,
			disableMouse = false,
			disableCombat = true,
		}, {
			animDict = lib,
			anim = anim,
			flags = 0,
		}, {
			model = "prop_stat_pack_01",
		},{}, function() -- Done
			StopAnimTask(PlayerPedId(), lib,anim, -4.0);
			TriggerEvent('esx_ambulancejob:heal', 'big', true)
			ESX.ShowHDNotification("Use Item",_U('used_medikit'),"ambulance")
		end, function()
			StopAnimTask(PlayerPedId(), lib,anim, -4.0);
		end,itemName)

	elseif itemName == 'bandage' then
		local lib, anim = 'anim@heists@narcotics@funding@gang_idle', 'gang_chatting_idle01'
		ESX.Game.Progress("bandaging", "שם פלסטר", 6000, false, true, {
			disableMovement = true,
			disableCarMovement = true,
			disableMouse = false,
			disableCombat = true,
		}, {
			animDict = lib,
			anim = anim,
			flags = 0,
		}, {
			model = "prop_paper_bag_small",
		},{}, function() -- Done
			StopAnimTask(PlayerPedId(), lib,anim, -4.0);
			TriggerEvent('esx_ambulancejob:heal', 'small', true)
			ESX.ShowHDNotification("Use Item",_U('used_bandage'),"ambulance")
		end, function()
			StopAnimTask(PlayerPedId(), lib,anim, -4.0);
		end,itemName)

	elseif itemName == 'orakim' then
		local playerPed = PlayerPedId()


		local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
		if closestPlayer == -1 or closestDistance > 3.0 then
			ESX.ShowHDNotification("ERROR","No Players Nearby",'error')
			return
		end

		if not IsPedDeadOrDying(GetPlayerPed(closestPlayer) and not Player(GetPlayerServerId(closestPlayer)).state.down) then
			ESX.ShowHDNotification("ERROR",'השחקן לא מעולף','error')
			return
		end


		local lib, anim = 'anim@heists@narcotics@funding@gang_idle', 'gang_chatting_idle01'
		TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 3.5, 'bandage', 0.9)
		ESX.Game.Progress("orakim", "שם חוסם עורקים", 6000, false, true, {
			disableMovement = true,
			disableCarMovement = true,
			disableMouse = false,
			disableCombat = true,
		}, {
			animDict = lib,
			anim = anim,
			flags = 0,
		}, {
			model = "prop_paper_bag_small",
		},{}, function() -- Done
			StopAnimTask(PlayerPedId(), lib,anim, -4.0);
			TriggerServerEvent('esx_ambulancejob:orakim',GetPlayerServerId(closestPlayer))
			ESX.ShowHDNotification("Use Item","שמת חוסם עורקים על הפצוע","ambulance")
		end, function()
			StopAnimTask(PlayerPedId(), lib,anim, -4.0);
		end,itemName)


		RemoveAnimDict(lib)
	elseif itemName == 'epipen' then
		local playerPed = PlayerPedId()
		local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
		if closestPlayer == -1 or closestDistance > 3.0 then
			ESX.ShowNotification("No Players Nearby")
			return
		end


		if not IsPedDeadOrDying(GetPlayerPed(closestPlayer) and not Player(GetPlayerServerId(closestPlayer)).state.down) then
			ESX.ShowNotification('השחקן לא מעולף')
			return
		end
		local lib, anim = 'weapons@first_person@aim_rng@generic@projectile@sticky_bomb@', 'plant_floor'
		TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 3.5, 'syringe', 0.9)
		ESX.Game.Progress("epipen", "מזריק", 1500, false, true, {
			disableMovement = true,
			disableCarMovement = true,
			disableMouse = false,
			disableCombat = true,
		}, {
			animDict = lib,
			anim = anim,
			flags = 0,
		}, {
			model = "prop_syringe_01",
			bone = 28422,
			coords = { x = 0.0, y = 0.0, z = 0.0 },
			rotation = { x = 0.0, y = 0.0, z = 0.0 },
		},{}, function() -- Done
			StopAnimTask(PlayerPedId(), lib,anim, -4.0);
			TriggerServerEvent('esx_ambulancejob:epipen',GetPlayerServerId(closestPlayer))
			ESX.ShowHDNotification("Use Item","השתמשת באפי-פן","ambulance")
		end, function()
			StopAnimTask(PlayerPedId(), lib,anim, -4.0);
		end,itemName)
	end
end)

function StartDistressSignal()
	Citizen.CreateThread(function()
		local timer = Config.BleedoutTimer

		while timer > 0 and isDead do
			Citizen.Wait(2)
			timer = timer - 30

			SetTextFont(fontId)
			SetTextScale(0.45, 0.45)
			SetTextColour(255, 255, 255, 255)
			SetTextDropshadow(0, 0, 0, 0, 255)
			SetTextDropShadow()
			SetTextOutline()
			BeginTextCommandDisplayText('STRING')
			AddTextComponentSubstringPlayerName(_U('distress_send'))
			EndTextCommandDisplayText(0.175, 0.805)

			if IsControlPressed(0, 47) then
				SendDistressSignal()

				Citizen.CreateThread(function()
					Citizen.Wait(1000 * 60 * 5)
					if isDead then
						StartDistressSignal()
					end
				end)

				break
			end
		end
	end)
end

function SendDistressSignal()
	local dispatchData = exports['rcore_dispatch']:GetPlayerData()

	if(dispatchData) then
		local street = dispatchData.street_2
		TriggerServerEvent("rcore_dispatch:server:CivDown", street)
	else
		TriggerServerEvent("rcore_dispatch:server:CivDown")
	end
	
	PlaySound(-1, "Menu_Accept", "Phone_SoundSet_Default", 0, 0, 1)
	ESX.ShowRGBNotification("success",_U('distress_sent'))
end

--[[ SESX CHANGE END ]]--

function DrawGenericTextThisFrame()
	SetTextFont(fontId)
	SetTextScale(0.0, 0.4)
	SetTextColour(255, 255, 255, 255)
	SetTextDropshadow(0, 0, 0, 0, 255)
	SetTextDropShadow()
	SetTextOutline()
	SetTextCentre(true)
end

function secondsToClock(seconds)
	local seconds, hours, mins, secs = tonumber(seconds), 0, 0, 0

	if seconds <= 0 then
		return 0, 0
	else
		local hours = string.format("%02.f", math.floor(seconds / 3600))
		local mins = string.format("%02.f", math.floor(seconds / 60 - (hours * 60)))
		local secs = string.format("%02.f", math.floor(seconds - hours * 3600 - mins * 60))

		return mins, secs
	end
end

local function AcceptRespawn()
	CreateThread(function()
		local respawn = lib.alertDialog({
			header = '?האם אתה בטוח שאתה רוצה לעשות ריספאון',
			content = '.ביצוע ריספאון באמצע סיטואציה הסתיים בבאן',
			centered = true,
			cancel = true
		})
		if(isDead) then
			respawn = respawn == "confirm" or false
			if(respawn) then
				RemoveItemsAfterRPDeath()
			end
		end
	end)
end

function StartDeathTimer()
	local earlySpawnTimer = ESX.Math.Round(Config.EarlyRespawnTimer / 1000)
	local bleedoutTimer = ESX.Math.Round(Config.BleedoutTimer / 1000)


	Citizen.CreateThread(function()
		-- early respawn timer
		while earlySpawnTimer > 0 and isDead do
			Citizen.Wait(1000)

			if earlySpawnTimer > 0 then
				earlySpawnTimer = earlySpawnTimer - 1
			end
		end

		-- bleedout timer
		while bleedoutTimer > 0 and isDead do
			Citizen.Wait(1000)

			if bleedoutTimer > 0 then
				bleedoutTimer = bleedoutTimer - 1
			end
		end
	end)

	Citizen.CreateThread(function()
		local textload
		-- local timeHeld = 0

		-- early respawn timer
		while earlySpawnTimer > 0 and isDead do
			Citizen.Wait(0)
			text = _U('respawn_available_in', secondsToClock(earlySpawnTimer))

			DrawGenericTextThisFrame()

			SetTextEntry("STRING")
			AddTextComponentString(text)
			DrawText(0.5, 0.8)
		end

		-- bleedout timer
		while bleedoutTimer > 0 and isDead do
			Citizen.Wait(0)
			text = _U('respawn_bleedout_in', secondsToClock(bleedoutTimer))

			text = text .. _U('respawn_bleedout_prompt')

			-- if IsControlPressed(0, 38) and timeHeld > 60 then
			-- 	RemoveItemsAfterRPDeath()
			-- 	break
			-- end

			if(IsControlJustPressed(0,38)) then
				AcceptRespawn()
			end

			-- if IsControlPressed(0, 38) then
			-- 	timeHeld = timeHeld + 1
			-- else
			-- 	timeHeld = 0
			-- end

			DrawGenericTextThisFrame()

			SetTextEntry("STRING")
			AddTextComponentString(text)
			DrawText(0.5, 0.8)
		end
			
		if bleedoutTimer < 1 and isDead then
			RemoveItemsAfterRPDeath()
		end
	end)
end


RegisterNetEvent('esx_ambulancejob:forcerespawn',function()
	if(GetInvokingResource()) then return end
	if not LocalPlayer.state.down then return end
	if(isDead) then
		RemoveItemsAfterRPDeath()
	end
end)

RegisterNetEvent("esx_ambulancejob:client:RestartImminent", function()
	if(GetInvokingResource()) then return end
	if not LocalPlayer.state.down then return end
	if(isDead) then
		ESX.ShowRGBNotification("info", "!המערכת כפתה עליך ריספאון מידי בגלל שיש ריסטארט בדקה הקרובה")
		RemoveItemsAfterRPDeath()
	end
end)



RegisterNetEvent('esx:SetPlayerDown')
AddEventHandler('esx:SetPlayerDown',function(boolan)
	ESX.PlayerData.down = boolan
end)

function RemoveItemsAfterRPDeath()
	ESX.SEvent('esx_ambulancejob:setDeathStatus', false)

	SetLaststand(false)
	isDead = false
	IsFinished = false
	SwitchOutPlayer(PlayerPedId(), 1, 1)
	SetCloudsAlpha(0.0)

	ShowTip()

	Citizen.CreateThread(function()
		ESX.TriggerServerCallback('esx_ambulancejob:removeItemsAfterRPDeath', function()

			local formattedCoords = {}

			local spawn = Config.RespawnPoint[math.random(1,#Config.RespawnPoint)]

			formattedCoords = {
				x = spawn.coords.x,
				y = spawn.coords.y,
				z = spawn.coords.z
			} 

			local heading = spawn.heading
			ESX.SetPlayerData('lastPosition', formattedCoords)
			ESX.SetPlayerData('loadout', {})

			RespawnPed(PlayerPedId(), formattedCoords, heading)

			AnimpostfxStop('DeathFailOut')
		end)

		PlaySound(-1, "Menu_Accept", "Phone_SoundSet_Default", 0, 0, 1)
		ESX.ShowNotification("🗑️ כל הדברים שלך נלקחו")
		exports['gi-base']:DefaultPulse()
		exports['vms_hud']:ResetLastHit()
		exports['esx_policejob']:SetStatus("gunpowder",nil)
	end)
end


local GameTips = {
	".הידעת?: להרביץ בבית חולים מסתיים באדמין ג'ייל",
	"[F9] - הידעת?: אתה יכול לאזוק בכפתור",
	"[F6] - הידעת?: אתה יכול לגשת לתפריט העבודה בכפתור",
	"[F1] - אתה יכול לגשת לטלפון שלך על ידי לחיצה על המקש ",
	"!נתקעת בלי רכב? אתה יכול להזמין את הרכב האישי שלך דרך הטלפון",
	"אוכל יקר יותר ממלא את מד האוכל יותר",
	"discord.gg/fivemil !משעמם לך בטעינה? אתה מוזמן להיכנס לשרת הדיסקורד שלנו",
	"אתה יכול לבחור עבודה בלשכת העבודה ב 382",
	"הלבנת כספים נעשת דרך משפחות פשע",
	"אתה יכול לקנות נשקים במזומן בשוק השחור ",
	"ניתן לשבת על רוב הכיסאות דרך העין ",
	"[L] ניתן להציג תעודת זהות דרך המקש",
	"[F9] - יש אפשרות לשבת בתוך בגאז של רכב דרך הכפתור",
	"(לא עובד אם יש מד''א בשרת) בדלפק הבתי חולים בשביל לקבל החייאה /checkin ניתן לרשום",

}

function ShowTip()
	local text = GameTips[math.random(#GameTips)]
	TriggerEvent('chat:addMessage', { args = { "^2TIP  ", "^1"..text }, color = 0,255,255 })
end

function RespawnPed(ped, coords, heading)
	local inSwitch = IsPlayerSwitchInProgress()
	if(inSwitch) then
		FreezeEntityPosition(ped,true)
	end
	SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, false, true)
	NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, heading, true, false)
	SetPlayerInvincible(PlayerId(), false)
	TriggerEvent('playerSpawned', coords.x, coords.y, coords.z)
	local height = GetEntityHeightAboveGround(ped)
	if(height and height > 0.3 and height < 7.0) then
		local curcoords = GetEntityCoords(ped)
		SetEntityCoords(ped,curcoords.x,curcoords.y,curcoords.z - height)
	end
	ClearPedBloodDamage(ped)
	SwitchInPlayer(PlayerPedId())
	ESX.UI.Menu.CloseAll()

	CreateThread(function()
		while IsPlayerSwitchInProgress() do
			Citizen.Wait(1000)
			SwitchInPlayer(PlayerPedId())
		end
		SetCloudsAlpha(1.0)
	
		if(inSwitch) then
			local anim = 
			TriggerEvent('animations:client:EmoteCommandStart',{Config.RespawnAnimations[math.random(1,#Config.RespawnAnimations)]})
			FreezeEntityPosition(PlayerPedId(),false)
			Wait(1000)
			FreezeEntityPosition(PlayerPedId(),false)
		end
	
	end)
end

AddEventHandler('esx:onPlayerDeath', function(data)
	OnPlayerDeath()
end)

local AllowedWeaponTypes = {
    416676503, -- אקדחים
    -728555052, -- Melee
	690389602, -- Stungun
}
local Recovery = false

RegisterNetEvent('esx_ambulancejob:revive')
AddEventHandler('esx_ambulancejob:revive', function(byMedic)
	SetLaststand(false)
	ESX.SEvent('esx_ambulancejob:setDeathStatus', false)
	
	isDead = false
	IsFinished = false

	Citizen.CreateThread(function()
		DoScreenFadeOut(800)

		local timer = GetGameTimer()
		while not IsScreenFadedOut() do
			Citizen.Wait(50)
			if((GetTimeDifference(GetGameTimer(), timer) > 1600)) then
				break
			end
		end
		local playerPed = PlayerPedId()

		local coords = GetEntityCoords(playerPed)

		local formattedCoords = {
			x = ESX.Math.Round(coords.x, 1),
			y = ESX.Math.Round(coords.y, 1),
			z = ESX.Math.Round(coords.z - 1.0, 1)
		}

		ESX.SetPlayerData('lastPosition', formattedCoords)

		RespawnPed(playerPed, formattedCoords, 0.0)

		if(IsEntityOnFire(playerPed)) then
			StopEntityFire(playerPed)
		end

		TriggerEvent('CarryPeople:cl_stop')

		StopScreenEffect('DeathFailOut')
		DoScreenFadeIn(800)

		if(byMedic) then
			ESX.ShowRGBNotification("success",'מד"א טיפל בך')
			if(Recovery) then
				return
			end
			Recovery = true
			RequestAnimSet("move_m@drunk@slightlydrunk")
			while not HasAnimSetLoaded("move_m@drunk@slightlydrunk") do
			  Citizen.Wait(0)
			end
		
			SetPedMovementClipset(PlayerPedId(), "move_m@drunk@slightlydrunk", true)
			StartScreenEffect('FocusIn', 0, true)
			ShakeGameplayCam("DRUNK_SHAKE", 0.3)
			
			local RecoveryStart = GetGameTimer()
			local timdiff = math.random(180000,240000)
			local Notify = false
			
			while Recovery do
				Citizen.Wait(0)

				local ped = PlayerPedId()
				if(IsControlPressed(0,24) or IsControlPressed(0,25)) then
					SetPedConfigFlag(ped,187,true)
				else
					SetPedConfigFlag(ped,187,false)
				end

				if(IsControlJustPressed(0,45)) then
					MakePedReload(ped)
				end

				if((GetTimeDifference(GetGameTimer(), RecoveryStart) >= timdiff) or isDead) then
					Recovery = false
				end

				SetPedMovementClipset(PlayerPedId(), "move_m@drunk@slightlydrunk", true)
				if(not Notify) then
					if(IsHudComponentActive(19)) then
						ESX.ShowHelpNotification("You Are ~g~Recovering~w~ And Cant Use ~r~Heavy Weapons~w~.",false,true,7000)
					end
				end

				local wep = GetSelectedPedWeapon(ped)
				if(wep ~= GetHashKey("WEAPON_UNARMED") and wep ~= GetHashKey("OBJECT")) then
					local weptype = GetWeapontypeGroup(wep)

					local allowed = false				
					for k,v in pairs(AllowedWeaponTypes) do
						if(weptype == v) then
							allowed = true
							break
						end
					end

					if(allowed == false) then
						TriggerEvent("ox_inventory:disarm")
						-- SetCurrentPedWeapon(ped,GetHashKey("WEAPON_UNARMED"),true)
						-- ESX.ShowHDNotification("החלמה","אתה לא יכול כרגע להשתמש בכלי נשק כבדים","ambulance")
					end
				end
			end
			SetPedConfigFlag(PlayerPedId(),187,false)

			Wait(500)
			ResetPedMovementClipset(PlayerPedId(), 0)
			TriggerEvent('gi-emotes:RevertWalk')
			AnimpostfxStopAll()
			if(isDead) then
				StartScreenEffect('DeathFailOut', 0, false)
			end
			ShakeGameplayCam("DRUNK_SHAKE", 0.0)
			RemoveAnimDict("move_m@drunk@slightlydrunk")
		else
			ESX.ShowRGBNotification("success","קיבלת רבייב על ידי אדמין")
			if(Recovery) then
				Recovery = false
			end
		end
	end)
end)

local WeaponBlock = {
    "WEAPON_SNIPERRIFLE",
    "WEAPON_CARBINERIFLE",
    "WEAPON_CARBINERIFLE_MK2",
    "WEAPON_ASSAULTRIFLE",
    "WEAPON_ASSAULTRIFLE_MK2",
	"WEAPON_HEAVYRIFLE",
	"WEAPON_COMPACTRIFLE",
	"WEAPON_TACTICALRIFLE",
	"WEAPON_ADVANCEDRIFLE",
	"WEAPON_SPECIALCARBINE",
	"WEAPON_BATTLERIFLE",
	"WEAPON_BULLPUPRIFLE",
	"WEAPON_MILITARYRIFLE",
	"WEAPON_MACHINEPISTOL",
    "WEAPON_MICROSMG",
	"WEAPON_GUSENBERG",
	"WEAPON_MINISMG",
	"WEAPON_SMG",
	"WEAPON_PUMPSHOTGUN",
	"WEAPON_REVOLVER",
    "WEAPON_PISTOL50",

}

RegisterNetEvent("ox_inventory:currentWeapon",function(weapon)
	Wait(1)
	if(Recovery) then
		if(weapon and weapon.name) then
			for i = 1, #WeaponBlock, 1 do
				if(string.lower(weapon.name) == string.lower(WeaponBlock[i])) then
					TriggerEvent("ox_inventory:disarm")
					-- SetCurrentPedWeapon(PlayerPedId(),GetHashKey("WEAPON_UNARMED"),true)
					ESX.ShowHDNotification("החלמה","אתה לא יכול כרגע להשתמש בכלי נשק כבדים","ambulance")
					break
				end
			end
		end
	end
end)


-- Load unloaded IPLs
if Config.LoadIpl then
	Citizen.CreateThread(function()
		RequestIpl('Coroner_Int_on') -- Morgue
	end)
end

exports("IsPlayerDown",function()
	local down = false
	
	if(InLaststand or IsFinished) then
		return true
	end

	return false
end)


local group

RegisterNetEvent('es_admin:setGroup')
AddEventHandler('es_admin:setGroup', function(g)
	group = g
end)

RegisterNetEvent("esx_ambulancejob:Notify",function(message)
	if(group) then
		if(group == "superadmin" or group == "servermanagement") then
			TriggerEvent('chatMessage',message)
		end
	end

end)