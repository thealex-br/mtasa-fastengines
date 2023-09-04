
audioDistance = 100

elementDataName = "engineRPM" -- used to make integrations to some speedometer system
elementDataIDs = "vehicleID"  -- used by 'newmodels library'

reverseGearPower = 1.3

gearMultiplier = {
    [1] = 1.12,
    [2] = 1.07,
    [3] = 1.00,
    [4] = 0.98,
    [5] = 0.97,
}

--  [ID] Accel, Slide, Burnout, not accel, Air, Vol, Idle RPM, Max RPM, Audio.ogg
--                                                   (0 to 1), (0 to 1)
info = {
    [415] = {860, 900, 1100, 700, 600, 8.5, 0, 1.0, "audio/ferrari2.ogg"},

    -- more examples
    [80001] = {800, 900, 1100, 700, 600, 4.5, 0, 0.97, "audio/lamborghini2.ogg"},
    [80002] = {920, 1000, 1100, 800, 700, 1.5, 0.08, 0.97, "audio/ferrari1.ogg"},
    [80003] = {900, 1000, 1100, 800, 700, 4.5, 0, 0.97, "audio/lamborghini2.ogg"},
    [80004] = {900, 1000, 1100, 800, 700, 4.0, 0, 0.97, "audio/bugatti1.ogg"},

    [80005] = {940, 1000, 1100, 800, 700, 1.5, 0, 0.97, "audio/300zx.ogg"},
    [80006] = {800, 900, 1000, 800, 700, 2.0, 0, 0.97, "audio/gtr1.ogg"},
    [80007] = {910, 1000, 1100, 800, 700, 2.5, 0, 0.97, "audio/lamborghini1.ogg"},
    [80008] = {915, 1000, 1100, 800, 700, 1.3, 0, 0.97, "audio/mr2.ogg"},
    [80011] = {965, 1000, 1100, 800, 700, 2.0, 0, 0.97, "audio/gtr1.ogg"},
    [80012] = {930, 970, 1100, 840, 700, 2.3, 0, 0.97, "audio/wraith.ogg"},
    [80013] = {930, 970, 1100, 840, 700, 2.3, 0, 0.97, "audio/charger.ogg"},
    [80014] = {930, 970, 1100, 840, 700, 4.3, 0, 0.97, "audio/lamborghini3.ogg"},

    [80009] = {930, 970, 1100, 840, 700, 2.0, 0, 0.97, "audio/bentley1.ogg"},
    [80010] = {930, 970, 1100, 840, 700, 2.0, 0, 0.97, "audio/challenger.ogg"},
    [80015] = {940, 1000, 1100, 800, 700, 1.5, 0, 0.97, "audio/350z.ogg"},
    [80016] = {940, 1000, 1100, 800, 700, 1.8, 0, 0.97, "audio/porsche1.ogg"},
    [80019] = {890, 1010, 1100, 760, 700, 3.5, 0, 0.97, "audio/lamborghini4.ogg"},
    [80020] = {840, 860, 1100, 760, 700, 5.0, 0, 0.97, "audio/lamborghini3.ogg"},
    [80021] = {880, 890, 1100, 760, 700, 10.0, 0, 0.97, "audio/ferrari2.ogg"},
    [80022] = {840, 860, 1100, 760, 700, 5.0, 0, 0.97, "audio/magnum.ogg"},
    [80023] = {760, 800, 1100, 840, 700, 2.0, 0, 0.97, "audio/lamborghini1.ogg"},

    [80025] = {930, 970, 1100, 840, 700, 2.0, 0, 0.97, "audio/challenger.ogg"},
    [80026] = {930, 970, 1100, 840, 700, 4.0, 0, 0.97, "audio/lamborghini5.ogg"},
    [80028] = {940, 970, 1100, 840, 700, 2.0, 0, 0.97, "audio/mercedes1.ogg"},
    [80029] = {945, 970, 1100, 840, 700, 0.5, 0, 0.97, "audio/charger2.ogg"},
    [80030] = {930, 970, 1100, 840, 700, 1.0, 0, 0.97, "audio/challenger2.ogg"},

    [80032] = {930, 970, 1100, 840, 700, 2.0, 0, 0.97, "audio/wraith.ogg"},
    [80034] = {915, 970, 1100, 840, 700, 1.7, 0, 0.97, "audio/wraith.ogg"},

    [80035] = {945, 970, 1100, 880, 780, 1.6, 0, 0.97, "audio/bmwm3gtr.ogg"},
    [80036] = {935, 970, 1100, 880, 780, 0.75, 0, 0.97, "audio/gti.ogg"},

    [80038] = {930, 970, 1100, 840, 700, 2.3, 0, 0.97, "audio/wraith.ogg"},
}

--[[ Warning | Aviso
    EN: It is recommended that: for vehicles that reach more than (124 mph | 200 kmh) have 'USE_MAXSP_LIMIT' enabled in their handling, this
    will make the gear ratios have the ideal spacing to flow without too much revs.
    PT: e recomendado que: para os veículos que alcançem mais de 200 kmh tenham 'USE_MAXSP_LIMIT' ativado em sua handling, isso vai fazer com que a
    relação das marchas tenham o espaçamento ideal para fluirem sem cortar giro em excesso.

    EN: vehicles with less than 5 gears will rev more than expected, change the power in 'info' to compensate.
    PT: veículos com menos de 5 marchas vão cortar giro em excesso, altere sua força em 'info' para compensar o rpm.
]]