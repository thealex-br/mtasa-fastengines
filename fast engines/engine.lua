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
    rpm = math.max(rpm, info.min)
    rpm = smooth(rpm, 0.35, vehicle)

    local clamped = toScale(rpm, info.min, info.max)
    setElementData(vehicle, config.rpmKey, clamped, false)

    setSoundSpeed(engine, rpm)

    local volume = info.vol - math.clamp( (config.engine.volumeDown * info.vol) * rpm, info.min, config.engine.volumeMin * info.vol)
    setSoundVolume(engine, volume )
end

function doEngineSound()
    if not vehicles or #vehicles == 0 then
        return
    end

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

                    local hndspeed = getData(vehicle, "topSpeed")
                    local hndgears = getData(vehicle, "maxGears")

                    local x, y, z = getElementVelocity(vehicle)
                    local speed = math.pow(x*x + y*y, info.ratio or 0.5)
                    local realSpeed = math.pow(x*x + y*y, 0.5) * 180

                    local hill = math.clamp(z, -0.09, 0.09)
                    local gear = getVehicleCurrentGear(vehicle)
                    gear = gear > 0 and gear or config.engine.ratio[0]
                    local gearMult = (info.gearRatio and info.gearRatio[gear]) or (config.engine.ratio and config.engine.ratio[gear]) or 1

                    if not state then
                        speed = 0
                    else
                        if not isOnGround(vehicle) then
                            speed = info.air * speed
                        else
                            local isDrifting = isTractionState(vehicle, 1)
                            if isDrifting and accelInput > brakeInput then
                                if realSpeed < 0.1 * hndspeed and gear == 1 then
                                    speed = info.accel * math.max(speed + hill, 0.7)
                                else
                                    local drift = getDrift(vehicle, x, y)
                                    speed = info.accel * gearMult * speed + hill + (drift > 0.1 and info.slide*drift or 0)
                                end
                            else
                                if accelInput > brakeInput then
                                    speed = info.accel * gearMult * speed + hill
                                else
                                    speed = info.decel * speed + hill
                                end
                            end
                            if realSpeed < 8 and (isDrifting or hbrakeInput == 1 and accelInput > 0.5) then
                                speed = info.accel
                            end
                        end
                    end

                    local audio = (gear + speed / gear) / hndspeed
                    audio = math.max(audio, state and info.min or 0)

                    local rpm = smoothRPM(vehicle, audio, info.max, info.smoother)

                    local volume = info.vol - math.clamp( (config.engine.volumeDown * info.vol) * rpm, info.min, config.engine.volumeMin * info.vol)

                    doExtras(vehicle, rpm, accelInput, brakeInput)
                    setSoundSpeed(engine, rpm)

                    if not config.smoother.enable or (config.smoother.simple and driver ~= localPlayer) then
                        setElementData(vehicle, config.rpmKey, toScale(rpm, info.min, info.max), false)
                        setSoundVolume(engine, config.engine.volume*volume)
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
