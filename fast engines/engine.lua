vehicles = {}

local function smoothRPM(vehicle, rpm, maxrpm, smoother)
    local currentRPM = getData(vehicle, "enginerpm") or 0
    local nRPM = currentRPM + (currentRPM < rpm and (smoother and smoother[1] or config.engine.smoother[1]) or (smoother and smoother[2] or config.engine.smoother[2]))
    currentRPM = currentRPM < rpm and math.min(nRPM, rpm) or math.max(nRPM, rpm)
    local final = math.clamp(currentRPM, 0, maxrpm)
    setData(vehicle, "enginerpm", final)
    return final
end

local exception = { [17] = true, [19] = true, [6] = true, [5] = true }
addEventHandler("onClientWorldSound", root, function(group)
    if getData(source, "elegible") and not exception[group] then
        cancelEvent()
    end
end)

function extraSmoother(vehicle, engine, rpm, info)
    rpm = smooth(rpm, 0.35, vehicle)

    local clamped = math.scale(rpm, info.min, info.max)
    setElementData(vehicle, config.rpmKey, clamped, false)

    setSoundSpeed(engine, rpm)

    local volume = info.vol - math.clamp( (config.engine.volumeDown * info.vol) * rpm, info.min, config.engine.volumeMin * info.vol)
    setSoundVolume(engine, volume )
end

function doEngineSound()
    while true do
        for _, vehicle in ipairs(vehicles) do
            local driver = getVehicleController(vehicle)
            local info = info[getCustomID(vehicle)]
            if driver and info then
                local state = getVehicleEngineState(vehicle)
                local engine = getData(vehicle, "engine")
                if not engine then
                    setData(vehicle, "engine", playAttachedSound3D(info.audio, vehicle, true, 0, 0, config.engine.distance/6, config.engine.distance) )
                    if not hasElementData(vehicle, config.tunningKey) then
                        setElementData(vehicle, config.tunningKey, {als=info.als, turbo=info.turbo, blowoff=info.blowoff}, false)
                    end
                else
                    local accelInput = getPedAnalogControlState(driver, "accelerate", false)
                    local brakeInput = getPedAnalogControlState(driver, "brake_reverse", false)
                    local hbrakeInput = getPedAnalogControlState(driver, "handbrake", false)

                    local hnd = getData(vehicle, "handling")
                    local hndspeed = hnd.topSpeed
                    local hndgears = hnd.maxGears
                    local hnddrive = hnd.traction

                    local x, y, z = getElementVelocity(vehicle)
                    local speed = (x*x + y*y) ^ info.ratio or 0.5
                    local realSpeed = (x*x + y*y) ^ 0.5 * 180

                    local hill = math.clamp(z, -0.09, 0.09)
                    local gear = getVehicleCurrentGear(vehicle)
                    gear = gear > 0 and gear or config.engine.ratio[0]
                    local gearMult = (info.gearRatio and info.gearRatio[gear]) or (config.engine.ratio and config.engine.ratio[gear]) or 1

                    if state then
                        if isOnGround(vehicle, hnddrive) then
                            local isDrifting = isTractionState(vehicle, hnddrive, 1, 1)
                            if isDrifting and realSpeed < 0.1*hndspeed and gear == 1 then
                                speed = info.accel * math.max(speed + hill, 0.7)
                            else
                                if accelInput > brakeInput then
                                    local drift = isDrifting and info.slide * getDrift(vehicle, x, y) or 0
                                    speed = info.accel * gearMult * speed + hill + drift
                                else
                                    speed = info.decel * gearMult * speed + hill
                                end
                            end
                            if realSpeed < 8 and (isDrifting or hbrakeInput == 1 and accelInput > 0.5) then
                                speed = info.accel
                            end
                        else
                            speed = info.air * gearMult * speed
                        end
                    end
                    speed = (gear + speed / gear) / hndspeed
                    speed = math.max(speed, state and info.min or 0)

                    local rpm = smoothRPM(vehicle, speed, info.max, info.smoother)
                    local vol = info.vol - math.clamp( (config.engine.volumeDown * info.vol) * rpm, info.min, config.engine.volumeMin * info.vol)

                    doExtras(vehicle, rpm, accelInput, brakeInput)
                    setSoundSpeed(engine, rpm)

                    if not config.smoother.enable or (config.smoother.simple and driver ~= localPlayer) then
                        setElementData(vehicle, config.rpmKey, math.scale(rpm, info.min, info.max), false)
                        setSoundVolume(engine, config.engine.volume * vol)
                    else
                        setData(vehicle, "cached", {max=info.max, min=info.min, vol=info.vol})
                    end
                end
            end
        end
        coroutine.yield()
    end
end

local doEngineSoundCO = coroutine.create(doEngineSound)
setTimer(function()
    coroutine.resume(doEngineSoundCO)
end, config.wait, 0)

addEventHandler("onClientRender", root, function()
    local simple = config.smoother.simple
    if config.smoother.enable then
        for _, vehicle in pairs(vehicles) do
            local driver = getVehicleController(vehicle)

            if simple and driver ~= localPlayer then
                break
            end

            local engine = getData(vehicle, "engine")
            local rpm = getData(vehicle, "enginerpm")
            local info = getData(vehicle, "cached")
            if engine and rpm and info then
                extraSmoother(vehicle, engine, rpm, info)
            end
        end
    end
end)
