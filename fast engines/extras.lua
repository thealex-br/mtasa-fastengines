eData = {
    ['turbo'] = nil,
    ['rpm'] = 0,
    ['gear'] = 0,
    ['blow'] = false,
}

local function smoothRPM(vehicle, rpm)
    local currentRPM = eData[vehicle].rpm or minimal
    local nRPM = currentRPM + (currentRPM < rpm and 0.08 or -0.2)
    currentRPM = currentRPM < rpm and math.min(nRPM, rpm) or math.max(nRPM, rpm)
    eData[vehicle].rpm = clamp(currentRPM, minimal, 1)
    return eData[vehicle].rpm
end

function doExtras(vehicle, driver, rpm, accel, brake)
    local data = getElementData(vehicle, tunningKey)
    if not data then
        return
    end
    eData[vehicle] = eData[vehicle] or {}
    local eData = eData[vehicle]

    local gear = getVehicleCurrentGear(vehicle)

    if data.turbo then
        if not isElement(eData.turbo) then
            eData.turbo = playAttachedSound3D("audio/extras/turbo.wav", vehicle, true, turboVolume, 0.01, turboDistance/15, turboDistance)
            eData.rpm = 0
        else
            eData.rpm = smoothRPM(vehicle, (rpm > minTurboRPM and accel > brake) and (eData.rpm + 0.1) or (eData.rpm - 0.7) )
            setSoundSpeed(eData.turbo, eData.rpm)
        end
    elseif isElement(eData.turbo) then
        destroyElement(eData.turbo)
        eData.turbo = nil
    end

    if data.turbo and data.blowoff then
        if rpm > minBlowoffRPM and accel > brake then
            eData.blow = true
        elseif accel <= brake and eData.rpm > 0.95 * minBlowoffRPM and eData.blow then
            eData.blow = false
            playAttachedSound3D("audio/extras/turbo_shift1.wav", vehicle, false, blowoffVolume, 1, blowoffDistance/15, blowoffDistance)

            eData.rpm = 0.3 * minBlowoffRPM

            if isTimer(eData.timer) then
                killTimer(eData.timer)
            end
            eData.timer = setTimer(fxAddBackfire, 20, 4, vehicle)
        end
    end

    eData.gear = eData.gear or gear

    if rpm > minAlsRPM and eData.gear ~= gear then
        eData.gear = gear
        if data.turbo then
            eData.rpm = 0.5*minAlsRPM
        end

        if data.als then
            if isTimer(eData.timer) then
                killTimer(eData.timer)
            end
            eData.timer = setTimer(fxAddBackfire, 30, 3, vehicle)
            playAttachedSound3D("audio/extras/als"..math.random(13)..".wav", vehicle, false, alsVolume, 1, alsDistance/15, alsDistance)
        end

    end
end