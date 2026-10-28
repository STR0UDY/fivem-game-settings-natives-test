-- Test commands for the game settings natives from https://github.com/citizenfx/fivem/pull/4313
-- Requires a FiveM client built from that PR. Output goes to the F8 console and an on-screen overlay.

local OVERLAY_LINES = 24
local OVERLAY_SECONDS = 15

local overlay = {}
local overlayUntil = 0

local function log(line)
    print(line)

    overlay[#overlay + 1] = line:gsub('%^%d', '')
    while #overlay > OVERLAY_LINES do
        table.remove(overlay, 1)
    end
    overlayUntil = GetGameTimer() + OVERLAY_SECONDS * 1000
end

local OVERLAY_X = 0.03
local OVERLAY_Y = 0.05
local OVERLAY_LINE_HEIGHT = 0.02
local OVERLAY_WIDTH = 0.3

CreateThread(function()
    while true do
        if GetGameTimer() < overlayUntil then
            local height = #overlay * OVERLAY_LINE_HEIGHT + 0.01
            DrawRect(OVERLAY_X + OVERLAY_WIDTH / 2 - 0.005, OVERLAY_Y + height / 2 - 0.003, OVERLAY_WIDTH, height, 0, 0, 0, 160)

            for i, line in ipairs(overlay) do
                SetTextFont(0)
                SetTextScale(0.0, 0.28)
                SetTextColour(255, 255, 255, 235)
                SetTextOutline()
                BeginTextCommandDisplayText('STRING')
                AddTextComponentSubstringPlayerName(line)
                EndTextCommandDisplayText(OVERLAY_X, OVERLAY_Y + (i - 1) * OVERLAY_LINE_HEIGHT)
            end
            Wait(0)
        else
            Wait(250)
        end
    end
end)

-- returns ok, result; prints the error when the native throws
local function call(label, fn, ...)
    local ok, result = pcall(fn, ...)
    if not ok then
        log(('^1[gs] %s failed: %s^7'):format(label, tostring(result)))
    end
    return ok, result
end

local function formatValue(value)
    if math.type(value) == 'float' then
        return (('%.3f'):format(value):gsub('0+$', ''):gsub('%.$', ''))
    end
    return tostring(value)
end

local APPLY_RESULTS = { [0] = 'rejected (resolution not available)', [1] = 'applied', [2] = 'restart required (not applied live)' }

local function describeApply(result)
    return ('%s (%s)'):format(tostring(result), APPLY_RESULTS[result] or '?')
end

local function sortedKeys(t)
    local keys = {}
    for k in pairs(t) do keys[#keys + 1] = k end
    table.sort(keys)
    return keys
end

-- gs_get            print every setting
-- gs_get MSAA       print one setting
RegisterCommand('gs_get', function(_, args)
    local ok, settings = call('GetGameSettings', GetGameSettings)
    if not ok then return end

    if args[1] then
        log(('[gs] %s = %s'):format(args[1], formatValue(settings[args[1]])))
        return
    end

    local keys = sortedKeys(settings)
    log(('[gs] GetGameSettings returned %d settings'):format(#keys))

    for _, key in ipairs(keys) do
        log(('[gs] %s = %s'):format(key, formatValue(settings[key])))
    end
end, false)

-- gs_res            list resolutions offered for the current monitor
RegisterCommand('gs_res', function()
    local ok, list = call('GetAvailableScreenResolutions', GetAvailableScreenResolutions)
    if not ok then return end

    log(('[gs] %d resolutions:'):format(#list))
    for _, r in ipairs(list) do
        log(('[gs]   %dx%d'):format(r.width, r.height))
    end
end, false)

-- gs_set TextureQuality 2      stage a change (not applied yet)
RegisterCommand('gs_set', function(_, args)
    local name, value = args[1], tonumber(args[2])
    if not name or not value then
        log('[gs] usage: gs_set <name> <value>')
        return
    end

    if call('SetGameSetting', SetGameSetting, name, value + 0.0) then
        log(('[gs] staged %s = %s'):format(name, value))
    end
end, false)

-- gs_apply          apply staged changes (not saved)
-- gs_apply 1        apply and save to settings.xml
RegisterCommand('gs_apply', function(_, args)
    local save = args[1] == '1'
    local ok, applied = call('ApplyGameSettings', ApplyGameSettings, save)
    if ok then
        log(('[gs] apply -> %s, save=%s'):format(describeApply(applied), tostring(save)))
    end
end, false)

-- gs_clear          drop staged changes
RegisterCommand('gs_clear', function()
    call('ClearPendingGameSettings', ClearPendingGameSettings)
    log('[gs] cleared staged changes')
end, false)

-- gs_res_set 1920 1080   stage + apply a resolution in one go (not saved)
RegisterCommand('gs_res_set', function(_, args)
    local w, h = tonumber(args[1]), tonumber(args[2])
    if not w or not h then
        log('[gs] usage: gs_res_set <width> <height>')
        return
    end

    call('SetGameSetting', SetGameSetting, 'ScreenWidth', w + 0.0)
    call('SetGameSetting', SetGameSetting, 'ScreenHeight', h + 0.0)
    local ok, applied = call('ApplyGameSettings', ApplyGameSettings, false)
    if ok then
        log(('[gs] resolution %dx%d -> %s'):format(w, h, describeApply(applied)))
    end
end, false)

-- gs_restart TextureQuality   whether changing a setting needs a game restart
RegisterCommand('gs_restart', function(_, args)
    if not args[1] then
        log('[gs] usage: gs_restart <name>')
        return
    end

    local ok, requires = call('GetGameSettingRequiresRestart', GetGameSettingRequiresRestart, args[1])
    if ok then
        log(('[gs] %s requires restart: %s'):format(args[1], tostring(requires)))
    end
end, false)

CreateThread(function()
    log('[gs] gamesettings_test ready - type gs_get in the F8 console')
end)
