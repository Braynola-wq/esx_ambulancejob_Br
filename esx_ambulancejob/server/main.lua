-- Server-side logic for esx_ambulancejob
-- This file was created to resolve a missing file error from fxmanifest.lua.
-- Add any necessary server-side functions and event handlers here.

ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

-- Example: Register server-side events or callbacks if needed
-- RegisterServerEvent('esx_ambulancejob:exampleServerEvent')
-- AddEventHandler('esx_ambulancejob:exampleServerEvent', function()
--     -- Handle event
-- end)

-- ESX.RegisterServerCallback('esx_ambulancejob:exampleCallback', function(source, cb, ...)
--     -- Handle callback
--     cb(true)
-- end)

print("esx_ambulancejob: server/main.lua loaded.")
