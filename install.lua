-- NovaOS safe installer for OpenOS
local fs=require("filesystem")
local internet=require("internet")
local root="https://cdn.jsdelivr.net/gh/Madusanka2013-hub/NovaOS@9e9b84a22b29b815d349365c9e1ff836a29533f8/"
assert(fs.isDirectory("/home"),"Requires a writable OpenOS /home")
fs.makeDirectory("/home/novaos")
local function fetch(name,to)
  io.write("Downloading "..name.."\n")
  local response,why=internet.request(root..name)
  assert(response,why or "No internet")
  local buffer={}
  for chunk in response do buffer[#buffer+1]=chunk end
  local data=table.concat(buffer)
  assert(#data>0,"Empty download for "..name)
  local temp=to..".tmp"
  local f,err=io.open(temp,"wb")
  assert(f,err)
  f:write(data);f:close()
  if fs.exists(to) then assert(fs.remove(to),"Cannot replace "..to) end
  assert(fs.rename(temp,to),"Cannot move file into place")
end
fetch("desktop/foundation.lua","/home/novaos/foundation.lua")
local f=assert(io.open("/home/nova.lua","w"))
f:write('dofile("/home/novaos/foundation.lua")\n')
f:close()
print("NovaOS installed. Run: lua /home/nova.lua")
print("Your OpenOS installation has not been replaced.")
