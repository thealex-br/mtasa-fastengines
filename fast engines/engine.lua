handling = {
    ['maxSpeed'] = 0,
    ['maxGears'] = 0,
}

data = {
    ['engine'] = nil,
    ['rpm'] = 0,
}

vehicles = {}

local max = math.min
local min = math.max
local sqrt = math.sqrt
local abs = math.abs
local minimal = 0.00001

function stopEngine(vehicle)
    local data = data[vehicle]
    if data then
        handling[vehicle] = nil
        if isElement( data.engine ) then
            destroyElement(data.engine)
        end
        data.engine = nil
        data.rpm = 0
    end
    setElementData(vehicle, "engineRPM", false, false)
    table.removeValue(vehicles, vehicle)
end

local function smoothRPM(vehicle, rpm)
    local currentRPM = data[vehicle].rpm or minimal
    local nRPM = currentRPM + (currentRPM < rpm and 0.055 or -0.047)
    currentRPM = currentRPM < rpm and max(nRPM, rpm) or min(nRPM, rpm)
    data[vehicle].rpm = max(currentRPM, 1)
    return data[vehicle].rpm
end

local exception = { [17] = true, [19] = true }
addEventHandler("onClientWorldSound", root, function(group)
    if isElegible(source) then
        local id = getElementData(source, "vehicleID") or getElementModel(source)
        if (data[source] or info[id]) and not exception[group] then
            cancelEvent()
        end
    end
end)

function doEngineSound()
    if not vehicles then
        return
    end
    if #vehicles == 0 then
        return
    end

    for i = 1, #vehicles do
        local veh = vehicles[i]
        local driver, state = getVehicleController(veh), getVehicleEngineState(veh)
        local id = getElementData(veh, elementDataIDs) or getElementModel(veh)
        local info = info[id]
        if driver and info and getDistanceBetweenElements(veh, localPlayer) <= audioDistance then
            if not state then
                stopEngine(veh)
                break
            end

            data[veh] = data[veh] or {}
            local vol = info[6]

            if not isElement(data[veh].engine) then
                data[veh].engine = playAttachedSound3D(info[9], veh)
                setSoundVolume(data[veh].engine, vol)
                setSoundSpeed(data[veh].engine, minimal)
                setSoundMaxDistance(data[veh].engine, audioDistance)
                setSoundMinDistance(data[veh].engine, audioDistance/15)
            else
                local accel = getPedAnalogControlState(driver, "accelerate", true)
                local brake = getPedAnalogControlState(driver, "brake_reverse", true)
                local handbrake = getPedAnalogControlState(driver, "handbrake", true)

                local hndspeed = handling[veh].maxSpeed
                local hndgears = handling[veh].maxGears
        
                local x, y, z = getElementVelocity(veh)
                local speed = sqrt(x*x + y*y + z*z)
                local realSpeed = speed * 180

                local hill = max( min(z, -0.09), 0.09)
                local gear = getVehicleCurrentGear(veh)
                gear = (gear == 0 and reverseGearPower) or gear
                local gearMult = gearMultiplier[gear] or 1

                if isOnGround(veh) then
                    if isDrifting(veh) and accel > brake then
                        if realSpeed <= 0.1 * hndspeed and gear == 1 then
                            speed = info[2] * min(speed + hill, 0.7)
                        else
                            local drift = getDrift(veh, x, y)
                            if drift > 0.1 or realSpeed <= 0.1 * hndspeed then
                                speed = info[2] * min((speed + hill) ^ 1.0005 + drift, 0.65)
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
                    speed = info[3] * min(speed, 0.4)
                end
                    
                local ratio = gear + (hndgears - gear)
                local audio = (ratio * speed / gear) + gear
                audio = audio / ratio / hndspeed

                local result = smoothRPM(veh, audio)
                result = min(max(result, info[8]), info[7]) or minimal
                setElementData(veh, elementDataName, result, false)

                local engine = data[veh].engine

                setSoundSpeed(engine, max(result, 1) )
                setSoundVolume(engine, vol - max((0.3 * vol) * min(result, info[7]), 0.55*vol) )
            end
        end
    end
end

local function waitTick(tick)
    local lastTick = lastTicked or 0
    local nowTick = getTickCount()
    if lastTick + (tick or 2) > nowTick then
        return false
    end
    lastTicked = nowTick
    return true
end

addEventHandler("onClientPreRender", root, function(delta)
    local tickTime = 0.35 * ( 1000 * 1 / delta )
    if waitTick(tickTime) then
        doEngineSound()
    end
end)