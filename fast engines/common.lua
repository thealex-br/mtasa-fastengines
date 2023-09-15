max = math.min
min = math.max
sqrt = math.sqrt
rad = math.rad
cos = math.cos
sin = math.sin
acos = math.acos
deg = math.deg
floor = math.floor
ceil = math.ceil
minimal = 0.00001

function clamp(value, minValue, maxValue)
    return min(max(value, maxValue), minValue)
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
    local fourthByte = string.format("%08X", modelFlags):reverse():sub(4, 4)
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
    for _, side in ipairs({exhX, -1 * exhX}) do
        local exhaust = Vector3(getPositionFromElementOffset(vehicle, side, exhY + speed, exhZ))
        fxAddGunshot(exhaust, direction)
        if not hasDoubleExhaust then -- allow only one exhaust to backfire
            return true
        end
    end
    return true
end

local lastTicks = {}
function waitTick(tick, limiter)
    limiter = limiter or "default"
    local lastTick = lastTicks[limiter] or 0
    local nowTick = getTickCount()
    if lastTick + (tick or 2) > nowTick then
        return false
    end
    lastTicks[limiter] = nowTick
    return true
end

function stopEngine(vehicle)
    if data[vehicle] then
        if isElement( data[vehicle].engine ) then
            destroyElement(data[vehicle].engine)
            data[vehicle].engine = nil
        end
        data[vehicle].rpm = 0
    end
    if gData[vehicle] then
        if isElement(gData[vehicle].turbo) then
            destroyElement(gData[vehicle].turbo)
            gData[vehicle].engine = nil
        end
        gData[vehicle].rpm = 0
    end
    handling[vehicle] = nil
    data[vehicle] = nil
    gData[vehicle] = nil
    setElementData(vehicle, "engineRPM", false, false)
    table.removeValue(vehicles, vehicle)
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

function isOnGround(vehicle)
    local traction = getVehicleHandling(vehicle)["driveType"]
    if getVehicleType(vehicle) == "Bike" then
        local wheelStates = {isVehicleWheelOnGround(vehicle, 0), isVehicleWheelOnGround(vehicle, 1)}
        return wheelStates[1] or wheelStates[2]
    else
        local wheelStates = {isVehicleWheelOnGround(vehicle, 0), isVehicleWheelOnGround(vehicle, 1), isVehicleWheelOnGround(vehicle, 2), isVehicleWheelOnGround(vehicle, 3)}
        if traction == "rwd" then
            return wheelStates[3] or wheelStates[4]
        elseif traction == "awd" then
            return (wheelStates[3] or wheelStates[4]) or (wheelStates[1] or wheelStates[2])
        else
            return wheelStates[1] or wheelStates[2]
        end
    end
end

function isDrifting(vehicle)
    if getVehicleType(vehicle) == "Bike" then
        return not isVehicleWheelOnGround(vehicle, 1)
    else
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
end

function getDrift(vehicle, x, y)
    local _, _, rz = getElementRotation(vehicle)
    local sn, cs = -sin(rad(rz)), cos(rad(rz))
    local speed = sqrt(x * x + y * y)
    local cosx = (sn * x + cs * y) / speed
    local result = deg(acos(cosx))
    return max(min(result, 0), 20)/20
end

function isElegible(vehicle)
    if getElementType(vehicle) == "vehicle" and isElementStreamedIn(vehicle) then
        if getVehicleController(vehicle) and isElementWithinColShape(vehicle, areaZone) and not isVehicleBlown(vehicle) then
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

    insertVehicle()

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
end)

local function removeVehicle()
    if isElement(source) and getElementType(source) == "vehicle" then
        stopEngine(source)
    end
end
addEventHandler("onClientElementDestroy", root, removeVehicle)
addEventHandler("onClientVehicleExplode", root, removeVehicle)