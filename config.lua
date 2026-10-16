--[[
    =============================================
        Vehicle Lock System - Config
        Author: Your Server
        Version: 1.0.0
    =============================================

    SKILL CHECK DIFFICULTY OPTIONS:
    ─────────────────────────────────────────────
    You can use the preset strings: 'easy', 'medium', 'hard'

    OR define custom values using a table:
    {
        areaSize       = number,  -- Size of the "safe zone" on the bar.
                                  -- Larger = easier. Range: ~10 (brutal) to ~80 (very easy)
        speedMultiplier = number  -- How fast the indicator moves.
                                  -- Lower = easier. Range: 0.5 (slow) to 3.0 (very fast)
    }

    NOTIFICATION POSITIONS:
    ─────────────────────────────────────────────
    Valid positions: 'top', 'top-right', 'top-left',
                     'bottom', 'bottom-right', 'bottom-left', 'center-right'
]]

Config = {}

-- ─────────────────────────────────────────────────────────────────
-- LOCKPICK SKILL CHECK SETTINGS
-- ─────────────────────────────────────────────────────────────────

-- How many skill check rounds must the player complete to succeed?
-- More rounds = harder overall even at easy difficulty.
Config.SkillCheckRounds = 3

-- Difficulty per round. You can mix presets and custom tables.
-- The number of entries should match Config.SkillCheckRounds.
-- Preset options: 'easy' | 'medium' | 'hard'
Config.SkillCheckDifficulty = {
    'easy',     -- Round 1
    'medium',   -- Round 2
    'hard',     -- Round 3
}

-- Keys the player must press during the skill check.
-- You can add or remove keys from this list.
Config.SkillCheckKeys = { 'e' }

-- ─────────────────────────────────────────────────────────────────
-- LOCKPICK ANIMATION SETTINGS
-- ─────────────────────────────────────────────────────────────────

-- The animation dictionary (anim dict) used during lockpicking.
Config.LockpickAnimDict = 'veh@break_in@0h@p_m_one@'
Config.LockpickAnimName = 'low_force_entry_ds'

-- NOTE: The animation now loops automatically for the entire duration of the
-- skill check, then stops when the skill check completes. No fixed duration needed.

-- ─────────────────────────────────────────────────────────────────
-- SOUND SETTINGS
-- ─────────────────────────────────────────────────────────────────

-- How long (in milliseconds) the car alarm plays after a failed lockpick.
Config.AlarmDurationOnFail    = 8000   -- 8 seconds

-- How long the car alarm plays after a SUCCESSFUL lockpick.
Config.AlarmDurationOnSuccess = 5000   -- 5 seconds

-- ─────────────────────────────────────────────────────────────────
-- TARGET SETTINGS
-- ─────────────────────────────────────────────────────────────────

-- Maximum distance (in metres) the player can be from the door to see the option.
Config.TargetDistance = 2.0

-- The bone name for the driver's side front door.
-- This is the bone ox_target uses to detect which part of the vehicle you are looking at.
-- 'door_dside_f' = Driver Side Front door (standard for most GTA vehicles)
Config.DriverDoorBone = 'door_dside_f'

-- ─────────────────────────────────────────────────────────────────
-- NOTIFICATION SETTINGS
-- ─────────────────────────────────────────────────────────────────

-- Position of all notifications. See header comment for valid options.
Config.NotifyPosition = 'center-right'

-- How long (milliseconds) notifications stay on screen.
Config.NotifyDuration = 4000
