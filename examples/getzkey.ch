
/*
The following machine generated code must be used as follows:

   uint8_t buf[64]; // or larger
   getZoneKey(buf);

Key for domain: https://rtl-dev.equip.run/

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


static const uint8_t zKeyData[]={
	35,
	0x45 ,
	0x25 ,
	0xE2 ,
	0x5D ,
	0x7D ,
	0x71 ,
	0x2C ,
	0x2D ,
	0xEC ,
	0x80 ,
	0x16 ,
	0xA8 ,
	0xEE ,
	0xBF ,
	0xCF ,
	0xC4 ,
	0xE5 ,
	0x10 ,
	0x0D ,
	0x02 ,
	0xF7 ,
	0x9F ,
	0x13 ,
	0x8C ,
	0x13 ,
	0xE3 ,
	0x64 ,
	0x8F ,
	0xC7 ,
	0xD0 ,
	0x52 ,
	0x1B ,
	0x8A ,
	0xFD ,
	0xF4 ,
	0x15 ,
	0x61 ,
	0xE8 ,
	0x3E ,
	0x5B ,
	0xF9 ,
	0xC1 ,
	0x82 ,
	0xCA ,
	0xAA ,
	0xC8 ,
	0x5D ,
	0x08 ,
	0xA6 ,
	0xB9 ,
	0xB9 ,
	0x72 ,
	0x27 ,
	0x1B ,
	0x6A ,
	0xE7 ,
	0xF0 ,
	0x3A ,
	0xB3 ,
	0xB2 ,
	0x57 ,
	0x43 ,
	0x6C ,
	0x90 
};

static void getZoneKey(uint8_t buf[64])
{
	buf[22] = zKeyData[23] ^ zKeyData[46]; 
	buf[23] = buf[22] << 4;
	buf[22] = zkASCII[buf[22] >>= 4];
	buf[23] = zkASCII[buf[23] >> 4];
	buf[16] = zKeyData[61] ^ zKeyData[40]; 
	buf[17] = buf[16] << 4;
	buf[16] = zkASCII[buf[16] >>= 4];
	buf[17] = zkASCII[buf[17] >> 4];
	buf[62] = zKeyData[ 1] ^ zKeyData[50]; 
	buf[63] = buf[62] << 4;
	buf[62] = zkASCII[buf[62] >>= 4];
	buf[63] = zkASCII[buf[63] >> 4];
	buf[24] = zKeyData[63] ^ zKeyData[14]; 
	buf[25] = buf[24] << 4;
	buf[24] = zkASCII[buf[24] >>= 4];
	buf[25] = zkASCII[buf[25] >> 4];
	buf[60] = zKeyData[ 5] ^ zKeyData[62]; 
	buf[61] = buf[60] << 4;
	buf[60] = zkASCII[buf[60] >>= 4];
	buf[61] = zkASCII[buf[61] >> 4];
	buf[40] = zKeyData[27] ^ zKeyData[42]; 
	buf[41] = buf[40] << 4;
	buf[40] = zkASCII[buf[40] >>= 4];
	buf[41] = zkASCII[buf[41] >> 4];
	buf[58] = zKeyData[13] ^ zKeyData[ 6]; 
	buf[59] = buf[58] << 4;
	buf[58] = zkASCII[buf[58] >>= 4];
	buf[59] = zkASCII[buf[59] >> 4];
	buf[20] = zKeyData[15] ^ zKeyData[32]; 
	buf[21] = buf[20] << 4;
	buf[20] = zkASCII[buf[20] >>= 4];
	buf[21] = zkASCII[buf[21] >> 4];
	buf[48] = zKeyData[29] ^ zKeyData[28]; 
	buf[49] = buf[48] << 4;
	buf[48] = zkASCII[buf[48] >>= 4];
	buf[49] = zkASCII[buf[49] >> 4];
	buf[32] = zKeyData[19] ^ zKeyData[ 4]; 
	buf[33] = buf[32] << 4;
	buf[32] = zkASCII[buf[32] >>= 4];
	buf[33] = zkASCII[buf[33] >> 4];
	buf[50] = zKeyData[53] ^ zKeyData[24]; 
	buf[51] = buf[50] << 4;
	buf[50] = zkASCII[buf[50] >>= 4];
	buf[51] = zkASCII[buf[51] >> 4];
	buf[56] = zKeyData[17] ^ zKeyData[54]; 
	buf[57] = buf[56] << 4;
	buf[56] = zkASCII[buf[56] >>= 4];
	buf[57] = zkASCII[buf[57] >> 4];
	buf[52] = zKeyData[21] ^ zKeyData[64]; 
	buf[53] = buf[52] << 4;
	buf[52] = zkASCII[buf[52] >>= 4];
	buf[53] = zkASCII[buf[53] >> 4];
	buf[54] = zKeyData[47] ^ zKeyData[12]; 
	buf[55] = buf[54] << 4;
	buf[54] = zkASCII[buf[54] >>= 4];
	buf[55] = zkASCII[buf[55] >> 4];
	buf[46] = zKeyData[33] ^ zKeyData[22]; 
	buf[47] = buf[46] << 4;
	buf[46] = zkASCII[buf[46] >>= 4];
	buf[47] = zkASCII[buf[47] >> 4];
	buf[18] = zKeyData[59] ^ zKeyData[10]; 
	buf[19] = buf[18] << 4;
	buf[18] = zkASCII[buf[18] >>= 4];
	buf[19] = zkASCII[buf[19] >> 4];
	buf[44] = zKeyData[41] ^ zKeyData[ 8]; 
	buf[45] = buf[44] << 4;
	buf[44] = zkASCII[buf[44] >>= 4];
	buf[45] = zkASCII[buf[45] >> 4];
	buf[ 0] = zKeyData[ 9] ^ zKeyData[38]; 
	buf[ 1] = buf[ 0] << 4;
	buf[ 0] = zkASCII[buf[ 0] >>= 4];
	buf[ 1] = zkASCII[buf[ 1] >> 4];
	buf[ 6] = zKeyData[39] ^ zKeyData[ 2]; 
	buf[ 7] = buf[ 6] << 4;
	buf[ 6] = zkASCII[buf[ 6] >>= 4];
	buf[ 7] = zkASCII[buf[ 7] >> 4];
	buf[ 4] = zKeyData[37] ^ zKeyData[56]; 
	buf[ 5] = buf[ 4] << 4;
	buf[ 4] = zkASCII[buf[ 4] >>= 4];
	buf[ 5] = zkASCII[buf[ 5] >> 4];
	buf[42] = zKeyData[ 3] ^ zKeyData[60]; 
	buf[43] = buf[42] << 4;
	buf[42] = zkASCII[buf[42] >>= 4];
	buf[43] = zkASCII[buf[43] >> 4];
	buf[14] = zKeyData[57] ^ zKeyData[16]; 
	buf[15] = buf[14] << 4;
	buf[14] = zkASCII[buf[14] >>= 4];
	buf[15] = zkASCII[buf[15] >> 4];
	buf[34] = zKeyData[ 7] ^ zKeyData[30]; 
	buf[35] = buf[34] << 4;
	buf[34] = zkASCII[buf[34] >>= 4];
	buf[35] = zkASCII[buf[35] >> 4];
	buf[38] = zKeyData[43] ^ zKeyData[58]; 
	buf[39] = buf[38] << 4;
	buf[38] = zkASCII[buf[38] >>= 4];
	buf[39] = zkASCII[buf[39] >> 4];
	buf[ 8] = zKeyData[25] ^ zKeyData[26]; 
	buf[ 9] = buf[ 8] << 4;
	buf[ 8] = zkASCII[buf[ 8] >>= 4];
	buf[ 9] = zkASCII[buf[ 9] >> 4];
	buf[28] = zKeyData[45] ^ zKeyData[44]; 
	buf[29] = buf[28] << 4;
	buf[28] = zkASCII[buf[28] >>= 4];
	buf[29] = zkASCII[buf[29] >> 4];
	buf[ 2] = zKeyData[31] ^ zKeyData[20]; 
	buf[ 3] = buf[ 2] << 4;
	buf[ 2] = zkASCII[buf[ 2] >>= 4];
	buf[ 3] = zkASCII[buf[ 3] >> 4];
	buf[36] = zKeyData[55] ^ zKeyData[18]; 
	buf[37] = buf[36] << 4;
	buf[36] = zkASCII[buf[36] >>= 4];
	buf[37] = zkASCII[buf[37] >> 4];
	buf[10] = zKeyData[49] ^ zKeyData[36]; 
	buf[11] = buf[10] << 4;
	buf[10] = zkASCII[buf[10] >>= 4];
	buf[11] = zkASCII[buf[11] >> 4];
	buf[26] = zKeyData[51] ^ zKeyData[34]; 
	buf[27] = buf[26] << 4;
	buf[26] = zkASCII[buf[26] >>= 4];
	buf[27] = zkASCII[buf[27] >> 4];
	buf[30] = zKeyData[35] ^ zKeyData[48]; 
	buf[31] = buf[30] << 4;
	buf[30] = zkASCII[buf[30] >>= 4];
	buf[31] = zkASCII[buf[31] >> 4];
	buf[12] = zKeyData[11] ^ zKeyData[52]; 
	buf[13] = buf[12] << 4;
	buf[12] = zkASCII[buf[12] >>= 4];
	buf[13] = zkASCII[buf[13] >> 4];
}
