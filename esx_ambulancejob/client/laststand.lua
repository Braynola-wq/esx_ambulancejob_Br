-- Config
LaststandCarObject = {}
Laststand = Laststand or {}
Laststand.ReviveInterval = 300
Laststand.MinimumRevive = 120

-- Code


LaststandTime = 0

lastStandDict = "combat@damage@writhe"
lastStandAnim = "writhe_loop"


function SetLaststand(bool, spawn)
    local ped = PlayerPedId()
    if bool then
        SetFacialIdleAnimOverride(PlayerPedId(), "dead_1", 0)
        TriggerEvent('esx:SetPlayerDown',true)
        InLaststand = true
        Wait(1000)
        local isincar = IsPedInAnyVehicle(ped, false)
        if isincar then
            LaststandCarObject = {
                ['obj'] = GetVehiclePedIsIn(ped, false),
                ['seat'] = getSeat(GetVehiclePedIsIn(ped, false), ped)
            }
        end

        while GetEntitySpeed(ped) > 0.5 or IsPedRagdoll(ped) do
            Citizen.Wait(10)
        end

        if(not IsEntityDead(ped)) then
            InLaststand = false
            TriggerEvent('esx:SetPlayerDown',false)
            return
        end

        --TriggerServerEvent("InteractSound_SV:PlayOnSource", "demo", 0.1)

        LaststandTime = Laststand.ReviveInterval

        local pos = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)
        NetworkResurrectLocalPlayer(pos.x, pos.y, pos.z, heading, true, false)
        SetEntityHealth(ped, 150)        
        if isincar then
            SetPedIntoVehicle(ped, LaststandCarObject['obj'], LaststandCarObject['seat'])
            LoadAnimation("veh@low@front_ps@idle_duck")
            TaskPlayAnim(ped, "veh@low@front_ps@idle_duck", "sit", 2.0, 2.0, -1, 51, 0, false, false, false)
            RemoveAnimDict("veh@low@front_ps@idle_duck")
        else
            LoadAnimation(lastStandDict)
            TaskPlayAnim(ped, lastStandDict, lastStandAnim, 1.0, 8.0, -1, 1, -1, false, false, false)
            RemoveAnimDict(lastStandDict)
        end



        Citizen.CreateThread(function()
            while InLaststand do
                if LaststandTime - 1 > Laststand.MinimumRevive then
                    LaststandTime = LaststandTime - 1
                    Config.DeathTime = LaststandTime
                elseif LaststandTime - 1 <= Laststand.MinimumRevive and LaststandTime - 1 ~= 0 then
                    LaststandTime = LaststandTime - 1
                    Config.DeathTime = LaststandTime
                elseif LaststandTime - 1 <= 0 then
                    ESX.ShowHDNotification("Death System","You've bled out..", "warning")
                    SetLaststand(false)
                    OnDeath()
                end
                Citizen.Wait(1000)
            end
        end)
    else
        ClearFacialIdleAnimOverride(PlayerPedId())
        InLaststand = false
        IsFinished = false
        LaststandTime = 0
        TriggerEvent('esx:SetPlayerDown',false)
    end
end

function LoadAnimation(dict)
    while not HasAnimDictLoaded(dict) do
        RequestAnimDict(dict)
        Citizen.Wait(100)
    end
end

function getSeat(isincar, ped)
    for v = -1, 6 do
        local sped = GetPedInVehicleSeat(isincar, v)
        if sped == ped then
            return v
        end
    end
    return nil
end