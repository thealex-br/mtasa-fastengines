local storage = {}
function setData(element, key, value)
    storage[element] = storage[element] or {}
    storage[element][key] = value or nil
end
function getData(element, key)
    return storage[element] and storage[element][key] or false
end -- yes, i really hate working with tables ¯\_(ツ)_/¯

local smooths = {}
local function update(value, name)
    smooths[name].value = smooths[name].value * (1 - smooths[name].factor) + (value or 0) * smooths[name].factor
    return smooths[name].value
end
function smooth(value, factor, name)
    if not smooths[name] then
        smooths[name] = {value = value, factor = factor or 0.2}
    end
    return update(value, name)
end

function math.clamp(value, min, max)
    return math.max(math.min(value, max), min)
end

local last = 0
function waitTime(ms)
    local now = getTickCount()
    if last + (ms or 0) > now then
        return false
    end
    last = now
    return true
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
    for _, key in ipairs(config.keys) do
        local id = getElementData(vehicle, key)
        if id then
            return id
        end
    end
    return getElementModel(vehicle)
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
    assert(type(element)=='userdata' and getElementType(vehicle)=="Automobile", "Expected vehicle at argument 1, got "..type(vehicle))
    local modelFlags = getVehicleHandling(vehicle).modelFlags
    local fourthByte = string.format("%08X", modelFlags):reverse():sub(4, 4)
    local hasExhausts = allowedExhaustTypes[fourthByte]
    local twoExhausts = hasExhausts and allowedExhaustBytes[fourthByte]
    if not hasExhausts then -- handling don't have exhaust
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
        if not twoExhausts then -- allow only one exhaust to backfire
            return
        end
    end
end

function stopEngine(vehicle)
    vehicle = source or vehicle
    if not (type(vehicle) == 'userdata' and getElementType(vehicle) == "vehicle") then
        return false
    end
    
    setData(vehicle, "elegible", nil)

    local engine = getData(vehicle, "engine")
    if engine then
        destroyElement(engine)
    end
    setData(vehicle, "engine", nil)
    setData(vehicle, "enginerpm", nil)
    setData(vehicle, "cached", nil)

    local turbo = getData(vehicle, "turbo")
    if turbo then
        destroyElement(turbo)
    end
    setData(vehicle, "turbo", nil)
    setData(vehicle, "turborpm", nil)

    setData(vehicle, "topSpeed", nil)
    setData(vehicle, "maxGears", nil)

    storage[vehicle] = nil
    smooths[vehicle] = nil

    setElementData(vehicle, config.rpmKey, nil, false)
    table.removeValue(vehicles, vehicle)
end

function playAttachedSound3D(soundPath, element, loop, vol, speed, min, max)
    assert(soundPath and fileExists(soundPath), "Expected audio file at argument 1, got "..type(soundPath))
    assert(type(element)=='userdata' and isElement(element), "Expected element at argument 2, got "..type(element))

    local sound = playSound3D(soundPath, 0, 0, 0, loop or false)
    if not isElement(sound) then
        return false
    end
    attachElements(sound, element)
    setElementDimension(sound, getElementDimension(element))
    setElementInterior(sound, getElementInterior(element))

    setSoundSpeed(sound, speed or 0)
    setSoundVolume(sound, vol or 0)
    setSoundMinDistance(sound, min or 100/6)
    setSoundMaxDistance(sound, max or 100)
    setData(element, "elegible", true)
    return sound
end

function isOnGround(vehicle)
    local vehicleType = getVehicleType(vehicle)
    if vehicleType == "Bike" then
        local states = {f=isVehicleWheelOnGround(vehicle, 0), b=isVehicleWheelOnGround(vehicle, 1)}
        return states.f or states.b
    end
    local traction = getVehicleHandling(vehicle).driveType
    local states = {fl=isVehicleWheelOnGround(vehicle, 0), fr=isVehicleWheelOnGround(vehicle, 2), rl=isVehicleWheelOnGround(vehicle, 1), rr=isVehicleWheelOnGround(vehicle, 3)}
    local lockup = {
        ['rwd'] = states.fr or states.rr,
        ['awd'] = (states.fr or states.rr) or (states.fl or states.rl),
        ['fwd'] = states.fl or states.rl,
    }
    return lockup[traction]
end

function isTractionState(vehicle, state)
    local vehicleType = getVehicleType(vehicle)
    if vehicleType == "Bike" then
        local states = {f=isVehicleWheelOnGround(vehicle, 0), b=isVehicleWheelOnGround(vehicle, 1)}
        return not states.b
    end
    local traction = getVehicleHandling(vehicle).driveType
    local states = {fl=getVehicleWheelFrictionState(vehicle, 0), fr=getVehicleWheelFrictionState(vehicle, 2), rl=getVehicleWheelFrictionState(vehicle, 1), rr=getVehicleWheelFrictionState(vehicle, 3)}
    local lockup = {
        ['rwd'] = states.rl == state and states.rr == state,
        ['awd'] = (states.rl == state and states.rr == state) or (states.fl == state and states.fr == state),
        ['fwd'] = {states.fl == state and states.fr == state},
    }
    return lockup[traction]
end

function getDrift(vehicle, x, y)
    local rot = select(3, getElementRotation(vehicle))
    local sn, cs = -math.sin(math.rad(rot)), math.cos(math.rad(rot))
    local speed = math.sqrt(x * x + y * y)
    local cosx = (sn * x + cs * y) / speed
    local result = math.deg(math.acos(cosx))
    return math.clamp(result, 0, 15) / 15
end

function toScale(number, min, max)
    return (number + min) / (max + min)
end

function isElegible(vehicle, ignoreCol)
    if not (getElementType(vehicle) == "vehicle" and isElementStreamedIn(vehicle)) then
        return false
    end
    if not getVehicleController(vehicle) then
        return false
    end
    if isVehicleBlown(vehicle) then
        return false
    end
    if ignoreCol then
        return true
    end
    if not isElementWithinColShape(vehicle, areaZone) then
        return false
    end
    return true
end

local function updateHandling()
    for _, vehicle in ipairs(vehicles) do
        if isElegible(vehicle) then
            local hnd = getVehicleHandling(vehicle)
            setData(vehicle, "topSpeed", hnd['maxVelocity'])
            setData(vehicle, "maxGears", hnd['numberOfGears'])
        end
    end
end
setTimer(updateHandling, 1000, 0)

local function canProceed(element)
    element = element or source
    if isElegible(element) and not table.hasValue(vehicles, element) then
        table.insert(vehicles, element)
        updateHandling()
    end
end

local function insertVehicle()
    local vehicles = getElementsWithinColShape(areaZone, "vehicle")
    for _, vehicle in ipairs(vehicles) do
        canProceed(vehicle)
    end
end

addEventHandler("onClientResourceStart", resourceRoot, function()
    areaZone = createColSphere(0, 0, 0, config.engine.distance)
    attachElements(areaZone, localPlayer)

    insertVehicle()

    addEventHandler("onClientColShapeHit", areaZone, canProceed)
    addEventHandler("onClientColShapeLeave", areaZone, stopEngine)

    addEventHandler("onClientElementStreamIn", root, canProceed)
    addEventHandler("onClientElementStreamOut", root, stopEngine)

    addEventHandler("onClientElementDestroy", root, stopEngine)
    addEventHandler("onClientVehicleExplode", root, stopEngine)


    addEventHandler ("onClientVehicleEnter", root, function(_, seat)
        if seat == 0 and not table.hasValue(vehicles, source) then
            canProceed(source)
        end
    end)

    addEventHandler ("onClientVehicleStartExit", root, function(_, seat)
        if seat == 0 and table.hasValue(vehicles, source) then
            stopEngine(source)
        end
    end)
end)
