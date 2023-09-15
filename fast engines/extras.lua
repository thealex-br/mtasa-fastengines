gData = { 
    ['turbo'] = nil,
    ['rpm'] = 0,
    ['gear'] = 0,
    ['blow'] = false,
}

local function smoothRPM(vehicle, rpm)
    local currentRPM = gData[vehicle].rpm or minimal
    local nRPM = currentRPM + (currentRPM < rpm and 0.08 or -0.2)
    currentRPM = currentRPM < rpm and max(nRPM, rpm) or min(nRPM, rpm)
    gData[vehicle].rpm = clamp(currentRPM, 0.01, 1)
    return gData[vehicle].rpm
end

function doTurboSound(vehicle, driver, rpm, accel, brake)
    local data = hasElementData(vehicle, tunningDataName)
    if not data then
        return
    end 
    local data = getElementData(vehicle, tunningDataName)
    if not data then
        return
    end 
    gData[vehicle] = gData[vehicle] or {}
    local gData = gData[vehicle] 

    local gear = getVehicleCurrentGear(vehicle)
        
    if data.turbo then
        if not isElement(gData.turbo) then
            gData.turbo = playAttachedSound3D("audio/extras/turbo.wav", vehicle, true)
            gData.rpm = 0
            setSoundSpeed(gData.turbo, 0.01)
            setSoundVolume(gData.turbo, turboVolume)
            setSoundMaxDistance(gData.turbo, turboDistance)
            setSoundMinDistance(gData.turbo, turboDistance/15)
        else
            gData.rpm = smoothRPM(vehicle, (rpm > turboRPM and accel > brake) and (gData.rpm + 0.1) or (gData.rpm - 0.7) )
            setSoundSpeed(gData.turbo, gData.rpm)
        end
    elseif isElement(gData.turbo) then
        destroyElement(gData.turbo)
        gData.turbo = nil
    end

    if data.turbo and data.blowoff then
        if rpm > blowoffRPM and accel > brake then
            gData.blow = true
        elseif accel <= brake and gData.rpm > 0.95 * blowoffRPM and gData.blow then
            gData.blow = false
            local audio = playAttachedSound3D("audio/extras/turbo_shift1.wav", vehicle, false)
            setSoundVolume(audio, blowoffVolume)
            setSoundMaxDistance(audio, blowoffDistance)
            setSoundMinDistance(audio, blowoffDistance/15)

            gData.rpm = 0.3 * blowoffRPM

            if isTimer(gData.timer) then
                killTimer(gData.timer)
            end
            gData.timer = setTimer(fxAddBackfire, 20, 4, vehicle)
        end
    end

    gData.gear = gData.gear or gear

    if rpm > alsRPM and gData.gear ~= gear then
        gData.gear = gear
        if data.turbo then
            gData.rpm = 0.5*alsRPM
        end

        if data.als then
            if isTimer(gData.timer) then
                killTimer(gData.timer)
            end
            gData.timer = setTimer(fxAddBackfire, 30, 3, vehicle)
            local audio = playAttachedSound3D("audio/extras/als"..math.random(13)..".wav", vehicle, false)
            setSoundVolume(audio, alsVolume)
            setSoundMaxDistance(audio, alsDistance)
            setSoundMinDistance(audio, alsDistance/15)
        end

    end
end