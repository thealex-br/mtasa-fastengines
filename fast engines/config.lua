--[[ Warning
    🇺🇸: it is recommended that: for vehicles that reach more than (124 mph | 200 kmh) have 'USE_MAXSP_LIMIT' enabled in their handling, this
    will make the gear ratios have the ideal spacing to flow without too much revs.

    🇺🇸: vehicles with less than 5 gears will rev more than expected, change the power in 'info' to compensate.

    Changelog:
    + added per vehicle ratio
    + added per vehicle gearRatio
    + added per vehicle rpm smoother control (how fast/slow the rpm will increase/decrease)
    + added more volume options
    + added 'support' for more libraries like 'newmodels'
    + small code cleanup
    + fixed silenced vehicle when spawning inside the detection area (colshape)

    Readme:
    per-vehicle extras(turbo,als and blowoff) now uses a different structure, see below

]]

-- General Configurations
tickMult = 0.5 -- old value was 0.35 (20ms after frame finishes), new is 0.5 (30ms after frame finishes)

engineDistance = 100
engineVolume = 0.85
engineVolumeDownMult = 0.65  -- old default was 0.3, now its 0.65 (how much the volume will lower while rpm gets highter, relative to vehicle volume)
engineVolumeMinMult = 0.8    -- old default was 0.55, now its 0.8 (minimum volume, relative to vehicle volume)

engineRPMUp = 0.055
engineRPMDown = -0.047
-- change this per-vehicle, useful to make heavy cars behave more muscle, or sports with faster gear change

alsDistance = 60
alsVolume = 0.15

turboDistance = 40
turboVolume = 0.2

blowoffDistance = 40
blowoffVolume = 0.1

elementDataIDs = {"objectID", "vehicleID"} -- integration newmodels or similar resources

rpmKey = "engineRPM"            -- integration
tunningKey = "vehicle:upgrades" -- tunning, uses the same structure as bengines
-- examples:
-- setElementData(vehicle, "vehicle:upgrades", {als=true, turbo=true, blowoff=true})
-- setElementData(vehicle, "vehicle:upgrades", {als=true})

minTurboRPM = 0.65     -- minimum rpm to activate the turbo
minBlowoffRPM = 0.83   -- minimum rpm to blowoff valve
minAlsRPM = 0.83       -- minimum rpm to backfire when changing gears

gearReverse = 1.7
gearRatio = { -- for all vehicles
    [1] = 1.12,
    [2] = 1.07,
    [3] = 1.00,
    [4] = 0.97,
    [5] = 0.95,
}

-- [ID] Accelerate, Slide, Burnout, Decelerate, Air, Volume, Idle RPM, Max RPM, Audio.Ogg, [ALS, Turbo, BlowOff, ratio, gearRatio, smoother]
--                                                           (0 to 1), (0 to 1)            bool,  bool,    bool, float,     table,    table,

-- per-vehicle gearRatio uses the same structure as global gearRatio, it can be also incomplete: {[2] = 1.07, [5] = 0.82}
-- per-vehicle smoother: 'smoother = {0.095, -0.06}'

info = {
    [415] = {880, 900, 1100, 700, 600, 8.5, 0, 1.0, "audio/ferrari2.ogg", smoother={0.075, -0.056}}, -- sport
    [480] = {880, 900, 1100, 700, 600, 2.5, 0, 1.0, "audio/porsche1.ogg", smoother={0.045, -0.038}}, -- sport
    [603] = {ratio = 0.48, 980, 1010, 1100, 890, 840, 4.5, 0, 1.1, "audio/charger.ogg", smoother={0.053, -0.032}}, -- muscle
    [562] = {ratio = 0.52, 960, 980, 1100, 890, 840, 4.5, 0, 1.04, "audio/skyline.ogg", als=true, turbo=true, blowoff=true}, -- jdm ?
    [506] = {ratio = 0.52, 950, 980, 1100, 700, 600, 2.5, 0, 1.0, "audio/ferrari1.ogg", smoother={0.078, -0.08}}, -- sport
}