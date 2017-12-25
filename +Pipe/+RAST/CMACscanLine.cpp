#include <stdio.h>

#include "../mex/auGeneral.h"
#include "../mex/pipeDefinitions.h"

const char* cStrErr = "CMAC:nrhs";

struct Regs {
    int imgHsize;
    int imgVsize;

    int sampleRate;
    int codeLength;

    int cmaMaxSamples;

    bool invalidateDiffTxRx;
    bool rangeFinder;
    bool discardLateChuncks = true;

    uint8 nScansPerPixel;
};

struct Input {
    Image<uint8> chunks;
    Array<Point> xy;
    Array<uint16> ir;
    Array<uint16> nest;
    Array<int16> offset;
    Array<uint8> flags;
    Array<uint32> timestamp;
};

struct Output {
    Image3D<uint8> cmaA;
    Image3D<uint8> cmaC;
    Image<uint32> irA;
    Image<uint16> irC;
    Image<uint16> irMin;
    Image<uint16> irMax;
    Image<uint16> nest;
    Image<uint8> flags;
    Image<uint32> timestamp;
    Array<Point> xy;
};

struct Stats {
    Image<uint16> xLate;
    Image<uint16> nThrownChunks;
};

struct Pixel {
    uint32 irA;
    uint32 irC;
    uint16 irMin;
    uint16 irMax;
    uint16 nest = 0; // when 0 the pixel is initialized
    int16 xMin = 0;
    int16 xMax = 0;
    int16 lastOutX = -1;
    uint8 flags;
    uint8 nScans = 0;
    bool lastScanDir = 0;
    uint16 nChunks = 0; // for stats only
    uint8* cmaA = 0;
    uint8* cmaC = 0;
};

inline void copyCma(const uint8* src, uint8* dst, int k)
{
    for (int i = 0; i != k; ++i)
        dst[i] = src[i];
}

inline void clearCma(uint8* dst, int k)
{
    for (int i = 0; i != k; ++i)
        dst[i] = 0;
}

inline void outputPixel(Pixel& px, const Point& p, int K, uint32 timestamp,
    Point* outXY, int& iOutXY, Output& out, Stats& stats)
{
    const int16 x = p.x();
    const int16 y = p.y();

    if (x > px.lastOutX) { // guarantee strict x-monotonicity
        px.lastOutX = x;
        outXY[iOutXY] = p;
        ++iOutXY;

        copyCma(px.cmaA, out.cmaA(y, x), K);
        copyCma(px.cmaC, out.cmaC(y, x), K);
        out.nest(y, x) = px.nest;
        out.irA(y, x) = px.irA;
        out.irC(y, x) = px.irC;
        out.irMin(y, x) = px.irMin;
        out.irMax(y, x) = px.irMax;
        out.flags(y, x) = px.flags;
        out.timestamp(y, x) = timestamp;
    }
    else {
        stats.xLate(y, x) = max(stats.xLate(y, x), uint16(px.lastOutX - x + 1));
        stats.nThrownChunks(y, x) += px.nChunks;
    }

}

int countScanlines(const Input& in)
{
    const int N = in.chunks.height();

    if (N == 0)
        return 0;

    bool firstScan = true;
    bool firstScanDir = in.flags[0] & cPixelFlagsScanDirMask;
    bool globalScanDir = firstScanDir;

    int nScanlines = 0;

    for (int i = 0; i != N; ++i) {
        const uint8 flags = in.flags[i];
        if (flags == cPixelFlagsEOFMask) {
            break;
        }

        const bool scanDir = flags & cPixelFlagsScanDirMask;

        if (globalScanDir != scanDir) {
            globalScanDir = scanDir;
            if (firstScan)
                firstScan = false;
            else
                ++nScanlines;
        }
    }
    return nScanlines;
}

int buildCMAs(const Input& in, Output& out, Point* outXY, const Regs& regs, Stats& stats)
{
    const int N = in.chunks.height();

    if (N == 0)
        return 0;

    const int W = regs.imgHsize;
    const int H = regs.imgVsize;
    const int K = out.cmaA.depth();

    const int sz[2] = { W, H };
    const int cColumnSize = sz[1];

    const int nScanlines = out.irA.height();
    
    // column buffer
    Image<uint8> cmaA(K, cColumnSize, 0);
    Image<uint8> cmaC(K, cColumnSize, 0);
    Array<Pixel> column(cColumnSize);

    // initialization
    for (int i = 0; i != cColumnSize; ++i) {
        column[i].cmaA = cmaA.row(i);
        column[i].cmaC = cmaC.row(i);
    }

    int iOutXY = 0;
    
    bool firstScan = true;
    bool firstScanDir = in.flags[0] & cPixelFlagsScanDirMask;

    bool globalScanDir = firstScanDir;
    bool outputScan = false;
    int globalScanCounter = 0;
    int iScanline = -1;
    
    int16 yPrev = -1024;

    uint32 lastTimestamp = (N == 0) ? 0 : in.timestamp[N - 1];

    for (int i = 0; i != N; ++i) {
        const uint8 flags = in.flags[i];
        if (flags == cPixelFlagsEOFMask) {
            lastTimestamp = (i == 0) ? 0 : in.timestamp[i-1];
            break;
        }

        const bool scanDir = flags & cPixelFlagsScanDirMask;
        if (firstScan) {
            if (scanDir != firstScanDir)
                firstScan = false;
            else
                continue;
        }
        
        const uint8* chunk = &in.chunks.data()[i << cChunkExp];
        const uint16 ir = in.ir[i];
        const Point& p = in.xy[i];
        const int tOffset = in.offset[i];

        if (globalScanDir != scanDir) {
            globalScanCounter++;
            globalScanDir = scanDir;
            outputScan = false;
        }
        if (globalScanCounter == regs.nScansPerPixel) {
            iScanline++;
            globalScanCounter = 0;
            outputScan = true;
        }
        
        const int16 y = p.y();

        if (outputScan && y != yPrev && yPrev >= 0) {
            Pixel& px = column[yPrev];
            const int16 x = iScanline;// (px.xMin + px.xMax) >> 1; // !!! add extra bits from PCQ
            Point pOut;
            pOut.x() = x;
            pOut.y() = yPrev;

            if (px.nScans == regs.nScansPerPixel && 0 <= x && x < nScanlines) // x < regs.imgHsize
                outputPixel(px, pOut, K, in.timestamp[i], outXY, iOutXY, out, stats);

            clearCma(px.cmaA, K);
            clearCma(px.cmaC, K);
            px.nScans = 0;
            px.nChunks = 0;
            px.nest = 0;
        }

        yPrev = y;

        Pixel& px = column[y];

        if (px.nScans == 0) { // initialize the pixel in a row
            px.nScans = 1;
            px.nChunks = 0;
            px.lastScanDir = scanDir;
            px.xMin = p.x();
            px.xMax = p.x();
            px.nest = 0;

            px.flags = flags;
            px.irMin = ir;
            px.irMax = ir;
            px.irA = 0;
            px.irC = 0;
        }
        else {
            if (px.lastScanDir != scanDir)
                px.nScans++;
            if (regs.invalidateDiffTxRx && (pixelFlagsTxRxMode(px.flags) != pixelFlagsTxRxMode(flags)))
                px.flags |= cPixelFlagsTxRxMask; // invalidate
        }
        
        px.nChunks++;
        px.lastScanDir = scanDir;
        px.xMin = min(px.xMin, p.x());
        px.xMax = max(px.xMax, p.x());
        px.irMin = min(ir, px.irMin);
        px.irMax = max(ir, px.irMax);

        px.nest = in.nest[i]; // always overwrite

        // aggregate
        for (int k = 0; k != cChunkSize; ++k) {
            int j = k + tOffset;
            if (j >= K)
                j -= K;

            if (cmaC(j, y) == regs.cmaMaxSamples)
                continue;

            cmaA(j, y) += chunk[k];
            cmaC(j, y) += 1;
        }

        if (ir != 0 && px.irC < 65535) { // counter is 16 bit
            px.irA += ir;
            px.irC += 1;
        }
    }

    /*
    for (int y = 0; y != cColumnSize; ++y) {
        Pixel& px = column[y];

        if (px.nChunks == 0)
            continue; // the entire line have not received any data

        const int16 x = (px.xMin + px.xMax) >> 1; // !!! add extra bits from PCQ
        if (x < 0 && regs.imgHsize >= x)
            continue;

        Point pOut;
        pOut.x() = x;
        pOut.y() = y;

        outputPixel(px, pOut, K, lastTimestamp, outXY, iOutXY, out, stats);
        lastTimestamp += 5;
    }
    */

    return iOutXY;
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{

    if (nrhs != 2) // check for proper number of arguments
        mexErrMsgIdAndTxt(cStrErr, "2 inputs parameters are required:\n"
            "  (1) struct with:\n"
            "   - chunks: matrix 64 x N of uint8,\n"
            "   - xy: matrix 2 x N of int16,\n"
            "   - ir: matrix 1 x N of uint16,\n"
            "   - nest: matrix 1 x N of uint16,\n"
            "   - offset: matrix 1 x N of uint16,\n"
            "   - flags: matrix 1 x n of uint8,\n"
            "   - timestamps: matrix 1 x n of uint32,\n"
            "  (2) regs: struct of registers\n"
        );

    if (nlhs != 2)
        mexErrMsgIdAndTxt(cStrErr, "2 outputs (output struct, stats) are required.");

    Input in;
    const mxArray* mxInput = prhs[0];

    mxGetImageField(mxInput, "chunks", in.chunks, cStrErr);
    if (in.chunks.width() != cChunkSize)
        mexErrMsgIdAndTxt(cStrErr, "chunks must be a matrix 64 x N of uint8.");
    const int n = in.chunks.height();

    Image<int16> imgXY;
    mxGetImageField(mxInput, "xy", imgXY, cStrErr);
    if (imgXY.height() != n || imgXY.width() != 2)
        mexErrMsgIdAndTxt(cStrErr, "xy field should be a 2 x N matrix, when N is equal to the number of chunks");
    in.xy.set((Point*)imgXY.data(), n);

    mxGetArrayField(mxInput, "ir", in.ir, cStrErr);
    mxGetArrayField(mxInput, "nest", in.nest, cStrErr);
    mxGetArrayField(mxInput, "offset", in.offset, cStrErr);
    mxGetArrayField(mxInput, "flags", in.flags, cStrErr);
    mxGetArrayField(mxInput, "timestamp", in.timestamp, cStrErr);

    if (in.ir.size() != n || in.nest.size() != n || in.flags.size() != n || in.timestamp.size() != n)
        mexErrMsgIdAndTxt(cStrErr, "IR, nest, flags, timestamps must be of the number of chunks");
    
    const mxArray* mxRegs = prhs[1];
    Regs regs;
    regs.imgVsize = mxField<int>(mxRegs, "imgVsize", cStrErr);
    regs.imgHsize = mxField<int>(mxRegs, "imgHsize", cStrErr);
    regs.sampleRate = mxField<int>(mxRegs, "sampleRate", cStrErr);
    regs.codeLength = mxField<int>(mxRegs, "codeLength", cStrErr);
    regs.cmaMaxSamples = mxField<int>(mxRegs, "cmaMaxSamples", cStrErr);
    regs.invalidateDiffTxRx = mxField<bool>(mxRegs, "invalidateDiffTxRx", cStrErr);
    regs.rangeFinder = mxField<bool>(mxRegs, "rangeFinder", cStrErr);
    regs.discardLateChuncks = mxField<bool>(mxRegs, "discardLateChuncks", cStrErr);
    regs.nScansPerPixel = mxField<int>(mxRegs, "nScansPerPixel", cStrErr);

    const int nScanlines = countScanlines(in)/regs.nScansPerPixel + 2;

    const int M = regs.imgVsize;
    const int N = nScanlines; // regs.imgHsize;
    const int K = regs.sampleRate * regs.codeLength;

    MexStruct mxOut;
    plhs[0] = mxOut.mxStruct();
    Output out;
    
    out.cmaA.set(mxOut.add<uint8>("cmaA", K, M, N), M, N, K);
    out.cmaC.set(mxOut.add<uint8>("cmaC", K, M, N), M, N, K);

    out.irA.set(mxOut.add<uint32>("irA", M, N), M, N);
    out.irC.set(mxOut.add<uint16>("irC", M, N), M, N);

    out.irMin.set(mxOut.add<uint16>("irMin", M, N), M, N);
    out.irMax.set(mxOut.add<uint16>("irMax", M, N), M, N);

    out.nest.set(mxOut.add<uint16>("nest", M, N), M, N);

    out.flags.set(mxOut.add<uint8>("flags", M, N), M, N);
    
    out.timestamp.set(mxOut.add<uint32>("timestamp", M, N), M, N);

    Point* outXY = new Point[M * N * 2];

    Stats stats;
    MexStruct mxStats;
    plhs[1] = mxStats.mxStruct();
    stats.xLate.set(mxStats.add<uint16>("xLate", M, N), M, N);
    stats.nThrownChunks.set(mxStats.add<uint16>("nThrownChunks", M, N), M, N);

    const int nOutXY = buildCMAs(in, out, outXY, regs, stats);

    out.xy.set((Point*)mxOut.add<int16>("xy", 2, nOutXY), nOutXY);

    for (int i = 0; i != nOutXY; ++i)
        out.xy[i] = outXY[i];

    delete outXY;
}
