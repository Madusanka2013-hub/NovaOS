-- NovaOS 0.7 XP Visual Core - OpenComputers text GPU renderer
local c=require("component");local pc=require("computer")
local g=assert(c.gpu);g.bind(c.screen.address)
local mw,mh=g.maxResolution();pcall(g.setResolution,math.min(mw,100),math.min(mh,35))
local W,H=g.getResolution();assert(W>=55 and H>=22,"Need 55x22 screen")
local C={sky=0x4A91E6,sky2=0x2E79D7,cloud=0xFFFFFF,hill=0x7DBD39,grass=0x3A9828,dark=0x237E1F,bar=0x1654BF,bar2=0x10449D,start=0x349A31,white=0xFFFFFF,ink=0x202020,cream=0xF5F3EB,pale=0xDCEAF9,select=0x205DB5}
local icons={
 {"Arbeitsplatz",{"  BBBB  "," BWWWWB "," BBCCBB ","  BBBB  "}},
 {"Eigene Dateien",{"  YYYY  "," YYYYYY "," YWWWWY ","  YYYY  "}},
 {"Internet",{"  CCCC  "," CWWCC  ","CCWWCC  ","  CCCC  "}},
 {"Papierkorb",{"  WWWW  ","  WBBW  ","  WBBW  ","   WW   "}}
}
local pal={B=0x244E99,W=0xFFFFFF,C=0x36C5EB,Y=0xF4C650}
local chosen=nil;local menu=false;local active=true;local dirty=true
local function fill(x,y,w,h,b)if w>0 and h>0 then g.setBackground(b);g.fill(x,y,w,h," ")end end
local function put(x,y,s,fg,bg,max)if x<1 or y<1 or x>W or y>H then return end;g.setForeground(fg);g.setBackground(bg);g.set(x,y,tostring(s):sub(1,math.min(max or W,W-x+1)))end
local function bgAt(y)if y<3 then return C.sky2 elseif y<math.floor(H*.59) then return C.sky elseif y<math.floor(H*.72) then return C.hill elseif y<math.floor(H*.87) then return C.grass else return C.dark end end
local function wallpaper()
 for y=1,H-1 do fill(1,y,W,1,bgAt(y))end
 local x=math.floor(W*.40)
 fill(x,4,12,1,C.cloud);fill(x+3,3,13,1,C.cloud);fill(x+7,5,14,1,C.cloud)
 fill(math.floor(W*.78),6,9,1,C.cloud);fill(math.floor(W*.78)+3,5,9,1,C.cloud)
 for x=25,W,2 do local y=math.floor(H*.62)+math.floor(math.sin(x/12)*2);if y>4 and y<H-2 then put(x,y,"_",C.hill,bgAt(y))end end
end
local function image(x,y,pixels)
 for row=1,#pixels do
  local s=pixels[row]
  for col=1,#s do
   local ch=s:sub(col,col)
   if pal[ch] then
    local yy=y+row-1
    if yy<H then put(x+col-1,yy," ",pal[ch],pal[ch])end
   end
  end
 end
end
local function desktop()
 wallpaper()
 for i,v in ipairs(icons)do
  local y=3+(i-1)*6
  if y+5<H-1 then
   if chosen==i then fill(2,y,21,5,C.select) end
   image(5,y,v[2])
   local base=chosen==i and C.select or bgAt(y+4)
   put(3,y+4,v[1],C.white,base,20)
  end
 end
end
local function taskbar()
 fill(1,H,W,1,C.bar);fill(1,H,12,1,C.start)
 put(2,H,"* Start",C.white,C.start,10)
 fill(W-10,H,11,1,C.bar2)
 local m=math.floor(pc.uptime()/60)
 put(W-7,H,string.format("%02d:%02d",math.floor(m/60)%24,m%60),C.white,C.bar2,5)
end
local function startmenu()
 if not menu then return end
 local Y=H-17
 fill(2,Y,42,16,C.bar2);fill(3,Y+1,40,14,C.cream);fill(27,Y+4,16,9,C.pale)
 fill(3,Y+1,40,3,C.bar)
 put(5,Y+2,"Administrator",C.white,C.bar,30)
 local programs={"Internet Explorer","E-Mail","Media Player","Editor","Alle Programme"}
 local links={"Eigene Dateien","Eigene Bilder","Arbeitsplatz","Systemsteuerung","Suchen"}
 for i,s in ipairs(programs)do put(5,Y+4+i,s,C.ink,C.cream,20)end
 for i,s in ipairs(links)do put(28,Y+4+i,s,C.ink,C.pale,14)end
 fill(3,H-3,40,1,C.bar2)
 put(5,H-3,"Abmelden",C.white,C.bar2)
 put(23,H-3,"Ausschalten",C.white,C.bar2)
end
local function draw()desktop();startmenu();taskbar();dirty=false end
local previous,last=0,0
local function click(x,y)
 if y==H and x<=12 then menu=not menu;dirty=true;return end
 if menu then
  if x>=22 and x<=43 and y==H-3 then active=false;return end
  menu=false;dirty=true;return
 end
 for i=1,#icons do local yy=3+(i-1)*6
  if x<=23 and y>=yy and y<=yy+4 then
   chosen=i;dirty=true
   local now=pc.uptime()
   if previous==i and now-last<.45 then menu=true end
   previous=i;last=now;return
  end
 end
 chosen=nil;dirty=true
end
local ok,err=xpcall(function()
 local old=-1
 while active do
  local m=math.floor(pc.uptime()/60);if m~=old then old=m;dirty=true end
  if dirty then draw()end
  local e,a,b,d=pc.pullSignal(1)
  if e=="touch" then click(b,d)
  elseif e=="key_down" then
   if b==113 or b==81 then menu=not menu;dirty=true
   elseif b==27 then active=false end
  elseif e=="interrupted" then active=false end
 end
end,debug.traceback)
g.setBackground(0);g.setForeground(C.white);g.fill(1,1,W,H," ")
if not ok then error(err)end
