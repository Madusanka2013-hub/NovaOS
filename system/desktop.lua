-- NovaOS 0.2 - lightweight desktop preview
local gpu=require("component").gpu
local computer=require("computer")
local fs=require("filesystem")
local w,h=gpu.getResolution()
local apps={"Files","Terminal","System","Settings"}
local wins,focus={},nil
local menu,dirty,running=false,true,true
local cwd,input="/home",""
local log={"NovaShell v0.2 - help for commands"}
local colors={bg=0x10283B,task=0x14202D,win=0x253448,bar=0x374F68,txt=0xEDF4FA,accent=0x66BFFF}
local function rect(x,y,a,b,c)
  gpu.setBackground(c);gpu.fill(x,y,a,b," ")
end
local function write(x,y,s,fg,bg,max)
  if x>w or y>h or x<1 or y<1 then return end
  gpu.setBackground(bg or colors.win);gpu.setForeground(fg or colors.txt)
  gpu.set(x,y,tostring(s):sub(1,math.min(w-x+1,max or 999)))
end
local function add(s)
  log[#log+1]=tostring(s)
  if #log>60 then table.remove(log,1) end
end
local function command(s)
  add("> "..s)
  local cmd,arg=s:match("^(%S+)%s*(.-)%s*$")
  if not cmd then return end
  if cmd=="help" then add("help, pwd, ls, cd, clear, about, exit")
  elseif cmd=="pwd" then add(cwd)
  elseif cmd=="about" then add("NovaOS 0.2 / lightweight alpha")
  elseif cmd=="clear" then log={}
  elseif cmd=="exit" then running=false
  elseif cmd=="cd" then
    local path=fs.canonical(arg:sub(1,1)=="/" and arg or cwd.."/"..arg)
    if fs.isDirectory(path) then cwd=path else add("No such folder") end
  elseif cmd=="ls" then
    local path=fs.canonical(arg:sub(1,1)=="/" and arg or cwd.."/"..arg)
    if fs.isDirectory(path) then
      local n=0
      for f in fs.list(path) do add(f);n=n+1;if n>=20 then break end end
    else add("Not a folder") end
  else add("Unknown command") end
end
local function open(name)
  for i,v in ipairs(wins) do if v.name==name then focus=i;v.min=false;dirty=true;return end end
  if #wins>=3 then return end
  local ww,hh=math.min(w-4,math.max(38,math.floor(w*.7))),math.min(h-3,math.max(12,math.floor(h*.7)))
  wins[#wins+1]={name=name,x=math.min(4+#wins*2,w-ww),y=math.min(3+#wins,h-hh-1),w=ww,h=hh,min=false}
  focus=#wins;menu=false;dirty=true
end
local function render()
  rect(1,1,w,h,colors.bg)
  write(3,2,"NOVA OS 0.2",colors.accent,colors.bg)
  for i,name in ipairs(apps) do
    local y=5+i*3
    if y<h then write(3,y,"["..i.."] "..name,colors.txt,colors.bg) end
  end
  for index,v in ipairs(wins) do
    if not v.min then
      rect(v.x,v.y,v.w,v.h,colors.win)
      rect(v.x,v.y,v.w,2,colors.bar)
      write(v.x+2,v.y+1,v.name,colors.txt,colors.bar)
      write(v.x+v.w-5,v.y+1,"_ X",colors.txt,colors.bar)
      local y=v.y+3
      if v.name=="Files" then
        write(v.x+2,y,cwd,colors.accent,colors.win,v.w-4);y=y+2
        if fs.isDirectory(cwd) then
          for file in fs.list(cwd) do
            if y>=v.y+v.h-2 then break end
            write(v.x+2,y,file,colors.txt,colors.win,v.w-4);y=y+1
          end
        end
      elseif v.name=="Terminal" then
        local start=math.max(1,#log-(v.h-6))
        for n=start,#log do
          if y>=v.y+v.h-2 then break end
          write(v.x+2,y,log[n],colors.txt,colors.win,v.w-4);y=y+1
        end
        write(v.x+2,v.y+v.h-2,"> "..input.."_",colors.accent,colors.win,v.w-4)
      elseif v.name=="System" then
        write(v.x+2,y,"Free RAM: "..math.floor(computer.freeMemory()/1024).." KiB")
        write(v.x+2,y+2,"Total RAM: "..math.floor(computer.totalMemory()/1024).." KiB")
      else
        write(v.x+2,y,"Midnight theme")
        write(v.x+2,y+2,"Resolution: "..w.." x "..h)
        write(v.x+2,y+4,"Ctrl+C to exit")
      end
    end
  end
  rect(1,h,w,1,colors.task)
  write(2,h,"[START]",colors.accent,colors.task)
  local x=11
  for i,v in ipairs(wins) do
    local s="["..v.name.."]"
    if x+#s<w-8 then write(x,h,s,i==focus and colors.accent or colors.txt,colors.task);x=x+#s+1 end
  end
  if menu then
    local my=math.max(2,h-9)
    rect(2,my,22,h-my,colors.win)
    write(4,my+1,"START",colors.accent)
    for i,name in ipairs(apps) do write(4,my+2+i,i.." "..name) end
    write(4,my+8,"Q Exit",colors.accent)
  end
  dirty=false
end
local drag
local function click(x,y)
  if y==h and x<=9 then menu=not menu;dirty=true;return end
  if menu then
    local my=math.max(2,h-9)
    if x<=23 and y>=my+3 and y<=my+6 then open(apps[y-my-2]);return end
    if x<=23 and y==my+8 then running=false;return end
    menu=false
  end
  for i=#wins,1,-1 do
    local v=wins[i]
    if not v.min and x>=v.x and x<v.x+v.w and y>=v.y and y<v.y+v.h then
      focus=i
      if y<=v.y+1 then
        if x>=v.x+v.w-2 then table.remove(wins,i);focus=nil
        elseif x>=v.x+v.w-5 then v.min=true;focus=nil
        else drag={index=i,dx=x-v.x,dy=y-v.y} end
      end
      dirty=true;return
    end
  end
  for i=1,#apps do if x<22 and y==5+i*3 then open(apps[i]);return end end
  dirty=true
end
local ok,err=xpcall(function()
  while running do
    if dirty then render() end
    local event,a,b,c=computer.pullSignal(5)
    if event=="touch" then click(b,c)
    elseif event=="drag" and drag then
      local v=wins[drag.index]
      if v then
        v.x=math.max(1,math.min(w-v.w,b-drag.dx))
        v.y=math.max(1,math.min(h-v.h-1,c-drag.dy))
        dirty=true
      end
    elseif event=="drop" then drag=nil
    elseif event=="key_down" then
      if focus and wins[focus] and wins[focus].name=="Terminal" then
        if c==28 then local s=input;input="";command(s)
        elseif c==14 then input=input:sub(1,-2)
        elseif b and b>=32 and b<=126 and #input<70 then input=input..string.char(b) end
      elseif b and b>=49 and b<=52 then open(apps[b-48])
      elseif b==113 then menu=not menu end
      dirty=true
    elseif event=="interrupted" then running=false end
  end
end,debug.traceback)
gpu.setBackground(0x000000);gpu.setForeground(0xFFFFFF);gpu.fill(1,1,w,h," ")
if not ok then error(err) end
