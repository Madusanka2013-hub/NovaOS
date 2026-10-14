-- NovaOS XP Edition 0.4 alpha
local c=require('component') local pc=require('computer') local fs=require('filesystem')
local g=assert(c.gpu) assert(c.isAvailable('screen'),'screen missing') g.bind(c.screen.address)
local mw,mh=g.maxResolution() pcall(g.setResolution,math.min(mw,100),math.min(mh,35))
local W,H=g.getResolution() assert(W>=55 and H>=20,'Need 55x20 screen')
local C={sky1=0x67A7F7,sky2=0x3E86E1,cloud=0xF9FDFF,hill1=0x77C126,hill2=0x4E9D1E,grass=0x3A8919,
 task=0x245BCE,task2=0x0D49C2,start=0x3E9E2E,start2=0x28701E,white=0xFFFFFF,black=0x1B1B1B,panel=0xF5F6F8,
 border=0x1E59B2,menuR=0xEAF4FF,menuL=0xF8F8F8,dim=0x5F6D7A,sel=0xCFE7FF,title=0x0E4AB7,title2=0x5085D6}
local apps={{'My Computer','computer'},{'My Documents','docs'},{'Internet Explorer','explorer'},{'Command Prompt','term'},{'Notepad','note'},{'Control Panel','control'},{'System Monitor','monitor'}}
local icons={1,2,3,4,5}
local win,focus,menu,dirty,live={},nil,false,true,true
local folder='/home' local note='' local input='' local logs={'Microsoft(R) Command Prompt','Type help'} local drag=nil
local function rect(x,y,w,h,b) if w>0 and h>0 then g.setBackground(b) g.fill(x,y,w,h,' ') end end
local function text(x,y,s,fg,bg,m) if x<1 or y<1 or x>W or y>H then return end g.setForeground(fg or C.black) g.setBackground(bg or C.panel) g.set(x,y,tostring(s):sub(1,math.min(W-x+1,m or W))) end
local function add(s) logs[#logs+1]=tostring(s) if #logs>50 then table.remove(logs,1) end end
local function shell(s)
 add('> '..s) local cmd,arg=s:match('^(%S+)%s*(.-)%s*$') if not cmd then return end
 if cmd=='help' then add('help ls cd pwd clear free reboot exit')
 elseif cmd=='pwd' then add(folder)
 elseif cmd=='clear' then logs={}
 elseif cmd=='free' then add(math.floor(pc.freeMemory()/1024)..' KiB free')
 elseif cmd=='reboot' then pc.shutdown(true)
 elseif cmd=='exit' then live=false
 elseif cmd=='cd' then local p=fs.canonical(arg:sub(1,1)=='/' and arg or folder..'/'..arg) if fs.isDirectory(p) then folder=p else add('Directory not found') end
 elseif cmd=='ls' then local p=fs.canonical((arg~='' and (arg:sub(1,1)=='/' and arg or folder..'/'..arg)) or folder) if fs.isDirectory(p) then local n=0 for f in fs.list(p) do add(f) n=n+1 if n>=24 then break end end else add('Not a directory') end
 else add('Unknown command') end end
local function title(i) return apps[i][1] end
local function open(i)
 for k,v in ipairs(win) do if v.i==i then v.hide=false focus=k menu=false dirty=true return end end
 if #win>=4 then return end
 local ww,hh=math.min(W-6,math.max(42,math.floor(W*.70))),math.min(H-5,math.max(12,math.floor(H*.68)))
 local n=#win win[n+1]={i=i,x=math.min(W-ww,10+n*3),y=math.min(H-hh-1,3+n*2),w=ww,h=hh,hide=false} focus=n+1 menu=false dirty=true
end
local function wallpaper()
 for y=1,H-2 do
  if y<math.floor(H*0.58) then rect(1,y,W,1,y<3 and C.sky2 or C.sky1)
  elseif y<math.floor(H*0.72) then rect(1,y,W,1,C.hill1)
  else rect(1,y,W,1,C.hill2) end
 end
 local cy=3 if H>24 then rect(10,cy,8,1,C.cloud) rect(14,cy+1,10,1,C.cloud) rect(40,cy+2,12,1,C.cloud) rect(65,cy,9,1,C.cloud) end
end
local function desktopIcons()
 local y=3
 for _,idx in ipairs(icons) do
  local n=title(idx) rect(3,y,2,1,C.white) rect(4,y+1,2,1,C.white) text(7,y,n,C.white,C.sky1,18); y=y+4
 end
end
local function body(v)
 local x,y,w,h=v.x,v.y,v.w,v.h local L,R=x+2,x+w-2 local B=y+h-2 local yy=y+5
 if v.i<=3 then
  local dir=v.i==2 and '/home' or folder
  text(L,yy,'Address: '..dir,C.black,C.panel,w-5) yy=yy+2
  rect(L,yy,w-4,1,C.sel) text(L+1,yy,'Name',C.black,C.sel,w-6) yy=yy+2
  if fs.isDirectory(dir) then for f in fs.list(dir) do if yy>=B then break end text(L+1,yy,f,C.black,C.panel,w-6) yy=yy+1 end end
 elseif v.i==4 then
  rect(x+1,y+4,w-2,h-5,0x101010) local s=math.max(1,#logs-(h-8)) yy=y+5
  for n=s,#logs do if yy>=B then break end text(L,yy,logs[n],C.white,0x101010,w-5) yy=yy+1 end
  text(L,B,'> '..input..'_',0x90FF90,0x101010,w-5)
 elseif v.i==5 then text(L,yy,'Notepad',C.dim,C.panel) text(L,yy+2,note..'_',C.black,C.panel,w-5)
 elseif v.i==6 then
  text(L,yy,'Control Panel',C.black,C.panel) text(L,yy+2,'Display',C.border,C.panel) text(L,yy+3,'System',C.border,C.panel) text(L,yy+4,'Programs',C.border,C.panel)
 else
  text(L,yy,'Total RAM: '..math.floor(pc.totalMemory()/1024)..' KiB') text(L,yy+2,'Free RAM: '..math.floor(pc.freeMemory()/1024)..' KiB') text(L,yy+4,'Render mode: event-driven')
 end
end
local function window(v,k)
 local x,y,w,h=v.x,v.y,v.w,v.h rect(x,y,w,h,C.border) rect(x+1,y+1,w-2,h-2,C.panel)
 rect(x+1,y+1,w-2,2,k==focus and C.title or C.title2)
 text(x+3,y+1,title(v.i),C.white,k==focus and C.title or C.title2,w-15)
 text(x+w-9,y+1,'[_][X]',C.white,k==focus and C.title or C.title2,8)
 rect(x+1,y+3,w-2,1,0xECE9D8) text(x+2,y+3,'File  Edit  View  Favorites  Tools  Help',C.black,0xECE9D8,w-4)
 body(v)
end
local function startMenu()
 if not menu then return end
 local my=H-14 rect(2,my,34,13,C.border) rect(3,my+1,32,11,C.menuL) rect(25,my+1,10,11,C.menuR)
 rect(3,my+1,32,2,C.title2) text(5,my+1,'Administrator',C.white,C.title2)
 local left={'Internet','E-Mail','NOVA','Windows Media Player','','All Programs >'}
 for i=1,#apps do if i<=6 then text(5,my+2+i,apps[i][1],C.black,C.menuL,18) end end
 local right={'My Documents','My Pictures','My Music','My Computer','Control Panel','Help and Support','Search','Run...'}
 for i,s in ipairs(right) do text(26,my+1+i,s,C.black,C.menuR,9) end
 rect(3,my+11,32,1,0xE0E0E0) text(5,my+11,'Log Off',C.black,0xE0E0E0) text(24,my+11,'Turn Off',C.black,0xE0E0E0)
end
local function taskbar()
 rect(1,H,W,1,C.task) rect(1,H,11,1,C.start) text(3,H,'Start',C.white,C.start,7)
 local x=13 for k,v in ipairs(win) do if not v.hide then local s='['..title(v.i):sub(1,10)..']'; if x+#s<W-10 then rect(x,H,#s,1,k==focus and C.task2 or C.task); text(x,H,s,C.white,k==focus and C.task2 or C.task,#s); x=x+#s+1 end end end
 local t=math.floor(pc.uptime()/60) text(W-8,H,string.format('%02d:%02d',math.floor(t/60)%24,t%60),C.white,C.task,8)
end
local function draw()
 wallpaper() desktopIcons() for k,v in ipairs(win) do if not v.hide then window(v,k) end end startMenu() taskbar() dirty=false end
local function hit(x,y)
 for k=#win,1,-1 do local v=win[k] if not v.hide and x>=v.x and x<v.x+v.w and y>=v.y and y<v.y+v.h then return k end end end
local function click(x,y)
 if y==H and x<=11 then menu=not menu dirty=true return end
 if menu then local my=H-14 if x>=4 and x<=23 and y>=my+3 and y<=my+8 then open(y-(my+2)); return elseif y==my+11 and x>=23 then live=false return else menu=false dirty=true end end
 local k=hit(x,y)
 if k then local v=win[k] focus=k if y<=v.y+2 then if x>=v.x+v.w-4 then table.remove(win,k) focus=nil elseif x>=v.x+v.w-9 then v.hide=true focus=nil else drag={k,x-v.x,y-v.y} end end dirty=true return end
 local yy=3 for _,idx in ipairs(icons) do if x>=3 and x<=24 and y>=yy and y<=yy+1 then open(idx) return end yy=yy+4 end dirty=true end
local function key(ch,code)
 local v=focus and win[focus]
 if v and not v.hide and v.i==4 then if code==28 then local s=input input='' shell(s) elseif code==14 then input=input:sub(1,-2) elseif ch and ch>=32 and ch<=126 and #input<100 then input=input..string.char(ch) end
 elseif v and not v.hide and v.i==5 then if code==14 then note=note:sub(1,-2) elseif ch and ch>=32 and ch<=126 and #note<350 then note=note..string.char(ch) end
 else if ch and ch>=49 and ch<=55 then open(ch-48) elseif ch==113 or ch==81 then menu=not menu end end dirty=true end
local ok,er=xpcall(function() local old=-1 while live do local m=math.floor(pc.uptime()/60) if m~=old then old=m dirty=true end if dirty then draw() end local e,a,b,d=pc.pullSignal(1)
 if e=='touch' then click(b,d) elseif e=='drag' and drag then local v=win[drag[1]] if v then v.x=math.max(1,math.min(W-v.w,b-drag[2])) v.y=math.max(1,math.min(H-v.h-1,d-drag[3])) dirty=true end elseif e=='drop' then drag=nil elseif e=='key_down' then key(b,d) elseif e=='interrupted' then live=false end end end,debug.traceback)
g.setBackground(0x000000) g.setForeground(C.white) g.fill(1,1,W,H,' ') if not ok then error(er) end