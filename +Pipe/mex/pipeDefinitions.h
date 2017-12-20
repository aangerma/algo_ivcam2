#pragma once

static const uint8 cFlagsLdOnMask = uint8(1) << 0;
static const uint8 cFlagsCodeStartMask = uint8(1) << 1;
static const uint8 cFlagsScanDirMask = uint8(1) << 2;
static const uint8 cFlagsTxRxShift = 3;
static const uint8 cFlagsTxRxMask = uint8(3) << cFlagsTxRxShift;
static const uint8 cFlagsRoiMask = uint8(1) << 5;

static const uint8 cPixelFlagsScanDirMask = uint8(1) << 0;
static const uint8 cPixelFlagsTxRxShift = 1;
static const uint8 cPixelFlagsTxRxMask = uint8(3) << cPixelFlagsTxRxShift;
static const uint8 cPixelFlagsEOFMask = uint8(1) << 3;

inline uint8 flagsTxRxMode(uint8 flags) { return (flags & cFlagsTxRxMask) >> cFlagsTxRxShift; }
inline uint8 pixelFlagsTxRxMode(uint8 flags) { return (flags & cPixelFlagsTxRxMask) >> cPixelFlagsTxRxShift; }
inline uint8 clearPixelFlagsEOF(uint8 flags) { return (flags & ~cPixelFlagsEOFMask); }

const int cChunkExp = 6;
const int cChunkSize = 1 << cChunkExp;

struct Point {
    int16 p[2];

    int16 x() const { return p[0]; }
    int16 y() const { return p[1]; }

    int16& x() { return p[0]; }
    int16& y() { return p[1]; }

    int16 operator[] (int i) const { return p[i]; }
    int16& operator[] (int i) { return p[i]; }

    Point() {}
    Point(int a) { p[0] = p[1] = a; }
    Point(int _x, int _y) { p[0] = _x;  p[1] = _y; }
};
