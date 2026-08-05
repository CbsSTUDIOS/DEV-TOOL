local CBS_CurrentVersion = "1.0.0"
local CBS_GithubRepo = "CbsSTUDIOS/DEV-TOOL"


local function CBSFunction_PrintLogo()
    print("")
    print("")
    print("              ^3CBS STUDIO DEV TOOL - DEVELOPER UTILITY^0                ")
    print("")
    print("                   ^5Made by CBS STUDIO^0                         ")
    print("")
    print("")
    print("^1[CBS DEV TOOL]^0 ^3Version:^0 ^2" .. CBS_CurrentVersion .. "^0")
    print("")
end


local function CBSFunction_CompareVersions(currentVer, latestVer)
    local function parseVersion(ver)
        local parts = {}
        for num in string.gmatch(ver, "%d+") do
            table.insert(parts, tonumber(num))
        end
        return parts
    end
    local current = parseVersion(currentVer)
    local latest = parseVersion(latestVer)
    local maxLen = math.max(#current, #latest)
    for i = 1, maxLen do
        local c = current[i] or 0
        local l = latest[i] or 0
        if c < l then
            return -1
        elseif c > l then
            return 1
        end
    end
    return 0
end


local function CBSFunction_CheckVersion()
    local url = "https://raw.githubusercontent.com/" .. CBS_GithubRepo .. "/main/version.txt"
    PerformHttpRequest(url, function(statusCode, responseText, headers)
        if statusCode == 200 and responseText then
            local latestVersion = string.gsub(responseText, "%s+", "")
            local comparison = CBSFunction_CompareVersions(CBS_CurrentVersion, latestVersion)
            if comparison == -1 then
                print("")
                print("                    ^3UPDATE AVAILABLE^0                          ")
                print("")
                print("")
                print("^1[CBS DEV TOOL]^0 ^3Current:^0 ^1" .. CBS_CurrentVersion .. "^0 ^3->^0 ^3Latest:^0 ^2" .. latestVersion .. "^0")
                print("^1[CBS DEV TOOL]^0 ^5https://github.com/" .. CBS_GithubRepo .. "/releases^0")
                print("")
            end
        end
    end, "GET", "", {})
end


Citizen.CreateThread(function()
    Wait(1000)
    CBSFunction_PrintLogo()
    CBSFunction_CheckVersion()
end)
