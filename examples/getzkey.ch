
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


static const uint8_t zKeyData[]={
	146,
	0x2F /* 01 ix:18 2F = AC ^ 83 */,
	0xA2 /* 02 ix:01 XOR mask */,
	0xE3 /* 03 ix:20 E3 = 07 ^ E4 */,
	0x70 /* 04 ix:17 XOR mask */,
	0xF3 /* 05 ix:04 F3 = 6D ^ 9E */,
	0x12 /* 06 ix:21 XOR mask */,
	0xBA /* 07 ix:30 BA = 40 ^ FA */,
	0xCD /* 08 ix:32 XOR mask */,
	0xCC /* 09 ix:15 CC = A1 ^ 6D */,
	0xD4 /* 10 ix:12 XOR mask */,
	0x84 /* 11 ix:09 84 = AB ^ 2F */,
	0xA6 /* 12 ix:02 XOR mask */,
	0x9D /* 13 ix:21 9D = 8F ^ 12 */,
	0x9E /* 14 ix:04 XOR mask */,
	0x94 /* 15 ix:02 94 = 32 ^ A6 */,
	0x93 /* 16 ix:28 XOR mask */,
	0xA9 /* 17 ix:06 A9 = 7D ^ D4 */,
	0xA4 /* 18 ix:27 XOR mask */,
	0x3F /* 19 ix:19 3F = 7E ^ 41 */,
	0x17 /* 20 ix:13 XOR mask */,
	0xAB /* 21 ix:11 AB = D3 ^ 78 */,
	0xCB /* 22 ix:29 XOR mask */,
	0x50 /* 23 ix:13 50 = 47 ^ 17 */,
	0x17 /* 24 ix:31 XOR mask */,
	0x37 /* 25 ix:24 37 = 35 ^ 02 */,
	0xFA /* 26 ix:30 XOR mask */,
	0x9A /* 27 ix:23 9A = AC ^ 36 */,
	0x66 /* 28 ix:16 XOR mask */,
	0x22 /* 29 ix:25 22 = A7 ^ 85 */,
	0x5B /* 30 ix:26 XOR mask */,
	0x7B /* 31 ix:14 7B = A5 ^ DE */,
	0x75 /* 32 ix:22 XOR mask */,
	0xFB /* 33 ix:10 FB = DB ^ 20 */,
	0x20 /* 34 ix:10 XOR mask */,
	0xC7 /* 35 ix:16 C7 = A1 ^ 66 */,
	0xE4 /* 36 ix:20 XOR mask */,
	0x97 /* 37 ix:17 97 = E7 ^ 70 */,
	0x85 /* 38 ix:25 XOR mask */,
	0xCC /* 39 ix:03 CC = AF ^ 63 */,
	0x8F /* 40 ix:05 XOR mask */,
	0x99 /* 41 ix:08 99 = 3B ^ A2 */,
	0xD4 /* 42 ix:06 XOR mask */,
	0x3E /* 43 ix:32 3E = F3 ^ CD */,
	0xDE /* 44 ix:14 XOR mask */,
	0x41 /* 45 ix:12 41 = 95 ^ D4 */,
	0x02 /* 46 ix:24 XOR mask */,
	0xB5 /* 47 ix:29 B5 = 7E ^ CB */,
	0x41 /* 48 ix:19 XOR mask */,
	0x73 /* 49 ix:26 73 = 28 ^ 5B */,
	0xA2 /* 50 ix:08 XOR mask */,
	0x00 /* 51 ix:07 00 = A6 ^ A6 */,
	0x2F /* 52 ix:09 XOR mask */,
	0x9C /* 53 ix:31 9C = 8B ^ 17 */,
	0xA6 /* 54 ix:07 XOR mask */,
	0x39 /* 55 ix:27 39 = 9D ^ A4 */,
	0x36 /* 56 ix:23 XOR mask */,
	0x1D /* 57 ix:01 1D = BF ^ A2 */,
	0x83 /* 58 ix:18 XOR mask */,
	0x8E /* 59 ix:22 8E = FB ^ 75 */,
	0x78 /* 60 ix:11 XOR mask */,
	0x02 /* 61 ix:28 02 = 91 ^ 93 */,
	0x6D /* 62 ix:15 XOR mask */,
	0xC7 /* 63 ix:05 C7 = 48 ^ 8F */,
	0x63 /* 64 ix:03 XOR mask */
};

static void getZoneKey(uint8_t buf[64])
{
	buf[48] = zKeyData[29] ^ zKeyData[38]; /* A7 = 22 ^ 85 */
	buf[49] = buf[48] << 4;
	buf[48] = zkASCII[buf[48] >>= 4];
	buf[49] = zkASCII[buf[49] >> 4];
	buf[10] = zKeyData[17] ^ zKeyData[42]; /* 7D = A9 ^ D4 */
	buf[11] = buf[10] << 4;
	buf[10] = zkASCII[buf[10] >>= 4];
	buf[11] = zkASCII[buf[11] >> 4];
	buf[12] = zKeyData[51] ^ zKeyData[54]; /* A6 = 00 ^ A6 */
	buf[13] = buf[12] << 4;
	buf[12] = zkASCII[buf[12] >>= 4];
	buf[13] = zkASCII[buf[13] >> 4];
	buf[62] = zKeyData[43] ^ zKeyData[ 8]; /* F3 = 3E ^ CD */
	buf[63] = buf[62] << 4;
	buf[62] = zkASCII[buf[62] >>= 4];
	buf[63] = zkASCII[buf[63] >> 4];
	buf[20] = zKeyData[21] ^ zKeyData[60]; /* D3 = AB ^ 78 */
	buf[21] = buf[20] << 4;
	buf[20] = zkASCII[buf[20] >>= 4];
	buf[21] = zkASCII[buf[21] >> 4];
	buf[ 0] = zKeyData[57] ^ zKeyData[ 2]; /* BF = 1D ^ A2 */
	buf[ 1] = buf[ 0] << 4;
	buf[ 0] = zkASCII[buf[ 0] >>= 4];
	buf[ 1] = zkASCII[buf[ 1] >> 4];
	buf[46] = zKeyData[25] ^ zKeyData[46]; /* 35 = 37 ^ 02 */
	buf[47] = buf[46] << 4;
	buf[46] = zkASCII[buf[46] >>= 4];
	buf[47] = zkASCII[buf[47] >> 4];
	buf[ 6] = zKeyData[ 5] ^ zKeyData[14]; /* 6D = F3 ^ 9E */
	buf[ 7] = buf[ 6] << 4;
	buf[ 6] = zkASCII[buf[ 6] >>= 4];
	buf[ 7] = zkASCII[buf[ 7] >> 4];
	buf[50] = zKeyData[49] ^ zKeyData[30]; /* 28 = 73 ^ 5B */
	buf[51] = buf[50] << 4;
	buf[50] = zkASCII[buf[50] >>= 4];
	buf[51] = zkASCII[buf[51] >> 4];
	buf[22] = zKeyData[45] ^ zKeyData[10]; /* 95 = 41 ^ D4 */
	buf[23] = buf[22] << 4;
	buf[22] = zkASCII[buf[22] >>= 4];
	buf[23] = zkASCII[buf[23] >> 4];
	buf[18] = zKeyData[33] ^ zKeyData[34]; /* DB = FB ^ 20 */
	buf[19] = buf[18] << 4;
	buf[18] = zkASCII[buf[18] >>= 4];
	buf[19] = zkASCII[buf[19] >> 4];
	buf[52] = zKeyData[55] ^ zKeyData[18]; /* 9D = 39 ^ A4 */
	buf[53] = buf[52] << 4;
	buf[52] = zkASCII[buf[52] >>= 4];
	buf[53] = zkASCII[buf[53] >> 4];
	buf[14] = zKeyData[41] ^ zKeyData[50]; /* 3B = 99 ^ A2 */
	buf[15] = buf[14] << 4;
	buf[14] = zkASCII[buf[14] >>= 4];
	buf[15] = zkASCII[buf[15] >> 4];
	buf[26] = zKeyData[31] ^ zKeyData[44]; /* A5 = 7B ^ DE */
	buf[27] = buf[26] << 4;
	buf[26] = zkASCII[buf[26] >>= 4];
	buf[27] = zkASCII[buf[27] >> 4];
	buf[38] = zKeyData[ 3] ^ zKeyData[36]; /* 07 = E3 ^ E4 */
	buf[39] = buf[38] << 4;
	buf[38] = zkASCII[buf[38] >>= 4];
	buf[39] = zkASCII[buf[39] >> 4];
	buf[56] = zKeyData[47] ^ zKeyData[22]; /* 7E = B5 ^ CB */
	buf[57] = buf[56] << 4;
	buf[56] = zkASCII[buf[56] >>= 4];
	buf[57] = zkASCII[buf[57] >> 4];
	buf[40] = zKeyData[13] ^ zKeyData[ 6]; /* 8F = 9D ^ 12 */
	buf[41] = buf[40] << 4;
	buf[40] = zkASCII[buf[40] >>= 4];
	buf[41] = zkASCII[buf[41] >> 4];
	buf[60] = zKeyData[53] ^ zKeyData[24]; /* 8B = 9C ^ 17 */
	buf[61] = buf[60] << 4;
	buf[60] = zkASCII[buf[60] >>= 4];
	buf[61] = zkASCII[buf[61] >> 4];
	buf[44] = zKeyData[27] ^ zKeyData[56]; /* AC = 9A ^ 36 */
	buf[45] = buf[44] << 4;
	buf[44] = zkASCII[buf[44] >>= 4];
	buf[45] = zkASCII[buf[45] >> 4];
	buf[42] = zKeyData[59] ^ zKeyData[32]; /* FB = 8E ^ 75 */
	buf[43] = buf[42] << 4;
	buf[42] = zkASCII[buf[42] >>= 4];
	buf[43] = zkASCII[buf[43] >> 4];
	buf[28] = zKeyData[ 9] ^ zKeyData[62]; /* A1 = CC ^ 6D */
	buf[29] = buf[28] << 4;
	buf[28] = zkASCII[buf[28] >>= 4];
	buf[29] = zkASCII[buf[29] >> 4];
	buf[34] = zKeyData[ 1] ^ zKeyData[58]; /* AC = 2F ^ 83 */
	buf[35] = buf[34] << 4;
	buf[34] = zkASCII[buf[34] >>= 4];
	buf[35] = zkASCII[buf[35] >> 4];
	buf[ 2] = zKeyData[15] ^ zKeyData[12]; /* 32 = 94 ^ A6 */
	buf[ 3] = buf[ 2] << 4;
	buf[ 2] = zkASCII[buf[ 2] >>= 4];
	buf[ 3] = zkASCII[buf[ 3] >> 4];
	buf[30] = zKeyData[35] ^ zKeyData[28]; /* A1 = C7 ^ 66 */
	buf[31] = buf[30] << 4;
	buf[30] = zkASCII[buf[30] >>= 4];
	buf[31] = zkASCII[buf[31] >> 4];
	buf[16] = zKeyData[11] ^ zKeyData[52]; /* AB = 84 ^ 2F */
	buf[17] = buf[16] << 4;
	buf[16] = zkASCII[buf[16] >>= 4];
	buf[17] = zkASCII[buf[17] >> 4];
	buf[ 4] = zKeyData[39] ^ zKeyData[64]; /* AF = CC ^ 63 */
	buf[ 5] = buf[ 4] << 4;
	buf[ 4] = zkASCII[buf[ 4] >>= 4];
	buf[ 5] = zkASCII[buf[ 5] >> 4];
	buf[36] = zKeyData[19] ^ zKeyData[48]; /* 7E = 3F ^ 41 */
	buf[37] = buf[36] << 4;
	buf[36] = zkASCII[buf[36] >>= 4];
	buf[37] = zkASCII[buf[37] >> 4];
	buf[54] = zKeyData[61] ^ zKeyData[16]; /* 91 = 02 ^ 93 */
	buf[55] = buf[54] << 4;
	buf[54] = zkASCII[buf[54] >>= 4];
	buf[55] = zkASCII[buf[55] >> 4];
	buf[24] = zKeyData[23] ^ zKeyData[20]; /* 47 = 50 ^ 17 */
	buf[25] = buf[24] << 4;
	buf[24] = zkASCII[buf[24] >>= 4];
	buf[25] = zkASCII[buf[25] >> 4];
	buf[58] = zKeyData[ 7] ^ zKeyData[26]; /* 40 = BA ^ FA */
	buf[59] = buf[58] << 4;
	buf[58] = zkASCII[buf[58] >>= 4];
	buf[59] = zkASCII[buf[59] >> 4];
	buf[ 8] = zKeyData[63] ^ zKeyData[40]; /* 48 = C7 ^ 8F */
	buf[ 9] = buf[ 8] << 4;
	buf[ 8] = zkASCII[buf[ 8] >>= 4];
	buf[ 9] = zkASCII[buf[ 9] >> 4];
	buf[32] = zKeyData[37] ^ zKeyData[ 4]; /* E7 = 97 ^ 70 */
	buf[33] = buf[32] << 4;
	buf[32] = zkASCII[buf[32] >>= 4];
	buf[33] = zkASCII[buf[33] >> 4];
}
