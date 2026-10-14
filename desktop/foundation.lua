-- NovaOS 0.6.0 | Phase 1 / milestone 1.0: desktop foundation
-- OpenOS hosted safety preview. No filesystem writes.
local component=require("component")
local computer=require("computer")
local gpu=assert(component.gpu,"NovaOS: GPU missing")
assert(component.isAvailable("screen"),"NovaOS: screen missing")
gpu.bind(component.screen.address)
local maxW,maxH=gpu.maxResolution()
pcall(gpu.setResolution,math.min(maxW,100),math.min(maxH,35))
local W,H=gpu.getResolution()
assert(W>=50 and H>=18,"NovaOS needs 50x18 screen")
local C={sky=0x4B94EA,skyTop=0x2874CD,skyLight=0x79B7FA,cloud=0xFFFFFF,
hill=0x79C943,grass=0x4AAB2E,deep=0x2A812B,task=0x2058BE,
start=0x358E32,startEdge=0x206D24,white=0xFFFFFF,select=0x164B9F,
outline=0xD6EAFF,shadow=0x245A94}
local icons={
 {label="Arbeitsplatz",shape={" P ","[=]","[_]"}},
 {label="Eigene Dateien",shape={" ___","|__|","[__]"}},
 {label="Papierkorb",shape={" ___","|#|","|_|"}},
 {label="Netzwerk",shape={" o ","-+-"," o "}},
 {label="NovaOS",shape={" / ","N O"," \\"}}
}
local selected=nil
local status="Desktop 1.0 | Testmodus"
local running=true
local dirty=true
local previousClick=0
local previousIndex=0
local lastMinute=-1
local mx=3
local function fill(x,y,w,h,color)
 if x<1 or y<1 or x+w-1>W or y+h-1>H then return end
 gpu.setBackground(color)
 gpu.fill(x,y,w,h," ")
end
local function put(x,y,s,fg,bg,limit)
 if x<1 or y<1 or x>W or y>H then return end
 gpu.setForeground(fg)
 gpu.setBackground(bg)
 gpu.set(x,y,tostring(s):sub(1,math.min(W-x+1,limit or W)))
end
local function iconPos(i)
 local rows=math.max(1,math.floor((H-6)/5))
 local column=math.floor((i-1)/rows)
 local row=(i-1)%rows
 return mx+column*22,3+row*5
end
local function groundColor(y)
 if y<=2 then return C.skyTop end
 if y<math.floor(H*.53) then return C.sky end
 if y<math.floor(H*.61) then return C.skyLight end
 if y<math.floor(H*.71) then return C.hill end
 if y<math.floor(H*.82) then return C.grass end
 return C.deep
end
local function background()
 local horizon=math.floor(H*.65)
 for y=1,H-1 do fill(1,y,W,1,groundColor(y)) end
 if H>=23 then
  local a=math.floor(W*.35)
  local b=math.floor(W*.70)
  fill(a,4,8,1,C.cloud)
  fill(a+3,3,12,1,C.cloud)
  fill(a+7,5,9,1,C.cloud)
  fill(b,6,10,1,C.cloud)
  fill(b+4,5,12,1,C.cloud)
 end
 -- Low-resolution grass contours. No external image or framebuffer.
 for x=25,W-1,2 do
  local delta=math.floor(math.sin(x/13)*2)
  local y=math.max(12,math.min(H-3,horizon+delta))
  put(x,y,"_",C.hill,groundColor(y),1)
 end
end
local function drawIcons()
 for i,item in ipairs(icons) do
  local x,y=iconPos(i)
  local active=selected==i
  for lineIndex,shape in ipairs(item.shape) do
   local py=y+lineIndex-1
   if py<H-1 then
    local bg=active and C.select or groundColor(py)
    if active then fill(x,py,math.min(18,W-x),1,bg) end
    put(x+2,py,shape,C.white,bg,8)
   end
  end
  local ly=y+3
  if ly<H-1 then
   local bg=active and C.select or groundColor(ly)
   if active then fill(x,ly,math.min(19,W-x),1,bg) end
   put(x,ly,item.label,C.white,bg,19)
  end
 end
end
local function taskbar()
 fill(1,H,W,1,C.task)
 fill(1,H,11,1,C.start)
 put(2,H,"Start",C.white,C.start)
 local info=status
 if W>54 then put(14,H,info,C.white,C.task,W-27) end
 local minutes=math.floor(computer.uptime()/60)
 local clock=string.format("%02d:%02d",math.floor(minutes/60)%24,minutes%60)
 put(W-6,H,clock,C.white,C.task,5)
end
local function render()
 background()
 drawIcons()
 taskbar()
 dirty=false
end
local function iconHit(x,y)
 for i=1,#icons do
  local ix,iy=iconPos(i)
  if x>=ix and x<=ix+19 and y>=iy and y<=iy+3 then return i end
 end
end
local function activate(i)
 selected=i
 status=icons[i].label.." | Desktop-Prototyp"
 dirty=true
end
local function press(x,y)
 if y==H then
  if x<=11 then
   status="Startmenue kommt in Meilenstein 1.2"
   dirty=true
  end
  return
 end
 local index=iconHit(x,y)
 if not index then selected=nil;dirty=true;return end
 local now=computer.uptime()
 if previousIndex==index and now-previousClick<0.45 then
  activate(index)
  status=icons[index].label.." | Apps folgen spaeter"
 else selected=index;dirty=true end
 previousIndex=index
 previousClick=now
end
local function keyboard(char,scan)
 if scan==200 or scan==203 then selected=math.max(1,(selected or 2)-1)
 elseif scan==208 or scan==205 then selected=math.min(#icons,(selected or 0)+1)
 elseif scan==28 and selected then activate(selected)
 elseif char==113 or char==81 then running=false
 else return end
 dirty=true
end
local ok,err=xpcall(function()
 while running do
  local minute=math.floor(computer.uptime()/60)
  if minute~=lastMinute then lastMinute=minute;dirty=true end
  if dirty then render() end
  local event,a,b,c=computer.pullSignal(2)
  if event=="touch" then press(b,c)
  elseif event=="key_down" then keyboard(b,c)
  elseif event=="interrupted" then running=false end
 end
end,debug.traceback)
gpu.setBackground(0x000000)
gpu.setForeground(C.white)
gpu.fill(1,1,W,H," ")
if not ok then error(err) end
