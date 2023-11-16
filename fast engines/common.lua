minimal = 0.00001

function clamp(value, minValue, maxValue)
    return math.max(math.min(value, maxValue), minValue)
end

function getPositionFromElementOffset(element,offX,offY,offZ)
    local m = getElementMatrix ( element )
    local x = offX * m[1][1] + offY * m[2][1] + offZ * m[3][1] + m[4][1]
    local y = offX * m[1][2] + offY * m[2][2] + offZ * m[3][2] + m[4][2]
    local z = offX * m[1][3] + offY * m[2][3] + offZ * m[3][3] + m[4][3]
    return x, y, z
end

function table.removeValue(tab, val)
    for index, value in pairs(tab) do
        if value == val then
            table.remove(tab, index)
            return index
        end
    end
    return false
end

function table.hasValue(tab, val)
    for index, value in pairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end

function getCustomID(vehicle)
    for _, key in pairs(elementDataIDs) do
        local id = getElementData(vehicle, key)
        if id then
            return id
        end
    end
    return getElementModel(vehicle)
end

local allowedExhaustBytes = { ["2"] = true, ["6"] = true, ["A"] = true, ["E"] = true }
local allowedExhaustTypes = { ["0"] = true, ["1"] = false, ["2"] = true, ["3"] = false }
function fxAddBackfire(vehicle)
    if not (isElement(vehicle) and getVehicleType(vehicle) == "Automobile") then
        return
    end
    local modelFlags = getVehicleHandling(vehicle).modelFlags
    local fourthByte = string.format("%08X", modelFlags):reverse():sub(4, 4)
    local twoExhaust = allowedExhaustTypes[fourthByte] and allowedExhaustBytes[fourthByte]
    local oneExhaust = allowedExhaustTypes[fourthByte]
    if not oneExhaust then -- handling don't have exhaust
        return
    end
    local speed = Vector3(getElementVelocity(vehicle)).length / 1.5
    local exhX, exhY, exhZ = getVehicleDummyPosition(vehicle, "exhaust")
    if not exhX then -- if exhaust don't exist
        return
    end
    local direction = Vector3(getPositionFromElementOffset(vehicle, 0, -10000000, 0))
    for _, side in ipairs({exhX, -1 * exhX}) do
        local exhaust = Vector3(getPositionFromElementOffset(vehicle, side, exhY + speed, exhZ))
        fxAddGunshot(exhaust, direction)
        if not twoExhaust then -- allow only one exhaust to backfire
            return
        end
    end
end

local last = 0
function waitTick(tick, limiter)
    local now = getTickCount()
    if last + (tick or 2) > now then
        return false
    end
    last = now
    return true
end

function stopEngine(vehicle)
    vehicle = source or vehicle
    if not (type(vehicle) == "userdata" and getElementType(vehicle) == "vehicle") then
        return false
    end

    local engineData = data[vehicle]
    local extrasData = eData[vehicle]
    if engineData then
        if isElement(engineData.engine) then destroyElement(engineData.engine) end
        engineData.engine = nil
        engineData.rpm = 0
    end
    if extrasData then
        if isElement(extrasData.turbo) then destroyElement(extrasData.turbo) end
        extrasData.engine = nil
        extrasData.rpm = 0
    end
    engineData = nil
    extrasData = nil
    handling[vehicle] = nil
    setElementData(vehicle, "engineRPM", nil)
    table.removeValue(vehicles, vehicle)
end

function playAttachedSound3D(soundPath, element, loop, volume, speed, minDistance, maxDistance)
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

    setSoundSpeed(sound, speed or 1)
    setSoundVolume(sound, volume or 1)
    setSoundMinDistance(sound, minDistance or 100/15)
    setSoundMaxDistance(sound, maxDistance or 100)
    return sound
end

function isOnGround(vehicle)
    local traction = getVehicleHandling(vehicle)["driveType"]
    if getVehicleType(vehicle) == "Bike" then
        local states = {isVehicleWheelOnGround(vehicle, 0), isVehicleWheelOnGround(vehicle, 1)}
        return states[1] or states[2]
    end
    local states = {isVehicleWheelOnGround(vehicle, 0), isVehicleWheelOnGround(vehicle, 1), isVehicleWheelOnGround(vehicle, 2), isVehicleWheelOnGround(vehicle, 3)}
    if traction == "rwd" then
        return states[3] or states[4]
    elseif traction == "awd" then
        return (states[3] or states[4]) or (states[1] or states[2])
    else
        return states[1] or states[2]
    end
end

function isDrifting(vehicle)
    if getVehicleType(vehicle) == "Bike" then
        return not isVehicleWheelOnGround(vehicle, 1)
    end
    local traction = getVehicleHandling(vehicle)["driveType"]
    local frictionStates = {getVehicleWheelFrictionState(vehicle, 0), getVehicleWheelFrictionState(vehicle, 2), getVehicleWheelFrictionState(vehicle, 1), getVehicleWheelFrictionState(vehicle, 3)}
    if traction == "rwd" then
        return frictionStates[3] == 1 and frictionStates[4] == 1
    elseif traction == "awd" then
        return (frictionStates[3] == 1 and frictionStates[4] == 1) or (frictionStates[1] == 1 and frictionStates[2] == 1)
    else
        return frictionStates[1] == 1 and frictionStates[2] == 1
    end
end

function getDrift(vehicle, x, y)
    local _, _, rz = getElementRotation(vehicle)
    local sn, cs = -math.sin(math.rad(rz)), math.cos(math.rad(rz))
    local speed = math.sqrt(x * x + y * y)
    local cosx = (sn * x + cs * y) / speed
    local result = math.deg(math.acos(cosx))
    return clamp(result, 0, 20) / 20
end

function isElegible(vehicle)
    if getElementType(vehicle) == "vehicle" and isElementStreamedIn(vehicle) then
        if getVehicleController(vehicle) and isElementWithinColShape(vehicle, areaZone) and not isVehicleBlown(vehicle) then
            return true
        end
    end
    return false
end

local function updateHandling()
    for _, vehicle in pairs(vehicles) do
        if isElegible(vehicle) then
            local hnd = getVehicleHandling(vehicle)
            handling[vehicle] = handling[vehicle] or {}
            handling[vehicle].maxSpeed = hnd['maxVelocity']
            handling[vehicle].maxGears = hnd['numberOfGears']
        end
    end
end
setTimer(updateHandling, 2*1000, 0)

local function canProceed(element)
    element = element or source
    if isElegible(element) and not table.hasValue(vehicles, element) then
        table.insert(vehicles, element)
        updateHandling()
    end
end

local function insertVehicle()
    local vehicles = getElementsWithinColShape(areaZone, "vehicle")
    for _, vehicle in pairs(vehicles) do
        canProceed(vehicle)
    end
end

addEventHandler("onClientResourceStart", resourceRoot, function()
    areaZone = createColSphere(0, 0, 0, engineDistance/2)
    attachElements(areaZone, localPlayer)

    insertVehicle()

    addEventHandler("onClientColShapeHit", areaZone, canProceed)
    addEventHandler("onClientElementStreamIn", root, canProceed)
    addEventHandler("onClientElementDestroy", root, stopEngine)
    addEventHandler("onClientVehicleExplode", root, stopEngine)

    addEventHandler("onClientColShapeLeave", areaZone, function(element)
        if table.hasValue(vehicles, element) then
            stopEngine(element)
        end
    end)

    addEventHandler ("onClientVehicleEnter", root, function(_, seat)
        if seat == 0 and not table.hasValue(vehicles, source) then
            canProceed(source)
        end
    end)

    addEventHandler ("onClientVehicleExit", root, function(_, seat)
        if seat == 0 and table.hasValue(vehicles, source) then
            stopEngine(source)
        end
    end)
end)