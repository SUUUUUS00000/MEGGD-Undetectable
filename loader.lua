local cloneref = cloneref or function(obj) return obj end
local gethui = gethui or function() return game:GetService("CoreGui") end
local newcclosure = newcclosure or function(fn) return fn end

local function resolveGlobal(name, fallback)
    if fallback ~= nil then
        return fallback
    end
    local genv = (getgenv and getgenv()) or _G
    if genv and genv[name] ~= nil then
        return genv[name]
    end
    return nil
end

local function createFakeScript()
    local fake = Instance.new("LocalScript")
    fake.Name = "Animate"
    return cloneref(fake)
end

local function freezeTableCopy(original)
    local copy = table.clone(original)
    if table.freeze then
        table.freeze(copy)
    end
    return copy
end

local function createEnvironment(customGlobals)
    customGlobals = customGlobals or {}

    local localGlobalStorage = {}
    local sandboxed_G = {}
    local sandboxed_shared = {}

    local rawGame = cloneref(game)
    local safeWorkspace = cloneref(workspace)
    local virtualScript = createFakeScript()

    local safeGame = newproxy(true)
    local safeGameMt = getmetatable(safeGame)

    safeGameMt.__index = newcclosure(function(self, key)
        if key == "GetService" or key == "FindService" or key == "service" then
            return newcclosure(function(serviceParent, serviceName)
                local serviceObj = rawGame:GetService(tostring(serviceName))
                if serviceObj then
                    return cloneref(serviceObj)
                end
                return nil
            end)
        end
        local prop = rawGame[key]
        if typeof(prop) == "Instance" then
            return cloneref(prop)
        end
        return prop
    end)

    safeGameMt.__namecall = newcclosure(function(self, ...)
        local method = resolveGlobal("getnamecallmethod") and getnamecallmethod()
        local args = {...}
        if method == "GetService" or method == "FindService" or method == "service" then
            local serviceObj = rawGame:GetService(tostring(args[1]))
            if serviceObj then
                return cloneref(serviceObj)
            end
            return nil
        end
        return rawGame[method](rawGame, ...)
    end)

    safeGameMt.__tostring = newcclosure(function()
        return tostring(rawGame)
    end)

    safeGameMt.__metatable = "The metatable is locked"

    local safePrint = newcclosure(function(...)
        local rprint = resolveGlobal("rconsoleprint")
        if rprint then
            local args = {...}
            local out = ""
            for i = 1, #args do
                out = out .. tostring(args[i]) .. (i == #args and "\n" or "\t")
            end
            rprint(out)
        else
            print(...)
        end
    end)

    local safeWarn = newcclosure(function(...)
        local rprint = resolveGlobal("rconsoleprint")
        if rprint then
            local args = {...}
            local out = "[WARN] "
            for i = 1, #args do
                out = out .. tostring(args[i]) .. (i == #args and "\n" or "\t")
            end
            rprint(out)
        else
            warn(...)
        end
    end)

    local safeDebug = table.clone(debug)
    local originalDebugInfo = debug.info

    safeDebug.info = newcclosure(function(target, what)
        if type(target) == "number" and target > 1 then
            target = target + 1
        end
        return originalDebugInfo(target, what)
    end)

    safeDebug.traceback = newcclosure(function(message, level)
        level = (level or 1) + 1
        local tb = debug.traceback(message, level)
        local cleaned = tb:gsub(".-:%d+:%s*", "")
        return cleaned
    end)

    if table.freeze then
        table.freeze(safeDebug)
    end

    local env = {}

    local baseGlobals = {
        print = safePrint,
        warn = safeWarn,
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
        require = newcclosure(function(module)
            local result = require(module)
            if type(result) == "table" then
                return table.clone(result)
            end
            return result
        end),
        _VERSION = _VERSION,
        gcinfo = gcinfo,
        collectgarbage = collectgarbage,

        tick = tick,
        time = time,
        elapsedTime = elapsedTime,
        wait = wait,
        delay = delay,
        spawn = spawn,
        settings = settings,
        UserSettings = UserSettings,
        stats = stats,
        version = version,

        string = freezeTableCopy(string),
        table = freezeTableCopy(table),
        math = freezeTableCopy(math),
        os = freezeTableCopy(os),
        task = freezeTableCopy(task),
        coroutine = freezeTableCopy(coroutine),
        debug = safeDebug,
        utf8 = freezeTableCopy(utf8),
        bit32 = freezeTableCopy(bit32),

        script = virtualScript,

        Instance = Instance,
        Enum = Enum,

        Vector3 = Vector3,
        Vector2 = Vector2,
        Vector3int16 = Vector3int16,
        Vector2int16 = Vector2int16,
        CFrame = CFrame,
        Color3 = Color3,
        UDim = UDim,
        UDim2 = UDim2,
        Ray = Ray,
        Region3 = Region3,
        Region3int16 = Region3int16,
        Rect = Rect,
        TweenInfo = TweenInfo,
        Axes = Axes,
        Faces = Faces,
        PhysicalProperties = PhysicalProperties,
        DateTime = DateTime,
        Random = Random,
        Font = Font,
        Content = Content,
        ColorSequence = ColorSequence,
        ColorSequenceKeypoint = ColorSequenceKeypoint,
        NumberSequence = NumberSequence,
        NumberSequenceKeypoint = NumberSequenceKeypoint,
        NumberRange = NumberRange,
        RaycastParams = RaycastParams,
        OverlapParams = OverlapParams,
        CatalogSearchParams = CatalogSearchParams,
        PathWaypoint = PathWaypoint,
        FloatCurveKey = FloatCurveKey,
        RotationCurveKey = RotationCurveKey,

        game = safeGame,
        workspace = safeWorkspace,
        Workspace = safeWorkspace,

        _G = sandboxed_G,
        shared = sandboxed_shared,

        cloneref = cloneref,
        gethui = gethui,

        checkcaller = resolveGlobal("checkcaller", checkcaller),
        clonefunction = resolveGlobal("clonefunction", clonefunction),
        getcallingscript = newcclosure(function()
            return virtualScript
        end),
        hookfunction = resolveGlobal("hookfunction", hookfunction),
        replaceclosure = resolveGlobal("replaceclosure", replaceclosure),
        iscclosure = resolveGlobal("iscclosure", iscclosure),
        islclosure = resolveGlobal("islclosure", islclosure),
        isexecutorclosure = resolveGlobal("isexecutorclosure", isexecutorclosure),
        checkclosure = resolveGlobal("checkclosure", checkclosure),
        isourclosure = resolveGlobal("isourclosure", isourclosure),
        newcclosure = resolveGlobal("newcclosure", newcclosure),
        restorefunction = resolveGlobal("restorefunction", restorefunction),
        restoreclosure = resolveGlobal("restoreclosure", restoreclosure),
        restorefunc = resolveGlobal("restorefunc", restorefunc),
        ishooked = resolveGlobal("ishooked", ishooked),
        isfunctionhooked = resolveGlobal("isfunctionhooked", isfunctionhooked),
        hookproto = resolveGlobal("hookproto", hookproto),
        isprotohooked = resolveGlobal("isprotohooked", isprotohooked),
        restoreproto = resolveGlobal("restoreproto", restoreproto),

        getrawmetatable = resolveGlobal("getrawmetatable", getrawmetatable),
        setrawmetatable = resolveGlobal("setrawmetatable", setrawmetatable),
        hookmetamethod = resolveGlobal("hookmetamethod", hookmetamethod),
        getnamecallmethod = resolveGlobal("getnamecallmethod", getnamecallmethod),
        isreadonly = resolveGlobal("isreadonly", isreadonly),
        setreadonly = resolveGlobal("setreadonly", setreadonly),

        Drawing = resolveGlobal("Drawing", Drawing),
        cleardrawcache = resolveGlobal("cleardrawcache", cleardrawcache),
        getrenderproperty = resolveGlobal("getrenderproperty", getrenderproperty),
        setrenderproperty = resolveGlobal("setrenderproperty", setrenderproperty),
        isrenderobj = resolveGlobal("isrenderobj", isrenderobj),

        readfile = resolveGlobal("readfile", readfile),
        listfiles = resolveGlobal("listfiles", listfiles),
        writefile = resolveGlobal("writefile", writefile),
        makefolder = resolveGlobal("makefolder", makefolder),
        appendfile = resolveGlobal("appendfile", appendfile),
        isfile = resolveGlobal("isfile", isfile),
        isfolder = resolveGlobal("isfolder", isfolder),
        delfile = resolveGlobal("delfile", delfile),
        delfolder = resolveGlobal("delfolder", delfolder),
        loadfile = resolveGlobal("loadfile", loadfile),
        dofile = resolveGlobal("dofile", dofile),
        getsafedir = resolveGlobal("getsafedir", getsafedir),

        isrbxactive = resolveGlobal("isrbxactive", isrbxactive),
        isgameactive = resolveGlobal("isgameactive", isgameactive),
        mouse1click = resolveGlobal("mouse1click", mouse1click),
        mouse1press = resolveGlobal("mouse1press", mouse1press),
        mouse1release = resolveGlobal("mouse1release", mouse1release),
        mouse2click = resolveGlobal("mouse2click", mouse2click),
        mouse2press = resolveGlobal("mouse2press", mouse2press),
        mouse2release = resolveGlobal("mouse2release", mouse2release),
        mousemoveabs = resolveGlobal("mousemoveabs", mousemoveabs),
        mousemoverel = resolveGlobal("mousemoverel", mousemoverel),
        mousescroll = resolveGlobal("mousescroll", mousescroll),

        fireclickdetector = resolveGlobal("fireclickdetector", fireclickdetector),
        getcallbackvalue = resolveGlobal("getcallbackvalue", getcallbackvalue),
        getconnections = resolveGlobal("getconnections", getconnections),
        getcustomasset = resolveGlobal("getcustomasset", getcustomasset),
        gethiddenproperty = resolveGlobal("gethiddenproperty", gethiddenproperty),
        sethiddenproperty = resolveGlobal("sethiddenproperty", sethiddenproperty),
        gethiddenproperties = resolveGlobal("gethiddenproperties", gethiddenproperties),
        getproperties = resolveGlobal("getproperties", getproperties),
        getinstances = resolveGlobal("getinstances", getinstances),
        getnilinstances = resolveGlobal("getnilinstances", getnilinstances),
        isscriptable = resolveGlobal("isscriptable", isscriptable),
        setscriptable = resolveGlobal("setscriptable", setscriptable),
        setrbxclipboard = resolveGlobal("setrbxclipboard", setrbxclipboard),
        firesignal = resolveGlobal("firesignal", firesignal),
        replicatesignal = resolveGlobal("replicatesignal", replicatesignal),
        cansignalreplicate = resolveGlobal("cansignalreplicate", cansignalreplicate),
        getsignalwhitelist = resolveGlobal("getsignalwhitelist", getsignalwhitelist),
        getsignalargumentsinfo = resolveGlobal("getsignalargumentsinfo", getsignalargumentsinfo),
        isnetworkowner = resolveGlobal("isnetworkowner", isnetworkowner),

        identifyexecutor = resolveGlobal("identifyexecutor", identifyexecutor),
        getexecutorname = resolveGlobal("getexecutorname", getexecutorname),
        lz4compress = resolveGlobal("lz4compress", lz4compress),
        lz4decompress = resolveGlobal("lz4decompress", lz4decompress),
        messagebox = resolveGlobal("messagebox", messagebox),
        queue_on_teleport = resolveGlobal("queue_on_teleport", queue_on_teleport),
        queueonteleport = resolveGlobal("queueonteleport", queueonteleport),
        request = resolveGlobal("request", request),
        http_request = resolveGlobal("http_request", http_request),
        http = resolveGlobal("http", http),
        setclipboard = resolveGlobal("setclipboard", setclipboard),
        toclipboard = resolveGlobal("toclipboard", toclipboard),
        setfpscap = resolveGlobal("setfpscap", setfpscap),
        WebSocket = resolveGlobal("WebSocket", WebSocket),

        getgc = resolveGlobal("getgc", getgc),
        filtergc = resolveGlobal("filtergc", filtergc),
        filter_gc = resolveGlobal("filter_gc", filter_gc),
        getloadedmodules = resolveGlobal("getloadedmodules", getloadedmodules),
        getrenv = resolveGlobal("getrenv", getrenv),
        getrunningscripts = resolveGlobal("getrunningscripts", getrunningscripts),
        getscriptbytecode = resolveGlobal("getscriptbytecode", getscriptbytecode),
        dumpstring = resolveGlobal("dumpstring", dumpstring),
        getscriptclosure = resolveGlobal("getscriptclosure", getscriptclosure),
        getscriptfunction = resolveGlobal("getscriptfunction", getscriptfunction),
        getscripthash = resolveGlobal("getscripthash", getscripthash),
        getscripts = resolveGlobal("getscripts", getscripts),
        getsenv = resolveGlobal("getsenv", getsenv),
        getthreadidentity = resolveGlobal("getthreadidentity", getthreadidentity),
        getidentity = resolveGlobal("getidentity", getidentity),
        getthreadcontext = resolveGlobal("getthreadcontext", getthreadcontext),
        setthreadidentity = resolveGlobal("setthreadidentity", setthreadidentity),
        setidentity = resolveGlobal("setidentity", setidentity),
        setthreadcontext = resolveGlobal("setthreadcontext", setthreadcontext),
        getscriptfromthread = resolveGlobal("getscriptfromthread", getscriptfromthread),
        getthreadscript = resolveGlobal("getthreadscript", getthreadscript),
        getrendersteppedlist = resolveGlobal("getrendersteppedlist", getrendersteppedlist),

        cache = resolveGlobal("cache", cache),
        compareinstances = resolveGlobal("compareinstances", compareinstances),

        crypt = resolveGlobal("crypt", crypt),
        base64 = resolveGlobal("base64", base64),
        base64_encode = resolveGlobal("base64_encode", base64_encode),
        base64_decode = resolveGlobal("base64_decode", base64_decode),

        rconsoleclear = resolveGlobal("rconsoleclear", rconsoleclear),
        rconsolecreate = resolveGlobal("rconsolecreate", rconsolecreate),
        rconsoledestroy = resolveGlobal("rconsoledestroy", rconsoledestroy),
        rconsoleinput = resolveGlobal("rconsoleinput", rconsoleinput),
        rconsoleprint = resolveGlobal("rconsoleprint", rconsoleprint),
        rconsolesettitle = resolveGlobal("rconsolesettitle", rconsolesettitle),
        consoleclear = resolveGlobal("consoleclear", consoleclear),
        consolecreate = resolveGlobal("consolecreate", consolecreate),
        consoledestroy = resolveGlobal("consoledestroy", consoledestroy),
        consoleinput = resolveGlobal("consoleinput", consoleinput),
        consoleprint = resolveGlobal("consoleprint", consoleprint),
        consolesettitle = resolveGlobal("consolesettitle", consolesettitle),
        rconsolename = resolveGlobal("rconsolename", rconsolename)
    }

    for key, value in pairs(baseGlobals) do
        if value ~= nil then
            env[key] = value
        end
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
        end),

        __metatable = "The metatable is locked"
    }

    return setmetatable(env, envMetatable)
end

local function sanitizeTraceback(err)
    local errString = tostring(err)
    local cleaned = errString:gsub(".-:%d+:%s*", "")
    return cleaned
end

local function executeScript(source, env, chunkName)
    chunkName = chunkName or ""
    local executable, compileErr = loadstring(source, chunkName)
    if not executable then
        return false, compileErr
    end

    if setfenv then
        setfenv(executable, env)
    end

    local result = {}
    local success = false

    local runnerThread = coroutine.create(newcclosure(function()
        local packed = table.pack(xpcall(executable, newcclosure(function(err)
            return sanitizeTraceback(err)
        end)))
        success = packed[1]
        for i = 2, packed.n do
            table.insert(result, packed[i])
        end
    end))

    local resumeOk, resumeErr = coroutine.resume(runnerThread)
    if not resumeOk then
        return false, sanitizeTraceback(resumeErr)
    end

    executable = nil
    source = nil

    return success, table.unpack(result)
end

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
