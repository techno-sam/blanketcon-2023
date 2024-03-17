-- FIXME: Higher-quality hash for next year :)
-- SHA1 hash function in ComputerCraft (Unsafe, for educational/legacy uses only)
-- By Anavrins
-- For help and details, you can DM me on Discord (Anavrins#4600)
-- MIT License
-- Pastebin: https://pastebin.com/SfL7vxP3
-- Last updated: March 27 2020
 
local mod32 = 2^32
local band    = bit32 and bit32.band or bit.band
local bor     = bit32 and bit32.bor or bit.bor
local bnot    = bit32 and bit32.bnot or bit.bnot
local bxor    = bit32 and bit32.bxor or bit.bxor
local blshift = bit32 and bit32.lshift or bit.blshift
local upack   = unpack
local brshift = function(n, b)
    local s = n/(2^b)
    return s-s%1
end
local lrotate = function(n, b)
    local s = n/(2^(32-b))
    local f = s%1
    return (s-f) + f*mod32
end
 
local H = {
    0x67452301,
    0xefcdab89,
    0x98badcfe,
    0x10325476,
    0xc3d2e1f0,
}
 
local function counter(incr)
    local t1, t2 = 0, 0
    if 0xFFFFFFFF - t1 < incr then
        t2 = t2 + 1
        t1 = incr - (0xFFFFFFFF - t1) - 1
    else t1 = t1 + incr
    end
    return t2, t1
end
 
local function BE_toInt(bs, i)
    return blshift((bs[i] or 0), 24) + blshift((bs[i+1] or 0), 16) + blshift((bs[i+2] or 0), 8) + (bs[i+3] or 0)
end
 
local function preprocess(data)
    local len = #data
    local proc = {}
    data[#data+1] = 0x80
    while #data%64~=56 do data[#data+1] = 0 end
    local blocks = math.ceil(#data/64)
    for i = 1, blocks do
        proc[i] = {}
        for j = 1, 16 do
            proc[i][j] = BE_toInt(data, 1+((i-1)*64)+((j-1)*4))
        end
    end
    proc[blocks][15], proc[blocks][16] = counter(len*8)
    return proc
end
 
local function digestblock(w, C)
    for j = 17, 80 do w[j] = lrotate(bxor(w[j-3], w[j-8], w[j-14], w[j-16]), 1) end
 
    local a, b, c, d, e = upack(C)
 
    for j = 1, 80 do
        local f, k = 0, 0
        if j <= 20 then
            f = bor(band(b, c), band(bnot(b), d))
            k = 0x5a827999
        elseif j <= 40 then
            f = bxor(b, c, d)
            k = 0x6ed9eba1
        elseif j <= 60 then
            f = bor(band(b, c), band(b, d), band(c, d))
            k = 0x8f1bbcdc
        elseif j <= 80 then
            f = bxor(b, c, d)
            k = 0xca62c1d6
        end
        local temp = (lrotate(a, 5) + f + e + k + w[j])%mod32
        a, b, c, d, e = temp, a, lrotate(b, 30), c, d
    end
 
    C[1] = (C[1] + a)%mod32
    C[2] = (C[2] + b)%mod32
    C[3] = (C[3] + c)%mod32
    C[4] = (C[4] + d)%mod32
    C[5] = (C[5] + e)%mod32
 
    return C
end
 
local mt = {
    __tostring = function(a) return string.char(unpack(a)) end,
    __index = {
        toHex = function(self, s) return ("%02x"):rep(#self):format(unpack(self)) end,
        isEqual = function(self, t)
            if type(t) ~= "table" then return false end
            if #self ~= #t then return false end
            local ret = 0
            for i = 1, #self do
                ret = bit32.bor(ret, bxor(self[i], t[i]))
            end
            return ret == 0
        end
    }
}
 
local function toBytes(t, n)
    local b = {}
    for i = 1, n do
        b[(i-1)*4+1] = band(brshift(t[i], 24), 0xFF)
        b[(i-1)*4+2] = band(brshift(t[i], 16), 0xFF)
        b[(i-1)*4+3] = band(brshift(t[i], 8), 0xFF)
        b[(i-1)*4+4] = band(t[i], 0xFF)
    end
    return setmetatable(b, mt)
end
 
local function digest(data)
    local data = data or ""
    data = type(data) == "table" and {upack(data)} or {tostring(data):byte(1,-1)}
 
    data = preprocess(data)
    local C = {upack(H)}
    for i = 1, #data do C = digestblock(data[i], C) end
    return toBytes(C, 5)
end
 
local function hmac(input, key)
    local input = type(input) == "table" and {upack(input)} or {tostring(input):byte(1,-1)}
    local key = type(key) == "table" and {upack(key)} or {tostring(key):byte(1,-1)}
 
    local blocksize = 64
 
    key = #key > blocksize and digest(key) or key
 
    local ipad = {}
    local opad = {}
    local padded_key = {}
 
    for i = 1, blocksize do
        ipad[i] = bxor(0x36, key[i] or 0)
        opad[i] = bxor(0x5C, key[i] or 0)
    end
 
    for i = 1, #input do
        ipad[blocksize+i] = input[i]
    end
 
    ipad = digest(ipad)
 
    for i = 1, blocksize do
        padded_key[i] = opad[i]
        padded_key[blocksize+i] = ipad[i]
    end
 
    return digest(padded_key)
end
 
return {
    digest = digest,
    hmac   = hmac,
}
