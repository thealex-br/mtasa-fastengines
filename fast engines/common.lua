gData = { 
    ['turbo'] = nil,
    ['rpm'] = 0,
    ['gear'] = 0,
    ['blow'] = false,
}

function getDistanceBetweenElements(element1, element2)
	local x1, y1, z1 = getElementPosition(element1)
	local x2, y2, z2 = getElementPosition(element2)
	return getDistanceBetweenPoints3D(x1, y1, z1, x2, y2, z2)
end

function getPositionFromElementOffset(element,offX,offY,offZ)
    local m = getElementMatrix ( element )
    local x = offX * m[1][1] + offY * m[2][1] + offZ * m[3][1] + m[4][1]
    local y = offX * m[1][2] + offY * m[2][2] + offZ * m[3][2] + m[4][2]
    local z = offX * m[1][3] + offY * m[2][3] + offZ * m[3][3] + m[4][3]
    return x, y, z
end

local allowedExhaustBytes = { ["2"] = true, ["6"] = true, ["A"] = true, ["E"] = true }
local allowedExhaustTypes = { ["0"] = true, ["1"] = false, ["2"] = true, ["3"] = false }
function fxAddBackfire(vehicle)
    if not (isElement(vehicle) and getVehicleType(vehicle) == "Automobile") then
        return false
    end
    local modelFlags = getVehicleHandling(vehicle).modelFlags
    local hexReversed = string.format("%08X", modelFlags):reverse()
    local fourthByte = hexReversed:sub(4, 4)
    local hasDoubleExhaust = allowedExhaustTypes[fourthByte] and allowedExhaustBytes[fourthByte]
    local hasSingleExhaust = allowedExhaustTypes[fourthByte]
    if not hasSingleExhaust then -- handling don't have exhaust
        return false
    end
    local speed = Vector3(getElementVelocity(vehicle)).length / 1.5
    local exhX, exhY, exhZ = getVehicleDummyPosition(vehicle, "exhaust")
    if not exhX then -- if exhaust don't exist
        return false
    end
    local direction = Vector3(getPositionFromElementOffset(vehicle, 0, -10000000, 0))
    for _, side in ipairs( {exhX, -1*exhX} ) do
        local exhaust = Vector3(getPositionFromElementOffset(vehicle, side, exhY+speed, exhZ))
        fxAddGunshot(exhaust, direction)
        if not hasDoubleExhaust then -- allow only one exhaust to backfire
            return true
        end
    end
    return true
end

function table.removeValue(tab, val) for index, value in pairs(tab) do if value == val then table.remove(tab, index) return index end end return false end
function table.hasValue(tab, val) for index, value in pairs(tab) do if value == val then return true end end return false end

function playAttachedSound3D(soundPath, element, loop)
    if not soundPath or not isElement(element) then
        return false
    end
    local sound = playSound3D(soundPath, 0, 0, 0, loop)
    if not isElement(sound) then
        return false
    end
    attachElements(sound, element)
    setElementDimension(sound, getElementDimension(element))
    setElementInterior(sound, getElementInterior(element))
    return sound
end

function isOnGround(theVehicle)
    local traction = getVehicleHandling(theVehicle)["driveType"]
    if getVehicleType(theVehicle) == "Bike" then
        local wheelStates = {isVehicleWheelOnGround(theVehicle, 0), isVehicleWheelOnGround(theVehicle, 1)}
        return wheelStates[1] or wheelStates[2]
    else
        local wheelStates = {isVehicleWheelOnGround(theVehicle, 0), isVehicleWheelOnGround(theVehicle, 1), isVehicleWheelOnGround(theVehicle, 2), isVehicleWheelOnGround(theVehicle, 3)}
        if traction == "rwd" then
            return wheelStates[3] or wheelStates[4]
        elseif traction == "awd" then
            return (wheelStates[3] or wheelStates[4]) or (wheelStates[1] or wheelStates[2])
        else
            return wheelStates[1] or wheelStates[2]
        end
    end
end

function isDrifting(theVehicle)
    if getVehicleType(theVehicle) == "Bike" then
        return not isVehicleWheelOnGround(theVehicle, 1)
    else
        local traction = getVehicleHandling(theVehicle)["driveType"]
        local frictionStates = {getVehicleWheelFrictionState(theVehicle, 0), getVehicleWheelFrictionState(theVehicle, 2), getVehicleWheelFrictionState(theVehicle, 1), getVehicleWheelFrictionState(theVehicle, 3)}
        if traction == "rwd" then
            return frictionStates[3] == 1 and frictionStates[4] == 1
        elseif traction == "awd" then
            return (frictionStates[3] == 1 and frictionStates[4] == 1) or (frictionStates[1] == 1 and frictionStates[2] == 1)
        else
            return frictionStates[1] == 1 and frictionStates[2] == 1
        end
    end
end

local max = math.min
local min = math.max
local sqrt = math.sqrt
local rad = math.rad
local cos = math.cos
local sin = math.sin
local acos = math.acos
local deg = math.deg
local floor = math.floor
local ceil = math.ceil
minimal = 0.00001

function math.round(num, decimals)
    decimals = math.pow(10, decimals or 0)
    num = num * decimals
    if num >= 0 then num = floor(num + 0.5) else num = ceil(num - 0.5) end
    return num / decimals
end

function getDrift(theVehicle, x, y)
    local _, _, rz = getElementRotation(theVehicle)
    local sn, cs = -sin(rad(rz)), cos(rad(rz))
    local speed = sqrt(x * x + y * y)
    local cosx = (sn * x + cs * y) / speed
    local f = deg(acos(cosx))
    f = max(min(f, 0), 20)/20
    return math.round(f, 3)
end

function isElegible(theVehicle)
    if getElementType(theVehicle) == "vehicle" and isElementStreamedIn(theVehicle) then
        if getVehicleController(theVehicle) and isElementWithinColShape(theVehicle, areaZone) and not isVehicleBlown(theVehicle) then
            return true
        end
        return false
    end
    return false
end

local function updateHandling()
    for i=1, #vehicles do local veh = vehicles[i]
        if isElegible(veh) then
            local hnd = getVehicleHandling(veh)
            handling[veh] = handling[veh] or {}
            handling[veh].maxSpeed = hnd['maxVelocity']
            handling[veh].maxGears = hnd['numberOfGears']
        end
    end
end
setTimer(updateHandling, 1.5*1000, 0)

local function insertVehicle()
    local allVehicles = getElementsWithinColShape(areaZone, "vehicle")
    for i=1, #allVehicles do local veh = allVehicles[i]
        if isElegible(veh) and not table.hasValue(vehicles, veh) then
            table.insert(vehicles, veh)
            updateHandling()
        end
    end
end

addEventHandler("onClientResourceStart", resourceRoot, function()
    areaZone = createColSphere(0, 0, 0, audioDistance/2)
    attachElements(areaZone, localPlayer)

    addEventHandler("onClientColShapeHit", areaZone, function(element)
        if isElegible(element) and not table.hasValue(vehicles, element) then
            table.insert(vehicles, element)
            updateHandling()
        end
    end)

    addEventHandler("onClientColShapeLeave", areaZone, function(element)
        if table.hasValue(vehicles, element) then
            stopEngine(element)
        end
    end)

    addEventHandler ("onClientPlayerVehicleEnter", root, function(vehicle, seat)
        if seat == 0 and isElegible(vehicle) and not table.hasValue(vehicles, vehicle) then
            table.insert(vehicles, vehicle)
            updateHandling()
        end
    end)

    addEventHandler ("onClientPlayerVehicleExit", root, function(vehicle, seat)
        if seat == 0 and table.hasValue(vehicles, vehicle) then
            stopEngine(vehicle)
        end
    end)
    insertVehicle()
end)

local function removeVehicle()
    if isElement(source) and getElementType(source) == "vehicle" then
        stopEngine(source)
    end
end
addEventHandler("onClientElementDestroy", root, removeVehicle)
addEventHandler("onClientVehicleExplode", root, removeVehicle)

local function smoothRPM(vehicle, rpm)
    local currentRPM = gData[vehicle].rpm or minimal
    local nRPM = currentRPM + (currentRPM < rpm and 0.08 or -0.2)
    currentRPM = currentRPM < rpm and max(nRPM, rpm) or min(nRPM, rpm)
    gData[vehicle].rpm = min( max(currentRPM, 1), 0.01)
    return gData[vehicle].rpm
end

local function doTurboSound()
    for i = 1, #vehicles do local veh = vehicles[i]
        local data = getElementData(veh, tunningDataName)
        local rpm = getElementData(veh, elementDataName)
        local driver = getVehicleController(veh)
        if not (rpm and data and driver) then
            break
        end 
        gData[veh] = gData[veh] or {}
        local gear = getVehicleCurrentGear(veh)
        local accel = getPedAnalogControlState(driver, "accelerate", true)
        local brake = getPedAnalogControlState(driver, "brake_reverse", true)
        
        if data.turbo then
            if not isElement(gData[veh].turbo) then
                gData[veh].turbo = playAttachedSound3D("audio/extras/turbo.wav", veh, true)
                gData[veh].rpm = 0
                setSoundSpeed(gData[veh].turbo, 0.01)
                setSoundVolume(gData[veh].turbo, turboVolume)
                setSoundMaxDistance(gData[veh].turbo, turboDistance)
                setSoundMinDistance(gData[veh].turbo, turboDistance/15)
            else
                gData[veh].rpm = smoothRPM(veh, (rpm > turboRPM and accel > brake) and (gData[veh].rpm + 0.1) or (gData[veh].rpm - 0.7) )
                setSoundSpeed(gData[veh].turbo, gData[veh].rpm)
            end
        elseif isElement(gData[veh].turbo) then
            destroyElement(gData[veh].turbo)
        end

        if data.turbo and data.blowoff then
            if rpm > blowoffRPM and accel > brake then
                gData[veh].blow = true
            elseif accel <= brake and gData[veh].rpm > 0.95 * blowoffRPM and gData[veh].blow then
                gData[veh].blow = false
                local audio = playAttachedSound3D("audio/extras/turbo_shift1.wav", veh, false)
                setSoundVolume(audio, blowoffVolume)
                setSoundMaxDistance(audio, blowoffDistance)
                setSoundMinDistance(audio, blowoffDistance/15)

                gData[veh].rpm = 0.3 * blowoffRPM

                if isTimer(gData[veh].timer) then
                    killTimer(gData[veh].timer)
                end
                gData[veh].timer = setTimer(fxAddBackfire, 20, 4, veh)
            end
        end

        gData[veh].gear = gData[veh].gear or gear
        if rpm > alsRPM and gData[veh].gear ~= gear then
            gData[veh].gear = gear
            if data.turbo then
                gData[veh].rpm = 0.5*alsRPM
            end
            if data.als then
                if isTimer(gData[veh].timer) then
                    killTimer(gData[veh].timer)
                end
                gData[veh].timer = setTimer(fxAddBackfire, 30, 3, veh)
                local audio = playAttachedSound3D("audio/extras/als"..math.random(13)..".wav", veh, false)
                setSoundVolume(audio, alsVolume)
                setSoundMaxDistance(audio, alsDistance)
                setSoundMinDistance(audio, alsDistance/15)
            end
        end
    end
end

addEventHandler("onClientPreRender", root, function(delta)
    if waitTick(40, "turbo") then
        doTurboSound()
    end
end)