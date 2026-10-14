-- NovaOS XP Edition 0.3 alpha
local c=require("component");local pc=require("computer");local fs=require("filesystem")
local g=assert(c.gpu);g.bind(c.screen.address)
local mw,mh=g.maxResolution();pcall(g.setResolution,math.min(mw,100),math.min(mh,35))
local W,H=g.getResolution();assert(W>=50 and H>=18,"Need 50x18 screen")
local B=0x2675B9;local T=0x214FB3;local G=0x328C25;local P=0xF1F1EF;local K=0x202020;local F=0xFFFFFF
local apps={"My Computer","My Documents","Explorer","Notepad","Command Prompt","Control Panel","System Monitor"}
local windows={};local focus=nil;local menu=false;local dirty=true;local live=true
local folder="/home";local note="";local input="";local logs={"NovaOS XP Edition 0.3","Type help"}
local function rect(x,y,w,h,bg)if w>0 and h>0 then g.setBackground(bg);g.fill(x,y,w,h," ")end end
local function put(x,y,s,fg,bg,limit)if x<1 or x>W or y<1 or y>H then return end;g.setBackground(bg or P);g.setForeground(fg or K);g.set(x,y,tostring(s):sub(1,math.min(W-x+1,limit or W)))end
local function log(s)logs[#logs+1]=s;if #logs>40 then table.remove(logs,1)end end
local function shell(s)
 log("> "..s);local cmd,arg=s:match("^(%S+)%s*(.-)%s*$");if not cmd then return end
 if cmd=="help" then log("help ls cd pwd clear free exit")
 elseif cmd=="pwd" then log(folder)
 elseif cmd=="free" then log(math.floor(pc.freeMemory()/1024).." KiB free")
 elseif cmd=="clear" then logs={}
 elseif cmd=="exit" then live=false
 elseif cmd=="cd" then local p=fs.canonical(arg:sub(1,1)=="/" and arg or folder.."/"..arg);if fs.isDirectory(p)then folder=p else log("Invalid folder")end
 elseif cmd=="ls" then local p=fs.canonical(arg:sub(1,1)=="/" and arg or folder.."/"..arg);if fs.isDirectory(p)then local n=0;for f in fs.list(p)do log(f);n=n+1;if n>=20 then break end end else log("Not found")end
 else log("Unknown command")end
end
local function open(i)
 for k,v in ipairs(windows)do if v.i==i then v.hide=false;focus=k;menu=false;dirty=true;return end end
 if #windows>=4 then return end
 local w,h=math.min(W-4,math.max(42,math.floor(W*.72))),math.min(H-4,math.max(12,math.floor(H*.75)))
 local n=#windows;windows[n+1]={i=i,x=math.min(W-w,4+n*2),y=math.min(H-h-1,2+n),w=w,h=h,hide=false}
 focus=n+1;menu=false;dirty=true
end
local function drawWin(v,k)
 local x,y,w,h=v.x,v.y,v.w,v.h
 rect(x,y,w,h,T);rect(x+1,y+3,w-2,h-4,F)
 put(x+2,y+1,apps[v.i],F,T,w-13);put(x+w-8,y+1,"[_][X]",F,T,7)
 rect(x+1,y+3,w-2,1,P);put(x+2,y+3,"File  Edit  View  Help",K,P,w-4)
 local yy=y+5
 if v.i<=3 then
  local dir=v.i==2 and "/home" or folder
  put(x+2,yy,"Address: "..dir,K,F,w-5);yy=yy+2
  if fs.isDirectory(dir)then
   for f in fs.list(dir)do if yy>=y+h-2 then break end;put(x+2,yy,f,K,F,w-5);yy=yy+1 end
  end
 elseif v.i==4 then put(x+2,yy,"Notepad - temporary notes",K,F,w-4);put(x+2,yy+2,note.."_",K,F,w-5)
 elseif v.i==5 then
  rect(x+1,y+4,w-2,h-5,K)
  local from=math.max(1,#logs-(h-7));yy=y+5
  for n=from,#logs do if yy>=y+h-2 then break end;put(x+2,yy,logs[n],F,K,w-5);yy=yy+1 end
  put(x+2,y+h-2,"> "..input.."_",0x99FF99,K,w-5)
 elseif v.i==6 then put(x+2,yy,"Windows XP inspired theme");put(x+2,yy+2,"Display: "..W.." x "..H);put(x+2,yy+4,"Ctrl+C: Exit NovaOS")
 else put(x+2,yy,"Free RAM: "..math.floor(pc.freeMemory()/1024).." KiB");put(x+2,yy+2,"Total RAM: "..math.floor(pc.totalMemory()/1024).." KiB")end
end
local function draw()
 rect(1,1,W,H,B);put(3,1,"NovaOS XP Edition",F,B)
 for i,name in ipairs(apps)do local y=3+(i-1)*3;if y<H then put(3,y,"["..i.."]",F,B);put(3,y+1,name,F,B,21)end end
 for k,v in ipairs(windows)do if not v.hide then drawWin(v,k)end end
 rect(1,H,W,1,T);rect(1,H,10,1,G);put(2,H,"START",F,G)
 local x=12;for k,v in ipairs(windows)do local s="["..apps[v.i]:sub(1,9).."]";if x+#s<W-9 then put(x,H,s,F,T);x=x+#s+1 end end
 local tm=math.floor(pc.uptime()/60);put(W-8,H,string.format("%02d:%02d",math.floor(tm/60)%24,tm%60),F,T)
 if menu then
  local my=math.max(2,H-13);rect(2,my,29,H-my,P);rect(2,my,29,2,T);put(4,my+1,"NovaOS Start",F,T)
  for i,name in ipairs(apps)do local y=my+2+i;if y<H-2 then put(4,y,i.." "..name,K,P,25)end end
  put(4,H-2,"Q Shutdown",K,P)
 end
 dirty=false
end
local dragging=nil
local function touch(x,y)
 if y==H and x<=10 then menu=not menu;dirty=true;return end
 if menu then
  local my=math.max(2,H-13);local i=y-my-2
  if x<=31 and i>=1 and i<=#apps then open(i);return end
  if x<=31 and y==H-2 then live=false;return end
  menu=false
 end
 for k=#windows,1,-1 do local v=windows[k]
  if not v.hide and x>=v.x and x<v.x+v.w and y>=v.y and y<v.y+v.h then
   focus=k
   if y<=v.y+1 then if x>=v.x+v.w-4 then table.remove(windows,k);focus=nil
   elseif x>=v.x+v.w-8 then v.hide=true;focus=nil
   else dragging={k,x-v.x,y-v.y}end end
   dirty=true;return
  end
 end
 for i=1,#apps do local yy=3+(i-1)*3;if x<=24 and (y==yy or y==yy+1)then open(i);return end end
 dirty=true
end
local ok,err=xpcall(function()
 local oldMinute=-1
 while live do
  local m=math.floor(pc.uptime()/60);if m~=oldMinute then dirty=true;oldMinute=m end
  if dirty then draw()end
  local ev,a,b,d=pc.pullSignal(1)
  if ev=="touch" then touch(b,d)
  elseif ev=="drag" and dragging then local v=windows[dragging[1]];if v then v.x=math.max(1,math.min(W-v.w,b-dragging[2]));v.y=math.max(1,math.min(H-v.h-1,d-dragging[3]));dirty=true end
  elseif ev=="drop" then dragging=nil
  elseif ev=="key_down" then local v=focus and windows[focus]
   if v and v.i==5 then if d==28 then local s=input;input="";shell(s)elseif d==14 then input=input:sub(1,-2)elseif b and b>=32 and b<=126 and #input<100 then input=input..string.char(b)end
   elseif v and v.i==4 then if d==14 then note=note:sub(1,-2)elseif b and b>=32 and b<=126 and #note<300 then note=note..string.char(b)end
   elseif b and b>=49 and b<=55 then open(b-48)elseif b==113 then menu=not menu end
   dirty=true
  elseif ev=="interrupted" then live=false end
 end
end,debug.traceback)
g.setBackground(K);g.setForeground(F);g.fill(1,1,W,H," ")
if not ok then error(err)end
