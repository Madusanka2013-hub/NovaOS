-- NovaOS 0.9.0 XP Core (OpenOS hosted).
-- Core-only milestone: desktop, start menu, taskbar, window manager, rendering boundary.
-- OC text GPUs cannot display image files directly. Never generate fake text-art icons.
local component = require("component")
local computer = require("computer")
local gpu = assert(component.gpu, "NovaOS: GPU missing")
assert(component.isAvailable("screen"), "NovaOS: screen missing")
assert(gpu.bind(component.screen.address), "NovaOS: GPU bind failed")
local mw, mh = gpu.maxResolution()
pcall(gpu.setResolution, math.min(mw,100), math.min(mh,35))
local W,H = gpu.getResolution()
assert(W>=55 and H>=22, "NovaOS XP Core needs a 55x22 screen")
local C = {
  desktop=0x367BC6, task=0x1658CA, taskDark=0x0C348D, taskLight=0x3B82EC,
  start=0x398E37, startDark=0x276D2A, white=0xFFFFFF, black=0x151515,
  menu=0xFFFFFF, secondary=0xD7E5F7, title=0x0856BA, unfocused=0x7E9FC6,
  chrome=0xECE9D8, border=0x134FA6, select=0x316AC5
}
local desktopItems = {
  {id="computer",name="Arbeitsplatz",image="computer.png"},
  {id="documents",name="Eigene Dateien",image="documents.png"},
  {id="network",name="Netzwerkumgebung",image="network.png"},
  {id="trash",name="Papierkorb",image="recycle-bin.png"}
}
local state={running=true, menu=false, selected=nil, focus=nil, windows={}, drag=nil,
             lastClickTime=-1,lastClickItem=0,dirty=true,clock=-1,notice=nil}
local graphics=nil
-- Future native NeoForge graphics component contract (not bundled with OCM).
-- Only used when an addon provides it; old GPUs continue to run without errors.
local addr=component.list("nova_graphics")()
if addr then
  local ok,proxy=pcall(component.proxy,addr)
  if ok and proxy and type(proxy.drawImage)=="function" then graphics=proxy end
end
local function rect(x,y,w,h,color)
  x=math.max(1,math.floor(x));y=math.max(1,math.floor(y))
  w=math.min(math.floor(w),W-x+1);h=math.min(math.floor(h),H-y+1)
  if w<=0 or h<=0 then return end
  gpu.setBackground(color);gpu.fill(x,y,w,h," ")
end
local function txt(x,y,s,fg,bg,max)
  if x<1 or y<1 or x>W or y>H then return end
  gpu.setForeground(fg);gpu.setBackground(bg)
  gpu.set(x,y,tostring(s):sub(1,math.max(0,math.min(max or W,W-x+1))))
end
local function image(asset,x,y,w,h)
  if not graphics then return false end
  local ok,result=pcall(graphics.drawImage,"novaos/"..asset,x,y,w,h)
  return ok and result~=false
end
local function iconPosition(i)
  local rows=math.max(1,math.floor((H-5)/5))
  return 3+math.floor((i-1)/rows)*23,2+((i-1)%rows)*5
end
local function desktop()
  rect(1,1,W,H-1,C.desktop)
  if not image("bliss.png",1,1,W,H-1) then
    -- Solid fallback deliberately contains no block/pixel approximation of Bliss.
    txt(W-23,2,"NovaOS 0.9 XP Core",C.white,C.desktop,22)
  end
  for i,item in ipairs(desktopItems) do
    local x,y=iconPosition(i)
    if y+3<H then
      local color=state.selected==i and C.select or C.desktop
      if state.selected==i then rect(x-1,y,21,4,color) end
      local shown=image("icons/"..item.image,x+5,y,8,3)
      if not shown then txt(x+1,y+1," ",C.white,color) end
      txt(x,y+3,item.name,C.white,color,20)
    end
  end
end
local function addWindow(title)
  for i,v in ipairs(state.windows) do
    if v.title==title then v.min=false;state.focus=i;state.menu=false;state.dirty=true;return end
  end
  local w=math.min(W-5,math.max(40,math.floor(W*.65)))
  local h=math.min(H-4,math.max(12,math.floor(H*.60)))
  local n=#state.windows
  state.windows[#state.windows+1]={title=title,x=5+n*2,y=3+n,w=w,h=h,min=false,max=false,
    restore=nil}
  state.focus=#state.windows;state.menu=false;state.dirty=true
end
local function drawWindow(v,active)
  if v.min then return end
  local x,y,w,h=v.x,v.y,v.w,v.h
  rect(x,y,w,h,C.border)
  rect(x+1,y+1,w-2,h-2,C.chrome)
  local bar=active and C.title or C.unfocused
  rect(x+1,y+1,w-2,2,bar)
  txt(x+3,y+1,v.title,C.white,bar,w-16)
  txt(x+w-12,y+1,"[_][O][X]",C.black,C.chrome,10)
  txt(x+3,y+5,"NovaOS XP Core 0.9.0",C.black,C.chrome,w-6)
  txt(x+3,y+7,graphics and "Native graphics component detected." or "Image backend not installed.",C.black,C.chrome,w-6)
  txt(x+3,y+9,"Core desktop, start and window controls.",C.black,C.chrome,w-6)
end
local function taskbar()
  rect(1,H,W,1,C.task)
  rect(1,H,12,1,C.startDark)
  rect(2,H,10,1,C.start)
  txt(4,H,"Start",C.white,C.start,7)
  local x=14
  for i,v in ipairs(state.windows) do
    local width=math.min(17,W-13-x)
    if width>5 then
      local color=(state.focus==i and not v.min) and C.taskDark or C.taskLight
      rect(x,H,width,1,color);txt(x+1,H,v.title,C.white,color,width-2)
      x=x+width+1
    end
  end
  rect(W-10,H,11,1,C.taskDark)
  local min=math.floor(computer.uptime()/60)
  txt(W-7,H,string.format("%02d:%02d",math.floor(min/60)%24,min%60),C.white,C.taskDark,5)
end
local menuLeft={"Internet","E-Mail","Alle Programme"}
local menuRight={"Eigene Dateien","Arbeitsplatz","Systemsteuerung"}
local function startMenu()
  if not state.menu then return end
  local y=H-17
  rect(2,y,45,16,C.taskDark)
  rect(3,y+1,43,14,C.menu)
  rect(3,y+1,43,3,C.task)
  txt(5,y+2,"Administrator",C.white,C.task,36)
  rect(27,y+4,19,9,C.secondary)
  for i,name in ipairs(menuLeft) do txt(5,y+4+i,name,C.black,C.menu,20) end
  for i,name in ipairs(menuRight) do txt(28,y+4+i,name,C.black,C.secondary,17) end
  rect(3,H-3,43,1,C.task)
  txt(6,H-3,"Abmelden",C.white,C.task)
  txt(26,H-3,"Ausschalten",C.white,C.task)
end
local function draw()
  desktop()
  for i,v in ipairs(state.windows) do if i~=state.focus then drawWindow(v,false) end end
  if state.focus then
    local v=state.windows[state.focus]
    if v then drawWindow(v,true) end
  end
  startMenu()
  taskbar()
  state.dirty=false
end
local function itemHit(x,y)
  for i in ipairs(desktopItems) do
    local ix,iy=iconPosition(i)
    if x>=ix-1 and x<=ix+20 and y>=iy and y<=iy+3 then return i end
  end
end
local function focusWindow(x,y)
  for i=#state.windows,1,-1 do
    local v=state.windows[i]
    if not v.min and x>=v.x and x<v.x+v.w and y>=v.y and y<v.y+v.h then return i end
  end
end
local function click(x,y)
  if y==H then
    if x<=12 then state.menu=not state.menu;state.dirty=true;return end
    local p=14
    for i,v in ipairs(state.windows) do
      local width=math.min(17,W-13-p)
      if width>5 and x>=p and x<p+width then
        v.min=not v.min;state.focus=v.min and nil or i
        state.menu=false;state.dirty=true;return
      end
      p=p+width+1
    end
    return
  end
  if state.menu then
    local my=H-17
    if x>=27 and x<=46 and y>=my+5 and y<=my+7 then
      local names={"Eigene Dateien","Arbeitsplatz","Systemsteuerung"}
      addWindow(names[y-my-4]);return
    elseif y==H-3 and x>=25 and x<=46 then
      state.running=false;return
    end
    state.menu=false;state.dirty=true;return
  end
  local n=focusWindow(x,y)
  if n then
    local v=state.windows[n];state.focus=n
    if y<=v.y+2 then
      if x>=v.x+v.w-5 then
        table.remove(state.windows,n);state.focus=#state.windows>0 and #state.windows or nil
      elseif x>=v.x+v.w-9 then
        if v.max then
          v.x,v.y,v.w,v.h=v.restore.x,v.restore.y,v.restore.w,v.restore.h
          v.restore=nil;v.max=false
        else
          v.restore={x=v.x,y=v.y,w=v.w,h=v.h}
          v.x,v.y,v.w,v.h=1,1,W,H-1;v.max=true
        end
      elseif x>=v.x+v.w-12 then v.min=true;state.focus=nil
      else state.drag={v=v,dx=x-v.x,dy=y-v.y} end
    end
    state.dirty=true;return
  end
  local i=itemHit(x,y)
  state.selected=i
  if i then
    local now=computer.uptime()
    if state.lastClickItem==i and now-state.lastClickTime<0.45 then
      addWindow(desktopItems[i].name)
      state.lastClickItem=0
    else
      state.lastClickItem=i;state.lastClickTime=now
    end
  end
  state.dirty=true
end
local previousW,previousH=W,H
local ok,err=xpcall(function()
  while state.running do
    local m=math.floor(computer.uptime()/60)
    if state.clock~=m then state.clock=m;state.dirty=true end
    if state.dirty then draw() end
    local event,a,b,c=computer.pullSignal(1)
    if event=="touch" then click(b,c)
    elseif event=="drag" and state.drag then
      local v=state.drag.v
      if not v.max then
        v.x=math.max(1,math.min(W-v.w,b-state.drag.dx))
        v.y=math.max(1,math.min(H-v.h-1,c-state.drag.dy))
        state.dirty=true
      end
    elseif event=="drop" then state.drag=nil
    elseif event=="key_down" then
      if b==27 then state.menu=false;state.dirty=true
      elseif b==113 or b==81 then state.menu=not state.menu;state.dirty=true end
    elseif event=="interrupted" then state.running=false end
  end
end,debug.traceback)
gpu.setBackground(0x000000);gpu.setForeground(C.white);gpu.fill(1,1,W,H," ")
if not ok then error(err) end
