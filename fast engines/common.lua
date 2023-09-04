function getDistanceBetweenElements(element1, element2)
	local x1, y1, z1 = getElementPosition(element1)
	local x2, y2, z2 = getElementPosition(element2)
	return getDistanceBetweenPoints3D(x1, y1, z1, x2, y2, z2)
end

function table.removeValue(tab, val) for index, value in pairs(tab) do if value == val then table.remove(tab, index) return index end end return false end
function table.hasValue(tab, val) for index, value in pairs(tab) do if value == val then return true end end return false end

function playAttachedSound3D(soundPath, element)
    if not soundPath or not isElement(element) then
        return false
    end
    local sound = playSound3D(soundPath, 0, 0, 0, true)
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
    local wheelStates = {isVehicleWheelOnGround(theVehicle, 0), isVehicleWheelOnGround(theVehicle, 1), isVehicleWheelOnGround(theVehicle, 2), isVehicleWheelOnGround(theVehicle, 3)}
    if traction == "rwd" then
        return wheelStates[3] or wheelStates[4]
    elseif traction == "awd" then
        return (wheelStates[3] or wheelStates[4]) or (wheelStates[1] or wheelStates[2])
    else
        return wheelStates[1] or wheelStates[2]
    end
end

function isDrifting(theVehicle)
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
        if getVehicleController(theVehicle) and not isVehicleBlown(theVehicle) then
            return true
        end
        return false
    end
    return false
end

addEventHandler("onClientResourceStart", resourceRoot, function()
    local x, y, z = getElementPosition( localPlayer )
    local allVehicles = getElementsWithinRange(x, y, z, audioDistance, "vehicle")
    for _, veh in pairs( allVehicles ) do
        if isElegible(veh) and not table.hasValue(vehicles, veh) then
            table.insert(vehicles, veh)
        end
    end
end)

local function insertVehicle()
    local x, y, z = getElementPosition( localPlayer )
    local allVehicles = getElementsWithinRange(x, y, z, audioDistance, "vehicle")
    for _, veh in pairs( allVehicles ) do
        if isElegible(veh) and not table.hasValue(vehicles, veh) then
            table.insert(vehicles, veh)
        end
    end
end
addEventHandler("onClientVehicleEnter", root, insertVehicle)
addEventHandler("onClientElementStreamIn", root, insertVehicle)

local function removeVehicle()
    if source and isElement(source) and getElementType(source) == "vehicle" then
        stopEngine(source)
    end
end
addEventHandler("onClientElementDestroy", root, removeVehicle)
addEventHandler("onClientVehicleExplode", root, removeVehicle)
addEventHandler("onClientElementStreamOut", root, removeVehicle)
addEventHandler("onClientElementInteriorChange", root, removeVehicle)
addEventHandler("onClientElementDimensionChange", root, removeVehicle)

local function removeVehicleOwnerLeave(thePlayer, theSeat)
    if getElementType(source) == "vehicle" and theSeat == 0 then
        stopEngine(source)
    end
end
addEventHandler("onClientVehicleExit", root, removeVehicleOwnerLeave)

local function updateHandling()
    for _, veh in pairs( vehicles ) do
        if isElegible(veh) then
            local hnd = getVehicleHandling(veh)
            handling[veh] = handling[veh] or {}
            handling[veh].maxSpeed = hnd['maxVelocity']
            handling[veh].maxGears = hnd['numberOfGears']
        end
    end
end
addEventHandler("onClientVehicleEnter", root, updateHandling)
addEventHandler("onClientResourceStart", resourceRoot, updateHandling)
addEventHandler("onClientElementStreamIn", root, updateHandling)
setTimer(updateHandling, 1000, 0)