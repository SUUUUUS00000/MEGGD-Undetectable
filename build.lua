local readfile = readfile
local writefile = writefile
local isfile = isfile
local crypt = crypt

local function resolveModulePath(baseName)
    if isfile("src/" .. baseName .. ".luau") then
        return "src/" .. baseName .. ".luau"
    elseif isfile("src/" .. baseName .. ".lua") then
        return "src/" .. baseName .. ".lua"
    end
    return nil
end

local function bundleModules()
    local envPath = resolveModulePath("env")
    local runnerPath = resolveModulePath("runner")
    local cryptoPath = resolveModulePath("crypto")

    if not envPath or not runnerPath or not cryptoPath then
        return nil, "Missing core files in src/ folder"
    end

    local envCode = readfile(envPath)
    local runnerCode = readfile(runnerPath)
    local cryptoCode = readfile(cryptoPath)

    local bundle = [[
local cloneref = cloneref or function(obj) return obj end
local gethui = gethui or function() return game:GetService("CoreGui") end
local newcclosure = newcclosure or function(fn) return fn end
local request = request or http_request or (http and http.request)

local createEnvironment = (function()
]] .. envCode .. [[
end)()

local executeScript = (function()
]] .. runnerCode .. [[
end)()

local Crypto = (function()
]] .. cryptoCode .. [[
end)()

local Sandbox = {}
Sandbox.__index = Sandbox

function Sandbox.new(baseGlobals)
    local self = setmetatable({}, Sandbox)
    self.baseGlobals = baseGlobals or {}
    return self
end

function Sandbox:protectGui(guiInstance)
    if typeof(guiInstance) == "Instance" then
        guiInstance.Parent = gethui()
        return guiInstance
    end
    return nil
end

function Sandbox:execute(source, extraGlobals, chunkName)
    local mergedGlobals = {}
    for k, v in pairs(self.baseGlobals) do
        mergedGlobals[k] = v
    end
    if extraGlobals then
        for k, v in pairs(extraGlobals) do
            mergedGlobals[k] = v
        end
    end
    mergedGlobals.protectGui = newcclosure(function(gui)
        return self:protectGui(gui)
    end)
    local env = createEnvironment(mergedGlobals)
    return executeScript(source, env, chunkName or "")
end

function Sandbox.run(source, extraGlobals, chunkName)
    local defaultInstance = Sandbox.new()
    return defaultInstance:execute(source, extraGlobals, chunkName)
end

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

    local rawCode, decryptErr = Crypto.decryptPayload(
        encryptedPayload,
        config.key,
        config.iv,
        config.hash
    )

    encryptedPayload = nil

    if not rawCode then
        return false, decryptErr
    end

    local runSuccess, runErr = Sandbox.run(rawCode, config.extraGlobals or {}, config.chunkName or "")
    rawCode = nil
    return runSuccess, runErr
end

return executeRemoteEncrypted
]]
    return bundle
end

local function buildProject()
    if not crypt or not crypt.encrypt or not crypt.generatekey then
        print("Error: Executor lacks UNC crypt support")
        return
    end

    if not isfile("input.lua") then
        writefile("input.lua", 'print("Hello from fully encrypted sandbox!")')
        print("Created input.lua template. Put your script inside input.lua and run build again.")
        return
    end

    local targetSource = readfile("input.lua")

    local key = crypt.generatekey()
    local iv = crypt.generatebytes(16)
    local encryptedData = crypt.encrypt(targetSource, key, iv, "CBC")
    local contentHash = crypt.hash(targetSource, "sha256")

    writefile("payload.enc", encryptedData)
    print("Successfully generated payload.enc")

    local bundledLoader, bundleErr = bundleModules()
    if not bundledLoader then
        print("Bundle Error: " .. tostring(bundleErr))
        return
    end

    writefile("loader.lua", bundledLoader)
    print("Successfully generated standalone loader.lua")

    print(":: MEGGD-Undetectable ::")
    print("Secret Keys:")
    print("KEY: " .. key)
    print("IV:  " .. iv)
    print("HASH: " .. contentHash)
    print(":: MEGGD-Undetectable ::")
    print("Run Command:")
    print([[
local runLoader = loadstring(game:HttpGet("https://raw.githubusercontent.com/SUUUUUS00000/MEGGD-Undetectable/main/loader.lua"))()

runLoader({
    payloadUrl = "https://raw.githubusercontent.com/SUUUUUS00000/MEGGD-Undetectable/main/payload.enc",
    key = "]] .. key .. [[",
    iv = "]] .. iv .. [[",
    hash = "]] .. contentHash .. [[",
    chunkName = "sys_runtime"
})
]])
    print(":: MEGGD-Undetectable ::")
end

buildProject()
