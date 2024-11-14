ESX = nil
QBCore = nil

if Framework == 'ESX' then
    ESX = exports['es_extended']:getSharedObject()
elseif Framework == 'QB' then
    QBCore = exports['qb-core']:GetCoreObject()
end

local resourceName = GetCurrentResourceName()

local currentLine = "BRDG>SRVR>FRAME #"

SS_Core = {

    Notification = function(src, data)
        if Config.Notification.enable then
            if Framework == 'ESX' then
                TriggerClientEvent('esx:showNotification', src, data.message)
            elseif Framework == 'QB' then
                TriggerClientEvent('QBCore:Notify', src, data.message)
            end
        else
            TriggerClientEvent('ss-knowledge:bridge:utilities:notification', src, data)
        end
    end,

    RegisterCallback = function(name, cb)
        SS_Log("debug", "^4RegisterCallback ^0[^3"..name.."^0]", resourceName, currentLine.."29")
        if Framework == 'ESX' then
            ESX.RegisterServerCallback(name, cb)
        elseif Framework == 'QB' then
            QBCore.Functions.CreateCallback(name, cb)
        end
    end,
}

SS_Core.Player = {

    GetSource = function(src)
        local xPlayer = SS_Core.Player.GetFromId(tonumber(src))
        while xPlayer == nil do
            Wait(500)
            xPlayer = SS_Core.Player.GetFromId(tonumber(src))
        end
        SS_Log("id_debug", "^4Server Side - GetSource ^0[^3"..tonumber(src).."^0]", resourceName, currentLine.."46")
        if Framework == 'ESX' then
            return xPlayer.source
        elseif Framework == 'QB' then
            return xPlayer.PlayerData.source
        end
    end,

    GetFromId = function(src)
        SS_Log("id_debug", "^4Server Side - GetFromId ^0[^3"..(src).."^0]", resourceName, currentLine.."55")
        if Framework == 'ESX' then
            return ESX.GetPlayerFromId(src)
        elseif Framework == 'QB' then
            return QBCore.Functions.GetPlayer(src)
        end
    end,

    GetIdentifier = function(src)
        SS_Log("id_debug", "^4Server Side - GetIdentifier ^0[^3"..tonumber(src).."^0]", resourceName, currentLine.."64")
        local Player = SS_Core.Player.GetFromId(tonumber(src))
        if Player == nil then return end
        if Framework == 'ESX' then
            return Player.identifier
        elseif Framework == 'QB' then
            return Player.PlayerData.citizenid
        end
    end,

    GetCitizenName = function(src)
        SS_Log("id_debug", "^4Server Side - GetCitizenName ^0[^3"..tonumber(src).."^0]", resourceName, currentLine.."75")
        local Player = SS_Core.Player.GetFromId(tonumber(src))
        if Framework == 'ESX' then
            return Player.getName()
        elseif Framework == 'QB' then
            return Player.PlayerData.charinfo.firstname.. " "..Player.PlayerData.charinfo.lastname
        end
    end,
    IsAdmin = function(src)
        local permissions = Config.AdminOptions.ranks
        SS_Log("debug", "^4Admin command ranks^0] ^3"..tostring(json.encode(permissions)).."^0", resourceName, currentLine.."85")
        for k,v in pairs(permissions) do
            if IsPlayerAceAllowed(src, v) then
                SS_Log("debug", "^4Command perm granted to ^0[^3"..src.."^0] ^4Perm level^0 [^3"..v.."^0", resourceName, currentLine.."88")
                return true
            end
        end
        return false
    end,
}

SS_Core.RegisterCallback("ss-knowledge:server:fetchBranches", function(source, cb, otherID)
    local branches = {}
    if otherID == nil then
        branches = FetchDBBranches(source)
    else
        branches = FetchDBBranches(otherID)
    end
    SS_Log("debug", "^4Fetch Branches^0] [^3"..json.encode(branches, {indent = true}).."^0", resourceName, currentLine.."103")
    cb(branches)
end)

SS_Core.RegisterCallback("ss-knowledge:server:CheckAdminCommands", function(source, cb)
    cb(SS_Core.Player.IsAdmin(source))
end)

SS_Core.RegisterCallback("ss-knowledge:server:getPlayerName", function(source, cb, oID)
    local name = nil
    if oID == nil then
        name = SS_Core.Player.GetCitizenName(source)
    else
        name = SS_Core.Player.GetCitizenName(oID)
    end
    cb(tostring(name.." ["..(oID or source).."]"))
end)