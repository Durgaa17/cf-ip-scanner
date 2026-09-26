#!/usr/bin/env lua
-- CF IP Scanner - Lua version
-- Requires: lua + luasocket (optional) or just system ping

-- ====================== CONFIG ======================
local NETWORK = "104.18.16.0/20"
local WORKERS = 32
local TIMEOUT = 1  -- seconds
-- ====================================================

local function cidr_to_ips(cidr)
    local ip, prefix = cidr:match("([^/]+)/(%d+)")
    prefix = tonumber(prefix)

    local a, b, c, d = ip:match("(%d+)%.(%d+)%.(%d+)%.(%d+)")
    local ip_num = (tonumber(a) << 24) + (tonumber(b) << 16) + (tonumber(c) << 8) + tonumber(d)

    local mask = prefix == 0 and 0 or (~((1 << (32 - prefix)) - 1)) & 0xFFFFFFFF
    local network = ip_num & mask
    local broadcast = network | (~mask & 0xFFFFFFFF)

    local ips = {}
    for i = network + 1, broadcast - 1 do
        local aa = (i >> 24) & 255
        local bb = (i >> 16) & 255
        local cc = (i >> 8) & 255
        local dd = i & 255
        table.insert(ips, string.format("%d.%d.%d.%d", aa, bb, cc, dd))
    end
    return ips
end

local function is_alive(ip)
    local cmd
    if package.config:sub(1,1) == "\\" then
        -- Windows
        cmd = string.format("ping -n 1 -w %d %s >nul 2>&1", TIMEOUT * 1000, ip)
    else
        -- Linux / Termux
        cmd = string.format("ping -c 1 -W %d %s >/dev/null 2>&1", TIMEOUT, ip)
    end
    return os.execute(cmd) == true or os.execute(cmd) == 0
end

print("Scanning " .. NETWORK .. " with " .. WORKERS .. " workers...")
print("This may take a while depending on the range size.\n")

local ips = cidr_to_ips(NETWORK)
local total = #ips
print("Total hosts to scan: " .. total .. "\n")

local alive = {}
local file = io.open("reachable.txt", "w")

-- Simple sequential with progress (Lua threading is limited without libraries)
for i, ip in ipairs(ips) do
    if is_alive(ip) then
        print("[+] " .. ip)
        table.insert(alive, ip)
        file:write(ip .. "\n")
    end
end

file:close()

print("\n========================================")
print(string.format("Done! %d/%d hosts are reachable", #alive, total))
print("Results saved to: reachable.txt")
print("========================================")

if #alive > 0 then
    print("\nReachable IPs:")
    for _, ip in ipairs(alive) do
        print(ip)
    end
else
    print("\nNo reachable hosts found.")
end
