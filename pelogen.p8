pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
--pelogen lowpoly editor
--@shiftalow/bitchunk
--ver 0.2.3b
--utils
function tonorm(s)
if tonum(s) then return tonum(s)
elseif s=='true' then return true
elseif s=='false' then return false
elseif s=='nil' then return nil
end
return s
end

function tohex(p,n)
p=sub(tostr(tonum(p),1),3,6)
while sub(p,1,1)=='0' do
p=sub(p,2)
end
p=join(tbfill(0,(n or 0)-#p),'')..p
return p
end


function ttoh(h,l,b)
return bor(shl(tonum(h),b),tonum(l))
end
function htot(v)
return {lshr(band(v,0xff00),8),band(v,0xff)}
end

function ttable(p)
return type(p)=='table' and p
end

function replace(s,f,r)
local a=''
while #s>0 do
local t=sub(s,1,#f)
a=a..(t~=f and sub(s,1,1) or r or '')
s=sub(s,t==f and 1+#f or 2)
end
return a
end

function htbl(ht,ri)
local t,c,k,rt,p={},0
ri,ht=ri or 0,ri and ht or replace(ht,"\n")
while ht~='' do
p,ht=sub(ht,1,1),sub(ht,2)
if p=='{' or p=='=' then
rt,ht=htbl(ht,ri+1)
if rt then
if p=='=' then
t[k]=rt[1]
else
if k then
t[k]=rt
else
add(t,rt)
end
end
end
k=nil
elseif p=='}' or p==';' then
add(t,tonorm(k))
k=nil
return t,ht
elseif p==' ' then
add(t,tonorm(k))
k=nil
else
k=(k or '')..p
end
end
add(t,tonorm(k))
return t
end

mkrs,hovk=htbl'x y w h ex ey r p'
,htbl'{x y}{x ey}{ex y}{ex ey}'
function rfmt(p)
local x,y,w,h=unpack(ttable(p) or _split(p,' ',true))
return comb(mkrs,{x,y,w,h,x+w-1,y+h-1,w/2,p})
end

function exrect(p)
local o=rfmt(p)
return cat(o,{
cont=function(x,y)
if y then
return inrng(x,o.x,o.ex) and inrng(y,o.y,o.ey)
else
return o.cont(x.x,x.y) and o.cont(x.ex,x.ey)
end
end
,hover=function(r,p)
local h
for i,v in pairs(hovk) do
h=h or o.cont(r[v[1]],r[v[2]])
end
return h or p==nil and r.hover(o,true)
end
,ud=function(p,y,w,h)
return cat(
o,rfmt((tonum(p) or not p) and {p or o.x,y or o.y,w or o.w,h or o.h} or p
))
end
,rs=function(col,f)
local c=o.cam
f=(f or rect)(o.x-c.x,o.y-c.y,o.ex-c.x,o.ey-c.y,col)
return o
end
,rf=function(col)
return o.rs(col,rectfill)
end
,cs=function(col,f)
(f or circ)(o.x+o.r-o.cam.x,o.y+o.r-o.cam.y,o.w/2,col)
return o
end
,cf=function(col)
return o.cs(col,circfill)
end
,cam={x=0,y=0}
})
end

function toc(v,p)
return flr(v/(p or 8))
end

function join(s,d)
local a=''
for i,v in pairs(s) do
a=a..v..d
end
return sub(a,1,-1-#d)
end

_split,split=split,function(str,d,dd)
if dd then
local a,str={},split(str,dd)
while str[1] do
add(a,split(deli(str,1),d))
end
return a
end
return _split(str,d or ' ',false)
end

_bc={}
function htd(b,n)
local d={}
n=n or 2
for i=1,#b,n do
add(d,tonum('0x'..(sub(b,i,i+n-1))))
end
return d
end

function slice(r,f,t)
local v={}
for i=f,t or #r do
add(v,r[i])
end
return v
end

function cat(f,s)
for k,v in pairs(s) do
if tonum(k) then
add(f,v)
else
f[k]=v
end
end
return f
end

function comb(k,p)
local a={}
for i=1,#k do
a[k[i]]=p[i]
end
return a
end

function tbfill(v,n,r)
local t={}
if r and r>0 then
n,r=r,n
end
for i=0,n-1 do
t[i]=r and tbfill(v,r) or v
end
return t
end

function ecxy(p,f)
p=ttable(p) and p.x and p or rfmt(p)
for y=p.y,p.ey do
for x=p.x,p.ex do
f(x,y,p)
end
end
end

orc=exrect'-1 -1 3 3'
function outline(t,a)
local i,j,k,l=unpack(split(a))
ecxy(orc,function(x,y)
?t,x+i,y+j,l
end)
?t,i,j,k
end

function tmap(t,f)
for i,v in pairs(t) do
t[i]=f(v,i) or t[i]
end
return t
end

function mkpal(f,t)
return comb(htd(f,1),htd(t,1))
end
function ecmkpal(v)
return tmap(v,function(v,i)
i,v=unpack(v)
return tmap(v,function(v)
return mkpal(_ENV[i],v)
end)
end)
end
function ecpalt(p)
for i,v in pairs(p) do
if v==0 then
palt(i,true)
end
end
end

function inrng(c,l,h)
return mid(c,l,h)==c
end
function amid(c,a)
return mid(c,a,-a)
end

function bmch(b,m,l)
b=band(b,m)
return l and b~=0 or b==m
end
-->8
_sck=split'nm dur prm rate cnt rm'
function scorder(fn,d,p)
local o={}
return cat(o,comb(_sck,{
fn
,tonum(d)
,p
,function(d,r,c)
local f,t=unpack(ttable(d) or split(d))
r=r or o.dur
return (t-f)/r*min(c or o.cnt,r)+f
end
,0,false
}))	
end

_scal={}
function mkscenes(keys)
local s=add(_scal,{})
return s,tmap(ttable(keys) or {keys},function(v)
local o={}
s[v]=cat(o,comb(split'ps st rm cl fi cu sh us tra ords nm',{
function(fn,d,p)
return add(o.ords,scorder(fn,d,p))
end
,function(fn,d,p)
o.cl()
return o.ps(fn,d,p)
end
,function(s)
s=s and o.fi(s) or not s and o.cu()
if s then
del(o.ords,s).rm=true
end
return s
end
,function()
local s={}
while o.ords[1] do
add(s,o.rm())
end
return s
end
,function(key)
for v in all(o.ords) do
if v.nm==key or key==v then 
return v end
end
end
,function(n)
return o.ords[n or 1]
end
,function()
local v=o.cu()
return del(o.ords,v)
end
,function(s,d,p)
p=scorder(s,d,p)
o.ords=cat({p},o.ords)
return p
end
,function(n)
local c=o.cu(n)
if c then
local n=c.cnt+1
c.cnt,c.fst,c.lst=n==0x7fff and 1 or n,n==1,inrng(c.dur,1,n)
if c.rm or c.nm and _ENV[c.nm] and _ENV[c.nm](c) or c.lst then
o.rm(c)
end
end
end
,{},v
}))
end)
end

function scenesbat(b,p)
local res={}
tmap(split(b,' ',"\n"),function(v,i)
tmap(_scal,function(o,k)
local s,m,f,d=unpack(v)
if o[s] then
add(res,o[s][m](f,d,p or {}))
end
end)
end)
return res
end
-->8
dbg_str={}
isdebug=false
function dbg(str)
add(dbg_str,str)
end

function dbg_print()
dbg_each(dbg_str,0)
dbg_str={}
end

function dbg_each(tbl)
local c=0
tmap(tbl,function(str,i)
	if ttable(str) then	dbg_each(str)
	else
 	?str,0,(i-1)*6,15-(c%16)
//		p=p+#(tostr(str)..'')+1
		c+=1
	end
end)
//return p
end

vdmpl={}
function vdmp(v,x)
local tstr=htbl([[
number=#;string=$;boolean=%;function=*;nil=!;
]])
tstr.table='{'
local p,s=true,''
if x==nil then x=0 color(6) cls()
else
s=join(tbfill(' ',x),'')
end
v=ttable(v) and v or {v}
for i,str in pairs(v) do
	if ttable(str) then
	 add(vdmpl,s..i..tstr[type(str)])
		vdmp(str,x+1)
	 add(vdmpl,s..'}')
 p=true
	else
		if p then
		add(vdmpl,s)
		end
 vdmpl[#vdmpl]=vdmpl[#vdmpl]..tstr[type(str)]..':'..tostr(str)..' '
	p=false
	end
end
if x==0 then

--?join(vdmpl,"\n")
tmap(vdmpl,function(v)
?v 
end)
stop()
end
end


-->8

function _init()
menuitem(1,'play',function(v,i)

scenesbat[[
d st sc_d 0
k st sc_k 0
]]
end)
menuitem(2,'load',function(v,i)
scenesbat([[
d st spr_d 0
k st load_k 0
m cl
]],{t='exit form load: x',p='32 1 3 7'})
end)
menuitem(3,'save',function()
scenesbat([[
d st spr_d 0
k st save_k 0
m cl
]],{t='exit form save: x',p='32 1 13 7'})
end)
menuitem(4,'export',function(v,i)
scenesbat([[
d st spr_d 0
k st exp_k 0
m cl
]],{t='exit form export: x',p='32 1 8 7'})
end)

menuitem(5,'copy-code',function(v,i)
exportcode()
end)

poke(0x5f38,0)
poke(0x5f39,0)

btnc,btns,btrg,butrg=tbfill(0,8),{},{},{}
upsc,upscs=mkscenes(split'm k')
drsc,drscs=mkscenes(split'e d')

zoom=1
scale=1/zoom
arad=atan2(1/3,1)

vdist=4
prsp=4
xyz=htbl[[x y z]]
rada=htbl[[{1 0 0}{0 1 0}{0 0 1}]]
vfilti=2
//1 face, 2 line, 4 vertex
vfiltp=htbl[[0x1 0x7 0x2 0x4]]
vfilt=vfiltp[vfilti]
--eface=true
rolled=true
sizc=htbl[[15=3; 6=1; 1=0; 0=-1; 10=1;]]
kmap=htbl[[{-1 0} {1 0} {0 -1} {0 1}]]
wasd=htbl[[a d w s]]
view=exrect[[64 64 128 128]]
viewb=exrect[[64 64 128 128]]
rview=exrect[[0 0 128 128]]
opos=exrect[[0 0 0 0]]
orot=exrect[[0 0 0 0]]
oang=exrect[[0 0 0 0]]
oscl=exrect[[64 64 1 1]]
lpos=exrect[[-15 0 2 0]]
lpos.z=-1
view.z=64
viewb.z=64
culr=1
plgn_load({23})
btmr=vtxs
vtxs={}

genab=htbl[[x=true;y=true;z=true;]]
gedef=htbl[[x=false;y=false;z=false;]]
lsc=htbl'x{0x28 0x12}y{0x3b 0x13}z{0xdc 0x1d}'
lsci={}
tmap(lsc,function(v,i)
tmap(v,function(v)
lsci[v]=i
end)
end)

rfpt={}
rfp=tmap(split('8 9 10 11 12 13 14 15'),function(i)
local f=0
ecxy('0 0 4 4',function(x,y)
f+=shl(sget(x+i%16*8,y+toc(i%16,16)*8)~=0 and 1 or 0,12-y*4+3-x)
end)
add(rfpt,f+0.8)
return f
end)

spid=0
cvtxs={}
cvtx=0
vtxs={}
vtxsb={}
vcol=10
bgcol=5
opos.z=0
oposb=cat({},opos)
orot.z=0
orotb=cat({},orot)
oang.z=0
rview.z=0
ldps=3
vtxsl=1
vtxslb=1
vtxsll=0
vtxslf=1
dblwait=0

rothlf=32
rotful=64
scsize=128

tliw=0
llcnt=0
llpat=htbl[[
{0 3 ████}
{0 2 ░███}
{0 1 ░░██}
{0 0 ░░░█}
{3 3 █░░░}
{2 3 ██░░}
{1 3 ███░}
{1 2 ░██░}
]]
lfrom,lto,lltxt=unpack(llpat[llcnt+1])
llen=4

textured=nil
txrx=16
txry=0

floor=1

minpos=-7

mo=getmouse()
dragstart(opos,1)
dragstart(view,1)
dragstart(orot,1)
dragstart(lpos,1)


local obj={}
obj.rt=orot
obj.vt=vtxs

--clickp={}
--ecxy('-8 0 16 1',function(z)
--ecxy('-8 -8 16 16',function(x,y)
--add(clickp,{x,y,z})
--end)
--end)

cpals=0
cpalid=16
--cpalid=17
function lpal_i(i)
palx=i%16*8
paly=flr(i/16)*8
lpal=tbfill(0,16)
ecxy('0 0 2 1',function(c,r)
ecxy('0 0 4 8',function(x,y)
lpal[y+c*8]+=shl(sget(x+c*4+palx,y+paly),12-x*4)
end)
end)
end
lpal_i(cpalid)
--tmap(lpal,function(v,i)
--?(i..' '..v)
--end)
--stop()
scenesbat[[
d st def_d 0
k st edt_k 0
m st def_k 0
]]

--cubr=tbfill(6,3,3,3)
cubr=tbfill(tbfill(tbfill(6,3),3),3)
tmap(htbl[[
{{0 0 0}{0 0 0}{0 0 0}}
{{0 0 0}{0 15 0}{0 0 0}}
{{0 0 0}{0 0 0}{0 0 0}}
]],function(v,z)
tmap(v,function(v,y)
tmap(v,function(v,x)
cubr[z-1][y-1][x-1]=v
end)
end)
end)

--0:1
--1:
function def_d(o)
if not inrng(mo.x,8,120) or not inrng(mo.y,8,104) or xtzr or ytzr then
cls(lshr(lpal[bgcol],4))
clip(8,8,112,104)
rectfill(0,0,127,127,bgcol)
clip()
else
cls(bgcol)
end
local p=0

rectfill(64,64,64,64,7)
rfp,rfpt=rfpt,rfp
pal(0,lshr(lpal[bgcol],4))
textured=floor==2
objdraw(objrot({vt=btmr}))
textured=false
rfpt,rfp=rfp,rfpt
pal()

--base params
local msk=0xffff
local qv=vradq({orot.x,orot.y,orot.z},1/128)
--local qv=vradq({rview.x,rview.y,rview.z,orot.x,orot.y,orot.z},1/128)
local zr=8*64+prsp
local wz=view.z+prsp

--**draw glid**
fillp(0xcc33.8)
--clickp={x={},y={},z={}}

local c=genab.z and 13 or 6
if genab.x then
for i=max(opos.y-2,minpos),min(opos.y+2,7) do
local x=0
local y=genab.z and opos.y or i
local z=genab.z and i-opos.y+opos.z or opos.z
--line(unpack({line3(7+x,y,z,minpos+x,y,z,qv,c)},5))
end
end
if genab.y then
for i=max(opos.x-2,minpos),min(opos.x+2,7) do
local x=genab.z and opos.x or i
local y=0
local z=genab.z and i-opos.x+opos.z or opos.z
--line(unpack({line3(x,7+y,z,x,minpos+y,z,qv,c)},5))
end
end
if genab.z then
local st=genab.x and opos.x or opos.y
for i=max(st-2,minpos),min(st+2,7) do
local x=genab.x and i or opos.x
local y=genab.y and i or opos.y
local z=genab.x and 0 or 0
--line(unpack({line3(x,y,7+z,x,y,minpos+z,qv,c)},5))
end
end

local lx1={line3(7,opos.y,opos.z,0,opos.y,opos.z,qv,lsc.x[1])}
local lx2={line3(minpos,opos.y,opos.z,0,opos.y,opos.z,qv,lsc.x[2])}
local ly1={line3(opos.x,7,opos.z,opos.x,0,opos.z,qv,lsc.y[1])}
local ly2={line3(opos.x,minpos,opos.z,opos.x,0,opos.z,qv,lsc.y[2])}
local lz1={line3(opos.x,opos.y,7,opos.x,opos.y,0,qv,lsc.z[1])}
local lz2={line3(opos.x,opos.y,minpos,opos.x,opos.y,0,qv,lsc.z[2])}
local lo={line3(0,0,0,0,0,0,qv,0x100)}
local x1,y1,z1=lpos.x+64,lpos.y+64,lpos.z

local cuv=min(#vtxs,vtxsl)
--**line draw mode*
--local vs,vt=objdraw({vt=vtxs})
local vs,vt=objrot({vt=vtxs})
local pv={{x1,y1,z1,7},lo,lx2,ly2,lz2,lx1,ly1,lz1}
local filv,ctri={},{}
cvtxs={}
cvtx=0
--stop()
--vdmp(pv)
--local pv=bmch(vfilt,1)
local pv=bmch(vfilt,0)
 and cat(pv,vs)
 or {}
-- cursor(0,40)
local tcol,tcol2=toc(time()*20,4)%4*4,toc(time()*20,4)%2*4
tmap(pv,function(v,i)
v.s=v[3]
end)
quicksort(pv,1,#pv)

tmap(pv,function(v,i)

if v[4]==0x100 and bmch(vfilt,3,1) then
objdraw(vs,vt)
--objdraw(vs,vt)
--rectfill(0,20,30,40,8)
elseif v.i then
local z1=zr/(view.z-v[3]+prsp)
local x1,y1=v[1]*z1+view.x,v[2]*z1+view.y
--**vertex draw**
if inrng(mo.x,x1-2,x1+2) and inrng(mo.y,y1-2,y1+2) then
cvtx=v.i
spid=5
end

fillp()
add(cvtxs,v)
if inrng(v.i,vtxsl,vtxsl+vtxsll) then
--circfill(x1,y1,2,v.i==vtxsl and lshr(lpal[v[4]],toc(time()*20,4)%4*4) or 11)
add(filv,{x1,y1,2,lshr(lpal[v.i==vtxsl and v[4] or v[4]],tcol) or 11})
end
--if v.i==#vtxs and #vtxs>1 then
--local p=vt[v.i-1]
--local z2=zr/(view.z-p[3]+prsp)
--line(x1,y1,p[1]*z2+view.x,p[2]*z2+view.y,
--(v.i<3 or v.i%2==0) and 11 or 12)
--end
if bmch(4,vfilt,1) then
circ(x1,y1,2,v.t and 12 or lshr(lpal[v[4]],tcol2))
end
if cuv==v.i and vtxsll==0 and vtxsl>#vtxs then
ctri=vtxsl&1==0
 and {v,vt[v.i-1]}
  or {vt[v.i-1],v}
end
elseif vfilt~=0x1 and #v>8 then
if genab[lsci[v[4]]] then
fillp()
else
fillp(0x36c9.8)
end
line(unpack(v,5))
--end
if v[4]<0x20 then
rectfill(v[5]-1,v[6]-1,v[5]+1,v[6]+1,v[4])
end
fillp()
elseif vfilt~=0x1 and v[4]==7 then
--lightsource?
fillp(0xebeb.8)
line(v[1],v[2],64,64,0x7)
sspr(32,0,8,8,v[1]-3,v[2]-3,z1,z1)
fillp()
end
--pre=v
end)
fillp()
tmap(filv,function(v)
local x,y,r,c=unpack(v)
circfill(x,y,r,c)
circ(x,y,r,12)
end)
v=cubr
pfnc=circ

local q,vx,vy,vz=vrolq({0,opos.x,opos.y,opos.z},qv)
local zr=zr/(view.z-vz+prsp)

if not ctri[3] then
add(ctri,{vx,vy,vz,vcol},1)
end
if vfilt~=0x1 then
if bmch(2,vfilt,1) and ctri[3] then
--local c=min(#vtxs,vtxsl)
--local p1,p2,p3={vx,vy,vz}
--,vtxs[c]
--,vtxs[c-1]
--vdmp(ctri)
local v1,v2,v3=unpack(ctri)
local x1,y1,z1=unpack(v1)
local x2,y2,z2=unpack(v2)
local x3,y3,z3=unpack(v3)
color((x2-x1)*(y3-y1)-(x3-x1)*(y2-y1)<0 and v1[4] or lshr(lpal[v1[4]],8))
fillp(((0x36c9<<>time()*8)&0xffff)+0x.8)
--fillp(0x1248.8)
line(v3[1]*zr+view.x,v3[2]*zr+view.y,v1[1]*zr+view.x,v1[2]*zr+view.y)
tmap(ctri,function(v)
line(v[1]*zr+view.x,v[2]*zr+view.y)
end)
end
fillp()
circ(vx*zr+view.x,vy*zr+view.y,sin(time())*2+4,lshr(lpal[15],tcol))
end
rectfill(0,120,127,127,0)
for x=0,15 do
fillp()
rectfill(1+x*8,121,4+x*8,126,x)
fillp(0x0f0f)
rectfill(5+x*8,121,6+x*8,126,lshr(lpal[x],4))
end
fillp()
pset(1,121,5)
pal(7,vcol)
rect(vcol*8,120,vcol*8+8,127,lpal[vcol])
pal()
--local c=band(lpal[vcol],0xf)
--pal(mkpal('56dbc8$',(#vtxs<3 or vtxsl%2==1) and 'b0bb0'..c or '0cc0c'..c))
pal(15,lshr(lpal[vcol],tcol2+4))
pal(7,lshr(lpal[vcol],tcol2+8))
pal(14,lpal[vcol])
spr(spid,mo.x-3,mo.y-2)
local v=vtxs[vtxsl] or vtxs[vtxsl-1]
if v then
outline(v.i,join({mo.x,mo.y+5,14,15},' '))
end
pal()

--dbgs
dbg('★ '..join({opos.x,opos.y,opos.z},' '))
dbg('🅾️ '..join({flr(orot.x),flr(orot.y),flr(orot.z)},' '))
--dbg(join({orotb.x,orotb.y,orotb.z},' '))
--dbg(join({view.x,view.y,view.z},' '))
--dbg(join({dragst.x,dragst.y,dragst.z},' '))
--dbg(join({rview.x,rview.y,rview.z},' '))
dbg('✽ '..join({lpos.x,lpos.y,lpos.z},' '))
--dbg('o:'..join({orot.x,orot.y,orot.z},' '))
--dbg(stat(1))
?lltxt,96,0,7

end
function edt_k(o)
cat(genab,gedef)
local x,y
=cos(orot.y%rothlf/rothlf)>0
,cos(orot.x%rothlf/rothlf)>0
--=inrng(sgn(orot.x)*orot.x%64,-16,16)
--,inrng(sgn(orot.y)*orot.y%64,-16,16)
--genab.x=x and 1 or not y and -1
genab.x=x or not y
genab.y=y or not x and y
genab.z=not(genab.y and genab.x)
if keystate.x or keystate.c or keystate.z then
genab.x=keystate.x
genab.y=keystate.c
genab.z=keystate.z
end

--if mo.lut then
----**pick vertex**
--tmap(cvtxs,function(v)
--if inrng(mo.x,v[1]-1,v[1]+1) and inrng(mo.y,v[2]-1,v[2]+1) then
--vtxsl,vtxslb=v.i,vtxsl
--end
--end)
--end

if mo.lt then
dragstart(opos)
chold=true
elseif mo.lut then
chold=false
if vtxs[cvtx] and mo.x==mo.sx and mo.y==mo.sy then
cat(opos,comb(xyz,vtxs[cvtx]))
--vtxsl,vtxslb=cvtx,vtxsl
end
end

if keytrg.… then
--**undo pointer**
vtxsl,vtxslb=vtxslb,vtxsl
end
if mo.r and mo.lt and #vtxs>0 then
if keystate[' '] then

for i,v in pairs(vtxs) do
if vtxsl~=v.i and opos.x==v[1] and opos.y==v[2] and opos.z==v[3] then
vtxsl,vtxslb=v.i,vtxsl
break
--add(m,v.i)
end
end
else
local v=vtxs[min(vtxsl,#vtxs)]
opos.z=v[3]
opos.ud(v[1],v[2])
--vtxslb=vtxsl
vtxsl,vtxslb=#vtxs+1,vtxsl
vtxsll=0
end
end
--dbg(opos.sty)
if mo.r and mo.lt then
cat(orot,orotb)
end
if mo.l and mo.rt then
--**cancel cursor drag**
cat(opos,oposb)
chold=false
end

if not mo.r and mo.l and chold then
--**change edit color**
if mo.y>120 then
vcol=flr(min(mo.x/8,15))
chold=false
return
end

--**drag cursor**
if not keystate[' '] and mo.l then
scale=8
local p=tmap({dragdist(opos,orot)},function(v)
return mid(minpos,7,flr(v))
end)

--local p={dragdist(opos,orot)}
--tmap(xyz,function(v,i)
----local s=sgn(cos(orot[v]/128))
--s=genab[v] and del(p,p[1])+0.5 or opos[v]
----s=genab[v] and del(p,p[1])+0.5 or opos[v]
--opos[v]=mid(-8,7,flr(s))
--p=cat({},p)
--end)

opos.ud(genab.x and p[1] or opos.x,genab.y and p[2] or opos.y).z
=genab.z and (genab.y and p[3] or p[4]) or opos.z
scale=1

if opos.x+opos.y+opos.z~=oposb.x+oposb.y+oposb.z then
dblwait=12
end

end
end

if keytrg.★ then
vtxsll=-1
local svt,st,en=getsvt()
backvtxs()
vtxs[st],vtxs[en]=vtxs[en],vtxs[st]
vtxs[st].i=st
vtxs[en].i=en
--tmap(svt,function(vt)
--
--end)
end
if keytrg.█ then
--**select all vtx**
if vtxsl==#vtxs then
vtxsl,vtxslb=#vtxs+1,vtxsl
vtxsll=0
else
vtxsl,vtxslb=max(1,#vtxs),vtxsl
vtxsll=-max(#vtxs,1)+1
local v=vtxs[vtxsl]
if v then
opos.ud(v[1],v[2]).z=v[3]
end
end
end
--dbg(vtxsll)
if mo.r and keytrg['2'] or keytrg['"'] then
--** prev vtx **
		vtxsll=mid(vtxsll-1,#vtxs-vtxsl,-vtxsl)
 	vtxsl=mid(vtxsl,1,#vtxs)
elseif keytrg['2'] then
		vtxsl=max(vtxsl-1,1)
		vtxsll=0
end
if mo.r and keytrg['1'] or keytrg['!'] then
--** next vtx **
	vtxsll=mid(vtxsll+1,-vtxsl,#vtxs-vtxsl)
	vtxsl=mid(vtxsl,1,#vtxs)
--	vdmp({vtxsll,vtxsl})
elseif keytrg['1'] then
		vtxsl=min(vtxsl+1,#vtxs+1)
	 vtxsll=0
end

if mo.ldb then
--	local v={flr(opos.x),flr(opos.y),flr(opos.z),vcol}
-- vtxsb={}
--	tmap(vtxs,function(v)
--	add(vtxsb,cat({},v))
--	end)
backvtxs()
	
	if keystate.x then
		tmap(vtxs,function(v)
		v[2],v[3]=-v[3],v[2]
		end)
		return
	elseif keystate.c then
		tmap(vtxs,function(v)
		v[1],v[3]=-v[3],v[1]
		end)
		return
	elseif keystate.z then
		tmap(vtxs,function(v)
		v[1],v[2]=-v[2],v[1]
		end)
		return
	end
	
	local v={flr(opos.x),flr(opos.y),flr(opos.z),vcol}
	if keystate[' '] then
	vtxs=tmap(cat(cat(slice(vtxs,1,vtxsl),{v}),slice(vtxs,vtxsl+1)),function(v,i)
	v.i=i
--	v.p=vtxs[v.i-1]
	end)
	vtxsl+=1
	

	elseif vtxsll~=0 or vtxsl<=#vtxs then
	 local sv,st,en=getsvt()
		local ismv=v[1]~=vtxs[en][1] or v[2]~=vtxs[en][2] or v[3]~=vtxs[en][3]
	 tmap(sv,function(vt)
			ecxy('1 0 3 1',function(a)
			vt[a]+=v[a]-vtxs[en][a]
			end)
			vt[4]=ismv and vt[4] or vcol
	 end)
--		ecselvt(function(vt,st,en)
--		local ismv=v[1]~=vtxs[en][1] or v[2]~=vtxs[en][2] or v[3]~=vtxs[en][3]
--			ecxy('1 0 3 1',function(a)
--			vt[a]+=v[a]-vtxs[en][a]
--			end)
--			vt[4]=ismv and vt[4] or vcol
--		end)
	 
	else
	add(vtxs,v)

	v.i=#vtxs
--	v.p=vtxs[v.i-1]
	if v.i>1 then
end
	vtxsl,vtxslb=#vtxs+1,vtxsl
	vtxslf=vtxsl
	end
end
if mo.rdb then
--vtxsb={}
--tmap(vtxs,function(v)
--add(vtxsb,cat({},v))
--end)
backvtxs()

	if keystate[' '] then
	vtxs[vtxsl]=nil
	vtxsl=max(1,vtxsl-1)
	else
	del(vtxs,vtxs[vtxsl<#vtxs+1 and vtxsl or #vtxs])
	vtxs=cat({},vtxs)
	vtxsl,vtxslb=#vtxs+1,vtxsl
	vtxsll=0
	end
	tmap(vtxs,function(v,i)
	v.i=i
--	v.p=vtxs[v.i-1]
	end)
end
--cpals=(cpals+1)%3
--lpal_i(cpalid+cpals)

end

end
function def_k(o)
--input key as view control
oscl.w=1
oscl.h=1
--if o.fst then
--end

if keystate['9'] then
tliw+=0.01
elseif keystate['0'] then
tliw-=0.01
end

if not keystate.█ then
tmap(kmap,function(v,i)
if btnp(i-1) then
opos.x+=kmap[i][1]
opos.y+=kmap[i][2]
end
end)
opos.z-=(keytrg['['] and 1 or keytrg[']'] and -1 or 0)

end

spid=0

if mo.lt then
dragstart(view)
chold=true
elseif mo.lut then
chold=false
--**[cancel] drag cursor**
cat(oposb,opos)

end


--if mo.lt then
--dragstart(opos)
--dragstart(view)
--chold=true
--elseif mo.lut then
--chold=false
--end

if keystate[' '] and mo.l then
--**drag view**
--sss+=1.01
--spid=1
--local x,y=dragrot(view,{x=0,y=0,z=0})
local x,y=dragdist(view,{x=0,y=0,z=0})
view.ud(x,y)
else
--opos cursor control
end
dblwait=max(0,dblwait-1)

--local xr,yr=not inrng(mo.x,8,120),not inrng(mo.y,8,104)
--xtzr=(xtzr and not yr) or xr
--ytzr=(ytzr and not yr) or yr

if mo.rt then
xtzr,ytzr=not inrng(mo.x,8,120),not inrng(mo.y,8,104)
chold=true
cat(viewb,view)
if mo.y>120 then
bgcol=flr(min(mo.x/8,15))
chold=false
return
end

elseif mo.rut then
cat(orotb,orot)
end

if mo.r and chold then

--**rotate view**
rolled=true
spid=2
dragstart(orot)
dragstart(rview)
local y,x,zy,zx=dragrot(orot,{x=0,y=0,z=0})
--local x,y,zx,zy=dragrot(orot,{x=0,y=0,z=0})
--z=orot.z
local z=orot.z
if ytzr then
spid=3
z=zy
y=orot.y
end
if xtzr then
spid=3
z=zx
x=orot.x
end

if keystate[' '] then
--**rot z and fix rot x-y **
local zr=64/view.z
--local qv=vradq({opos.x*8,opos.y*8,opos.z*8},1/rotful)
--local q,x1,y1,z1=vrolq({0,view.x-64,view.y-64,view.z-64},qv)
local x,y=dragrot(rview,{x=0,y=0,z=0})

--lpos.ud(x,y)
rview.ud(x,y)


end
--**rot view with one axis 
if keystate.x then
x,y,z=y,orot.y,orot.z
end
if keystate.c then
x,y,z=orot.x,y,orot.z
end
if keystate.z then
x,y,z=orot.x,orot.y,x+y
end

if mo.l then

elseif not keystate[' '] then
orot.z=amid(z,32)
orot.ud(amid(x,32),amid(y,32))
end



--orot.ud(inrng(x,128,-128) and x or -sgn(x)*128
--,inrng(y,128,-128) and y or -sgn(y)*128)

--end
else
ytzr=false
xtzr=false
end

if mo.mt then
vcol=vtxs[vtxsl] and vtxs[vtxsl][4] or vcol
dragstart(lpos)
end

if mo.m then
local x,y=dragdist(lpos,{x=0,y=0,z=0})
if keystate[' '] then
lpos.z-=mo.w*2
lpos.z=x+y
else
lpos.ud(x,y)
end
end

if not mo.m then
if keystate[' '] then
spid=1

--mo.ldb=false
--mo.rdb=false
--dbg(mo.ldb)
view.z-=mo.w*4
else
--vcol=(vcol+16+mo.w)%16
opos.z=mid(opos.z+amid(mo.w,1),minpos,7)
--orot.z-=mo.w*2
end
end

if keystate['0'] then
chold=false
if mo.r then

orot.ud(0,0).z=0
rview.ud(0,0).z=0
elseif mo.l then
opos.ud(0,0).z=0
oposb.ud(0,0).z=0
elseif keystate[' '] then
view.ud(64,64).z=64
elseif mo.m then
lpos.ud(1,-5).z=-1
else
end
end

if keytrg.▥ then
vtxs,vtxsb=vtxsb,vtxs
end

if keytrg["\t"] then
vfilti=vfilti%#vfiltp+1
vfilt=vfiltp[vfilti]
--eface=not eface
end
if mo.mdb then
if keystate[' '] then
llcnt=llcnt+#llpat-1&0x7
else
llcnt=llcnt+1&0x7
end
lfrom,lto,lltxt=unpack(llpat[llcnt+1])
llen=lto-lfrom+1
--obj.rt=orot
--obj.vt=vtxs

end
function sc_d(o)
cls(bgcol)
orot.y+=0.5
objdraw(objrot({vt=vtxs}))
--?lltxt,96,0,7
end
function sc_k(o)
if o.fst then
oscl.w=1
oscl.h=1
end
--oscl.w=8
--oscl.h=8

--oscl.w=1+(mo.x-mo.sx)/128*8
--oscl.h=1+(mo.y-mo.sy)/128*8

if not keystate.█ then
tmap(kmap,function(v,i)
if btn(i-1) or btn(i-1,1) then
view.x-=kmap[i][1]
view.y-=kmap[i][2]
end
end)
end
if keystate.x then
scenesbat[[
d st def_d 0
k st edt_k 0
]]
return 1
end
end
function spr_d(o)
cls()
spr(0,0,0,16,16)
if keystate.z then
rectfill(0,0,127,7,1)
end
outline(o.prm.t,o.prm.p)
fillp(0xcc33)
local r=o.prm.ra or o.prm.r or {}
tmap(r.x and {r} or r,function(r,i)
r.rs(0x16)
outline(i,r.x..' '..r.y..' 0 7')
end)
fillp()
if(o.prm.cr)o.prm.cr.rs(7)

end
function exp_k(o)
if o.fst then
keytrg["\r"]=false
o.prm.ra={}
end
local i=mo.lt and #o.prm.ra+1 or #o.prm.ra
local c,s=selcell(o.prm)
o.prm.ra[i]=s or o.prm.ra[i]
del(o.prm.ra,mo.rt and o.prm.ra[#o.prm.ra])
--o.prm.r=mo.rt and {} or o.prm.r
--o.prm.cr=c or o.prm.cr

if keytrg.z then
local objs={}
tmap(o.prm.ra or {},function(r)
local ids={}
ecxy({toc(r.x),toc(r.y),toc(r.w),toc(r.h)},function(x,y)
add(ids,x+y*16)
end)
local g='--'..getgfx(r)
add(objs,g.."\n{"..join(ids,',')..'}')
end)
local u=[[
function _update()
cls()
plgn_render(1,{64,64,64},{time()*4,time()*4,time()*4},{1,1,1})
?'pelogen @) shiftalow/bitchunk',0,120,7
end
]]
printh("plgn_load({\n--paste the gfx code into the sprite sheet.\n"..join(objs,",\n").."\n--put the pasted sprite id in an array.\n})\n"..u,'@clip')
--o.prm.r={}
end

if keystate.x then
scenesbat[[
d st def_d 0
k st edt_k 0
m st def_k 0
]]
return 1
end
end
function save_k(o)
if o.fst then
keytrg["\r"]=false
end
--local r=o.prm.cr

local c,s=selcell(o.prm)
--o.prm.r=s or o.prm.r
--o.prm.cr=c or o.prm.cr

if o.prm.r then
if keytrg["\r"] or keytrg.z then
poke(0x5f30,1)
local st=0x40*32
local ids={}
--local r=o.prm.r
local r=o.prm.r
ecxy({toc(r.x),toc(r.y),toc(r.w),toc(r.h)},function(x,y)
add(ids,x+y*16)
end)

local sec,seci=0,1
tmap(vtxs,function(v,i)
if ids[1] then
poke2
(ids[1]%16*4+toc(ids[1],16)*8*0x40
+(i-1)%2*2+toc((i-1)%16,2)*0x40
,bor((v[1]+8)+(v[2]+8)*16+(v[3]+8)*256,shl(v[4],12))
)
sec+=1
if sec==16 then
ids=slice(ids,2)
sec=0
end
end
end)
cstore(0,0,0x2000)

end
end
if keystate.x then
scenesbat[[
d st def_d 0
k st edt_k 0
m st def_k 0
]]
return 1
end
end
function load_k(o)
if o.fst then
--keytrg["\r"]=false
end
local c,s=selcell(o.prm)
--o.prm.r=s or o.prm.r
--o.prm.cr=c or o.prm.cr
if o.prm.r then
if keytrg["\r"] or keytrg.z then
poke(0x5f30,1)
local ids={}
local r=o.prm.r
r.ud(toc(r.x),toc(r.y),toc(r.w),toc(r.h))

ecxy({r.x,r.y,r.w,r.h},function(x,y)
add(ids,x+y*16)
end)


plgn_load(ids)
scenesbat[[
d st def_d 0
k st edt_k 0
m st def_k 0
]]
return 1
end
end
if keystate.x then
scenesbat[[
d st def_d 0
k st edt_k 0
m st def_k 0
]]
return 1
end
end



end
function _update60()
tmap(btnc,function(v,i)
btns[i]=btn(i)
v=btn(i) and v+1 or 0
butrg[i]=v<btnc[i]
btnc[i]=v
btrg[i]=v==1
end)
tl,tr,tu,td,tz,tx,te=unpack(btrg,0)
mo=getmouse()
updatekey()
--presskey=getkey()
--panholdck()
--dbg(panhold[' '])

tmap(upscs,function(v)
upsc[v].tra()
end)
end
function _draw()
tmap(drscs,function(v)
drsc[v].tra()
end)
--dbg(stat(1))
isdebug=true
--dbg(llen)
--dbg(bmch(vfilt,3,1))
--dbg(vtxsl)
--dbg(vcol)
--dbg(llcnt)
dbg_print()
end

-->8
--control
mousestate,mousebtns,moky=unpack(htbl([[
{l=0;r=0;m=0;stx=0;sty=0;x=0;y=0;lh=0;rh=0;mh=0;}
{m r l}
{x y l r m w sx sy lh rh mh}
]]))

poke(0x5f2d,1)
function getmouse()
local mb=stat(34)
local mst=mousestate
local mo=comb(moky,
{stat(32)
,stat(33)
,band(mb,1)>0
,band(mb,2)>0
,band(mb,4)>0
,stat(36)
,mst.stx
,mst.sty
,mst.hl
,mst.hr
,mst.hm
})

function ambtn()
return mo.lt or mo.rt or mo.mt
end

tmap(mousebtns,function(k)
local ut,t,h=k..'ut',k..'t',k..'h'
if mo[k] then 
mst[k]+=1
mo[ut]=false
else
mo[ut]=mst[k]>0
mst[k]=0
end
mo[t]=mst[k]==1

mo[k..'db']=mo[t] and mst[h]>0
mst[h]=max(0,mst[h]-1)
if mo[t] then
mst[h]=mo[k..'db'] and 0 or 12
end

end)

if ambtn() then
mst.stx,mst.sty=mo.x,mo.y
end

mo.sx,mo.sy=mst.stx,mst.sty

mo.mv=(mo.x~=mst.x) or (mo.y~=mst.y)
mst.x,mst.y=mo.x,mo.y

return mo
end
dragst=htbl[[x=0;y=0;z=0;]]
function dragstart(vw,f)
if ambtn() or f then
vw.stx,vw.sty,vw.stz=vw.x,vw.y,vw.z
--local qv=vradq({orot.x,orot.y,orot.z},1/rotful)
--vw.stq,vw.stx,vw.sty,vw.stz=vrolq({0,vw.x,vw.y,vw.z},qv)
end
end

function dragrot(vw,rv)
--local qx,qy,qz=vradq({x=rv.x,y=rv.y,z=rv.z},1/rotful,rx,ry,rz)
local qv=vradq({rv.x,rv.y,rv.z},1/rotful)
local x,y,zx,zy=mo.x-mo.sx,mo.y-mo.sy,mo.x-mo.sx,mo.y-mo.sy
local q,x,y,zx=vrolq({0,x,y,zx},qv)
return
-- x/scsize*rotful+dragst.y
--,y/scsize*rotful+dragst.x
--,zx/scsize*rotful+dragst.z
--,zy/scsize*rotful+dragst.z
 x/scsize*rotful+vw.sty
,y/scsize*rotful+vw.stx
,zx/scsize*rotful+vw.stz
,zy/scsize*rotful+vw.stz
end

function dragdist(vw,rv)

local qv=vradq({rv.x,rv.y,rv.z},1/scsize)
local x,y,zx,zy=mo.x-mo.sx,mo.y-mo.sy
,mo.x-mo.sx
,mo.y-mo.sy
--,genab.y and mo.x-mo.sx or 0
--,genab.x and mo.y-mo.sy or 0
--local q,x,y,zx=vrolq({0,x,y,zx},qv)
--local q,x,y,zx=vrolq({0,genab.x and x or zx,genab.y and y or zy,zx},qv)

return
 x/scale+vw.stx
,y/scale+vw.sty

-- x/scale+(genab.x and vw.stx or vw.stz)
--,y/scale+(genab.y and vw.sty or vw.stz)
,zx/scale+vw.stz
,zy/scale+vw.stz

-- x/scale*rvrsa('x')+(genab.x and vw.stx or vw.stz)
--,y/scale*rvrsa('y')+(genab.y and vw.sty or vw.stz)
end
function rvrsa(a)
return sgn((a=='y' and cos or sin)((orot[a]-16)/scsize))
end

--btnstat={}
function statkeys()
local k={}
local i=0
while stat(30) do
k[stat(31)..'']=true
i+=1
end
return k
end


function updatekey()
--btnstat=statkeys()
local s=tmap(statkeys(),function(v,i)
presskey[i]=v
end)
--tmap(cat(presskey,btnstat),function(v,i)
tmap(presskey,function(v,i)
--local s=statkeys()
--tmap(s,function(v,i)
--presskey[i]=v
keytrg[i]=s[i]
panholdck(s,i)
end)
end
function getkey()
return presskey
end

presskey=''
presskey={}
panhold=0
panhold={}
keystate={}
keytrg={}


function panholdck(s,k)
k=k or ''
panhold[k]=panhold[k] or 0
panhold[k]+=min(1,panhold[k])

if s[k] then
--if s[k] then
 keystate[k]=true
 panhold[k]=panhold[k]>1 and 28 or 1
elseif panhold[k]>31 then
 keystate[k]=false
 panhold[k]=0
end
--dbg(panhold[k])
end

function selcell(prm)
--mx=17
local cr,sr=exrect'0 0 8 8'
cr.ud(toc(mo.x)*8,toc(mo.y)*8)
if mo.l then
local x,y=toc(mo.sx)*8,toc(mo.sy)*8
local reqn=toc(mx or 32767,16)+1
local w,h
=max(8,toc(mo.x+8)*8-x)
,max(8,toc(mo.y+8)*8-y)
--dbg(toc(reqn*8,h+8)*8)
--dbg(reqn)
--o.prm.r.ud(r.x,r.y
sr=exrect'0 0 0 0'.ud(x,y
--w h*w
,mid(8,w,toc(reqn*8,h)*8)
,mid(8,h,toc(reqn*8,w)*8))
--,mid(8,w,toc(reqn,toc(h+8))*8)
--,mid(8,h,toc(reqn,toc(w+8))*8))
end

prm.r=sr or prm.r
prm.cr=cr or prm.cr

return cr,sr
end


--function ecselvt(f)
-- local st=max(1,min(vtxsl+vtxsll,vtxsl))
-- local en=min(#vtxs,max(vtxsl+vtxsll,vtxsl))
--	for i=st,en do
--	f(vtxs[i],st,en)
--	end
--end

function getsvt()
local st,en,s
=max(1,min(min(vtxsl,#vtxs)+vtxsll,vtxsl))
,min(#vtxs,max(vtxsl+vtxsll,vtxsl))
,{}
for i=st,en do
add(s,vtxs[i])
end
return s,st,en
end

function backvtxs()
vtxsb={}
tmap(vtxs,function(v)
add(vtxsb,cat({},v))
end)
end
-->8
--draw code

function line3(x1,y1,z1,x2,y2,z2,qv,c,f)
local q,x1,y1,z1=vrolq({0,x1,y1,z1},qv)
local q,x2,y2,z2=vrolq({0,x2,y2,z2},qv)
local zr=64*8+prsp
local zl1=zr/(view.z-z1+prsp)
local zl2=zr/(view.z-z2+prsp)
local xl1,yl1,xl2,yl2=x1*zl1+view.x,y1*zl1+view.y,x2*zl2+view.x,y2*zl2+view.y
--if bmch(vfilt,2) then
--f=f or line
--f(x1,y1,x2,y2,c)
--end
--return x2,y2,z2,c
return x1,y1,z1,c,xl1,yl1,xl2,yl2,c
end

--todo apply to globalview localview
function vradq(v,s)
--return {radq(1*s,{rview.x*s,rview.y*s,rview.z*s})}
--return tmap(cat(v,{rview.x,rview.y,rview.z}),function(a,i)
return tmap(v,function(a,i)
i=(i-1)%3+1
return radq(a*s,normalize(rada[i][1],rada[i][2],rada[i][3]))
--return radq(a*s,{normalize(rada[i],1)})
end)

end

function vrolq(v,q)
--local rx,ry,rz=vradq(orotb,1/128)
local v1,v2,v3,v4=v[1],v[2],v[3],v[4]
for i,r in pairs(q) do
v1,v2,v3,v4=rolq(r[1],r[2],r[3],r[4],v1,v2,v3,v4)
end
return v1,v2,v3,v4
end

-->8
--for 3d render

function plgn_load(ids)
local ts={}
tmap(ids,function(v,i)
local l,t=v%16*8,toc(v,16)*8
ecxy('0 0 2 8',function(x,y)
x=x*4+l
y+=t
if sget(x,y)~=0 then
add(ts,{
sget(x,y)-8
,sget(x+1,y)-8
,sget(x+2,y)-8
,sget(x+3,y)
,i=#ts+1
})
else
end
end)
end)
vtxs=#ts>0 and ts or vtxs
end

--sort
function quicksort(v,s,e)
if(s>=e)return
local p=s
for i=s+1,e do
if v[i].s<v[s].s then
p+=1
v[p],v[i]=v[i],v[p]
end
end
v[s],v[p]=v[p],v[s]
quicksort(v,s,p-1)
quicksort(v,p+1,e)
end

--quaternion
function radq(r,v)
local s=sin(r)
return {cos(r),v[1]*s,v[2]*s,v[3]*s}
end

function qprd(r1,r2,r3,r4,q1,q2,q3,q4)
return
 q1*r1-q2*r2-q3*r3-q4*r4
,q1*r2+q2*r1+q3*r4-q4*r3
,q1*r3+q3*r1+q4*r2-q2*r4
,q1*r4+q4*r1+q2*r3-q3*r2
end
function rolq(r1,r2,r3,r4,q1,q2,q3,q4)
return qprd(r1,-r2,-r3,-r4,qprd(q1,q2,q3,q4,r1,r2,r3,r4))
end

function light(c,r)
local s=mid(r*llen+lfrom,lfrom,lto)
return c>>>flr(s)*4&0xff,rfp[mid(0,7,flr((s&0x.ffff)*7))+1]
end

function dot(v1,v2)
	return v1[1]*v2[1]+v1[2]*v2[2]+v1[3]*v2[3]
end

function cross(v1,v2)
return v1[2]*v2[3]-v1[3]*v2[2],v1[3]*v2[1]-v1[1]*v2[3],v1[1]*v2[2]-v1[2]*v2[1]
end

function normalize(x,y,z)
local l=1/sqrt(x*x+y*y+z*z)
return {x*l,y*l,z*l}
end

function objrot(o)
local zr=1
local vt={}
local tr={}
local vs={}
local qv=vradq({orot.x,orot.y,orot.z},1/128)
local vtx=o.vt
local orot=o.rt
vs=tmap(cat({},vtx),function(v,i)
local q,vx,vy,vz=vrolq({0,v[1],v[2],v[3]},qv)

v=cat({},{
vx*zr*oscl.w
,vy*zr*oscl.h
,vz*zr,v[4]
,i=i
})
vt[v.i]=v
return v
end)

return vs,vt
end
--function objdraw(o)
function objdraw(vs,vt)
tmap(rolled and vs or {},function(v,i)
v.s=i>2 and v[3]+vs[i-1][3]+vs[i-2][3] or v[3]
end)
quicksort(vs,1,#vs)

local lp=normalize(lpos.x,lpos.y,lpos.z)
local sl=vtxsl
local zr=1
local vi,pr,pl=view,prsp,lpal
local tcol=toc(time()*20,4)%4*4
for i,v in pairs(vs) do
if v.i>2 then
local v1,v2,v3=v,vt[v.i-1],vt[v.i-2]
if v.i&1==1 then
v1,v3=v3,v1
end
local x1,y1,z1=v1[1],v1[2],v1[3]
local x2,y2,z2=v2[1],v2[2],v2[3]
local x3,y3,z3=v3[1],v3[2],v3[3]
local c,fp
if sl==v.i then
c,fp=unpack({pl[v[4]]>>>tcol,0})
else
c,fp=light(
pl[v[4]]
,dot(
lp
,normalize(cross(
normalize(x1-x3,y1-y3,z1-z3)
,normalize(x2-x3,y2-y3,z2-z3)
))
))
end
local cull=(x2-x1)*(y3-y1)-(x3-x1)*(y2-y1)<0
if cull then
if fp then
zr=8*64+pr
local z1,z2,z3
=zr/(vi.z-z1+pr)
,zr/(vi.z-z2+pr)
,zr/(vi.z-z3+pr)
if bmch(vfilt,1) then
pelogen_tri
(x1*z1+vi.x
,y1*z1+vi.y
,x2*z2+vi.x
,y2*z2+vi.y
,x3*z3+vi.x
,y3*z3+vi.y
,c,fp)
else
line(x1*z1+vi.x
,y1*z1+vi.y
,x2*z2+vi.x
,y2*z2+vi.y,c)
line(x3*z3+vi.x
,y3*z3+vi.y)
line(x1*z1+vi.x
,y1*z1+vi.y)
end
end
end
end
end
end
--trifill
function pelogen_tri(l,t,c,m,r,b,col,f)
color(col)
fillp(f)
if(t>m) l,t,c,m=c,m,l,t
if(t>b) l,t,r,b=r,b,l,t
if(m>b) c,m,r,b=r,b,c,m
local i,j,k,r=(c-l)/(m-t),(r-l)/(b-t),(r-c)/(b-m),l
while t~=b do
for t=ceil(t),min(flr(m),127) do
rectfill(l,t,r,t)
r+=j
l+=i
end
l,t,m,i=c,m,b,k
end
end
-->8
--export

function getgfx(r)
local p=''
ecxy({r.x,r.y,r.w,r.h},function(x,y)
p=p..tohex(sget(x,y),1)
end)
return "[gfx]"..join({tohex(r.w,2),tohex(r.h,2),p},'').."[/gfx]"
end

function exportcode()
printh([[
--generated by pelogen
--@shiftalow/bitchunk
--v_ex0.2.3
--**color palette for light**--
]]..getgfx(exrect({palx,paly,8,8}))..
[[

--**cut & paste to sprite sheet**--
cpalid=--sprite id as a color palette

]]
..[[rfp={]]..join(tmap(rfp,function(v)return '0x'..tohex(v,4)end),',')..[[}
function plgn_load(r)
lpos=normalize(-15,0,2)
gvtx={}
vtxs={}
prspx=4
prspy=4
prspz=4
culr=1
lfrom,lto,llen=0,3,4
rothlf=32
rotful=64
palx=cpalid%16*8
paly=flr(cpalid/16)*8
--xyz=split('x y z')
rada={{0,1,0},{1,0,0},{0,0,1}}
lpal={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
lpal[0]=0
for c=0,1 do
for y=0,7 do
for x=0,3 do
lpal[y+c*8]+=shl(sget(x+c*4+palx,y+paly),12-x*4)
end
end
end
cls()
objl={}
for i,ids in pairs(r) do
local ts={}
for i,v in pairs(ids) do
local l,t=v%16*8,flr(v/16)*8
for y=0,7 do
y+=t
for x=0,1 do
x=x*4+l
if sget(x,y)~=0 then
add(ts,{
sget(x,y)-8
,sget(x+1,y)-8
,sget(x+2,y)-8
,sget(x+3,y)
,i=#ts+1
})
end
end
end
end
objl[i]=ts
end
return objl
end

--quaternion
function radq(r,v)
local s=sin(r)
return {cos(r),v[1]*s,v[2]*s,v[3]*s}
end

function qprd(r1,r2,r3,r4,q1,q2,q3,q4)
return
 q1*r1-q2*r2-q3*r3-q4*r4
,q1*r2+q2*r1+q3*r4-q4*r3
,q1*r3+q3*r1+q4*r2-q2*r4
,q1*r4+q4*r1+q2*r3-q3*r2
end

function rolq(r1,r2,r3,r4,q1,q2,q3,q4)
return qprd(r1,-r2,-r3,-r4,qprd(q1,q2,q3,q4,r1,r2,r3,r4))
end

function light(c,r)
local s=mid(r*llen,lfrom,lto)
return c>>>flr(s)*4&0xff,rfp[mid(1,8,flr((s&0x.ffff)*7)+1)]
end

function dot(v1,v2)
	return v1[1]*v2[1]+v1[2]*v2[2]+v1[3]*v2[3]
end

function cross(v1,v2)
return v1[2]*v2[3]-v1[3]*v2[2],v1[3]*v2[1]-v1[1]*v2[3],v1[1]*v2[2]-v1[2]*v2[1]
end

function normalize(x,y,z)
local l=1/sqrt(x*x+y*y+z*z)
return {x*l,y*l,z*l}
end

//**
//* m:int model_id
//* v:vecter pos
//* r:vectrr rot
//**/
function plgn_render(m,v,r,s)
local zr=8*64+prspx
local vt={}
local tr={}
local vs={}
local wx,wy,wz=v[1],v[2],v[3]
local r={r[1],r[2],r[3]}
local ra=1/rotful

local q={}
for i,v in pairs(r) do
add(q,radq(v*ra,rada[i]))
end
--local vs=gvtx[o.t] or {}
local vs={}

if #vs==0 then
for i,v in pairs(objl[m]) do
local v1,v2,v3,v4=0,v[1],v[2],v[3]
for i,r in pairs(q) do
v1,v2,v3,v4=rolq(r[1],r[2],r[3],r[4],v1,v2,v3,v4)
end
v={
v2*s[1]
,v3*s[2]
,v4*s[3],v[4]
,i=i
}
vt[v.i]=v
add(vs,v)
end
for i,v in pairs(vs) do
v.s=i>2 and v[3]+vs[i-1][3]+vs[i-2][3] or 0
end
quicksort(vs,1,#vs)
for i,v in pairs(vs) do
	if v.i>2 then
	local v1,v2,v3
		if band(v.i,1)==1 then
		v1,v2,v3=vt[v.i-2],vt[v.i-1],v
		else
		v1,v2,v3=v,vt[v.i-1],vt[v.i-2]
		end
	
	local x1,y1,z1=v1[1],v1[2],v1[3]
	local x2,y2,z2=v2[1],v2[2],v2[3]
	local x3,y3,z3=v3[1],v3[2],v3[3]
	local c,fp=light(
	lpal[ v[4] ]
	,dot(lpos
	,normalize(cross(
		normalize(x1-x3,y1-y3,z1-z3)
	,normalize(x2-x3,y2-y3,z2-z3)
	))
	))
	local cull=((x2-x1)*(y3-y1)-(x3-x1)*(y2-y1)<=0 and culr or bnot(culr))>0
	vs[i]={x1,y1,z1,x2,y2,z2,x3,y3,z3,c,fp,cull}
	end
end
	gvtx[m]=vs
end--not same obj

for i,v in pairs(vs) do

if v[11] and v[12] then
local z1,z2,z3
=zr/(wz-v[3]+prspx)
,zr/(wz-v[6]+prspy)
,zr/(wz-v[9]+prspz)
pelogen_tri
({v[1]*z1+wx,v[2]*z1+wy}
,{v[4]*z2+wx,v[5]*z2+wy}
,{v[7]*z3+wx,v[8]*z3+wy}
,v[10],v[11])
end
end
return vs
end

--sort	
function quicksort(v,s,e)
if(s>=e)return
local p=s
for i=s+1,e do
if v[i].s<v[s].s then
p+=1
v[p],v[i]=v[i],v[p]
end
end
v[s],v[p]=v[p],v[s]
quicksort(v,s,p-1)
quicksort(v,p+1,e)
end

--trifill
--@shiftalow/bitchunk
function pelogen_tri(v1,v2,v3,col,fp)
color(col)
fillp(fp)
if(v1[2]>v2[2]) v1,v2=v2,v1
if(v1[2]>v3[2]) v1,v3=v3,v1
if(v2[2]>v3[2]) v3,v2=v2,v3
local l,c,r,t,m,b=v1[1],v2[1],v3[1],flr(v1[2]),flr(v2[2]),v3[2]
local i,j,k=(c-l)/(m-t),(r-l)/(b-t),(r-c)/(b-m)
r=l
for t=t,m-1 do
rectfill(l,t,r,t)
r+=j
l+=i
end
for m=m,b-1 do
rectfill(c,m,r,m)
r+=j
c+=k
end
end
]],"@clip")
end
__gfx__
00000000000000000000000000000000000000000077700008888800000000000000000000700000007000000070000070700000070700000777000077770000
000f000000000000000000000000000000700000077f770008777800000000000000000000000000070000000700000007070000707700007077000070770000
00f0f0000777770000770770000777000707770007f0f70088b7c880000000000000000070000000700000007070000070700000770700007707000077770000
000f000007000700070007000007000007000070077f77008b000c80000000000000000000000000000700000707000007070000707000007770000077700000
00e7e0000700070007000700070707000700070077e7e7708d605d80000000000000000000000000000000000000000000000000000000000000000000000000
0e777e00070007000700070007000700700007007e777e708ddddd80000000000000000000000000000000000000000000000000000000000000000000000000
0eeeee00077777007707700000777000077707007eeeee7088888880000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000070007777777000000000000000000000000000000000000000000000000000000000000000000000000000000000
000002480000000000000000000000000000000000000000000000001f111ff10000000000700070007000700070007070707070070707070777077777777777
00010249000000000000000000000000000000000000000000000000ff10fff00000000000000000070007000700070007070707707770777077707770777077
0012249a000000000000000000000000000000000000000000000000000000000000000070007000700070007070707070707070770777077707770777777777
0123013b000000000000000000000000000000000000000000000000000000000000000000000000000700070707070707070707707070707770777077707770
012401dc000000000000000000000000000000000000000000000000000000000000000000700070007000700070007070707070070707070777077777777777
0015015d000000000000000000000000000000000000000000000000000000000000000000000000070007000700070007070707707770777077707770777077
15d6248e000000000000000000000000000000000000000000000000000000000000000070007000700070007070707070707070770777077707770777777777
156724ef000000000000000000000000000000000000000000000000000000000000000000000000000700070707070707070707707070707770777077707770
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000779a799a000000004cc54ac548a548850000000073787398979f957fb97eb99e9d9c9d7c00000000838a678a278a678a
00000000000000000000000000000000979a999a000000004c454a45488546850000000093789398977fb57fbb9d999d9b7c7d7c00000000a78aa78a678a838a
00000000000000000000000000000000997a799a00000000cc45ca45484546450000000095987398b77fb79f9b9d997d7b7c7b9c00000000e78aba8aa78aa78a
00000000000000000000000000000000797a779a00000000ccc5cac5c845c6450000000075987378d77ed79e9b7db97d5b7b5b9b00000000ba8aba8aa78ae78a
00000000000000000000000000000000777a979a00000000caa5caa5c885c6850000000075789378d99eb79ebb7dbb9d599b7b9b00000000ce8a8c8aba8aba8a
00000000000000000000000000000000977a997a00000000c8a5ca45c64546430000000095789598b99eb77e9b7d9b9d799b7b7b000000008c8a8c8aba8ace8a
00000000000000000000000000000000777a797a00000000c8454a45c68b468b00000000b57fb59fb97ed77e9d9c7b9c797b5b7b000000004e8a5a8a8c8a8c8a
00000000000000000000000000000000000000000000000048454aa5c88d488d00000000b79f959fd97ed99e7d9c7d7c597b599b000000005a8a5a8a8c8a4e8a
000000000000000000000000000000000000000000000000c8a348ab0000000000000000397a399a7799577979779b7795770000000000005a8a5a8a00000000
000000000000000000000000000000000000000000000000caad4aad0000000000000000379a599a777955797b779b970000000000000000678a278a00000000
000000000000000000000000000000000000000000000000cac34acb0000000000000000579a597a757975997b9799970000000000000000678a000000000000
000000000000000000000000000000000000000000000000cccd4ccd0000000000000000577a397a959777977997779700000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000377a379a979799975997579700000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000577a579ab797b9975977577700000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000055795599b777b9777977777700000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000075995799977799779777757700000000000000000000000000000000
__label__
555f55555555fff55555fff55555fff5555555555555555555555555555555555555555555555555555555555d55555575557555777777757777777577777775
55fff5555555f5f55555f5f55555f5f5555555555555555555555555555555555555555555555555555555555d55555555755575777777757777777577777775
fffffff55555f5f55555f5f35555f5f555555555555555555555555555555555555555555555555555555555d555555575557555777777757777777577777775
5fffff555555f5f55555f5f55555f5f555555555555555555555555555555555555555555555555555555555d555555555755575777777757777777577777775
5f555f555555fff55555fff53555fff55555555555555555555555555555555555555555555555555555555d5555555575557555777777757777777577777775
555555555555555555555555555555555555555555555555555555555555555555555555555555555555555d5555555555555555555555555555555555555555
5eeeee555555eee55555e5555555eee5555555555555555555555555555555555555555555555555555555d55555555555555555555555555555555555555555
ee555ee55555e5e55555e5555535e5e5555555555555555555555555555555555555555555555555555555d55555555555555555555555555555555555555555
ee5e5ee55555eee55555eee55555e5e5555555555555555555555555555555555555555555555555555555d55555555555555555555555555555555555555555
ee555ee5555555e55555e5e55553e5e555555555555555555555555555555555555555555555555555555d555555555555555555555555555555555555555555
5eeeee55555555e55555eee55555eee555555555555555555555555555555555555555555555555555555d555555555555555555555555555555555555555555
555555555555555555555555555553555555555555555555555555555555555555555555555555555555d5555555555555555555555555555555555555555555
55d5555555555555ddd555555555d55555555555ddd55555555555555555555555555555555555555555d5555555555555555555555555555555555555555555
55dddd555555555555d555555555d5555555555555d5555555555555555555555555555555555555555d55555555555555555555555555555555555555555555
55ddd5555555ddd555d55555ddd5ddd35555ddd55dd5555555555555555555555555555555555555555d55555555555555555555555555555555555555555555
5dddd5555555555555d555555555d5d55555555555d555555555555555555555555555555555555555d555555555555555555555555555555555555555555555
5555d5555555555555d555555555ddd535555555ddd555555555555555555555555555555555555555d555555555555555555555555555555555555555555555
555555555555555555555555555555555555555555555555555555555555555555555555555555555d5555555555555555555555555555555555555555555555
555555555555555555555555555555555535555555555555555555555555555555555555555555555d5555555555555555555555555555555555555555555555
555555555555555555555555555555555535555555555555555555555555555555555555555555555d5555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555d55555555555555555555555555555555555555555555555
55555555555555555555555555555555555535555555555555555555555555555555555555555555d55555555555555555555555555555555555555555555555
5555555555555555555555555555555555555555555555555555555555555555555555555555555d555555555555555555555555555555555555555555555555
5555555555555555555555555555555555555355555555555555555555555555555555555555555d555555555555555555555555555555555555555555555555
555555555555555555555555555555555555555555555555555555555555555555555555555555d5555555555555555555555555555555555555555555555555
555555555555555555555555555555555555555555555555555555555555555555555555555555d5555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555535555555555555555555555555555555555555d55555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555d55555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555553555555555555555555555555555555555555d55555555555555555555555555555555555555555555555555
5555555555555555555555555555555555555555555555555555555555555555555555555555d555555555555555555555555555555555555555555555555555
5555555555555555555555555555555555555555553555555555555555555555555555555555d555555555555555555555555555555555555555555555555555
555555555555555555555555555555555555555555355555555555555555555555555555555d5555555555555555555555555555555555555555555555555555
555555555555555555555555555555555555555555555555555555555555555555555555555d5555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555355555555555555555555555555555d55555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555d55555555555555555555555555555555555555555555555555555
5555555555555555555555555555555555555555555553555555555555555555555555555d555555555555555555555555555555555555555555555555555555
5555555555555555555555555555555555555555555555555555555555555555555555555d555555555555555555555555555555555555555555555555555555
555555555555555555555555555555555555555555555555555555555555555555555555d5555555555555555555555555555555555555555555555555555555
555555555555555555555555555555555555555555555553555555555555555555555555d5555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555559995555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555539995555555555555555595d59555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555595459555555555555555595d59555555555555555555555555555555555555555555555555555555
5555555555555555555555555555555555555555555555559534955555555555555559da59555555555555555555555555555555555555555555555555555555
5555555555555555555555555555555555555555555555559534aaaaaaaaaaaaaaaaaa9995555555555555555555555555555555555555555555555555555555
5555555555555555555555555555555555555555555555555aaaaaaaaaaaaaaaaaaaaaa444555555555555555555555555555555555555555555555555555555
5555555555555555555555555555555555555555555555555aaa34aaaaaaaaaaaaaaaaa444555555555555555555555555555555555555555555555555555555
555555555555555555555555555555555555555555555555aaaaa4aaaaaaaaaaaaaaaaa444455555555555555555555555555555555555555555555555555555
555555555555555555555555555555555555555555555555aaaaa34aaaaaaaaaaaaaaa4444445555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555aaaaaaa44aaaaaaaaaaaaaa4444445555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555aaaaaaaa3aaaaaaaaaaaaa44444444555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555aaaaaaaa34aaaaaaaaaaaa44444444555555555555555555555555555555555555111111111111111
5555555555555555555555555555555555555555555555aaaaaaaaaa4aaaaaaaaaaa444444444411111111111111111111111111111111111111111111111111
5555555555555555555555555555555555555555555555aaaaaaaaaaa3aaaaaaaaaa444444444441111111111111111111111111111111111111111111111111
555555555555555555555555555555555555555555555aaaaaaaaaaaaa4aaaaaaaa4444444444441111111111111111111111111111111111111111111111111
555555555555555555555555555555555555555555555aaaaaaaaaaaaa4aaaaaaaa4444444444444111111111111111111111111111111111111111111111111
55555555555555555555555555555555555555555555aaaaaaaaaaaaaaa4aaaaaa44444444444444411111111111111111111111111111111111111111111111
55555555555555555555555555555555555555555555aaaaaaaaaaaaaaa4aaaaaa44444444444444499911111111111111111111111111111111111111111111
5555555555555555555555555555555555555555555aaaaaaaaaaaaaaaaa3aaaaa44444444444444441191111111111111111111111111111111111111111111
5555555555555555555555555555555555555555555aaaaaaaaaaaaaaaaaaeeea444444444444444444191111111111111111111111111111111111111111111
555555555555555555555555555555555555555999aaaaaaaaaaaaaaaaaae449e444444444444444444191111111111111111111111111111111111111111111
2222222222222222222222222222222222222292229aaaaaaaaaaaaaaaaaea48e888888888888888888888888888888888888888888888888888888888888888
55555555555555555555555555555555555555955a9aaaaaaaaaaaaaaaaaeacae444444444444444441111111111111111111111111111111111111111111111
5555555555555555555555555555555555555595499949994999499949999eee9444444444444444441111111111111111111111111111111111111111111111
5555555555555555555555555555555555555559999999999999999999999c994444444444444444411111111111111111111111111111111111111111111111
555555555555555555555555555555555555555555499949994999499949c9494444444444444444411111111111111111111111111111111111111111111111
555555555555555555555555555555555555555555599999999999999999c9994444444444444444111111111111111111111111111111111111111111111111
55555555555555555555555555555555555555555559499949994999499c49994444444444444444111111111111111111111111111111111111111111111111
55555555555555555555555555555555555555555555999999999999999c99999944444444444444111111111111111111111111111111111111111111111111
5555555555555555555555555555555555555555555559499949994999c999499944444444444441111111111111111111111111111111111111111111111111
5555555555555555555555555555555555555555555559999999999999c999999994444444444441111111111111111111111111111111111111111111111111
555555555555555555555555555555555555555555555599499949994c9949994999444444444411111111111111111111111111111111111111111111111111
555555555555555555555555555555555555555555555559999999999c9999999999444444444411111111111111111111111111111111111111111111111111
55555555555555555555555555555555555555555555555599499949c94999499949944444444111111111111111111111111111111111111111111111111111
55555555555555555555555555555555555555555555555599999999c99999999999994444444111111111111111111111111111111111111111111111111111
5555555555555555555555555555555555555555555555511999499c499949994999494444444111111111111111111111111111111111111111111111111111
5555555555555555555555555555555555555555555555511199999c999999999999999444441111111111111111111111111111111111111111111111111111
555555555555555555555555555555555555555555555511114999c9994999499949994999941111111111111111111111111111111111111111111111111111
555555555555555555555555555555555555555555555511119999c9999999999999999944491111111111111111111111111111111111111111111111111111
55555555555555555555555555555555555555555555511111914c99499949994999499944491111111111111111111111111111111111111111111111111111
55555555555555555555555555555555555555555555511111199c11111111111111111911191111111111111111111111111111111111111111111111111111
55555555555555555555555555555555555555555555511111111c11111111111111111199911111111111111111111111111111111111111111111111111111
5555555555555555555555555555555555555555555511111111c11111111111111111111111b111111111111111111111111111111111111111111111111111
5555555555555555555555555555555555555555555511111111c111111111111111111111111111111111111111111111111111111111111111111111111111
555555555555555555555555555555555555555555511111111c1111111111111111111111111b11111111111111111111111111111111111111111111111111
555555555555555555555555555555555555555555511111111c1111111111111111111111111111111111111111111111111111111111111111111111111111
55555555555555555555555555555555555555555511111111c1111111111111111111111111111b111111111111111111111111111111111111111111111111
55555555555555555555555555555555555555555511111111c1111111111111111111111111111b111111111111111111111111111111111111111111111111
5555555555555555555555555555555555555555511111111c111111111111111111111111111111111111111111111111111111111111111111111111111111
5555555555555555555555555555555555555555511111111c1111111111111111111111111111111b1111111111111111111111111111111111111111111111
555555555555555555555555555555555555555511111111c1111111111111111111111111111111111111111111111111111111111111111111111111111111
555555555555555555555555555555555555555511111111c111111111111111111111111111111111b111111111111111111111111111111111111111111111
55555555555555555555555555555555555555511111111c11111111111111111111111111111111111111111111111111111111111111111111111111111111
55555555555555555555555555555555555555511111111c11111111111111111111111111111111111111111111111111111111111111111111111111111111
5555555555555555555555555555555555555511111111c1111111111111111111111111111111111111b1111111111111111111111111111111111111111111
5555555555555555555555555555555555555511111111c111111111111111111111111111111111111111111111111111111111111111111111111111111111
555555555555555555555555555555555555551111111c111111111111111111111111111111111111111b111111111111111111111111111111111111111111
555555555555555555555555555555555555511111111c1111111111111111111111111111111111111111111111111111411111111111111111111111111111
55555555555555555555555555555555555551111111c111111111111111111111111111111111111111111b1111111114141111111111111111111111111111
55555555555555555555555555555555555511111111c111111111111111111111111111111111111111111b1111111111411111111111111111111111111111
55555555555555555555555555555555555511111111c1111111111111111111111111111111111111111111111111111a2a1111111111111111111111111111
5555555555555555555555555555555555511111111c111111111111111111111111111111111111111111111b111111a222a111111111111111111111111111
5555555555555555555555555555555555511111111c1111111111111111111111111111111111111111111111111111a4444444441111111111111111111111
555555555555555555555555555555555511111111c11111111111111111111111111111111111111111111111b1111114aa44a4a41111111111111111111111
555555555555555555555555555555555511111111c11111111111111111111111111111111111111111111111111111144a44a4a41111111111111111111111
55555555555555555555555555555555511111111c111111111111111111111111111111111111111111111111111111114a44aaa41111111111111111111111
55555555555555555555555555555555511111111c11111111111111111111111111111111111111111111111111b111144a4444a41111111111111111111111
5555555555555555555555555555555511111111c111111111111111111111111111111111111111111111111111111114aaa414a41111111111111111111111
5555555555555555555555555555555511111111c1111111111111111111111111111111111111111111111111111b1114444414441111111111111111111111
555555555555555555555555555555511111111c1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
555555555555555555555555555555511111111c1111111111111111111111111111111111111111111111111111111b11111111111111111111111111111111
55555555555555555555555555555551111111c11111111111111111111111111111111111111111111111111111111b11111111111111111111111111111111
55555555555555555555555555555511111111c11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
5555555555555555555555555555551111111c111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
5555555555555555555555555555511111111c111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
555555555555555555555555555551111111c1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
555555555555555555555555555511111111c1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
55555555555555555555555555551111111c11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
55555555555555555555555555511111111c11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
55555555555555555555555555511111111c11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
5555555555555555555555555511111111c111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
00000000000000000000000000000000000000000000000000000000000000000000000000000000aaaaaaaaa000000000000000000000000000000000000000
05000000011110000222200003333110044441100555500006666550077775500888822009999220aaaaa440abbbb1100cccc1100dddd1100eeee4400ffff440
00000000011110000222211003333220044442200555511006666dd0077776600888844009999440aaaaa990abbbb3300ccccdd00dddd5500eeee8800ffffee0
00000000011110000222200003333110044441100555500006666550077775500888822009999220aaaaa440abbbb1100cccc1100dddd1100eeee4400ffff440
00000000011110000222211003333220044442200555511006666dd0077776600888844009999440aaaaa990abbbb3300ccccdd00dddd5500eeee8800ffffee0
00000000011110000222200003333110044441100555500006666550077775500888822009999220aaaaa440abbbb1100cccc1100dddd1100eeee4400ffff440
00000000011110000222211003333220044442200555511006666dd0077776600888844009999440aaaaa990abbbb3300ccccdd00dddd5500eeee8800ffffee0
00000000000000000000000000000000000000000000000000000000000000000000000000000000aaaaaaaaa000000000000000000000000000000000000000

__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001b800000000000000000000
__map__
4040404040404040404040404040404040414243404142434041424340414243000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4040404040404040404040404040404050515253505152535051525350515253000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4040404040404040404040404040404060616263606162636061626360616263000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4040404040404040404040404040404070717273707172737071727370717273000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4040404040404040404040404040404040414243404142434041424340414243000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4040404040404040404040404040404050515253505152535051525350515253000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4040404040404041424340404040404060616263606162636061626360616263000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4040404040405051525340404040404070717273707172737071727370717273000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4040404040406061626340404040404040414243404142434041424340414243000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4040404040407071727340404040404050515253505152535051525350515253000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4040404040404040404040404040404060616263606162636061626360616263000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4040404040404040404040404040404070717273707172737071727370717273000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4040404040404040404040404040404040414243404142434041424340414243000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4040404040404040404040404040404050515253505152535051525350515253000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4040404040404040404040404040404060616263606162636061626360616263000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4040404040404040404040404040404070717273707172737071727370717273000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
