local QBCore = exports['qb-core']:GetCoreObject()
local runners = {}

local deliveryItems = {
    "burger-bleeder",
    "burger-moneyshot",
    "pizza_box",
}

local DeliveryItem = QBCore.Functions.GetSharedItems(deliveryItems)

local Items = {
    [1] = {item = "burger-bleeder", rewardPer = 60},
    [2] = {item = "burger-moneyshot", rewardPer = 65},
    [3] = {item = "pizza_box", rewardPer = 65},
}

--Functions
local function GetRandomRunner()
    local shuffled = {}
    local count = 0
    for i, v in pairs(runners) do
        count = count + 1
        shuffled[#shuffled+1] = i
    end
    local rand = math.random(count)
    return shuffled[rand]
end

local function GetRandomDoor()
    local shuffled = {}
    local count = 0
    for i, v in pairs(Config.Doors) do
        if not v.taken then
            count = count + 1
            shuffled[#shuffled+1] = i
        end
    end
    if count > 0 then
        local rand = math.random(count)
        return shuffled[rand]
    else
        return nil
    end
end

local function GetTotalRunners()
    local count = 0
    for i, v in pairs(runners) do
        count = count + 1
    end
    return count
end

--Callbacks
QBCore.Functions.CreateCallback('qb-deliveryjob:server:GetDeliveries', function(source, cb)
    local src = source
    local jobs = { working = false }
    if runners[src] ~= nil then
        jobs = runners[src]
    end
    
    cb(jobs)
end)

--Events
AddEventHandler('playerDropped', function(DropReason)
    local src = source
    local newRunners = {}
    for k, v in pairs(runners) do
        if k ~= src then
            newRunners[k] = v
        end
    end
    runners = newRunners
end)

RegisterServerEvent('qb-deliveryjob:server:logout', function()
    local src = source

    local newRunners = {}
    for k, v in pairs(runners) do
        if k ~= src then
            newRunners[k] = v
        end
    end
    runners = newRunners
end)

RegisterServerEvent('qb-deliveryjob:server:toggleDeliveries', function()
    local src = source
    if runners[src] == nil then
        runners[src] = {
            jobs = {},
            jobCount = 0,
            working = true,
            lastJob = os.time(),
        }
        TriggerClientEvent("QBCore:Notify", src, "Started taking deliveries..", "success")
    else
        local newRunners = {}
        for k, v in pairs(runners) do
            if k ~= src then
                newRunners[k] = v
            end
        end
        runners = newRunners
        TriggerClientEvent("QBCore:Notify", src, "Stopped taking deliveries..", "error")
        TriggerClientEvent('qb-deliveryjob:client:cancelDoor', src)
    end
end)

RegisterServerEvent('qb-deliveryjob:server:doorSuccess', function(job)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    for k, v in pairs(runners[src].jobs) do
        if v.id == job then
            local item = v.item
            if Player.Functions.RemoveItem(item, v.itemCount) then
                local reward = 0
                for a, s in pairs(Items) do
                    if v.item == s.item then
                        reward = s.rewardPer * v.itemCount
                    end
                end
                local tip = math.ceil(2*(v.expire - os.time()) / 100)
                Player.Functions.AddMoney("cash", (reward + tip) * 3 , "delivery-success")
                TriggerClientEvent("QBCore:Notify", src, "Delivery Successful..", "success")
                TriggerClientEvent('qb-deliveryjob:client:cancelDoor', src, job)

                runners[src].jobs[k] = nil
                Config.Doors[job].taken = false
                runners[src].jobCount = runners[src].jobCount - 1
                break
            else
                TriggerClientEvent("QBCore:Notify", src, "Missing delivery items..", "error")
            end
        end
    end
end)

--[[ runners = {
    [src / #] = {
        jobs = {
            [1] = { id = #, loc = vector4, itemCount = #, item = string, itemProper = string, coords = {x, y, z}, expire = # time, area = string},
            [2] = { id = #, loc = vector4, itemCount = #, item = string, itemProper = string, coords = {x, y, z}, expire = # time, area = string},
        },
        jobCount = #,
        working = bool,
        lastJob = # time
    },
} ]]



--Threads
CreateThread(function()
    while true do
        if GetTotalRunners() > 0 then
            local door = GetRandomDoor()
            if door ~= nil then
                local v = Config.Doors[door]
                if not v.taken then
                    local src = GetRandomRunner()
                    if runners[src].jobCount < 4 and ( (os.time() - runners[src].lastJob) > 360 )then
                        local Player = QBCore.Functions.GetPlayer(src)
                        if Player ~= nil then
                            v.taken = true
                            local itemCount = math.random(4)
                            local item = Items[math.random(#Items)].item

                            local expireTime = os.time() + 1800  --1800 seconds is 30 min
                            local addJob = {id = door, loc = v.loc, itemCount = itemCount, item = item, itemProper = DeliveryItem[item].label, coords = {x = v.loc.x, y = v.loc.y, z = v.loc.z}, expire = expireTime, area = v.area}
                            runners[src].jobCount = runners[src].jobCount + 1
                            runners[src].lastJob = os.time()
                            table.insert(runners[src].jobs, addJob)

                            TriggerClientEvent('qb-deliveryjob:client:getJob', src, door)
                        else

                        end
                    end
                end
            end

            for k, v in pairs(runners) do
                for a, s in pairs(v.jobs) do
                    if s.expire <= os.time() then
                        TriggerClientEvent('qb-deliveryjob:client:cancelDoor', k, s.id)
                        runners[k].jobCount = runners[k].jobCount - 1
                        runners[k].jobs[a] = nil
                        Config.Doors[s.id].taken = false
                    end
                end
            end
        end
        Wait(10000)
    end
end)

-- CreateThread(function()
--     while true do
--         Wait(10000)
--         for k, v in pairs(runners) do
--             for a, s in pairs(v.jobs) do
--                 if s.expire <= os.time() then
--                     TriggerClientEvent('qb-deliveryjob:client:cancelDoor', k, s.id)
--                     runners[k].jobCount = runners[k].jobCount - 1
--                     runners[k].jobs[a] = nil
--                     Config.Doors[s.id].taken = false
--                 end
--             end
--         end
--     end
-- end)