local resourceName = GetCurrentResourceName()
local PlayerBranches = {}
local currentLine = "SRVR>MAIN #"

--- @param source integer, The source player ID
--- @returns branches table (via SortBranches function)
FetchDBBranches = function(source)
    SS_Log("debug", "^4FetchDBBranches^0] [^3"..tonumber(source).."^0", resourceName, currentLine.."7")
    local Player = SS_Core.Player.GetIdentifier(source)
    if Player ~= nil then
        local branches = MySQL.scalar.await('SELECT skills FROM '..Config.Triggers[Framework].playerdatabase..' WHERE '..Config.Triggers[Framework].playerid..' = ?', {Player})
        if branches == nil or branches == "NULL" then
            branches = SetupBranches()
            UpdateDBBranches(source, json.encode(branches))
            return SortBranches(Player,branches)
        elseif branches ~= nil then
            if string.len(branches) > 3 then
                return SortBranches(Player,json.decode(branches))
            end
        end
    end
end

--- @param Player integer, Player Identifier
--- @param data table, The branches table to be sorted
--- @returns sortedBranches table
SortBranches = function(Player,data)
    local sortedBranches = {}
    if data ~= nil then
        for branch, value in pairs(data) do
            local str = string.lower(branch)
            str = str:gsub("%s+", "")
            if Config.Branches[str] ~= nil then
                if Config.Branches[str].enable then
                    local xp = value
                    if type(xp) == "table" then
                        xp = tonumber(value.Current)
                    end
                    SS_Log("debug","^4SortBranch branch^0] [^3"..str.."^0] [^3"..json.encode(xp).."^0", resourceName, currentLine.."36")
                    sortedBranches[str] = xp
                end
            else
                SS_Log("debug","^4SortBranch^0] [^3branch name - "..str.."^0", resourceName, currentLine.."40")
                SS_Log("warn","^4SortBranch^0] [^3Please add this branch to config and restart^0] [^1branch name - "..str.."^0", resourceName, currentLine.."41")
            end
        end
        for branch, _ in pairs(Config.Branches) do
            if sortedBranches[branch] == nil and Config.Branches[branch].enable then
                sortedBranches[branch] = 0
            end
        end
    end

    if PlayerBranches[Player] and next(PlayerBranches[Player]) then
        PlayerBranches[Player] = {}
    end
    PlayerBranches[Player] = sortedBranches
    return sortedBranches
end

--- @returns sortedBranches, table A table containing the sorted branches
SetupBranches = function()
    local sortedBranches = {}
	for branch, _ in pairs(Config.Branches) do
		sortedBranches[branch] = 0
	end
    SS_Log("debug","^0[^4SetupBranches Branch Table^0] [^3 "..json.encode(sortedBranches), resourceName, currentLine.."53")
	return sortedBranches
end


AddEventHandler('onResourceStart', function(resource)
	if resource == resourceName then
        SS_Utils.VersionCheck("ss_knowledge","skys-scripts/ss_knowledge",false)
        SS_Utils.CheckForDBColumn(Config.Triggers[Framework].playerdatabase,"skills")
	end
end)

CheckArgs = function(id,branch,functionName)
    if id == nil or id == 0 then
        SS_Log("error", "^4"..functionName.."^0] [^3ID is invalid^0", resourceName)
        return false
    elseif branch == nil and type(branch) ~= "string" then
        SS_Log("error", "^4"..functionName.."^0] [^3Branch is invalid^0", resourceName)
        return false
    else
        SS_Log("debug","^4"..functionName.."^0] [^3ID = "..id.."^0] [^3Branch = "..tostring(branch).."^0", resourceName, currentLine.."92")
    end
    local playerId = tonumber(id)
    if playerId == nil then
        SS_Log("error", "^4"..functionName.."^0] [^3ID is not a number^0", resourceName)
        return false
    end
    local playerIdentifier = SS_Core.Player.GetIdentifier(playerId)
    if playerIdentifier == nil then
        SS_Log("error", "^4"..functionName.."^0] [^3Player identifier not found^0", resourceName)
        return false
    end
    if Config.Branches[branch] == nil then
        SS_Log("error", "^4"..functionName.."^0] [^3Branch does not exist in config^0", resourceName)
        return false
    end
    return true, playerIdentifier
end

--- @param ID integer, The player ID
--- @param data string, Full branches table to be pushed into the database.
UpdateDBBranches = function(ID,data)
    local PID = SS_Core.Player.GetIdentifier(ID)
    MySQL.query('UPDATE '..Config.Triggers[Framework].playerdatabase..' SET skills = @branches WHERE '..Config.Triggers[Framework].playerid..' = @id', { --It is set to a branch column to not cause conflictions with mz/ b1/ cw xp branch systems.
        ['@branches'] = data,
        ['@id'] = PID
    })
end

--- @param data table, Full branches table
--- @param otherID integer, The other player ID if nil implies the ID is the player that triggered net event.
RegisterNetEvent('ss-knowledge:server:updateBranches', function (data, otherID)
    if otherID == nil then
        UpdateDBBranches(source, tostring(data))
    else
        UpdateDBBranches(otherID, tostring(data))
        TriggerClientEvent("ss-knowledge:client:updateBranchesCommand", otherID)
    end
end)

--- @param data table email data table
--- @param data.subject string, the subject of the email
--- @param data.message string, the message of the email
--- @param returns boolean (true if mail was sent, false if mail was not sent) and string (the id of the mail or the error message)
RegisterNetEvent("ss-knowledge:server:lb-phone:sendMail", function(data)
    local phoneNumber = exports["lb-phone"]:GetEquippedPhoneNumber(source) -- phonenumber from source

    local playerMail = exports["lb-phone"]:GetEmailAddress(phoneNumber) -- mail from phonenumber
    local success, id = exports["lb-phone"]:SendMail({
        to = playerMail,
        subject = data.subject,
        message = data.message,
        attachments = {
        },
        actions = {
        }
    })
end)

-- Export functions

--- @param id number The player ID
--- @param branch string The branch to get knowledge for
GetKnowledgeBranchByServer = function(id, branch)
    local check, playerIdentifier = CheckArgs(id,branch,"GetKnowledgeBranchByServer")
    if not check then
        return
    end
    if PlayerBranches[playerIdentifier] ~= nil then
    local tier = 0
    local currentBranch = PlayerBranches[playerIdentifier][branch]
    local tiers =  Config.Branches[branch].customLevels or Config.DefaultLevels
    local tierLimits = tiers[1]
    for _, branchData in ipairs(tiers) do
        if currentBranch > branchData.minxp and currentBranch <= branchData.maxxp then
            if branchData.title then
                return branchData.title, branchData
            end
            return tier, branchData
        end
        if currentBranch > branchData.maxxp then
            tier = tier+1
            tierLimits = branchData
        end
    end
    if #tiers == tier then
        tier = #tiers
    end
    if tierLimits.title then
        return tierLimits.title, tierLimits
    end
    return tier, tierLimits
    end
end
exports("GetKnowledgeBranchByServer", GetKnowledgeBranchByServer)

--- @param id number The player ID
--- @param branch string which branch you wish to check
GetBranchTierByServer = function(id, branch)
    local check, playerIdentifier = CheckArgs(id,branch,"GetBranchTierByServer")
    if not check then
        return
    end
    local tier = 1
    local tiers =  Config.Branches[branch].customLevels or Config.DefaultLevels
    local currentBranch = PlayerBranches[playerIdentifier][branch]
    for Tier, branchData in ipairs(tiers) do
        if currentBranch >= branchData.minxp and currentBranch < branchData.maxxp then
            return Tier
        end
        if currentBranch > branchData.maxxp then
            tier = tier+1
        end
        if #tiers == tier then
            tier = #tiers
            return tier
        end
    end
end
exports('GetBranchTierByServer', GetBranchTierByServer)

--- @param id number The player ID
--- @param branch string which branch you wish to check.
--- @param amount integer the amount of xp you wish to check against.
CheckKnowledgeTierByServer = function(id,branch,amount)
    local check, playerIdentifier = CheckArgs(id,branch,"CheckKnowledgeTierByServer")
    if not check then
        return
    end
    if PlayerBranches[playerIdentifier][branch] then
        if GetBranchTierByServer(PlayerBranches[playerIdentifier][branch],branch) >= amount then
            return true
        else
            return false
        end
    else
        SS_Log("warn","^4"..Lang['branch_doesnt_exist']:format(branch).."^0", resourceName, currentLine.."174")
        return false
    end
end
exports('CheckKnowledgeTierByServer', CheckKnowledgeTierByServer)

--- @param id number The player ID
--- @param branch string which branch you wish to check.
--- @param amount integer the amount of xp you wish to check against.
CheckKnowledgeBranchByServer = function(id, branch, amount)
    local check, playerIdentifier = CheckArgs(id,branch,"CheckKnowledgeBranchByServer")
    if not check then
        return
    end
    if PlayerBranches[playerIdentifier][branch] then
        if PlayerBranches[playerIdentifier][branch] >= tonumber(amount) then
            return true
        else
            return false
        end
    else
        SS_Log("warn","^4"..Lang['branch_doesnt_exist']:format(branch).."^0", resourceName, currentLine.."160")
        return false
    end
end
exports('CheckKnowledgeBranchByServer', CheckKnowledgeBranchByServer)


--- @param id number The player ID
--- @param branch string which branch you wish to check.
--- @param amount integer the amount of xp you wish to check against.
UpdateKnowledgeBranchByServer = function(id, branch, amount)
    local check, _ = CheckArgs(id,branch,"UpdateKnowledgeBranchByServer")
    if not check then
        return
    end
    TriggerClientEvent("ss-knowledge:client:updateBranches", id, branch, amount)
end
exports('UpdateKnowledgeBranchByServer', UpdateKnowledgeBranchByServer)