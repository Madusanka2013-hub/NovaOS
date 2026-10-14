-- NovaOS XP Edition 0.5 | OpenComputers low-memory desktop
local c=require("component");local pc=require("computer");local fs=require("filesystem")
local g=assert(c.gpu,"GPU missing");assert(c.isAvailable("screen"),"Screen missing")
g.bind(c.screen.address);local mw,mh=g.maxResolution()
pcall(g.setResolution,math.min(100,mw),math.min(35,mh))
local W,H=g.getResolution();assert(W>=60 and H>=22,"Need at least 60x22")
local C={sky=0x4793DC,blue=0x2564C7,blue2=0x1246A4,green=0x338D2B,hill=0x78BC39,hill2=0x438C25,white=0xFFFFFF,black=0x1E2630,paper=0xFFFFFF,cream=0xECE9D8,pale=0xD7E6F7,dim=0x5C6B7B,menu=0xF9FAFD,sel=0xB7D5FC}
local A={"Arbeitsplatz","Eigene Dateien","Explorer","Editor","Eingabeaufforderung","Systemsteuerung","Task-Manager","Papierkorb"}
local windows={};local selected=nil;local showStart=false;local running=true;local dirty=true
local location="/home";local files={};local fileOffset=0;local choice=1
local document="";local currentFile=nil;local textInput="";local console={"NovaOS Eingabeaufforderung","Hilfe: help"};local status=""
local drag=nil;local minute=-1
local function block(x,y,w,h,b)if w>0 and h>0 then g.setBackground(b);g.fill(x,y,w,h," ")end end
local function label(x,y,s,fg,bg,m)
 if x<1 or y<1 or x>W or y>H then return end
 g.setForeground(fg or C.black);g.setBackground(bg or C.white)
 g.set(x,y,tostring(s):sub(1,math.min(m or W,W-x+1)))
end
local function resolve(p) return fs.canonical((p:sub(1,1)=="/") and p or location.."/"..p)end
local function refresh()
 files={};if fs.isDirectory(location)then
 for s in fs.list(location) do files[#files+1]=s;if #files>=100 then break end end
 table.sort(files)
 end;choice=1;fileOffset=0
end
refresh()
local function message(s) status=tostring(s);dirty=true end
local function openApp(id)
 for k,v in ipairs(windows)do if v.id==id then v.hidden=false;selected=k;showStart=false;dirty=true;return end end
 if #windows>=5 then message("Maximal 5 Fenster");return end
 local ww=math.min(W-6,math.max(50,math.floor(W*.75)))
 local hh=math.min(H-5,math.max(15,math.floor(H*.77)))
 local n=#windows
 windows[#windows+1]={id=id,x=math.min(W-ww,8+n*2),y=math.min(H-hh-1,2+n),w=ww,h=hh,hidden=false}
 selected=#windows;showStart=false;dirty=true
end
local function save()
 if not currentFile then message("Editor: erst Dateiname mit F2 angeben");return end
 local f,e=io.open(currentFile,"w");if not f then message(e or "Schreibfehler");return end
 f:write(document);f:close();message("Gespeichert: "..currentFile);refresh()
end
local function enterFile(s)
 local p=resolve(s);if fs.isDirectory(p)then location=p;refresh();message(location)
 else local f=io.open(p,"r");if not f then message("Kann Datei nicht oeffnen") return end
 document=f:read("*a") or "";f:close();if #document>1000 then document=document:sub(1,1000)end
 currentFile=p;openApp(4);message("Datei geoeffnet")end
end
local function say(s)console[#console+1]=tostring(s);if #console>60 then table.remove(console,1)end end
local function command(s)
 say("> "..s);local cmd,arg=s:match("^(%S+)%s*(.-)%s*$");if not cmd then return end
 if cmd=="help" then say("help ls cd pwd cat mkdir clear free exit")
 elseif cmd=="ls" then local n=0;for f in fs.list(location)do say(f);n=n+1;if n>=25 then break end end
 elseif cmd=="pwd" then say(location)
 elseif cmd=="free" then say(math.floor(pc.freeMemory()/1024).." KiB frei")
 elseif cmd=="clear" then console={}
 elseif cmd=="exit" then running=false
 elseif cmd=="cd" then local p=resolve(arg=="" and "/home" or arg);if fs.isDirectory(p)then location=p;refresh();say(location)else say("Pfad ungueltig")end
 elseif cmd=="mkdir" then if arg~="" then local ok=fs.makeDirectory(resolve(arg));say(ok and "Ordner angelegt" or "Fehler");refresh()end
 elseif cmd=="cat" then local f=io.open(resolve(arg),"r");if f then local n=0;for line in f:lines()do say(line);n=n+1;if n>=20 then break end end;f:close()else say("Datei nicht gefunden")end
 else say("Unbekannter Befehl")end
end
local function sky()
 for y=1,H-1 do
 local p=y/H
 local b=p<.60 and C.sky or p<.72 and C.hill or p<.87 and C.hill2 or C.green
 block(1,y,W,1,b)
 end
 if H>=28 then
 block(math.floor(W*.30),4,12,1,C.white);block(math.floor(W*.30)+4,3,12,1,C.white)
 block(math.floor(W*.73),7,10,1,C.white);block(math.floor(W*.73)+4,6,8,1,C.white)
 end
end
local function desktop()
 sky()
 local symbols={"[PC]","[D]","[FS]","[TXT]","[>_]","[CFG]","[RAM]","[BIN]"}
 for i=1,6 do local y=3+(i-1)*4;if y+1<H then
 label(3,y,symbols[i],C.white,C.sky,8)
 label(3,y+1,A[i],C.white,C.sky,21)end end
end
local function fileList(x,y,w,h)
 label(x,y,"Adresse: "..location,C.black,C.cream,w)
 block(x,y+2,w,1,C.pale);label(x+1,y+2,"Name",C.blue2,C.pale,w-2)
 local last=math.min(#files,fileOffset+h-4)
 for i=fileOffset+1,last do
  local yy=y+3+i-fileOffset-1
  local bg=i==choice and C.sel or C.white
  block(x,yy,w,1,bg);label(x+1,yy,files[i],C.black,bg,w-2)
 end
end
local function appContent(v)
 local x,y,w,h=v.x,v.y,v.w,v.h
 local lx,ty=x+3,y+5
 local maxw=w-6
 if v.id<=3 or v.id==8 then
  block(x+2,y+4,math.min(18,w-8),h-6,C.pale)
  label(x+3,y+5,"Dateiaufgaben",C.blue2,C.pale,15)
  label(x+3,y+7,"[+] Ordner",C.black,C.pale,15)
  label(x+3,y+9,"[..] Zurueck",C.black,C.pale,15)
  label(x+3,y+11,"[R] Aktualisieren",C.black,C.pale,16)
  fileList(x+21,y+5,w-24,h-7)
 elseif v.id==4 then
  label(lx,ty,currentFile or "Unbenannt",C.dim,C.paper,maxw)
  local yy=ty+2
  for line in (document.."\n"):gmatch("(.-)\n")do
   if yy>=y+h-2 then break end
   label(lx,yy,line,C.black,C.paper,maxw);yy=yy+1
  end
  label(lx,y+h-2,"Ctrl+S: Speichern | F2: neue Datei",C.dim,C.paper,maxw)
 elseif v.id==5 then
  block(x+2,y+4,w-4,h-6,0x111111)
  local yy=ty;local begin=math.max(1,#console-(h-9))
  for i=begin,#console do if yy>=y+h-3 then break end;label(lx,yy,console[i],C.white,0x111111,maxw);yy=yy+1 end
  label(lx,y+h-3,"> "..textInput.."_",0x89F69D,0x111111,maxw)
 elseif v.id==6 then
  label(lx,ty,"Systemsteuerung",C.blue2,C.paper)
  label(lx,ty+3,"Anzeige: XP Blau",C.black,C.paper)
  label(lx,ty+5,"Bildschirm: "..W.." x "..H,C.black,C.paper)
  label(lx,ty+7,"Dateiverwaltung: aktiv",C.black,C.paper)
 elseif v.id==7 then
  label(lx,ty,"Task-Manager",C.blue2,C.paper)
  label(lx,ty+2,"Gesamt-RAM: "..math.floor(pc.totalMemory()/1024).." KiB")
  label(lx,ty+3,"Frei: "..math.floor(pc.freeMemory()/1024).." KiB")
  label(lx,ty+5,"Fenster: "..#windows)
  label(lx,ty+7,"CPU: ereignisgesteuerte UI")
 end
end
local function drawWin(v,k)
 local x,y,w,h=v.x,v.y,v.w,v.h
 block(x,y,w,h,C.blue2);block(x+1,y+1,w-2,h-2,C.paper)
 local bar=k==selected and C.blue or C.blue2
 block(x+1,y+1,w-2,2,bar)
 label(x+3,y+1,A[v.id].." - NovaOS",C.white,bar,w-16)
 label(x+w-10,y+1,"[_][X]",C.white,bar,8)
 block(x+1,y+3,w-2,1,C.cream)
 label(x+3,y+3,"Datei  Bearbeiten  Ansicht  Extras  Hilfe",C.black,C.cream,w-6)
 appContent(v)
end
local function taskbar()
 block(1,H,W,1,C.blue)
 block(1,H,11,1,C.green);label(3,H,"Start",C.white,C.green,8)
 local x=13
 for k,v in ipairs(windows)do
  local s="["..A[v.id]:sub(1,8).."]"
  if x+#s<W-11 then label(x,H,s,C.white,k==selected and C.blue2 or C.blue,#s);x=x+#s+1 end
 end
 local m=math.floor(pc.uptime()/60)
 label(W-8,H,string.format("%02d:%02d",math.floor(m/60)%24,m%60),C.white,C.blue,6)
end
local function startMenu()
 if not showStart then return end
 local my=H-16;local width=43
 block(2,my,width,15,C.blue2);block(3,my+1,width-2,13,C.menu)
 block(3,my+1,width-2,2,C.blue)
 label(5,my+1,"Administrator  -  NovaOS",C.white,C.blue,width-4)
 block(25,my+3,19,10,C.pale)
 for i=1,7 do label(5,my+3+i,A[i]:sub(1,18),C.black,C.menu,18)end
 local links={"Eigene Dateien","Arbeitsplatz","Systemsteuerung","Task-Manager","Explorer"}
 for i,s in ipairs(links)do label(26,my+3+i,s,C.black,C.pale,17)end
 block(3,H-3,width-2,1,C.cream);label(5,H-3,"Abmelden",C.black,C.cream)
 label(25,H-3,"[X] Ausschalten",C.black,C.cream)
end
local function draw()
 desktop();for k,v in ipairs(windows)do if not v.hidden then drawWin(v,k)end end
 startMenu();taskbar()
 if status~="" and not showStart then label(32,2,status,C.white,C.sky,W-34)end
 dirty=false
end
local function hit(x,y)
 for k=#windows,1,-1 do local v=windows[k];if not v.hidden and x>=v.x and x<v.x+v.w and y>=v.y and y<v.y+v.h then return k end end
end
local function click(x,y)
 if y==H then
  if x<=11 then showStart=not showStart;dirty=true;return end
  local p=13
  for i,v in ipairs(windows)do local n=11;if x>=p and x<p+n then v.hidden=not v.hidden;selected=v.hidden and nil or i;dirty=true;return end;p=p+n end
 end
 if showStart then
  local my=H-16
  if x>=3 and x<=24 and y>=my+4 and y<=my+10 then openApp(y-my-3);return end
  if x>=25 and x<=44 and y>=my+4 and y<=my+8 then local links={2,1,6,7,3};openApp(links[y-my-3]);return end
  if y==H-3 and x>=25 and x<=44 then running=false;return end
  showStart=false;dirty=true
 end
 local k=hit(x,y)
 if k then
  local v=windows[k];selected=k
  if y<=v.y+2 then
   if x>=v.x+v.w-5 then table.remove(windows,k);selected=nil
   elseif x>=v.x+v.w-10 then v.hidden=true;selected=nil
   else drag={k,x-v.x,y-v.y}end
  elseif (v.id<=3 or v.id==8) and x>=v.x+21 and y>=v.y+8 then
   local i=fileOffset+y-(v.y+8)+1;if files[i]then choice=i;message(files[i])end
  end
  dirty=true;return
 end
 for i=1,6 do local yy=3+(i-1)*4;if x<=24 and y>=yy and y<=yy+1 then openApp(i);return end end
end
local function keyboard(ch,scan)
 local v=selected and windows[selected]
 if v and v.id==5 then
  if scan==28 then local s=textInput;textInput="";command(s)
  elseif scan==14 then textInput=textInput:sub(1,-2)
  elseif ch and ch>=32 and ch<=126 and #textInput<90 then textInput=textInput..string.char(ch)end
 elseif v and v.id==4 then
  if scan==14 then document=document:sub(1,-2)
  elseif scan==28 then document=document.."\n"
  elseif ch and ch>=32 and ch<=126 and #document<1000 then document=document..string.char(ch)end
 elseif v and v.id<=3 then
  if scan==28 and files[choice]then enterFile(files[choice])
  elseif scan==200 then choice=math.max(1,choice-1)
  elseif scan==208 then choice=math.min(#files,choice+1)
  elseif scan==14 then location=fs.path(location:sub(1,-2));refresh()
  end
 else
  if ch and ch>=49 and ch<=55 then openApp(ch-48)
  elseif ch==113 then showStart=not showStart end
 end
 dirty=true
end
local ok,err=xpcall(function()
 while running do
  local m=math.floor(pc.uptime()/60);if m~=minute then minute=m;dirty=true end
  if dirty then draw()end
  local e,a,b,d=pc.pullSignal(1)
  if e=="touch" then click(b,d)
  elseif e=="drag" and drag then
   local v=windows[drag[1]];if v then v.x=math.max(1,math.min(W-v.w,b-drag[2]));v.y=math.max(1,math.min(H-v.h-1,d-drag[3]));dirty=true end
  elseif e=="drop" then drag=nil
  elseif e=="key_down" then keyboard(b,d)
  elseif e=="interrupted" then running=false end
 end
end,debug.traceback)
g.setBackground(0x000000);g.setForeground(C.white);g.fill(1,1,W,H," ")
if not ok then error(err)end
