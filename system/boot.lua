-- NovaOS 0.1.0: OpenOS-hosted preview
local component=require("component")
local computer=require("computer")
local fs=require("filesystem")
local gpu=component.gpu
if not gpu or not component.isAvailable("screen") then error("GPU or screen missing") end
gpu.bind(component.screen.address)
local mw,mh=gpu.maxResolution()
local w,h=math.min(mw,100),math.min(mh,32)
assert(gpu.setResolution(w,h))
local colors={bg=0x101723,panel=0x192638,bar=0x27384C,fg=0xE9F1FA,muted=0x92A8BD,accent=0x35B8F7,ok=0x65DCA6}
local tabs={"Desktop","Files","Terminal","Hardware","Settings"}
local selected=1
local cwd="/home"
local history={}
local input=""
local running=true
local function fill(x,y,ww,hh,c)
  if ww<=0 or hh<=0 then return end
  gpu.setBackground(c)
  gpu.fill(x,y,ww,hh," ")
end
local function printAt(x,y,s,fg,bg)
  if x>w or y>h or y<1 then return end
  gpu.setForeground(fg or colors.fg)
  gpu.setBackground(bg or colors.bg)
  gpu.set(x,y,tostring(s):sub(1,w-x+1))
end
local function push(s)
  history[#history+1]=tostring(s)
  while #history>100 do table.remove(history,1) end
end
local function path(p)
  if p:sub(1,1)=="/" then return fs.canonical(p) end
  return fs.canonical(cwd.."/"..p)
end
local function execute(s)
  push("> "..s)
  local cmd,arg=s:match("^(%S+)%s*(.-)%s*$")
  if not cmd then return end
  if cmd=="help" then push("help ls cd pwd cat clear about reboot exit")
  elseif cmd=="pwd" then push(cwd)
  elseif cmd=="about" then push("NovaOS 0.1.0 | OpenOS-hosted preview")
  elseif cmd=="clear" then history={}
  elseif cmd=="cd" then
    local target=path(arg~="" and arg or "/home")
    if fs.isDirectory(target) then cwd=target else push("Not a folder: "..target) end
  elseif cmd=="ls" then
    local target=path(arg~="" and arg or ".")
    if not fs.isDirectory(target) then push("Not a folder: "..target)
    else
      local n=0
      for name in fs.list(target) do
        push(name);n=n+1
        if n>=24 then push("...more omitted");break end
      end
    end
  elseif cmd=="cat" then
    if arg=="" then push("Usage: cat FILE")
    else
      local f=io.open(path(arg),"r")
      if not f then push("File not found")
      else
        local n=0
        for line in f:lines() do push(line);n=n+1;if n>=50 then push("...truncated");break end end
        f:close()
      end
    end
  elseif cmd=="reboot" then computer.shutdown(true)
  elseif cmd=="exit" then running=false
  else push("Unknown command: "..cmd) end
end
local function draw()
  fill(1,1,w,h,colors.bg)
  fill(1,1,w,3,colors.bar)
  printAt(3,2,"NOVA",colors.accent,colors.bar)
  printAt(8,2,"OS  0.1.0",colors.fg,colors.bar)
  local x=2
  for i,name in ipairs(tabs) do
    printAt(x,5," "..i.." "..name.." ",selected==i and colors.accent or colors.muted,colors.panel)
    x=x+#name+6
  end
  fill(2,7,w-2,h-9,colors.panel)
  printAt(4,8,tabs[selected]:upper(),colors.accent,colors.panel)
  if selected==1 then
    printAt(4,11,"Welcome to NovaOS",colors.fg,colors.panel)
    printAt(4,13,"Modern Minecraft computer environment.",colors.muted,colors.panel)
    printAt(4,15,"Choose apps using keys 1 to 5.",colors.muted,colors.panel)
    printAt(4,17,"OpenOS remains installed.",colors.ok,colors.panel)
  elseif selected==2 then
    printAt(4,10,"Folder: "..cwd,colors.muted,colors.panel)
    if fs.isDirectory(cwd) then
      local y=12
      for name in fs.list(cwd) do
        if y>=h-2 then break end
        printAt(4,y,name,colors.fg,colors.panel);y=y+1
      end
    end
  elseif selected==3 then
    local last=math.max(1,#history-(h-12)+1)
    local y=10
    for i=last,#history do
      if y>=h-3 then break end
      printAt(4,y,history[i],colors.fg,colors.panel);y=y+1
    end
    printAt(4,h-3,"> "..input.."_",colors.ok,colors.panel)
  elseif selected==4 then
    local y=10
    for address,kind in component.list() do
      if y>=h-3 then break end
      printAt(4,y,kind.." "..address:sub(1,12),colors.fg,colors.panel);y=y+1
    end
    printAt(4,h-3,"Free: "..math.floor(computer.freeMemory()/1024).." KiB",colors.muted,colors.panel)
  else
    printAt(4,11,"NovaOS v0.1.0 Preview",colors.fg,colors.panel)
    printAt(4,13,"Resolution: "..w.."x"..h,colors.muted,colors.panel)
    printAt(4,15,"Press Q outside Terminal to quit.",colors.muted,colors.panel)
  end
  fill(1,h,w,1,colors.bar)
  printAt(2,h,"NovaOS | [1-5] Apps | [Q] Quit",colors.fg,colors.bar)
end
local ok,err=xpcall(function()
  while running do
    draw()
    local signal,a,b,c=computer.pullSignal(0.5)
    if signal=="key_down" then
      local char,code=b,c
      if selected==3 then
        if code==28 then local line=input;input="";execute(line)
        elseif code==14 then input=input:sub(1,-2)
        elseif char and char>=32 and char<=126 and #input<w-12 then input=input..string.char(char) end
      else
        if char==113 or char==81 then running=false
        elseif char and char>=49 and char<=53 then selected=char-48 end
      end
    elseif signal=="touch" then
      local xx,yy=b,c
      if yy==5 then
        local x=2
        for i,name in ipairs(tabs) do
          if xx>=x and xx<x+#name+5 then selected=i;break end
          x=x+#name+6
        end
      end
    elseif signal=="interrupted" then running=false end
  end
end,debug.traceback)
gpu.setBackground(0x000000);gpu.setForeground(0xFFFFFF);gpu.fill(1,1,w,h," ")
if not ok then error(err) end
