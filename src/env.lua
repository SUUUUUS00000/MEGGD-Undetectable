local cloneref = cloneref or function(obj) return obj end
local gethui = gethui or function() return game:GetService("CoreGui") end
local newcclosure = newcclosure or function(fn) return fn end

local function createEnvironment(customGlobals)
    customGlobals = customGlobals or {}

    local localGlobalStorage = {}
    local sandboxed_G = {}
    local sandboxed_shared = {}

    local safeGame = cloneref(game)
    local safeWorkspace = cloneref(workspace)

    local env = {}

    local whitelist = {
        print = print,
        warn = warn,
        error = error,
        assert = assert,
        type = type,
        typeof = typeof,
        tostring = tostring,
        tonumber = tonumber,
        pcall = pcall,
        xpcall = xpcall,
        select = select,
        next = next,
        pairs = pairs,
        ipairs = ipairs,
        unpack = table.unpack or unpack,
        setmetatable = setmetatable,
        getmetatable = getmetatable,
        rawget = rawget,
        rawset = rawset,
        rawequal = rawequal,
        rawlen = rawlen,
        loadstring = loadstring,

        string = table.clone(string),
        table = table.clone(table),
        math = table.clone(math),
        os = table.clone(os),
        task = table.clone(task),
        coroutine = table.clone(coroutine),
        debug = table.clone(debug),
        utf8 = table.clone(utf8),
        bit32 = table.clone(bit32),

        Instance = Instance,
        Enum = Enum,

        Vector3 = Vector3,
        Vector2 = Vector2,
        CFrame = CFrame,
        Color3 = Color3,
        UDim = UDim,
        UDim2 = UDim2,
        Ray = Ray,
        Region3 = Region3,
        Rect = Rect,
        TweenInfo = TweenInfo,
        Axes = Axes,
        Faces = Faces,
        PhysicalProperties = PhysicalProperties,
        DateTime = DateTime,
        ColorSequence = ColorSequence,
        ColorSequenceKeypoint = ColorSequenceKeypoint,
        NumberSequence = NumberSequence,
        NumberSequenceKeypoint = NumberSequenceKeypoint,
        NumberRange = NumberRange,
        Font = Font,

        game = safeGame,
        workspace = safeWorkspace,
        Workspace = safeWorkspace,
        
        _G = sandboxed_G,
        shared = sandboxed_shared,

        cloneref = cloneref,
        gethui = gethui,
    }

    for key, value in pairs(whitelist) do
        env[key] = value
    end

    for key, value in pairs(customGlobals) do
        env[key] = value
    end

    env._ENV = env

    local envMetatable = {
        __index = newcclosure(function(self, key)
            if localGlobalStorage[key] ~= nil then
                return localGlobalStorage[key]
            end
            return rawget(self, key)
        end),

        __newindex = newcclosure(function(self, key, value)
            localGlobalStorage[key] = value
        end)
    }

    return setmetatable(env, envMetatable)
end

return createEnvironment
