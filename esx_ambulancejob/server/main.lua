-- Placeholder for server-side logic for esx_ambulancejob
-- Ensure any actual server scripts are moved into this file or registered appropriately.

ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

-- Example of a server-side event (if you had one to move here)
-- RegisterServerEvent('myAmbulance:server:someEvent')
-- AddEventHandler('myAmbulance:server:someEvent', function(data)
--     local _source = source
--     local xPlayer = ESX.GetPlayerFromId(_source)
--     if xPlayer then
--         print('Event someEvent received from ' .. xPlayer.getName() .. ' with data: ' .. json.encode(data))
--         -- Your logic here
--     end
-- end)

print("[esx_ambulancejob] Server-side main.lua loaded.")
