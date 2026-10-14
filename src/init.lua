local cloneref = cloneref or function(obj) return obj end
local gethui = gethui or function() return game:GetService("CoreGui") end
local newcclosure = newcclosure or function(fn) return fn end

local function loadModule(path)
    if loadfile then
        local chunk, err = loadfile(path)
        if chunk then
            return chunk()
        end
    end
    if readfile and loadstring then
        local content = readfile(path)
        local chunk = loadstring(content)
        if chunk then
            return chunk()
        end
    end
    return nil
end

local createEnvironment = loadModule("src/env.luau")
local executeScript = loadModule("src/runner.luau")

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

return Sandbox
