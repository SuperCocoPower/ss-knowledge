local colorCodes = {
    error = "^1ERROR^0",
    debug = "^3DEBUG^0",
    warn = "^5WARN^0",
    info = "^2INFO^0",
    success = "^2SUCCESS^0",
    id_debug = "^3ID DEBUG^0",
}

SS_Log = function(warntype, message, asset, isClient, location, ...)
    local timestamp, logFormat, extraInfo = nil, nil, ""
    if not colorCodes[warntype] then
        warntype = "info"
    end
    if (warntype == "id_debug" and not (Config.Debug.enable and Config.Debug.idType)) or (warntype == "debug" and not Config.Debug.enable) then
        return
    end
    if os and type(os.date) == "function" then
        timestamp = os.date("^6%H:%M:%S^0] [^6%d-%m-%Y")
        logFormat = "^0["..timestamp.."^0] [^5Sky's Scripts^0] [^3"..asset.."^0] ["..colorCodes[warntype].."^0]\n[^3"..message.."^0]"
    else
        logFormat = "[^5Sky's Scripts^0] [^3"..asset.."^0] [^3"..colorCodes[warntype].."^0]\n[^3"..message.."^0]"
    end
    if (warntype == "debug" or warntype == "id_debug") and location then
        extraInfo = " [^3"..location.."^0]"
    end
    if ... then
        extraInfo = extraInfo.." [^3%s^0]"
    end
    local formattedMessage = string.format(logFormat..extraInfo, table.concat({...}, ", ") or "")
    print(formattedMessage)
end