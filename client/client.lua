local CBS_IsOpen = false
local CBS_NoClipActive = false
local CBS_NoClipSpeed = 1.0
local CBS_GodModeActive = false
local CBS_InvisibleActive = false
local CBS_InfiniteStaminaActive = false
local CBS_NoRagdollActive = false
local CBS_FreezePlayerActive = false
local CBS_ShowCoordsActive = false
local CBS_SpeedBoostActive = false
local CBS_VehicleGodModeActive = false
local CBS_OneHitKillActive = false
local CBS_SuperJumpActive = false
local CBS_NightVisionActive = false
local CBS_ThermalVisionActive = false
local CBS_FreeAimModeActive = false
local CBS_TimeFreezeActive = false
local CBS_WeatherLockActive = false
local CBS_LockedWeather = "CLEAR"
local CBS_LockedTime = { hour = 12, minute = 0 }
local CBS_EntityOutlineActive = false
local CBS_SpawnedEntities = {}
local CBS_HasAccess = false
local CBS_LastAimedEntity = nil
local CBS_FrozenEntities = {}


---@param message string
---@return nil
function CBSFunction_SendNotification(message)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostTicker(false, true)
end


---@param void
---@return vector3
function CBSFunction_GetPlayerCoords()
    return GetEntityCoords(PlayerPedId())
end


---@param void
---@return number
function CBSFunction_GetPlayerHeading()
    return GetEntityHeading(PlayerPedId())
end


---@param value number
---@param decimals number
---@return number
function CBSFunction_RoundNumber(value, decimals)
    local mult = 10 ^ (decimals or 0)
    return math.floor(value * mult + 0.5) / mult
end


---@param coordType string
---@return table
function CBSFunction_FormatCoords(coordType)
    local c = CBSFunction_GetPlayerCoords()
    local h = CBSFunction_GetPlayerHeading()
    if coordType == "vector2" then
        return { formatted = string.format("vector2(%.4f, %.4f)", c.x, c.y) }
    elseif coordType == "vector3" then
        return { formatted = string.format("vector3(%.4f, %.4f, %.4f)", c.x, c.y, c.z) }
    elseif coordType == "vector4" then
        return { formatted = string.format("vector4(%.4f, %.4f, %.4f, %.4f)", c.x, c.y, c.z, h) }
    elseif coordType == "heading" then
        return { formatted = string.format("%.4f", h) }
    end
    return { formatted = "" }
end


---@param text string
---@return nil
function CBSFunction_CopyToClipboard(text)
    SendNUIMessage({ action = "copyToClipboard", text = text })
    CBSFunction_SendNotification("~g~CBS~s~: Copied to clipboard")
end


---@param rotation vector3
---@return vector3
function CBSFunction_RotationToDirection(rotation)
    local rx = (math.pi / 180) * rotation.x
    local rz = (math.pi / 180) * rotation.z
    return vector3(
        -math.sin(rz) * math.abs(math.cos(rx)),
        math.cos(rz) * math.abs(math.cos(rx)),
        math.sin(rx)
    )
end


---@param entity number
---@return table
function CBSFunction_GetEntityInfo(entity)
    if not DoesEntityExist(entity) then return nil end
    local ec = GetEntityCoords(entity)
    local et = GetEntityType(entity)
    local tn = "Unknown"
    if et == 1 then tn = "Ped"
    elseif et == 2 then tn = "Vehicle"
    elseif et == 3 then tn = "Object" end
    return {
        type = tn,
        model = GetEntityModel(entity),
        health = GetEntityHealth(entity),
        maxHealth = GetEntityMaxHealth(entity),
        speed = CBSFunction_RoundNumber(GetEntitySpeed(entity) * 3.6, 2),
        coords = {
            x = CBSFunction_RoundNumber(ec.x, 4),
            y = CBSFunction_RoundNumber(ec.y, 4),
            z = CBSFunction_RoundNumber(ec.z, 4)
        },
        heading = CBSFunction_RoundNumber(GetEntityHeading(entity), 4),
        distance = CBSFunction_RoundNumber(#(GetEntityCoords(PlayerPedId()) - ec), 2)
    }
end


---@param x number
---@param y number
---@param z number
---@param text string
---@return nil
function CBSFunction_DrawText3D(x, y, z, text)
    local onScreen, sx, sy = World3dToScreen2d(x, y, z)
    if onScreen then
        SetTextScale(0.0, 0.35)
        SetTextFont(0)
        SetTextProportional(true)
        SetTextColour(255, 255, 255, 255)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        AddTextComponentString(text)
        DrawText(sx, sy)
    end
end


---@param x number
---@param y number
---@param text string
---@return nil
function CBSFunction_DrawText2D(x, y, text)
    SetTextFont(0)
    SetTextProportional(true)
    SetTextScale(0.0, 0.35)
    SetTextColour(255, 255, 255, 255)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x, y)
end


---@param entity number
---@return nil
function CBSFunction_DrawEntityBoundingBox(entity)
    if not DoesEntityExist(entity) then return end
    local model = GetEntityModel(entity)
    local min, max = GetModelDimensions(model)
    local rightVector, forwardVector, upVector, position = GetEntityMatrix(entity)
    local dimX = 0.5 * (max.x - min.x)
    local dimY = 0.5 * (max.y - min.y)
    local dimZ = 0.5 * (max.z - min.z)
    local e1 = position - rightVector * dimY - forwardVector * dimX - upVector * dimZ
    local e2 = e1 + rightVector * dimY * 2.0
    local e3 = e2 + upVector * dimZ * 2.0
    local e4 = e1 + upVector * dimZ * 2.0
    local e5 = position + rightVector * dimY + forwardVector * dimX + upVector * dimZ
    local e6 = e5 - rightVector * dimY * 2.0
    local e7 = e6 - upVector * dimZ * 2.0
    local e8 = e5 - upVector * dimZ * 2.0
    local cr, cg, cb, ca = 255, 50, 50, 180
    DrawLine(e1.x, e1.y, e1.z, e2.x, e2.y, e2.z, cr, cg, cb, ca)
    DrawLine(e1.x, e1.y, e1.z, e4.x, e4.y, e4.z, cr, cg, cb, ca)
    DrawLine(e2.x, e2.y, e2.z, e3.x, e3.y, e3.z, cr, cg, cb, ca)
    DrawLine(e3.x, e3.y, e3.z, e4.x, e4.y, e4.z, cr, cg, cb, ca)
    DrawLine(e5.x, e5.y, e5.z, e6.x, e6.y, e6.z, cr, cg, cb, ca)
    DrawLine(e5.x, e5.y, e5.z, e8.x, e8.y, e8.z, cr, cg, cb, ca)
    DrawLine(e6.x, e6.y, e6.z, e7.x, e7.y, e7.z, cr, cg, cb, ca)
    DrawLine(e7.x, e7.y, e7.z, e8.x, e8.y, e8.z, cr, cg, cb, ca)
    DrawLine(e1.x, e1.y, e1.z, e7.x, e7.y, e7.z, cr, cg, cb, ca)
    DrawLine(e2.x, e2.y, e2.z, e8.x, e8.y, e8.z, cr, cg, cb, ca)
    DrawLine(e3.x, e3.y, e3.z, e5.x, e5.y, e5.z, cr, cg, cb, ca)
    DrawLine(e4.x, e4.y, e4.z, e6.x, e6.y, e6.z, cr, cg, cb, ca)
end


---@param void
---@return nil
function CBSFunction_OpenDevTool()
    if not CBS_HasAccess then
        CBSFunction_SendNotification("~r~CBS~s~: No access")
        return
    end
    CBS_IsOpen = true
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)
    local ped = PlayerPedId()
    local c = GetEntityCoords(ped)
    local h = GetEntityHeading(ped)
    SendNUIMessage({
        action = "open",
        coords = {
            x = CBSFunction_RoundNumber(c.x, 4),
            y = CBSFunction_RoundNumber(c.y, 4),
            z = CBSFunction_RoundNumber(c.z, 4)
        },
        heading = CBSFunction_RoundNumber(h, 4),
        states = {
            godMode = CBS_GodModeActive,
            invisible = CBS_InvisibleActive,
            noClip = CBS_NoClipActive,
            infiniteStamina = CBS_InfiniteStaminaActive,
            noRagdoll = CBS_NoRagdollActive,
            freezePlayer = CBS_FreezePlayerActive,
            showCoords = CBS_ShowCoordsActive,
            speedBoost = CBS_SpeedBoostActive,
            vehicleGodMode = CBS_VehicleGodModeActive,
            oneHitKill = CBS_OneHitKillActive,
            superJump = CBS_SuperJumpActive,
            nightVision = CBS_NightVisionActive,
            thermalVision = CBS_ThermalVisionActive,
            freeAimMode = CBS_FreeAimModeActive,
            entityOutline = CBS_EntityOutlineActive,
            timeFreeze = CBS_TimeFreezeActive,
            weatherLock = CBS_WeatherLockActive
        }
    })
end


---@param void
---@return nil
function CBSFunction_CloseDevTool()
    CBS_IsOpen = false
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    SendNUIMessage({ action = "close" })
end


---@param state boolean
---@return nil
function CBSFunction_ToggleGodMode(state)
    CBS_GodModeActive = state
    SetEntityInvincible(PlayerPedId(), state)
end


---@param state boolean
---@return nil
function CBSFunction_ToggleInvisible(state)
    CBS_InvisibleActive = state
    SetEntityVisible(PlayerPedId(), not state, false)
end


---@param state boolean
---@return nil
function CBSFunction_ToggleInfiniteStamina(state)
    CBS_InfiniteStaminaActive = state
end


---@param state boolean
---@return nil
function CBSFunction_ToggleNoRagdoll(state)
    CBS_NoRagdollActive = state
    local ped = PlayerPedId()
    SetPedCanRagdoll(ped, not state)
    SetPedCanRagdollFromPlayerImpact(ped, not state)
    SetPedRagdollOnCollision(ped, not state)
end


---@param state boolean
---@return nil
function CBSFunction_ToggleFreezePlayer(state)
    CBS_FreezePlayerActive = state
    FreezeEntityPosition(PlayerPedId(), state)
end


---@param state boolean
---@return nil
function CBSFunction_ToggleShowCoords(state)
    CBS_ShowCoordsActive = state
end


---@param state boolean
---@return nil
function CBSFunction_ToggleSpeedBoost(state)
    CBS_SpeedBoostActive = state
end


---@param state boolean
---@return nil
function CBSFunction_ToggleVehicleGodMode(state)
    CBS_VehicleGodModeActive = state
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    if veh and veh ~= 0 then
        SetEntityInvincible(veh, state)
    end
end


---@param state boolean
---@return nil
function CBSFunction_ToggleOneHitKill(state)
    CBS_OneHitKillActive = state
    if state then
        SetPlayerWeaponDamageModifier(PlayerId(), 100.0)
    else
        SetPlayerWeaponDamageModifier(PlayerId(), 1.0)
    end
end


---@param state boolean
---@return nil
function CBSFunction_ToggleSuperJump(state)
    CBS_SuperJumpActive = state
end


---@param state boolean
---@return nil
function CBSFunction_ToggleNightVision(state)
    CBS_NightVisionActive = state
    SetNightvision(state)
end


---@param state boolean
---@return nil
function CBSFunction_ToggleThermalVision(state)
    CBS_ThermalVisionActive = state
    SetSeethrough(state)
end


---@param state boolean
---@return nil
function CBSFunction_ToggleNoClip(state)
    CBS_NoClipActive = state
    local ped = PlayerPedId()
    if state then
        SetEntityCollision(ped, false, false)
        FreezeEntityPosition(ped, true)
        SetEntityVisible(ped, false, false)
        SetEntityAlpha(ped, 0, false)
        SetEveryoneIgnorePlayer(PlayerId(), true)
        SetPoliceIgnorePlayer(PlayerId(), true)
    else
        SetEntityCollision(ped, true, true)
        FreezeEntityPosition(ped, false)
        SetEntityVisible(ped, true, false)
        ResetEntityAlpha(ped)
        SetEveryoneIgnorePlayer(PlayerId(), false)
        SetPoliceIgnorePlayer(PlayerId(), false)
    end
end


---@param state boolean
---@return nil
function CBSFunction_ToggleFreeAimMode(state)
    CBS_FreeAimModeActive = state
    if not state then
        CBS_LastAimedEntity = nil
        SendNUIMessage({ action = "clearEntityInfo" })
    end
end


---@param state boolean
---@return nil
function CBSFunction_ToggleEntityOutline(state)
    CBS_EntityOutlineActive = state
end


---@param state boolean
---@return nil
function CBSFunction_ToggleTimeFreeze(state)
    CBS_TimeFreezeActive = state
end


---@param weather string
---@return nil
function CBSFunction_SetWeather(weather)
    CBS_LockedWeather = weather
    CBS_WeatherLockActive = true
    SetWeatherTypeNowPersist(weather)
    SetWeatherTypeNow(weather)
    CBSFunction_SendNotification("~g~CBS~s~: Weather set to " .. weather)
end


---@param hour number
---@param minute number
---@return nil
function CBSFunction_SetTime(hour, minute)
    CBS_LockedTime.hour = hour
    CBS_LockedTime.minute = minute
    NetworkOverrideClockTime(hour, minute, 0)
    CBSFunction_SendNotification("~g~CBS~s~: Time set to " .. hour .. ":" .. string.format("%02d", minute))
end


---@param modelName string
---@return nil
function CBSFunction_SpawnVehicle(modelName)
    local modelHash = GetHashKey(modelName)
    if not IsModelInCdimage(modelHash) then
        CBSFunction_SendNotification("~r~CBS~s~: Invalid model")
        return
    end
    RequestModel(modelHash)
    local t = 0
    while not HasModelLoaded(modelHash) do
        Wait(10)
        t = t + 10
        if t > 5000 then return end
    end
    local ped = PlayerPedId()
    local c = GetEntityCoords(ped)
    local h = GetEntityHeading(ped)
    local veh = CreateVehicle(modelHash, c.x, c.y, c.z + 1.0, h, true, false)
    SetPedIntoVehicle(ped, veh, -1)
    SetVehicleEngineOn(veh, true, true, false)
    SetModelAsNoLongerNeeded(modelHash)
    table.insert(CBS_SpawnedEntities, veh)
    CBSFunction_SendNotification("~g~CBS~s~: Vehicle spawned")
end


---@param modelName string
---@return nil
function CBSFunction_SpawnPed(modelName)
    local modelHash = GetHashKey(modelName)
    if not IsModelInCdimage(modelHash) then
        CBSFunction_SendNotification("~r~CBS~s~: Invalid model")
        return
    end
    RequestModel(modelHash)
    local t = 0
    while not HasModelLoaded(modelHash) do
        Wait(10)
        t = t + 10
        if t > 5000 then return end
    end
    local ped = PlayerPedId()
    local c = GetEntityCoords(ped)
    local fv = GetEntityForwardVector(ped)
    local sc = c + fv * 3.0
    local p = CreatePed(4, modelHash, sc.x, sc.y, sc.z, GetEntityHeading(ped), true, false)
    SetModelAsNoLongerNeeded(modelHash)
    table.insert(CBS_SpawnedEntities, p)
    CBSFunction_SendNotification("~g~CBS~s~: Ped spawned")
end


---@param modelName string
---@return nil
function CBSFunction_SpawnObject(modelName)
    local modelHash = GetHashKey(modelName)
    if not IsModelInCdimage(modelHash) then
        CBSFunction_SendNotification("~r~CBS~s~: Invalid model")
        return
    end
    RequestModel(modelHash)
    local t = 0
    while not HasModelLoaded(modelHash) do
        Wait(10)
        t = t + 10
        if t > 5000 then return end
    end
    local ped = PlayerPedId()
    local c = GetEntityCoords(ped)
    local fv = GetEntityForwardVector(ped)
    local sc = c + fv * 3.0
    local obj = CreateObject(modelHash, sc.x, sc.y, sc.z, true, false, false)
    PlaceObjectOnGroundProperly(obj)
    SetModelAsNoLongerNeeded(modelHash)
    table.insert(CBS_SpawnedEntities, obj)
    CBSFunction_SendNotification("~g~CBS~s~: Object spawned")
end


---@param void
---@return nil
function CBSFunction_DeleteClosestEntity()
    local ped = PlayerPedId()
    local c = GetEntityCoords(ped)
    local closest = nil
    local closestD = 10.0
    local handle, entity = FindFirstObject()
    local success = true
    while success do
        if entity ~= 0 and entity ~= ped then
            local d = #(c - GetEntityCoords(entity))
            if d < closestD then closestD = d; closest = entity end
        end
        success, entity = FindNextObject(handle)
    end
    EndFindObject(handle)
    handle, entity = FindFirstVehicle()
    success = true
    while success do
        if entity ~= 0 and not IsPedInVehicle(ped, entity, false) then
            local d = #(c - GetEntityCoords(entity))
            if d < closestD then closestD = d; closest = entity end
        end
        success, entity = FindNextVehicle(handle)
    end
    EndFindVehicle(handle)
    handle, entity = FindFirstPed()
    success = true
    while success do
        if entity ~= 0 and entity ~= ped then
            local d = #(c - GetEntityCoords(entity))
            if d < closestD then closestD = d; closest = entity end
        end
        success, entity = FindNextPed(handle)
    end
    EndFindPed(handle)
    if closest and DoesEntityExist(closest) then
        SetEntityAsMissionEntity(closest, true, true)
        DeleteEntity(closest)
        CBSFunction_SendNotification("~g~CBS~s~: Entity deleted")
    else
        CBSFunction_SendNotification("~r~CBS~s~: No entity nearby")
    end
end


---@param void
---@return nil
function CBSFunction_CleanupEntities()
    local count = 0
    for i = #CBS_SpawnedEntities, 1, -1 do
        local ent = CBS_SpawnedEntities[i]
        if DoesEntityExist(ent) then
            SetEntityAsMissionEntity(ent, true, true)
            DeleteEntity(ent)
            count = count + 1
        end
        table.remove(CBS_SpawnedEntities, i)
    end
    CBSFunction_SendNotification("~g~CBS~s~: Cleaned " .. count .. " entities")
end


---@param void
---@return nil
function CBSFunction_TeleportToWaypoint()
    local wp = GetFirstBlipInfoId(8)
    if not DoesBlipExist(wp) then
        CBSFunction_SendNotification("~r~CBS~s~: No waypoint")
        return
    end
    local wc = GetBlipInfoIdCoord(wp)
    local ped = PlayerPedId()
    local found = false
    local gz = 0.0
    for z = 1000.0, 0.0, -25.0 do
        SetEntityCoordsNoOffset(ped, wc.x, wc.y, z, false, false, false)
        Wait(50)
        found, gz = GetGroundZFor_3dCoord(wc.x, wc.y, z, false)
        if found then
            SetEntityCoordsNoOffset(ped, wc.x, wc.y, gz + 1.0, false, false, false)
            break
        end
    end
    if not found then
        SetEntityCoordsNoOffset(ped, wc.x, wc.y, 250.0, false, false, false)
    end
    CBSFunction_SendNotification("~g~CBS~s~: Teleported")
end


---@param x number
---@param y number
---@param z number
---@return nil
function CBSFunction_TeleportToCoords(x, y, z)
    SetEntityCoordsNoOffset(PlayerPedId(), x + 0.0, y + 0.0, z + 0.0, false, false, false)
    CBSFunction_SendNotification("~g~CBS~s~: Teleported")
end


---@param void
---@return nil
function CBSFunction_RepairVehicle()
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    if veh and veh ~= 0 then
        SetVehicleFixed(veh)
        SetVehicleEngineHealth(veh, 1000.0)
        SetVehicleBodyHealth(veh, 1000.0)
        SetVehiclePetrolTankHealth(veh, 1000.0)
        SetVehicleDirtLevel(veh, 0.0)
        SetVehicleEngineOn(veh, true, true, false)
        CBSFunction_SendNotification("~g~CBS~s~: Vehicle repaired")
    else
        CBSFunction_SendNotification("~r~CBS~s~: Not in vehicle")
    end
end


---@param void
---@return nil
function CBSFunction_DeleteCurrentVehicle()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, true)
    if veh and veh ~= 0 then
        if IsPedInVehicle(ped, veh, false) then
            TaskLeaveVehicle(ped, veh, 16)
            Wait(800)
        end
        SetEntityAsMissionEntity(veh, true, true)
        DeleteVehicle(veh)
        CBSFunction_SendNotification("~g~CBS~s~: Vehicle deleted")
    else
        CBSFunction_SendNotification("~r~CBS~s~: No vehicle")
    end
end


---@param void
---@return nil
function CBSFunction_HealPlayer()
    local ped = PlayerPedId()
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    SetPedArmour(ped, 100)
    ClearPedBloodDamage(ped)
    CBSFunction_SendNotification("~g~CBS~s~: Healed")
end


---@param void
---@return nil
function CBSFunction_RevivePlayer()
    local ped = PlayerPedId()
    local c = GetEntityCoords(ped)
    NetworkResurrectLocalPlayer(c.x, c.y, c.z, GetEntityHeading(ped), true, false)
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    ClearPedBloodDamage(ped)
    ClearPedTasksImmediately(ped)
    CBSFunction_SendNotification("~g~CBS~s~: Revived")
end


RegisterKeyMapping("cbsdevtool", "Dev Tool", "keyboard", "F7")


RegisterCommand("devtool", function()
    if CBS_IsOpen then
        CBSFunction_CloseDevTool()
    else
        TriggerServerEvent("Cbs-devtool:server:checkAccess")
    end
end, false)


RegisterNetEvent("Cbs-devtool:client:accessResponse")
AddEventHandler("Cbs-devtool:client:accessResponse", function(hasAccess)
    CBS_HasAccess = hasAccess

    if hasAccess then
        CBSFunction_OpenDevTool()
    else
        CBSFunction_SendNotification("~r~CBS~s~: No access")
    end
end)


RegisterNUICallback("close", function(data, cb)
    CBSFunction_CloseDevTool()
    cb("ok")
end)


RegisterNUICallback("copyCoords", function(data, cb)
    local d = CBSFunction_FormatCoords(data.type)
    CBSFunction_CopyToClipboard(d.formatted)
    cb({ success = true, formatted = d.formatted })
end)


RegisterNUICallback("toggleGodMode", function(data, cb)
    CBSFunction_ToggleGodMode(data.state)
    cb({ success = true })
end)


RegisterNUICallback("toggleInvisible", function(data, cb)
    CBSFunction_ToggleInvisible(data.state)
    cb({ success = true })
end)


RegisterNUICallback("toggleNoClip", function(data, cb)
    CBSFunction_ToggleNoClip(data.state)
    cb({ success = true })
end)


RegisterNUICallback("toggleInfiniteStamina", function(data, cb)
    CBSFunction_ToggleInfiniteStamina(data.state)
    cb({ success = true })
end)


RegisterNUICallback("toggleNoRagdoll", function(data, cb)
    CBSFunction_ToggleNoRagdoll(data.state)
    cb({ success = true })
end)


RegisterNUICallback("toggleFreezePlayer", function(data, cb)
    CBSFunction_ToggleFreezePlayer(data.state)
    cb({ success = true })
end)


RegisterNUICallback("toggleShowCoords", function(data, cb)
    CBSFunction_ToggleShowCoords(data.state)
    cb({ success = true })
end)


RegisterNUICallback("toggleSpeedBoost", function(data, cb)
    CBSFunction_ToggleSpeedBoost(data.state)
    cb({ success = true })
end)


RegisterNUICallback("toggleVehicleGodMode", function(data, cb)
    CBSFunction_ToggleVehicleGodMode(data.state)
    cb({ success = true })
end)


RegisterNUICallback("toggleOneHitKill", function(data, cb)
    CBSFunction_ToggleOneHitKill(data.state)
    cb({ success = true })
end)


RegisterNUICallback("toggleSuperJump", function(data, cb)
    CBSFunction_ToggleSuperJump(data.state)
    cb({ success = true })
end)


RegisterNUICallback("toggleNightVision", function(data, cb)
    CBSFunction_ToggleNightVision(data.state)
    cb({ success = true })
end)


RegisterNUICallback("toggleThermalVision", function(data, cb)
    CBSFunction_ToggleThermalVision(data.state)
    cb({ success = true })
end)


RegisterNUICallback("toggleFreeAimMode", function(data, cb)
    CBSFunction_ToggleFreeAimMode(data.state)
    cb({ success = true })
end)


RegisterNUICallback("toggleEntityOutline", function(data, cb)
    CBSFunction_ToggleEntityOutline(data.state)
    cb({ success = true })
end)


RegisterNUICallback("toggleTimeFreeze", function(data, cb)
    CBSFunction_ToggleTimeFreeze(data.state)
    cb({ success = true })
end)


RegisterNUICallback("toggleWeatherLock", function(data, cb)
    CBS_WeatherLockActive = data.state
    cb({ success = true })
end)


RegisterNUICallback("setWeather", function(data, cb)
    CBSFunction_SetWeather(data.weather)
    cb({ success = true })
end)


RegisterNUICallback("setTime", function(data, cb)
    CBSFunction_SetTime(data.hour, data.minute)
    cb({ success = true })
end)


RegisterNUICallback("spawnVehicle", function(data, cb)
    CBSFunction_SpawnVehicle(data.model)
    cb({ success = true })
end)


RegisterNUICallback("spawnPed", function(data, cb)
    CBSFunction_SpawnPed(data.model)
    cb({ success = true })
end)


RegisterNUICallback("spawnObject", function(data, cb)
    CBSFunction_SpawnObject(data.model)
    cb({ success = true })
end)


RegisterNUICallback("deleteEntity", function(data, cb)
    CBSFunction_DeleteClosestEntity()
    cb({ success = true })
end)


RegisterNUICallback("cleanupEntities", function(data, cb)
    CBSFunction_CleanupEntities()
    cb({ success = true })
end)


RegisterNUICallback("teleportWaypoint", function(data, cb)
    CBSFunction_TeleportToWaypoint()
    cb({ success = true })
end)


RegisterNUICallback("teleportCoords", function(data, cb)
    CBSFunction_TeleportToCoords(
        tonumber(data.x) or 0.0,
        tonumber(data.y) or 0.0,
        tonumber(data.z) or 0.0
    )
    cb({ success = true })
end)


RegisterNUICallback("repairVehicle", function(data, cb)
    CBSFunction_RepairVehicle()
    cb({ success = true })
end)


RegisterNUICallback("deleteVehicle", function(data, cb)
    CBSFunction_DeleteCurrentVehicle()
    cb({ success = true })
end)


RegisterNUICallback("healPlayer", function(data, cb)
    CBSFunction_HealPlayer()
    cb({ success = true })
end)


RegisterNUICallback("revivePlayer", function(data, cb)
    CBSFunction_RevivePlayer()
    cb({ success = true })
end)


RegisterNUICallback("freeaimDeleteEntity", function(data, cb)
    if CBS_LastAimedEntity and DoesEntityExist(CBS_LastAimedEntity) then
        SetEntityAsMissionEntity(CBS_LastAimedEntity, true, true)
        DeleteEntity(CBS_LastAimedEntity)
        CBSFunction_SendNotification("~g~CBS~s~: Entity deleted")
        SendNUIMessage({ action = "clearEntityInfo" })
        CBS_LastAimedEntity = nil
    else
        CBSFunction_SendNotification("~r~CBS~s~: No aimed entity")
    end
    cb({ success = true })
end)


RegisterNUICallback("freeaimFreezeEntity", function(data, cb)
    if CBS_LastAimedEntity and DoesEntityExist(CBS_LastAimedEntity) then
        if CBS_FrozenEntities[CBS_LastAimedEntity] then
            CBS_FrozenEntities[CBS_LastAimedEntity] = false
            FreezeEntityPosition(CBS_LastAimedEntity, false)
            CBSFunction_SendNotification("~g~CBS~s~: Entity unfrozen")
        else
            CBS_FrozenEntities[CBS_LastAimedEntity] = true
            FreezeEntityPosition(CBS_LastAimedEntity, true)
            CBSFunction_SendNotification("~g~CBS~s~: Entity frozen")
        end
    else
        CBSFunction_SendNotification("~r~CBS~s~: No aimed entity")
    end
    cb({ success = true })
end)


RegisterNUICallback("freeaimCopyCoords", function(data, cb)
    if CBS_LastAimedEntity and DoesEntityExist(CBS_LastAimedEntity) then
        local ec = GetEntityCoords(CBS_LastAimedEntity)
        local eh = GetEntityHeading(CBS_LastAimedEntity)
        local formatted = string.format("vector4(%.4f, %.4f, %.4f, %.4f)", ec.x, ec.y, ec.z, eh)
        CBSFunction_CopyToClipboard(formatted)
    else
        CBSFunction_SendNotification("~r~CBS~s~: No aimed entity")
    end
    cb({ success = true })
end)


Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local ped = PlayerPedId()

        if CBS_InfiniteStaminaActive then
            RestorePlayerStamina(PlayerId(), 1.0)
        end

        if CBS_SuperJumpActive then
            SetSuperJumpThisFrame(PlayerId())
        end

        if CBS_SpeedBoostActive and IsControlPressed(0, 21) then
            local fv = GetEntityForwardVector(ped)
            SetEntityVelocity(ped, fv.x * 5.0, fv.y * 5.0, fv.z * 5.0)
        end

        if CBS_NoClipActive then
            local camRot = GetGameplayCamRot(2)
            local camFor = CBSFunction_RotationToDirection(camRot)
            local c = GetEntityCoords(ped)
            local spd = CBS_NoClipSpeed
            DisableControlAction(0, 32, true)
            DisableControlAction(0, 33, true)
            DisableControlAction(0, 34, true)
            DisableControlAction(0, 35, true)
            DisableControlAction(0, 44, true)
            DisableControlAction(0, 46, true)
            DisableControlAction(0, 21, true)
            if IsDisabledControlPressed(0, 21) then spd = spd * 3.0 end
            if IsDisabledControlPressed(0, 32) then c = c + camFor * spd end
            if IsDisabledControlPressed(0, 33) then c = c - camFor * spd end
            if IsDisabledControlPressed(0, 34) then c = c + vector3(-camFor.y, camFor.x, 0.0) * spd end
            if IsDisabledControlPressed(0, 35) then c = c + vector3(camFor.y, -camFor.x, 0.0) * spd end
            if IsDisabledControlPressed(0, 44) then c = c + vector3(0.0, 0.0, spd) end
            if IsDisabledControlPressed(0, 46) then c = c - vector3(0.0, 0.0, spd) end
            SetEntityCoordsNoOffset(ped, c.x, c.y, c.z, false, false, false)
            SetEntityHeading(ped, camRot.z)
        end

        if CBS_TimeFreezeActive then
            NetworkOverrideClockTime(CBS_LockedTime.hour, CBS_LockedTime.minute, 0)
        end

        if CBS_WeatherLockActive then
            SetWeatherTypeNowPersist(CBS_LockedWeather)
        end

        if CBS_ShowCoordsActive then
            local c = GetEntityCoords(ped)
            local h = GetEntityHeading(ped)
            CBSFunction_DrawText2D(0.01, 0.45, string.format("X: %.4f", c.x))
            CBSFunction_DrawText2D(0.01, 0.48, string.format("Y: %.4f", c.y))
            CBSFunction_DrawText2D(0.01, 0.51, string.format("Z: %.4f", c.z))
            CBSFunction_DrawText2D(0.01, 0.54, string.format("H: %.4f", h))
        end

        if CBS_FreeAimModeActive and not CBS_IsOpen then
            local currentRenderingCam = false
            if not IsGameplayCamRendering() then
                currentRenderingCam = GetRenderingCam()
            end

            local camRot = not currentRenderingCam and GetGameplayCamRot() or GetCamRot(currentRenderingCam, 2)
            local camC = not currentRenderingCam and GetGameplayCamCoord() or GetCamCoord(currentRenderingCam)
            local camD = CBSFunction_RotationToDirection(camRot)
            local endPoint = vector3(camC.x + camD.x * 100.0, camC.y + camD.y * 100.0, camC.z + camD.z * 100.0)

            local rh = StartShapeTestRay(camC.x, camC.y, camC.z, endPoint.x, endPoint.y, endPoint.z, -1, ped, 0)
            local retval, didHit, hitCoords, surfaceNormal, entityHit = GetShapeTestResult(rh)

            local pedCoords = GetEntityCoords(ped)
            DrawLine(pedCoords.x, pedCoords.y, pedCoords.z, hitCoords.x, hitCoords.y, hitCoords.z, 255, 50, 50, 180)
            DrawMarker(28, hitCoords.x, hitCoords.y, hitCoords.z, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.1, 0.1, 0.1, 255, 50, 50, 180, false, true, 2, nil, nil, false, false)

            if didHit and entityHit and entityHit ~= 0 and DoesEntityExist(entityHit) then
                if IsEntityAVehicle(entityHit) or IsEntityAPed(entityHit) or IsEntityAnObject(entityHit) then
                    CBS_LastAimedEntity = entityHit

                    CBSFunction_DrawEntityBoundingBox(entityHit)

                    local info = CBSFunction_GetEntityInfo(entityHit)
                    if info then
                        if CBS_EntityOutlineActive then
                            SetEntityDrawOutline(entityHit, true)
                            SetEntityDrawOutlineColor(255, 50, 50, 200)
                            SetEntityDrawOutlineShader(1)
                        end

                        local netId = nil
                        if NetworkGetEntityIsNetworked(entityHit) then
                            netId = NetworkGetNetworkIdFromEntity(entityHit)
                        end

                        SendNUIMessage({
                            action = "updateEntityInfo",
                            info = {
                                type = info.type,
                                model = info.model,
                                entityId = entityHit,
                                netId = netId,
                                health = info.health,
                                maxHealth = info.maxHealth,
                                speed = info.speed,
                                distance = info.distance,
                                heading = info.heading,
                                coords = info.coords,
                                owner = GetPlayerServerId(NetworkGetEntityOwner(entityHit))
                            }
                        })

                        if IsControlJustReleased(0, 38) then
                            SetEntityAsMissionEntity(entityHit, true, true)
                            DeleteEntity(entityHit)
                            if not DoesEntityExist(entityHit) then
                                CBSFunction_SendNotification("~g~CBS~s~: Entity deleted")
                            end
                            SendNUIMessage({ action = "clearEntityInfo" })
                            CBS_LastAimedEntity = nil
                        end

                        if IsControlJustReleased(0, 47) then
                            if CBS_FrozenEntities[entityHit] then
                                CBS_FrozenEntities[entityHit] = false
                                FreezeEntityPosition(entityHit, false)
                                CBSFunction_SendNotification("~g~CBS~s~: Entity unfrozen")
                            else
                                CBS_FrozenEntities[entityHit] = true
                                FreezeEntityPosition(entityHit, true)
                                CBSFunction_SendNotification("~g~CBS~s~: Entity frozen")
                            end
                        end

                        if IsControlJustReleased(0, 74) then
                            local ec = GetEntityCoords(entityHit)
                            local eh = GetEntityHeading(entityHit)
                            local formatted = string.format("vector4(%.4f, %.4f, %.4f, %.4f)", ec.x, ec.y, ec.z, eh)
                            CBSFunction_CopyToClipboard(formatted)
                        end
                    end
                else
                    if CBS_LastAimedEntity then
                        CBS_LastAimedEntity = nil
                        SendNUIMessage({ action = "clearEntityInfo" })
                    end
                end
            else
                if CBS_LastAimedEntity then
                    CBS_LastAimedEntity = nil
                    SendNUIMessage({ action = "clearEntityInfo" })
                end
            end
        else
            if not CBS_FreeAimModeActive and CBS_LastAimedEntity then
                CBS_LastAimedEntity = nil
                SendNUIMessage({ action = "clearEntityInfo" })
            end
        end

        if CBS_VehicleGodModeActive then
            local veh = GetVehiclePedIsIn(ped, false)
            if veh and veh ~= 0 then SetEntityInvincible(veh, true) end
        end

        if CBS_NoRagdollActive then
            SetPedCanRagdoll(ped, false)
            SetPedCanRagdollFromPlayerImpact(ped, false)
        end

        if CBS_IsOpen then
            DisableControlAction(0, 142, true)
            DisableControlAction(0, 18, true)
            DisableControlAction(0, 322, true)
            DisableControlAction(0, 106, true)
        end
    end
end)


Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)
        if CBS_IsOpen then
            local ped = PlayerPedId()
            local c = GetEntityCoords(ped)
            local h = GetEntityHeading(ped)
            SendNUIMessage({
                action = "updateCoords",
                coords = {
                    x = CBSFunction_RoundNumber(c.x, 4),
                    y = CBSFunction_RoundNumber(c.y, 4),
                    z = CBSFunction_RoundNumber(c.z, 4)
                },
                heading = CBSFunction_RoundNumber(h, 4)
            })
        end
    end
end)