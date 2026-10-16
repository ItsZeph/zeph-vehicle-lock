--[[
    =============================================
        Vehicle Lock System - Server
        vMenu Compatible Version
        Author: Zeph
        Version: 1.1.0
    =============================================
]]

-- ─────────────────────────────────────────────────────────────────
-- SERVER STATE
-- ─────────────────────────────────────────────────────────────────

-- Tracks who owns which vehicle.
-- Format: { [vehicleNetId] = playerServerId }
local vehicleOwners = {}

-- Tracks the lock state of each vehicle.
-- Format: { [vehicleNetId] = true (locked) | false (unlocked) }
local vehicleLockState = {}

-- ─────────────────────────────────────────────────────────────────
-- EVENT: CLIENT REQUESTS OWNERSHIP OF A VEHICLE
-- ─────────────────────────────────────────────────────────────────
--
-- Triggered automatically by our client poll loop when a player
-- enters a vehicle as the driver. This replaces the old manual
-- TriggerServerEvent('vl:server:vehicleSpawned', netId) approach,
-- making it fully compatible with vMenu (which fires no Lua events).
--
-- The server only accepts the claim if the vehicle has NO owner yet.
-- This prevents players from stealing ownership of another player's vehicle
-- by getting into the driver seat.

RegisterNetEvent('vl:server:claimVehicle', function(netId)
    local src = source

    if not netId or netId == 0 then return end

    -- If this vehicle already has an owner, silently reject the claim.
    if vehicleOwners[netId] then
        return
    end

    -- Register ownership and set initial state (unlocked on entry).
    vehicleOwners[netId]    = src
    vehicleLockState[netId] = false

    -- Confirm to the claiming client that they now own this vehicle.
    -- Only THEY receive this event — no one else.
    TriggerClientEvent('vl:client:claimVehicle', src, netId)

    print(('[VehicleLock] Player %s claimed ownership of vehicle netId %s'):format(src, netId))
end)

-- ─────────────────────────────────────────────────────────────────
-- EVENT: CLIENT REQUESTS A LOCK STATE CHANGE
-- ─────────────────────────────────────────────────────────────────
--
-- Called by:
--   - The owner, to lock or unlock their vehicle.
--   - A non-owner, after a successful lockpick (to unlock only).

RegisterNetEvent('vl:server:setLockState', function(netId, locked)
    local src = source

    if not netId or netId == 0 then return end

    local owner = vehicleOwners[netId]

    if src == owner then
        -- Owner can freely lock or unlock.
        vehicleLockState[netId] = locked

    elseif not locked then
        -- Non-owner requesting unlock (lockpick success).
        -- Only allow if the vehicle is currently locked.
        if vehicleLockState[netId] then
            vehicleLockState[netId] = false
        else
            return  -- Vehicle already unlocked, nothing to do.
        end
    else
        -- Non-owner trying to LOCK a vehicle they don't own — deny.
        print(('[VehicleLock] WARN: Player %s attempted to lock vehicle %s they do not own.'):format(src, netId))
        return
    end

    -- Broadcast the new state to ALL players so every client can update
    -- the vehicle's lock visuals and door target options.
    TriggerClientEvent('vl:client:syncLockState', -1, netId, vehicleLockState[netId])

    print(('[VehicleLock] Vehicle %s is now %s (changed by player %s)'):format(
        netId,
        vehicleLockState[netId] and 'LOCKED' or 'UNLOCKED',
        src
    ))
end)

-- ─────────────────────────────────────────────────────────────────
-- CLEANUP: PLAYER DISCONNECTS
-- ─────────────────────────────────────────────────────────────────
-- Remove their ownership records so vehicles aren't stuck as permanently owned.

AddEventHandler('playerDropped', function()
    local src = source
    for netId, ownerId in pairs(vehicleOwners) do
        if ownerId == src then
            vehicleOwners[netId]    = nil
            vehicleLockState[netId] = nil
            print(('[VehicleLock] Cleared ownership for vehicle %s — player %s disconnected.'):format(netId, src))
        end
    end
end)

-- ─────────────────────────────────────────────────────────────────
-- EXPORTS: Allow other resources to query vehicle lock info
-- ─────────────────────────────────────────────────────────────────

exports('getVehicleOwner', function(netId)
    return vehicleOwners[netId]
end)

exports('isVehicleLocked', function(netId)
    return vehicleLockState[netId] == true
end)
