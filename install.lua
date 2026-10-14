-- NovaOS installer/updater for OpenComputers Modernized (OpenOS).
-- Keeps OpenOS boot intact. Never installs a new EEPROM or bootloader.
local fs = require("filesystem")
local internet = require("internet")
local base = "https://raw.githubusercontent.com/Madusanka2013-hub/NovaOS/main/"
local home = "/home/novaos"
assert(fs.isDirectory("/home"), "Writable OpenOS /home required")
assert(fs.makeDirectory(home) or fs.isDirectory(home), "Cannot create NovaOS directory")

local files = {
  {"desktop/xp_visual07.lua", home .. "/xp_visual07.lua"},
  {"system/xp05.lua", home .. "/xp05.lua"}
}
local function download(source)
  local request, err = internet.request(base .. source .. "?nova_update=1")
  assert(request, "Download failed for " .. source .. ": " .. tostring(err))
  local chunks, bytes = {}, 0
  for chunk in request do
    chunks[#chunks + 1] = chunk
    bytes = bytes + #chunk
    assert(bytes < 512 * 1024, "File too large: " .. source)
  end
  assert(bytes > 0, "Empty download: " .. source)
  return table.concat(chunks)
end
local function save(path, data)
  local tmp = path .. ".download"
  local file, err = io.open(tmp, "wb")
  assert(file, tostring(err))
  file:write(data)
  file:close()
  -- Preserve the old working version until the new file has downloaded.
  if fs.exists(path) then
    if fs.exists(path .. ".bak") then assert(fs.remove(path .. ".bak")) end
    assert(fs.rename(path, path .. ".bak"), "Backup failed: " .. path)
  end
  local ok = fs.rename(tmp, path)
  if not ok then
    if fs.exists(path .. ".bak") then fs.rename(path .. ".bak", path) end
    error("Install failed: " .. path)
  end
end

-- Download everything before touching installed files.
local payloads = {}
for _, entry in ipairs(files) do
  print("Downloading " .. entry[1])
  payloads[#payloads + 1] = download(entry[1])
end
for i, entry in ipairs(files) do save(entry[2], payloads[i]) end

local launcher = [[
-- NovaOS launcher: standard XP preview; "apps" for the functional app prototype.
local mode = ...
if mode == "apps" then
  dofile("/home/novaos/xp05.lua")
else
  dofile("/home/novaos/xp_visual07.lua")
end
]]
save("/home/nova.lua", launcher)
print("NovaOS installation/update completed.")
print("Visual desktop: lua /home/nova.lua")
print("App prototype:   lua /home/nova.lua apps")
print("Backups of replaced files are kept as .bak")
print("OpenOS boot and your personal files are unchanged.")
