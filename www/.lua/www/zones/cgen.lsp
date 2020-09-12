<?lsp

local fmt=string.format

response:reset()
response:setheader("Content-Disposition", 'attachment; filename="getzkey.ch"')
response:setcontenttype("text/plain; charset=utf-8")

local zkey=app.rcZonesT()[request:header"host"]




local zkT={}
for x in zkey:gmatch("%x%x") do
   table.insert(zkT, tonumber(x, 16))
end

local zkxT={}
for i=1,32 do
   local x = ba.rnd(1,0xFE)
   local k=zkT[i]
   zkxT[ba.rnd()]={
      k=k,
      ix=i,
      c=k~x,
      x=x,
   }
end

local xorT={}
for _,v in pairs(zkxT) do
   xorT[ba.rnd()]={ix=v.ix, x=v.x}
end

local dataT={"\t"..ba.rnd(1,0xFF)}
local rndIxT={}
local keyIxT={}
local xorIxT={}
local ixK,ixX,kT,xT
local ix=0
for i=1,32 do
   ixK,kT=next(zkxT,ixK)
   ix=ix+1
   kT.dIx=ix
   table.insert(dataT, fmt("\t0x%02X /* %02d ix:%02d %02X = %02X ^ %02X */",
                           kT.c, kT.dIx, kT.ix, kT.c, kT.k, kT.x))
   ixX,xT=next(xorT,ixX)
   ix=ix+1
   xT.dIx=ix
   table.insert(dataT, fmt("\t0x%02X /* %02d ix:%02d XOR mask */",
                           xT.x, xT.dIx, xT.ix))
   rndIxT[ba.rnd()]= i
   keyIxT[kT.ix]=kT
   xorIxT[xT.ix]=xT
end


local codeT={}
for _,ix in pairs(rndIxT) do
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

#pragma GCC diagnostic ignored "-Wsequence-point"

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


