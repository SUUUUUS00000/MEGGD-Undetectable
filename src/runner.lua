local newcclosure = newcclosure or function(fn) return fn end

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

    return success, table.unpack(result)
end

return executeScript
