--[[ Warning
    recommended: for vehicles that reach more than 124 mph (200 kmh) have 'USE_MAXSP_LIMIT' enabled in their handling,
    this will make the gear ratios have the ideal spacing to flow without too much revs.

    vehicles with less than 5 gears will rev more than expected, lower the engine power to compensate.

    Changelog:
    + simplified configuration and engine configuration structure
    + simplified code in general
    + fixed silenced vehicle when spawning inside the detection area (colshape)
    + more performant "default sound disabler"
    + more smoother rpm transition (optional)
    + output rpm is always a number between 0 and 1
]]

-- General Configurations
config = {
    wait = 30,          -- wait ms between every frame, keep below 40
    
    smoother = { -- extra smoothness to rpm, will increase cpu usage to +- 0.2% per vehicle
        enable = false,
        simple = true,
    },

    keys = {"actualID", "vehicleID"}, -- integration newmodels and similar resources

    rpmKey = "engineRPM",            -- to integrate into speedometer systems, use getElementData(vehicle, "engineRPM") * 7000
    tunningKey = "vehicle:upgrades", -- tunning, uses the same structure as bengines
    -- examples:
    -- setElementData(vehicle, "vehicle:upgrades", {als=true, turbo=true, blowoff=true})
    -- setElementData(vehicle, "vehicle:upgrades", {als=true})

    engine = {
        distance = 60,
        volume = 0.85,
        volumeDown = 0.65,  -- old default was 0.3, now its 0.65 (how much the volume will lower while rpm gets highter, relative to vehicle volume)
        volumeMin = 0.8,    -- old default was 0.55, now its 0.8 (minimum volume, relative to vehicle volume)
        smoother = {0.055, -0.047},

        ratio = { -- for all vehicles
            [0] = 1.70,
            [1] = 1.12,
            [2] = 1.07,
            [3] = 1.00,
            [4] = 0.97,
            [5] = 0.95,
        },
    },

    als = {
        distance = 60,
        volume = 0.55,
        enable = 0.78,       -- minimum rpm to backfire when changing gears
    },

    turbo = {
        distance = 40,
        volume = 0.2,
        enable = 0.73,     -- minimum rpm to activate the turbo
    },

    blowoff = {
        distance = 40,
        volume = 0.1,
        enable = 0.78,   -- minimum rpm to blowoff valve
    },
}

--[[
OPT = optional

[id] = {ratio, gearRatio, accel, decel, air, slide, vol, min, max, audio, smoother, als, turbo, blowoff}

OPT ratio       = from 0 to 1, 0.5 if not used
OPT gearRatio   = table, same structure as global gearRatio, it can be also incomplete like: 'gearRatio = {[2] = 1.07, [5] = 0.82}'
accel           = from 0 to 1000, value for acceleration
decel           = from 0 to 1000, value for deceleration
air             = from 0 to 1000, value when vehicle is not on ground
slide           = from 0 to infinite, value is added to acceleration when sliding (between 100 and 200 is recommended)
volume          = volume, depends on audio volume
min             = from 0 to 1, minimal vehicle rpm
max             = from 0 to 1, maximum vehicle rpm
audio           = audio file string, like "audio/skyline.ogg"
OPT smoother    = table, like 'smoother={0.067, -0.048}'
OPT als         = bool
OPT turbo       = bool
OPT blowoff     = bool
]]

info = {
    [562]={ratio=0.53, accel=1020, decel=980, air=940, slide=400, vol=3.0, min=0.03, max=1.09, audio="audio/skyline.ogg", smoother={0.067, -0.048}},
    [10001]={ratio=0.53, accel=1020, decel=980, air=940, slide=400, vol=3.0, min=0.03, max=1.09, audio="audio/skyline.ogg", smoother={0.067, -0.048}},
    [10002]={ratio=0.53, accel=1020, decel=980, air=940, slide=400, vol=2.0, min=0.03, max=1.09, audio="audio/lamborghini4.ogg", smoother={0.067, -0.048}},
    [10003]={ratio=0.53, accel=1020, decel=980, air=940, slide=400, vol=2.0, min=0.03, max=1.09, audio="audio/240sx.ogg", smoother={0.067, -0.048}},
    [10004]={ratio=0.53, accel=1020, decel=980, air=940, slide=400, vol=2.0, min=0.03, max=1.09, audio="audio/rx8.ogg", smoother={0.067, -0.048}},
    [10005]={ratio=0.53, accel=1020, decel=980, air=940, slide=400, vol=4.0, min=0.03, max=1.09, audio="audio/charger.ogg", smoother={0.067, -0.048}},
    [10006]={ratio=0.53, accel=1000, decel=940, air=900, slide=400, vol=4.0, min=0.06, max=1.09, audio="audio/str8.ogg", smoother={0.072, -0.048}},
    [10007]={ratio=0.53, accel=1020, decel=980, air=940, slide=400, vol=2.0, min=0.03, max=1.09, audio="audio/srt8.ogg", smoother={0.067, -0.048}},
    [10008]={ratio=0.515, accel=930, decel=870, air=940, slide=400, vol=5.0, min=0.03, max=1.0, audio="audio/aston1.ogg", smoother={0.067, -0.048}},
    [10009]={ratio=0.53, accel=1020, decel=980, air=940, slide=400, vol=4.0, min=0.03, max=1.09, audio="audio/bmwm3gtr.ogg", smoother={0.067, -0.048}},
    [10010]={ratio=0.515, accel=980, decel=980, air=940, slide=400, vol=1.5, min=0.03, max=1.07, audio="audio/camaro.ogg", smoother={0.067, -0.048}},
    [10011]={ratio=0.53, accel=800, decel=980, air=940, slide=400, vol=4.0, min=0.03, max=1.09, audio="audio/audi1.ogg", smoother={0.087, -0.058}},
    [10012]={ratio=0.53, accel=1020, decel=980, air=940, slide=400, vol=2.0, min=0.03, max=1.09, audio="audio/rx8.ogg", smoother={0.067, -0.048}},
    [10013]={ratio=0.53, accel=1020, decel=980, air=940, slide=400, vol=4.0, min=0.03, max=1.09, audio="audio/lamborghini4.ogg", smoother={0.077, -0.048}},
    [10014]={ratio=0.53, accel=1020, decel=980, air=940, slide=400, vol=4.0, min=0.03, max=1.09, audio="audio/charger.ogg", smoother={0.067, -0.048}},
    [10015]={ratio=0.53, accel=1020, decel=980, air=940, slide=400, vol=1.0, min=0.03, max=1.09, audio="audio/300c.ogg", smoother={0.067, -0.048}},
    [10016]={ratio=0.53, accel=980, decel=920, air=880, slide=400, vol=4.5, min=0.03, max=1.06, audio="audio/mp4.ogg", smoother={0.065, -0.055}},
    [10024]={ratio=0.53, accel=960, decel=870, air=840, slide=450, vol=2.0, min=0.03, max=1.0, audio="audio/lamborghini6.ogg", smoother={0.10, -0.068}},
    [10029]={ratio=0.53, accel=1020, decel=920, air=900, slide=400, vol=4.0, min=0.03, max=1.09, audio="audio/charger.ogg", smoother={0.067, -0.048}},
    [10030]={ratio=0.53, accel=1020, decel=920, air=900, slide=400, vol=4.0, min=0.03, max=1.09, audio="audio/bmwm3gtr.ogg", smoother={0.067, -0.048}},
    [10031]={ratio=0.53, accel=1020, decel=920, air=900, slide=400, vol=4.0, min=0.03, max=1.09, audio="audio/eclipse1.ogg", smoother={0.067, -0.048}},
    [10032]={ratio=0.53, accel=940, decel=820, air=720, slide=400, vol=4.0, min=0.03, max=1.0, audio="audio/koegg.ogg", smoother={0.087, -0.078}},
    [10033]={ratio=0.53, accel=1020, decel=980, air=940, slide=400, vol=3.0, min=0.03, max=1.09, audio="audio/skyline.ogg", smoother={0.067, -0.048}},
    [10034]={ratio=0.53, accel=980, decel=900, air=840, slide=400, vol=0.5, min=0.03, max=1.09, audio="audio/gtr1.ogg", smoother={0.097, -0.058}},
    [10035]={ratio=0.53, accel=980, decel=900, air=840, slide=400, vol=0.5, min=0.03, max=1.06, audio="audio/ferrari1.ogg", smoother={0.097, -0.058}},
    [10036]={ratio=0.53, accel=200, decel=170, air=840, slide=50, vol=0.4, min=0.0, max=1.0, audio="audio/models.ogg", smoother={0.097, -0.058}},
    [10037]={ratio=0.55, accel=920, decel=800, air=700, slide=50, vol=4, min=0.0, max=1.04, audio="audio/f1.ogg", smoother={0.130, -0.08}},
    [10038]={ratio=0.53, accel=980, decel=900, air=840, slide=400, vol=1, min=0.03, max=1.06, audio="audio/bentley1.ogg", smoother={0.097, -0.058}},
}
