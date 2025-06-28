local deadAnimDict = "dead"
local deadAnim = "dead_a"
local deadCarAnimDict = "veh@low@front_ps@idle_duck"
local deadCarAnim = "sit"
local hold = 5

deathTime = 0
--[[Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
        local player = PlayerId()
		if NetworkIsPlayerActive(player) then
            local playerPed = PlayerPedId()
            if IsEntityDead(playerPed) and InLaststand and not IsFinished then
                SetLaststand(false)
                deathTime = 300
                OnDeath()
            end
		end
	end
end)--]]



Citizen.CreateThread(function()
	while true do
        Citizen.Wait(0)
        if IsFinished or InLaststand then            
            if IsFinished then
                local ped = PlayerPedId()
                if IsPedInAnyVehicle(ped, false) then
                    if not IsEntityPlayingAnim(ped, "veh@low@front_ps@idle_duck", "sit", 3) then
                        loadAnimDict("veh@low@front_ps@idle_duck")
                        TaskPlayAnim(ped, "veh@low@front_ps@idle_duck", "sit", 1.0, 1.0, -1, 1, 0, 0, 0, 0)
                        RemoveAnimDict("veh@low@front_ps@idle_duck")
                    end
                else
                    if not IsEntityPlayingAnim(ped, deadAnimDict, deadAnim, 3) then
                        loadAnimDict(deadAnimDict)
                        TaskPlayAnim(ped, deadAnimDict, deadAnim, 1.0, 1.0, -1, 1, 0, 0, 0, 0)
                        RemoveAnimDict(deadAnimDicts)
                    end
                end

                SetCurrentPedWeapon(ped, GetHashKey("WEAPON_UNARMED"), true)
            elseif InLaststand then
                local ped = PlayerPedId()
                if IsPedInAnyVehicle(ped, false) then
                    if not IsEntityPlayingAnim(ped, "veh@low@front_ps@idle_duck", "sit", 3) then
                        loadAnimDict("veh@low@front_ps@idle_duck")
                        TaskPlayAnim(ped, "veh@low@front_ps@idle_duck", "sit", 2.0, 2.0, -1, 51, 0, false, false, false)
                        RemoveAnimDict("veh@low@front_ps@idle_duck")
                    end
                else
                    if not IsEntityPlayingAnim(ped, lastStandDict, lastStandAnim, 3) then
                        loadAnimDict(lastStandDict)
                        TaskPlayAnim(ped, lastStandDict, lastStandAnim, 1.0, 8.0, -1, 1, -1, false, false, false)
                        RemoveAnimDict(lastStandDict)
                    end
                end
            end
		else
			Citizen.Wait(500)
		end
	end
end)

function OnDeath(spawn)
    if not IsFinished then
        IsFinished = true
        --TriggerServerEvent("InteractSound_SV:PlayOnSource", "demo", 0.1)
        local player = PlayerPedId()

        while GetEntitySpeed(player) > 0.5 or IsPedRagdoll(player) do
            Citizen.Wait(10)
        end

        if(not IsEntityDead(player)) then
            InLaststand = false
            TriggerEvent('esx:SetPlayerDown',false)
            return
        end

        if IsFinished then
            local isincar = IsPedInAnyVehicle(player, false)
            if isincar then
                LaststandCarObject = {
                    ['obj'] = GetVehiclePedIsIn(player, false),
                    ['seat'] = getSeat(GetVehiclePedIsIn(player, false), player)
                }
            end

            local pos = GetEntityCoords(player)
            local heading = GetEntityHeading(player)
            NetworkResurrectLocalPlayer(pos.x, pos.y, pos.z, heading, true, false)
            SetEntityInvincible(player, true)
            SetEntityHealth(player, GetEntityMaxHealth(player))
            SetFacialIdleAnimOverride(player, "dead_1", 0)
            if isincar then
                TaskWarpPedIntoVehicle(player, LaststandCarObject['obj'], LaststandCarObject['seat'])
                LoadAnimation("veh@low@front_ps@idle_duck")
                TaskPlayAnim(player, "veh@low@front_ps@idle_duck", "sit", 2.0, 2.0, -1, 51, 0, false, false, false)
                RemoveAnimDict("veh@low@front_ps@idle_duck")
            else
                LoadAnimation(lastStandDict)
                TaskPlayAnim(player, lastStandDict, lastStandAnim, 1.0, 8.0, -1, 1, -1, false, false, false)
                RemoveAnimDict(lastStandDict)
            end
            SetTimeout(1000,function()
                TriggerEvent('SetPulseDead')
            end)
        end
    end
end

function DrawTxt(x, y, width, height, scale, text, r, g, b, a, outline)
    SetTextFont(4)
    SetTextProportional(0)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, a)
    SetTextDropShadow(0, 0, 0, 0,255)
    SetTextEdge(2, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x - width/2, y - height/2 + 0.005)
end

function loadAnimDict(dict)
	while(not HasAnimDictLoaded(dict)) do
		RequestAnimDict(dict)
		Citizen.Wait(1)
	end
end