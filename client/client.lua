--[[
    =============================================
        Vehicle Lock System - Client
        vMenu Compatible Version
        Author: Zeph
        Version: 1.1.0
    =============================================

    HOW OWNERSHIP IS DETECTED (vMenu compatible):
    ─────────────────────────────────────────────
    vMenu is written in C# and does NOT fire any Lua event when it spawns
    a vehicle. Because of this, we cannot hook into a spawn event.

    Instead, we detect ownership automatically:
    When a player enters a vehicle as the DRIVER, and that vehicle has no
    registered owner yet, we claim it as theirs and tell the server.

    This means:
    - If YOU spawn it via vMenu and get in → you own it.
    - If someone ELSE owns a vehicle and you get in as a passenger → no claim.
    - If you get into an already-owned vehicle as driver → server rejects the claim silently.
]]

-- ─────────────────────────────────────────────────────────────────
-- LOCAL STATE
-- ─────────────────────────────────────────────────────────────────

-- Tracks vehicles that THIS local player owns.
-- Format: { [vehicleNetId] = true }
local ownedVehicles = {}

-- Tracks which vehicles currently have ox_target options registered.
-- Format: { [vehicleNetId] = true }
local registeredTargets = {}

-- Tracks the current alarm coroutine token per vehicle so we can cancel it.
-- Format: { [vehicleNetId] = table }
local alarmThreads = {}

-- The vehicle handle the player was in during the last poll tick.
local lastVehicle = 0

-- ─────────────────────────────────────────────────────────────────
-- HELPER: SEND NOTIFICATION
-- ─────────────────────────────────────────────────────────────────

local function notify(title, message, ntype)
    lib.notify({
        title       = title,
        description = message,
        type        = ntype,
        position    = Config.NotifyPosition,
        duration    = Config.NotifyDuration,
    })
end

-- ─────────────────────────────────────────────────────────────────
-- HELPER: PLAY LOCK / UNLOCK SOUND + HAZARD FLASH
-- ─────────────────────────────────────────────────────────────────

local function playLockSound(vehicle)
    PlaySoundFromEntity(-1, 'Remote_Control_Fob', vehicle, 'PI_Menu_Sounds', true, 0)
    SetVehicleIndicatorLights(vehicle, 0, true)
    SetVehicleIndicatorLights(vehicle, 1, true)
    Wait(350)
    SetVehicleIndicatorLights(vehicle, 0, false)
    SetVehicleIndicatorLights(vehicle, 1, false)
end

-- ─────────────────────────────────────────────────────────────────
-- HELPER: PLAY CAR ALARM
-- ─────────────────────────────────────────────────────────────────

local function playAlarm(vehicle, netId, duration)
    local token = {}
    alarmThreads[netId] = token

    CreateThread(function()
        local startTime = GetGameTimer()

        while alarmThreads[netId] == token do
            if GetGameTimer() - startTime >= duration then break end

            -- Play one beep of the alarm sound attached to the vehicle entity.
            -- This is the same audio ref GTA uses internally for vehicle alarms
            -- and works reliably from the client on any vehicle in range.
            PlaySoundFromEntity(-1, 'Alarm_Loop', vehicle, 'DLC_HEIST_BIOLAB_PREP_HACKING_SOUNDS', true, 0)

            -- Flash hazard lights in sync with each beep.
            SetVehicleIndicatorLights(vehicle, 0, true)
            SetVehicleIndicatorLights(vehicle, 1, true)
            Wait(500)

            if alarmThreads[netId] ~= token then break end

            SetVehicleIndicatorLights(vehicle, 0, false)
            SetVehicleIndicatorLights(vehicle, 1, false)
            Wait(500)
        end

        SetVehicleIndicatorLights(vehicle, 0, false)
        SetVehicleIndicatorLights(vehicle, 1, false)

        if alarmThreads[netId] == token then
            alarmThreads[netId] = nil
        end
    end)
end

-- ─────────────────────────────────────────────────────────────────
-- CORE: REGISTER OX_TARGET OPTIONS ON A VEHICLE DOOR
-- ─────────────────────────────────────────────────────────────────

local function registerVehicleTarget(vehicle, netId)
    if not DoesEntityExist(vehicle) then return end

    -- Clear any existing options first to avoid stacking duplicates.
    if registeredTargets[netId] then
        exports.ox_target:removeLocalEntity(vehicle, {
            'vl_lock_vehicle',
            'vl_unlock_vehicle',
            'vl_lockpick_vehicle',
        })
        registeredTargets[netId] = nil
    end

    local isOwner  = ownedVehicles[netId] == true
    local isLocked = GetVehicleDoorLockStatus(vehicle) >= 2
    local options  = {}

    if isOwner then
        if isLocked then
            options[#options + 1] = {
                name     = 'vl_unlock_vehicle',
                icon     = 'fas fa-lock-open',
                label    = 'Unlock Vehicle',
                distance = Config.TargetDistance,
                bones    = { Config.DriverDoorBone },
                onSelect = function()
                    TriggerEvent('vl:client:toggleLock', vehicle, netId, false)
                end,
            }
        else
            options[#options + 1] = {
                name     = 'vl_lock_vehicle',
                icon     = 'fas fa-lock',
                label    = 'Lock Vehicle',
                distance = Config.TargetDistance,
                bones    = { Config.DriverDoorBone },
                onSelect = function()
                    TriggerEvent('vl:client:toggleLock', vehicle, netId, true)
                end,
            }
        end
    else
        -- Non-owners only see the lockpick option when the vehicle is locked.
        if isLocked then
            options[#options + 1] = {
                name     = 'vl_lockpick_vehicle',
                icon     = 'fas fa-key',
                label    = 'Lockpick Vehicle',
                distance = Config.TargetDistance,
                bones    = { Config.DriverDoorBone },
                onSelect = function()
                    TriggerEvent('vl:client:startLockpick', vehicle, netId)
                end,
            }
        end
    end

    if #options > 0 then
        exports.ox_target:addLocalEntity(vehicle, options)
        registeredTargets[netId] = true
    end
end

-- ─────────────────────────────────────────────────────────────────
-- EVENT: LOCK / UNLOCK (OWNER ONLY)
-- ─────────────────────────────────────────────────────────────────

AddEventHandler('vl:client:toggleLock', function(vehicle, netId, lock)
    if not DoesEntityExist(vehicle) then return end
    if not ownedVehicles[netId] then return end

    TriggerServerEvent('vl:server:setLockState', netId, lock)
    playLockSound(vehicle)

    if lock then
        notify('Vehicle', 'Your vehicle has been locked.', 'success')
    else
        notify('Vehicle', 'Your vehicle has been unlocked.', 'success')
    end
end)

-- ─────────────────────────────────────────────────────────────────
-- EVENT: LOCKPICK (NON-OWNER)
-- ─────────────────────────────────────────────────────────────────

AddEventHandler('vl:client:startLockpick', function(vehicle, netId)
    if not DoesEntityExist(vehicle) then return end

    local ped = PlayerPedId()

    -- Step 1: Pre-load the anim dict. lib.requestAnimDict yields until ready,
    -- so by the time we call TaskPlayAnim the dict is guaranteed loaded.
    -- This must happen before the skill check starts so there is zero
    -- extra delay between clicking the prompt and the skill check appearing.
    lib.requestAnimDict(Config.LockpickAnimDict)

    -- Step 2: Start the looping animation.
    -- Flag 1  = loop the animation continuously until we stop it manually.
    -- We use -1 as the duration so GTA does not auto-stop it after a set time.
    TaskPlayAnim(
        ped,
        Config.LockpickAnimDict,
        Config.LockpickAnimName,
        3.0, -1.0,   -- blendIn / blendOut speed
        -1,          -- duration: -1 = play until manually stopped (true loop)
        1,           -- flag 1 = LOOP
        0.0, false, false, false
    )

    -- Step 3: Run the skill check immediately — no Wait() delay.
    -- The animation plays in the background while the player does the minigame.
    local success = lib.skillCheck(Config.SkillCheckDifficulty, Config.SkillCheckKeys)

    -- Stop the animation now that the skill check is finished.
    StopAnimTask(ped, Config.LockpickAnimDict, Config.LockpickAnimName, 1.0)

    -- Step 3: Handle the result.
    if success then
        TriggerServerEvent('vl:server:setLockState', netId, false)
        notify('Lockpick', 'You successfully picked the lock!', 'success')
        if DoesEntityExist(vehicle) then
            playAlarm(vehicle, netId, Config.AlarmDurationOnSuccess)
        end
    else
        notify('Lockpick', 'You failed to pick the lock.', 'error')
        if DoesEntityExist(vehicle) then
            playAlarm(vehicle, netId, Config.AlarmDurationOnFail)
        end
    end

    -- Refresh the target options to reflect new state.
    Wait(500)
    if DoesEntityExist(vehicle) then
        registerVehicleTarget(vehicle, netId)
    end
end)

-- ─────────────────────────────────────────────────────────────────
-- SERVER EVENT: SYNC LOCK STATE TO ALL CLIENTS
-- ─────────────────────────────────────────────────────────────────

RegisterNetEvent('vl:client:syncLockState', function(netId, locked)
    local vehicle = NetToVeh(netId)
    if not DoesEntityExist(vehicle) then return end

    if locked then
        SetVehicleDoorsLocked(vehicle, 2)   -- 2 = locked to everyone
    else
        SetVehicleDoorsLocked(vehicle, 1)   -- 1 = unlocked
    end

    registerVehicleTarget(vehicle, netId)
end)

-- ─────────────────────────────────────────────────────────────────
-- SERVER EVENT: CONFIRM OWNERSHIP CLAIM
-- ─────────────────────────────────────────────────────────────────
-- The server sends this back ONLY to the player whose claim was accepted.

RegisterNetEvent('vl:client:claimVehicle', function(netId)
    ownedVehicles[netId] = true
    -- Don't register target yet — player is still inside the vehicle.
    -- The poll loop will register it once they exit.
end)

-- ─────────────────────────────────────────────────────────────────
-- MAIN POLL LOOP — ENTER / EXIT DETECTION (vMenu compatible)
-- ─────────────────────────────────────────────────────────────────
--
-- Runs twice per second. Detects:
--   → Player gets into a vehicle as driver  (attempt ownership claim)
--   → Player exits a vehicle                (register door target)

CreateThread(function()
    while true do
        Wait(500)

        local ped     = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)  -- 0 if on foot

        if vehicle ~= 0 then
            -- ── Player is currently in a vehicle ─────────────────

            if vehicle ~= lastVehicle then
                -- They just entered a new vehicle.
                -- Only claim ownership if they are sitting in the DRIVER seat.
                -- GetPedInVehicleSeat(vehicle, -1) returns the ped in the driver seat.
                if GetPedInVehicleSeat(vehicle, -1) == ped then
                    local netId = VehToNet(vehicle)
                    if netId and netId ~= 0 then
                        -- Ask the server to register this player as owner.
                        -- Server silently rejects if vehicle is already owned.
                        TriggerServerEvent('vl:server:claimVehicle', netId)
                    end
                end
            end

            -- Suppress door target options while the player is inside.
            local netId = VehToNet(vehicle)
            if netId and netId ~= 0 and registeredTargets[netId] then
                exports.ox_target:removeLocalEntity(vehicle, {
                    'vl_lock_vehicle',
                    'vl_unlock_vehicle',
                    'vl_lockpick_vehicle',
                })
                registeredTargets[netId] = nil
            end

            lastVehicle = vehicle

        else
            -- ── Player is on foot ─────────────────────────────────

            if lastVehicle ~= 0 then
                -- They just exited a vehicle — register the door target.
                local netId = VehToNet(lastVehicle)
                if netId and netId ~= 0 and DoesEntityExist(lastVehicle) then
                    registerVehicleTarget(lastVehicle, netId)
                end
            end

            lastVehicle = 0
        end
    end
end)

-- ─────────────────────────────────────────────────────────────────
-- STREAM IN: Register lockpick for locked vehicles entering range
-- ─────────────────────────────────────────────────────────────────

AddEventHandler('entityStreamIn', function(entity)
    if GetEntityType(entity) ~= 2 then return end  -- 2 = vehicle

    local netId = VehToNet(entity)
    if not netId or netId == 0 then return end

    -- Skip vehicles this player owns (handled by the poll loop on exit).
    if not ownedVehicles[netId] then
        registerVehicleTarget(entity, netId)
    end
end)

-- ─────────────────────────────────────────────────────────────────
-- STREAM OUT: Clean up target tracking for out-of-range vehicles
-- ─────────────────────────────────────────────────────────────────

AddEventHandler('entityStreamOut', function(entity)
    if GetEntityType(entity) ~= 2 then return end

    local netId = VehToNet(entity)
    if netId and netId ~= 0 then
        registeredTargets[netId] = nil
    end
end)
