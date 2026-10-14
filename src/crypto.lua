local crypt = crypt or {}
local base64decode = crypt.base64decode or crypt.base64_decode or (base64 and base64.decode)
local decrypt = crypt.decrypt
local hash = crypt.hash

local Crypto = {}

function Crypto.decryptPayload(encryptedBase64, keyBase64, ivBase64, expectedHash)
    if not decrypt then
        return nil, "UNC crypt.decrypt is not supported"
    end

    local success, rawDecrypted = pcall(function()
        return decrypt(encryptedBase64, keyBase64, ivBase64, "CBC")
    end)

    if not success or not rawDecrypted then
        return nil, "Decryption failed"
    end

    if expectedHash and hash then
        local actualHash = hash(rawDecrypted, "sha256")
        if actualHash:lower() ~= expectedHash:lower() then
            return nil, "Hash verification mismatch"
        end
    end

    return rawDecrypted
end

return Crypto
