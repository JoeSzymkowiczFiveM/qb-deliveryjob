local QBCore = exports['qb-core']:GetCoreObject()
local activeDeliveries = {}

AddEventHandler("onResourceStop", function(r)
	if r == GetCurrentResourceName() then
        for _, v in pairs(activeDeliveries) do
            exports.ox_target:removeZone(v)
        end
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    TriggerServerEvent('qb-deliveryjob:server:logout')
end)

local function knockDoorAnim()
    local knockAnimLib = "timetable@jimmy@doorknock@"
    local knockAnim = "knockdoor_idle"
    local PlayerPed = PlayerPedId()

    --TriggerServerEvent("InteractSound_SV:PlayOnSource", "knock_door", 0.2)
    Wait(100)
    lib.requestAnimDict(knockAnimLib)
    TaskPlayAnim(PlayerPed, knockAnimLib, knockAnim, 3.0, 3.0, -1, 1, 0, false, false, false )
    Wait(3500)
    TaskPlayAnim(PlayerPed, knockAnimLib, "exit", 3.0, 3.0, -1, 1, 0, false, false, false)
    Wait(1000)
end

RegisterNetEvent('qb-deliveryjob:client:deliveryDoor', function(data)
    local door = data.door
    knockDoorAnim()
    TriggerServerEvent('qb-deliveryjob:server:doorSuccess', door)
end)

RegisterNetEvent('qb-deliveryjob:client:getJob', function(job)
    

    TriggerEvent('qb-phone:client:DeliveriesNotification', {
        message = "New QBer Eats Delivery Available!",
    })

    -- exports.qtarget:AddBoxZone("deliveryjob_door"..job, vector3(Config.Doors[job].loc.x, Config.Doors[job].loc.y, Config.Doors[job].loc.z), 1.0, 1.0, {
    --     name="deliveryjob_door_"..job,
    --     heading=(Config.Doors[job].loc.w),
    --     --debugPoly=true,
    --     minZ=(Config.Doors[job].loc.z - 1),
    --     maxZ=(Config.Doors[job].loc.z + 1)
    --     }, {
    --     options = {
    --         {
    --             event = "qb-deliveryjob:client:deliveryDoor",
    --             icon = "fas fa-door-closed",
    --             label = "Make Delivery",
    --             door = job,
    --         },
    --     },
    --     distance = 2.0
    -- })

    activeDeliveries[job] = exports.ox_target:addBoxZone({
        coords = vector3(Config.Doors[job].loc.x, Config.Doors[job].loc.y, Config.Doors[job].loc.z),
        size = vec3(1, 1, 2),
        rotation = Config.Doors[job].loc.w,
        --debug = true,
        options = {
            {
                name = 'box',
                event = 'qb-deliveryjob:client:deliveryDoor',
                icon = 'fas fa-door-closed',
                label = 'Make Delivery',
                door = job,
            }
        }
    })

    TriggerEvent('qb-phone:client:UpdateDeliveries')
end)

RegisterNetEvent('qb-deliveryjob:client:cancelDoor', function(job)
    
    for k, v in pairs(activeDeliveries) do
        if job ~= nil then
            if activeDeliveries[job] ~= nil then
                exports.ox_target:removeZone(activeDeliveries[job])
                activeDeliveries[job] = nil
            end
        else
            exports.ox_target:removeZone(v)
            activeDeliveries[k] = nil
        end
    end
    TriggerEvent('qb-phone:client:UpdateDeliveries')
end)