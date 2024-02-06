vehicles = {}

local function smoothRPM(vehicle, rpm, maxrpm, smoother)
    local currentRPM = getData(vehicle, "enginerpm") or minimal
    local nRPM = currentRPM + (currentRPM < rpm and (smoother and smoother[1] or config.engine.smoother[1]) or (smoother and smoother[2] or config.engine.smoother[2]))
    currentRPM = currentRPM < rpm and math.min(nRPM, rpm) or math.max(nRPM, rpm)
    local final = clamp(currentRPM, minimal, maxrpm)
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

    local volume = info.vol - clamp( (config.engine.volumeDown * info.vol) * rpm, info.min, config.engine.volumeMin * info.vol)
    setSoundVolume(engine, volume )
end

function doEngineSound()
    if not vehicles or #vehicles == 0 then
        return
    end

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
                local accel = getPedAnalogControlState(driver, "accelerate", false)
                local brake = getPedAnalogControlState(driver, "brake_reverse", false)
                local handbrake = getPedAnalogControlState(driver, "handbrake", false)

                local hndspeed = getData(vehicle, "topSpeed")
                local hndgears = getData(vehicle, "maxGears")

                local x, y, z = getElementVelocity(vehicle)
                local speed = (x*x + y*y) ^ (info.ratio or 0.5)
                local realSpeed = (x*x + y*y) ^ 0.5 * 180

                local hill = clamp(z, -0.09, 0.09)
                local gear = getVehicleCurrentGear(vehicle)
                gear = gear > 0 and gear or config.engine.ratio[0]
                local gearMult = (info.gearRatio and info.gearRatio[gear]) or (config.engine.ratio and config.engine.ratio[gear]) or 1

                if not state then
                    speed = 0
                else
                    if not isOnGround(vehicle) then
                        speed = info.air * speed
                    else
                        if isTractionState(vehicle, 1) and accel > brake then
                            if realSpeed < 0.1 * hndspeed and gear == 1 then
                                speed = info.accel * math.max(speed + hill, 0.7)
                            else
                                local drift = getDrift(vehicle, x, y)
                                speed = info.accel * gearMult * speed + hill + (drift > 0.1 and info.slide*drift or 0)
                            end
                        else
                            if accel > brake then
                                speed = info.accel * gearMult * speed + hill
                            else
                                speed = info.decel * speed + hill
                            end
                        end
                        if realSpeed < 8 and (isTractionState(vehicle, 1) or handbrake==1 and accel > 0.5) then
                            speed = info.accel
                        end
                    end
                end

                local ratio = gear + hndgears - gear
                local audio = gear + ratio * speed / gear
                audio = audio / ratio / hndspeed

                local rpm = smoothRPM(vehicle, audio, info.max, info.smoother)
                rpm = math.max(rpm, state and info.min or 0)

                local volume = info.vol - clamp( (config.engine.volumeDown * info.vol) * rpm, info.min, config.engine.volumeMin * info.vol)

                doExtras(vehicle, rpm, accel, brake)
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
end

addEventHandler("onClientRender", root, function()
    if waitTime(config.wait) then
        doEngineSound()
    end

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