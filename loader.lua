local request = request or http_request or (http and http.request)
local cloneref = cloneref or function(obj) return obj end

local function httpGetSafe(url)
    if request then
        local response = request({
            Url = url,
            Method = "GET",
            Headers = {
                ["User-Agent"] = "Roblox/WinInet"
            }
        })
        if response and response.Success and response.Body then
            return response.Body
        end
    end
    
    local httpService = cloneref(game:GetService("HttpService"))
    local ok, res = pcall(function()
        return game:HttpGet(url)
    end)
    if ok then
        return res
    end
    
    return nil
end

local function executeRemoteEncrypted(config)
    local encryptedPayload = httpGetSafe(config.payloadUrl)
    if not encryptedPayload then
        return false, "Failed to retrieve payload"
    end

    local cryptoModule = config.crypto or (loadfile and loadfile("src/crypto.luau")())
    local sandboxModule = config.sandbox or (loadfile and loadfile("src/init.luau")())

    if not cryptoModule or not sandboxModule then
        return false, "Core modules are missing"
    end

    local rawCode, decryptErr = cryptoModule.decryptPayload(
        encryptedPayload,
        config.key,
        config.iv,
        config.hash
    )

    encryptedPayload = nil

    if not rawCode then
        return false, decryptErr
    end

    local runSuccess, runErr = sandboxModule.run(rawCode, config.extraGlobals or {}, config.chunkName or "")

    rawCode = nil

    return runSuccess, runErr
end

return executeRemoteEncrypted
