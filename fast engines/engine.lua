handling = {
    ['maxSpeed'] = 0,
    ['maxGears'] = 0,
}

data = {
    ['engine'] = nil,
    ['rpm'] = 0,
}

vehicles = {}

local function smoothRPM(vehicle, rpm, maxrpm, smoother)
    local currentRPM = data[vehicle].rpm or minimal
    local nRPM = currentRPM + (currentRPM < rpm and (smoother and smoother[1] or engineRPMUp) or (smoother and smoother[2] or engineRPMDown))
    currentRPM = currentRPM < rpm and math.min(nRPM, rpm) or math.max(nRPM, rpm)
    data[vehicle].rpm = clamp(currentRPM, minimal, maxrpm)
    return data[vehicle].rpm
end

local exception = { [17] = true, [19] = true }
addEventHandler("onClientWorldSound", root, function(group)
    if isElegible(source) then
        local id = getCustomID(source)
        if (data[source] or info[id]) and not exception[group] then
            cancelEvent()
        end
    end
end)

function doEngineSound()
    if (not vehicles or #vehicles == 0) then return end

    for i = 1, #vehicles do local veh = vehicles[i]
        local driver, state = getVehicleController(veh), getVehicleEngineState(veh)
        local id = getCustomID(veh)
        local info = info[id]
        if driver and info then
            data[veh] = data[veh] or {}
            local vol = info[6]

            local engine = data[veh].engine
            if not isElement(engine) then
                data[veh].engine = playAttachedSound3D(info[9], veh, true, vol, minimal, engineDistance/15, engineDistance)
                if not hasElementData(veh, tunningKey) then
                    setElementData(veh, tunningKey, {als=info.als, turbo=info.turbo, blowoff=info.blowoff}, false)
                end
            else
                local accel = getPedAnalogControlState(driver, "accelerate", false)
                accel = accel >= 0.8 and accel or 0

                local brake = getPedAnalogControlState(driver, "brake_reverse", false)
                local handbrake = getPedAnalogControlState(driver, "handbrake", false)

                local hndspeed = handling[veh].maxSpeed
                local hndgears = handling[veh].maxGears

                local x, y, z = getElementVelocity(veh)
                local speed = (x*x + y*y + z*z) ^ (info.ratio or 0.5)
                local realSpeed = speed * 180

                local hill = clamp(z, -0.09, 0.09)
                local gear = getVehicleCurrentGear(veh)
                gear = gear > 0 and gear or gearReverse
                local gearMult = (info.gearRatio and info.gearRatio[gear]) or (gearRatio and gearRatio[gear]) or 1

                if isOnGround(veh) then
                    if isDrifting(veh) and accel > brake then
                        if realSpeed <= 0.1 * hndspeed and gear == 1 then
                            speed = info[2] * math.max(speed + hill, 0.7)
                        else
                            local drift = getDrift(veh, x, y)
                            if drift > 0.1 or realSpeed <= 0.1 * hndspeed then
                                speed = info[2] * math.max((speed + hill) ^ 1.0005 + drift, 0.65)
                            else
                                speed = info[1] * gearMult * speed + hill
                            end
                        end
                    else
                        if accel > brake then
                            speed = info[1] * gearMult * speed + hill
                        else
                            speed = info[4] * speed + hill
                        end
                    end
                else
                    speed = info[5] * speed
                end
                if realSpeed < 6 and ((accel > 0.5 and brake > 0.5 and handbrake == 0) or (accel > 0.5 and brake == 0 and handbrake == 1)) then
                    speed = info[3] * math.max(speed, 0.4)
                end

                local ratio = gear + hndgears - gear
                local audio = gear + ratio * speed / gear
                audio = audio / ratio / hndspeed

                local result = smoothRPM(veh, state and audio or minimal, info[8], info.smoother)
                result = math.max(result, state and info[7] or 0)
                setElementData(veh, rpmKey, result, false)

                local volume = vol - clamp( (engineVolumeDownMult * vol) * result, info[7], engineVolumeMinMult * vol)

                doExtras(veh, driver, result, accel, brake)
                setSoundSpeed(engine, result )
                setSoundVolume(engine, engineVolume*volume)
            end
        end
    end
end

addEventHandler("onClientPreRender", root, function(delta)
    local tickTime = tickMult * 1000 / delta
    if waitTick(tickTime, "engine") then
        doEngineSound()
    end
end)