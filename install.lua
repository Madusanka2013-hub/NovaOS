-- NovaOS versioned installer/updater 0.9.0 (OpenOS).
-- Run: lua /home/nova-install.lua [install|status|rollback|force]
-- Runtime versions stored under /home/novaos/versions/<version>/
local fs = require("filesystem")
local internet = require("internet")
local VERSION = "0.9.0"
local URL = "https://cdn.jsdelivr.net/gh/Madusanka2013-hub/NovaOS@main/"
local ROOT = "/home/novaos"
local VERSIONS = ROOT .. "/versions"
local CURRENT = ROOT .. "/current.version"
local PREVIOUS = ROOT .. "/previous.version"
local action = (...) or "install"

local function exists(path) return fs.exists(path) end
local function read(path)
  local f = io.open(path, "rb")
  if not f then return nil end
  local data = f:read("*a")
  f:close()
  return data
end
local function write(path, data)
  local file, err = io.open(path, "wb")
  assert(file, err or ("Cannot write " .. path))
  assert(file:write(data))
  file:close()
end
local function version(s)
  if s then return (s:match("^%s*([%w%.%-]+)")) end
end
local function installDir(v) return VERSIONS .. "/" .. v end
local function ready(v)
  return v and exists(installDir(v) .. "/xp_core09.lua") and exists(installDir(v) .. "/xp05.lua")
end
local function activate(v)
  assert(ready(v), "Version incomplete: " .. tostring(v))
  local current = version(read(CURRENT))
  if current and current ~= v then write(PREVIOUS, current .. "\n") end
  write(CURRENT, v .. "\n")
end
local LAUNCHER = [[
-- NovaOS stable launcher, controlled by current.version
local fs = require("filesystem")
local f = assert(io.open("/home/novaos/current.version","r"),"NovaOS not installed")
local v = assert(f:read("*l"),"NovaOS version is missing")
f:close()
assert(v:match("^[%w%.%-]+$"),"Invalid NovaOS version")
local mode = ...
local name = mode == "apps" and "xp05.lua" or "xp_core09.lua"
dofile("/home/novaos/versions/" .. v .. "/" .. name)
]]
local function makeLauncher()
  write("/home/nova.lua", LAUNCHER)
end

if action == "status" then
  print("NovaOS installed: " .. tostring(version(read(CURRENT)) or "none"))
  print("NovaOS installer: " .. VERSION)
  print("Rollback version: " .. tostring(version(read(PREVIOUS)) or "none"))
  return
elseif action == "rollback" then
  local previous = version(read(PREVIOUS))
  assert(ready(previous), "No complete previous version for rollback")
  local current = version(read(CURRENT))
  write(CURRENT, previous .. "\n")
  if current and current ~= previous then write(PREVIOUS, current .. "\n") end
  makeLauncher()
  print("NovaOS restored to " .. previous)
  return
elseif action ~= "install" and action ~= "force" then
  error("Usage: lua /home/nova-install.lua [install|status|rollback|force]")
end

assert(fs.isDirectory("/home"), "OpenOS /home missing")
assert(fs.makeDirectory(ROOT) or fs.isDirectory(ROOT), "Cannot create NovaOS root")
assert(fs.makeDirectory(VERSIONS) or fs.isDirectory(VERSIONS), "Cannot create versions folder")
if ready(VERSION) and action ~= "force" then
  activate(VERSION)
  makeLauncher()
  print("NovaOS " .. VERSION .. " already installed; launcher refreshed.")
  print("Run: lua /home/nova.lua")
  return
end

local files = {
  {"desktop/xp_core09.lua", "xp_core09.lua"},
  {"system/xp05.lua", "xp05.lua"}
}
local payload = {}
for i, entry in ipairs(files) do
  local url = URL .. entry[1] .. "?nova_version=" .. VERSION
  print("Downloading " .. entry[1])
  local request, err = internet.request(url)
  assert(request, "Download error: " .. tostring(err))
  local chunks, size = {}, 0
  for part in request do
    size = size + #part
    assert(size <= 512 * 1024, "Download exceeds size limit")
    chunks[#chunks+1] = part
  end
  payload[i] = table.concat(chunks)
  assert(#payload[i] > 20, "Incomplete download: " .. entry[1])
  assert(not payload[i]:find("<!DOCTYPE",1,true) and not payload[i]:find("<html",1,true),"Server returned HTML, not Lua")
  local loader, syntaxError = load(payload[i], "=" .. entry[1], "t")
  assert(loader, "Invalid Lua file: " .. tostring(syntaxError))
end
local dir = installDir(VERSION)
assert(fs.makeDirectory(dir) or fs.isDirectory(dir), "Cannot create version directory")
for i, entry in ipairs(files) do
  local file = dir .. "/" .. entry[2]
  write(file .. ".new", payload[i])
end
for _, entry in ipairs(files) do
  local file = dir .. "/" .. entry[2]
  if exists(file) then assert(fs.remove(file), "Cannot replace " .. file) end
  assert(fs.rename(file .. ".new", file), "Cannot activate " .. file)
end
activate(VERSION)
makeLauncher()
print("NovaOS " .. VERSION .. " installed successfully")
print("Start:      lua /home/nova.lua")
print("Apps demo:  lua /home/nova.lua apps")
print("Status:     lua /home/nova-install.lua status")
print("Rollback:   lua /home/nova-install.lua rollback")
print("Legacy /home/novaos/boot.lua is NOT modified.")
