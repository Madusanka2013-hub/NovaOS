-- NovaOS 0.9.1 graphics capability and asset adapter.
-- This module DOES NOT pretend the OC text GPU supports PNGs.
local component=require("component")
local M={}
local names={
  wallpaper="novaos/wallpapers/bliss.png",
  computer="novaos/icons/computer.png",
  documents="novaos/icons/documents.png",
  network="novaos/icons/network.png",
  trash="novaos/icons/recycle-bin.png",
  start="novaos/theme/start.png",
  title="novaos/theme/titlebar.png"
}
M.assets=names
M.native=nil
M.reason="Native image component is not installed"
local found=component.list("nova_graphics")()
if found then
  local ok,p=pcall(component.proxy,found)
  if ok and p and type(p.drawImage)=="function" then
    M.native=p
    M.reason="Native graphics component available (compatibility unverified)"
  else
    M.reason="nova_graphics detected without drawImage(asset,x,y,w,h)"
  end
end
M.capabilities={backend=M.native and "native" or "oc-text",images=M.native~=nil}
function M.draw(name,x,y,w,h)
  local asset=names[name]
  if not asset then return false,"Unknown asset: "..tostring(name) end
  if not M.native then return false,M.reason end
  local ok,result=pcall(M.native.drawImage,asset,x,y,w,h)
  if not ok then
    M.reason="Native drawImage failed: "..tostring(result)
    return false,M.reason
  end
  return result~=false
end
function M.diagnostics()
  return {
    "Graphics backend: "..M.capabilities.backend,
    "Image assets: "..(M.capabilities.images and "bridge detected" or "unsupported on text GPU"),
    "Status: "..M.reason
  }
end
return M
