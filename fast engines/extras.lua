local function smoothRPM(vehicle, rpm)
    local currentRPM = getData(vehicle, "turborpm") or 0
    local nRPM = currentRPM + (currentRPM < rpm and 0.08 or -0.2)
    currentRPM = currentRPM < rpm and math.min(nRPM, rpm) or math.max(nRPM, rpm)
    local final = math.clamp(currentRPM, 0, 1)
    setData(vehicle, "turborpm", final)
    return final
end

function doExtras(vehicle, finalRPM, accel, brake)
    local data = getElementData(vehicle, config.tunningKey)
    if not data then
        return
    end

    local gear = getVehicleCurrentGear(vehicle)

    local turbo = getData(vehicle, "turbo")

    if data.turbo then
        if not isElement(turbo) then
            setData(vehicle, "turbo", playAttachedSound3D("audio/extras/turbo.wav", vehicle, true, config.turbo.volume, 0, config.turbo.distance/6, config.turbo.distance))
            setData(vehicle, "turborpm", 0)
        else
            local rpm = getData(vehicle, "turborpm")
            rpm = smoothRPM(vehicle, (finalRPM >= config.turbo.enable and accel > brake and accel >= config.turbo.enable) and (rpm + accel*0.1) or (rpm - 0.7) )
            setData(vehicle, "turborpm", rpm)
            setSoundSpeed(turbo, rpm+0.001)
        end
    elseif isElement(turbo) then
        destroyElement(turbo)
        setData(vehicle, "turbo", nil)
    end

    if data.turbo and data.blowoff then
        if accel <= brake and getData(vehicle, "turborpm") > config.blowoff.enable then
            playAttachedSound3D("audio/extras/turbo_shift1.wav", vehicle, false, config.blowoff.volume, 1, config.blowoff.distance/6, config.blowoff.distance)

            setData(vehicle, "turborpm", 0)

            if isTimer(getData(vehicle, "timer")) then
                killTimer(getData(vehicle, "timer"))
            end
            setData(vehicle, "timer", setTimer(fxAddBackfire, 20, 3, vehicle))
        end
    end

    setData(vehicle, "gear", getData(vehicle, "gear") or gear )

    if finalRPM > config.als.enable and getData(vehicle, "gear") ~= gear then
        setData(vehicle, "gear", gear)
        if getData(vehicle, "turbo") then
            setData(vehicle, "turborpm", 0)
        end

        if data.als then
            if isTimer(getData(vehicle, "timer")) then
                killTimer(getData(vehicle, "timer"))
            end
            setData(vehicle, "timer", setTimer(fxAddBackfire, 30, 2, vehicle))
            playAttachedSound3D("audio/extras/als"..math.random(3)..".wav", vehicle, false, config.als.volume, 1, config.als.distance/6, config.als.distance)
        end

    end
end
