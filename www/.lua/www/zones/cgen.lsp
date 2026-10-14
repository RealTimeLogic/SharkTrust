<?lsp
if not app.sensitive.consume(app.sensitiveSession(request,page.zkey),"cgen") then
   return response:sendredirect"/verify?purpose=cgen"
end

local fmt=string.format

response:reset()
response:setheader("Cache-Control","no-store")
response:setheader("Content-Disposition", 'attachment; filename="getzkey.ch"')
response:setcontenttype("text/plain; charset=utf-8")

local zkey=app.rcZonesT()[app.host(request)]




local zkT={}
for x in zkey:gmatch("%x%x") do
   table.insert(zkT, tonumber(x, 16))
end

local zkxT={}
local function shuffle(list)
   for i=#list,2,-1 do
      local j=ba.rnd(1,i)
      list[i],list[j]=list[j],list[i]
   end
end
for i=1,32 do
   local x = ba.rnd(1,0xFE)
   local k=zkT[i]
   zkxT[i]={
      k=k,
      ix=i,
      c=k~x,
      x=x,
   }
end

local xorT={}
for i,v in ipairs(zkxT) do
   xorT[i]={ix=v.ix, x=v.x}
end
shuffle(zkxT)
shuffle(xorT)

local dataT={"\t"..ba.rnd(1,0xFF)}
local rndIxT={}
local keyIxT={}
local xorIxT={}
local ix=0
for i=1,32 do
   local kT=zkxT[i]
   ix=ix+1
   kT.dIx=ix
   table.insert(dataT, fmt("\t0x%02X /* %02d ix:%02d %02X = %02X ^ %02X */",
                           kT.c, kT.dIx, kT.ix, kT.c, kT.k, kT.x))
   local xT=xorT[i]
   ix=ix+1
   xT.dIx=ix
   table.insert(dataT, fmt("\t0x%02X /* %02d ix:%02d XOR mask */",
                           xT.x, xT.dIx, xT.ix))
   rndIxT[i]=i
   keyIxT[kT.ix]=kT
   xorIxT[xT.ix]=xT
end
shuffle(rndIxT)


local codeT={}
for _,ix in ipairs(rndIxT) do
   local kT,xT=keyIxT[ix],xorIxT[ix]
   table.insert(codeT, fmt("\tbuf[%2d] = zKeyData[%2d] ^ zKeyData[%2d]; /* %02X = %02X ^ %02X */",
                           (ix-1)*2, kT.dIx,xT.dIx, kT.k, kT.c, kT.x))
   table.insert(codeT, fmt("\tbuf[%2d] = buf[%2d] << 4;",(ix-1)*2+1,(ix-1)*2))
   table.insert(codeT, fmt("\tbuf[%2d] = zkASCII[buf[%2d] >>= 4];",(ix-1)*2,(ix-1)*2))
   table.insert(codeT, fmt("\tbuf[%2d] = zkASCII[buf[%2d] >> 4];",(ix-1)*2+1,(ix-1)*2+1))
end


print[[

/*
The following machine generated code must be used as follows:

   uint8_t buf[64]; // or larger
   getZoneKey(buf);

*/

#if __STDC_VERSION__ < 199901L
#define uint8_t unsigned char
#endif

#ifdef __GNUC__
#pragma GCC diagnostic ignored "-Wsequence-point"
#endif
#ifdef __ICCARM__
#pragma diag_suppress=Pa079
#endif

static const uint8_t zkASCII[] = {'0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'};

]]


print"static const uint8_t zKeyData[]={"
print(table.concat(dataT,",\n"))
print"};\n"

print"static void getZoneKey(uint8_t buf[64])\n{"
for _,d in ipairs(codeT) do
   print(d)
end
print"}"



response:abort()
?>


