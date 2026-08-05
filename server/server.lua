local CBS_AllowedIdentifiers = {
    "discord:1059878670740758610", -- your discord acces or steam
}


---@param source number
---@return boolean
function CBSFunction_CheckPlayerAccess(source)
    if not CBS_AllowedIdentifiers then return false end
    local identifiers = GetPlayerIdentifiers(source)
    if not identifiers then return false end
             for i = 1, #identifiers do
        for j = 1, #CBS_AllowedIdentifiers do
                      if identifiers[i] == CBS_AllowedIdentifiers[j] then
                return true
            end
        end
    end
    return false
end


---@param source number
---@param message string
---@return nil
function CBSFunction_LogAction(source, message)
    local playerName = GetPlayerName(source) or "Unknown"
    print(string.format("^1[CBS DEV TOOL]^0 %s (ID: %d): %s", playerName, source, message))
end


RegisterNetEvent("Cbs-devtool:server:checkAccess")
AddEventHandler("Cbs-devtool:server:checkAccess", function()
    local src = source
    local hasAccess = CBSFunction_CheckPlayerAccess(src)
    TriggerClientEvent("Cbs-devtool:client:accessResponse", src, hasAccess)
    if hasAccess then
        CBSFunction_LogAction(src, "done")
    else
        CBSFunction_LogAction(src, "noaccess")
    end
end)


RegisterNetEvent("Cbs-devtool:server:log")
AddEventHandler("Cbs-devtool:server:log", function(action)
              local src = source
        CBSFunction_LogAction(src, action)
end)