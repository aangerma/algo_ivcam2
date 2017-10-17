#include <stdio.h>

#include "../mex/auGeneral.h"

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
};


struct Point {
    int16 x() const { return p[0]; }
    int16 y() const { return p[1]; }

    int16& x() { return p[0]; }
    int16& y() { return p[1]; }

    int16 p[2];

    int16 operator[] (int i) const { return p[i]; }
    int16& operator[] (int i) { return p[i]; }
};

const int cChunkExp = 6;
const int cChunkSize = 1 << cChunkExp;

struct Stats {
    Image<uint32> timestamp;
    Image<uint16> xLate;
    Image<uint16> nThrownChunks;
};

int buildCMAs(const uint8* chunks, const uint16* IR, const uint16* nest, const Point* xy,
    const int16* tOffsets, const uint8* flags, const uint32* timestamps, int N,
    Image3D<uint8>& cmaA, Image3D<uint8>& cmaC,
    Image<uint32>& outIR, Image<uint16>& outIRC, Image<uint16>& outIRmin, Image<uint16>& outIRmax,
    Image<uint16>& outNest, Image<uint8>& outFlags, Point* outXY,
    const Regs& regs, Stats& stats)
{
    const int w = regs.imgHsize;
    const int h = regs.imgVsize;

    const int sz[2] = { w, h };

    const int cSizeCmaBank = sz[1];
    int16* cmaBank = new int16[cSizeCmaBank];
    for (int i = 0; i != cSizeCmaBank; ++i)
        cmaBank[i] = -1;

    FIFO<int16, 11> pxInOrder;

    const int cLenTemplate = cmaA.depth();

    int iOutXY = 0;

    uint32 lastTimestamp = (N == 0) ? 0 : timestamps[N - 1];

    for (int i = 0; i != N; ++i) {
        const uint8 flag = flags[i];
        if (flag == cPixelFlagsEOFMask) {
            lastTimestamp = (i == 0) ? 0 : timestamps[i-1];
            break;
        }

        const uint8* chunk = &chunks[i << cChunkExp];
        const uint16 ir = IR[i];
        const Point& p = xy[i];
        const int tOffset = tOffsets[i];

        const int16 y = p.y();

        if (cmaBank[y] != -1 && p.x() > cmaBank[y]) {
            // output pixel
            Point pOut;
            pOut.y() = y;
            pOut.x() = cmaBank[y];
            outXY[iOutXY] = pOut;
            ++iOutXY;
            stats.timestamp(pOut.y(), pOut.x()) = timestamps[i];
        }

        //CHECK(CMAC_strictly_monotonic_x, p.x() >= cmaBank[y]);
        //CHECK(CMAC_monotonic_x, p.x() + 1 >= cmaBank[y]);

        if (p.x() < cmaBank[y]) {
            stats.xLate(y, cmaBank[y]) = max(stats.xLate(y, cmaBank[y]), uint16(cmaBank[y] - p.x()));
        }

        if (p.x() > cmaBank[y])
            cmaBank[y] = p.x();
        else if (regs.discardLateChuncks && p.x() + 1 < cmaBank[y]) { // allow one column delay
            ++stats.nThrownChunks(y, p.x());
            outNest(y, cmaBank[y]) = nest[i]; // always overwrite:  align to ASIC - remove in the next version
            continue;
        }

        const int16 x = cmaBank[y];

        // aggregate
        for (int k = 0; k != cChunkSize; ++k) {
            int j = k + tOffset;
            if (j >= cLenTemplate)
                j -= cLenTemplate;

            if (cmaC(y, x, j) == regs.cmaMaxSamples)
                continue;
            cmaA(y, x, j) += chunk[k];
            cmaC(y, x, j) += 1;
        }

        if (outNest(y, x) == 0) { // initialize a pixel
            outFlags(y, x) = flags[i];
            outIRmin(y, x) = ir;
            outIRmax(y, x) = ir;
        }
        else if (regs.invalidateDiffTxRx && (pixelFlagsTxRxMode(outFlags(y, x)) != pixelFlagsTxRxMode(flags[i])))
            outFlags(y, x) |= cPixelFlagsTxRxMask;

        outIRmin(y, x) = min(ir, outIRmin(y, x));
        outIRmax(y, x) = max(ir, outIRmax(y, x));
        
        outNest(y, x) = nest[i]; // always overwrite

        if (ir != 0 && outIRC(y, x) < 65535) { // counter is 16 bit
            outIR(y, x) += ir;
            outIRC(y, x) += 1;
        }
    }

    for (int y = 0; y != cSizeCmaBank; ++y) {
        if (cmaBank[y] == -1)
            continue; // the entire line have not received any data
        Point pOut;
        pOut.y() = y;
        pOut.x() = cmaBank[y];
        outXY[iOutXY] = pOut;
        ++iOutXY;
        stats.timestamp(pOut.y(), pOut.x()) = lastTimestamp;
        lastTimestamp += 5;
    }

    // [!!!] add dummy pixel with EOF directly to the flow

    //if (iOutXY > 0) {
    //    Point pLast = outXY[iOutXY - 1];
    //    outFlags(pLast.y(), pLast.x()) |= cPixelFlagsEOFMask;
    //}

    delete cmaBank;

    return iOutXY;
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{

    if (nrhs != 8) // check for proper number of arguments
        mexErrMsgIdAndTxt(cStrErr, "4 inputs parameters are required:\n"
            "  (1) Chunks: matrix 64 x N of uint8,\n"
            "  (2) XY: matrix 2 x N of int16,\n"
            "  (3) IR: matrix 1 x N of uint16,\n"
            "  (4) NEST: matrix 1 x N of uint16,\n"
            "  (5) tOffset: matrix 1 x N of uint16,\n"
            "  (6) flags: matrix 1 x n of uint8,\n"
            "  (7) timestamps: matrix 1 x n of uint32,\n"
            "  (8) Regs: struct of registers\n"
        );

    if (nlhs != 10)
        mexErrMsgIdAndTxt(cStrErr, "10 outputs (cmaA, cmaC, IR, IRC, IRmin, IRmax, NEST, flags, timestamps, XY) are required.");

    const mxArray *mxChunks = prhs[0];
    const int n = int(mxGetN(mxChunks)); // number of chunks
    if (int(mxGetM(mxChunks)) != cChunkSize || !mxIsUint8(mxChunks))
        mexErrMsgIdAndTxt(cStrErr, "1st parameter (Chunks) must be a matrix 64 x N of uint8.");
    const uint8* chunks = (uint8*)mxGetData(mxChunks);

    const mxArray *mxXY = prhs[1];
    if (int(mxGetM(mxXY)) != 2 || !mxIsInt16(mxXY))
        mexErrMsgIdAndTxt(cStrErr, "2nd parameter (XY) must be a matrix 2 x N of int16.");
    if (int(mxGetN(mxXY)) != n)
        mexErrMsgIdAndTxt(cStrErr, "2nd parameter (XY: 2 x N) must be have the same N as the 1st parameter.");
    const Point* xy = (Point*)mxGetData(mxXY);

    const mxArray *mxIR = prhs[2];
    if (int(mxGetM(mxIR)) != 1 || !mxIsUint16(mxIR))
        mexErrMsgIdAndTxt(cStrErr, "3rd parameter (IR) must be a matrix 1 x N of uint16.");
    if (int(mxGetN(mxIR)) != n)
        mexErrMsgIdAndTxt(cStrErr, "3rd parameter (IR: 1 x N) must be have the same N as the 1st parameter.");
    const uint16* IR = (uint16*)mxGetData(mxIR);

    const mxArray *mxNest = prhs[3];
    if (int(mxGetM(mxNest)) != 1 || !mxIsUint16(mxNest))
        mexErrMsgIdAndTxt(cStrErr, "4th parameter (NEST) must be a matrix 1 x N of uint16.");
    if (int(mxGetN(mxNest)) != n)
        mexErrMsgIdAndTxt(cStrErr, "4th parameter (NEST: 1 x N) must be have the same N as the 1st parameter.");
    const uint16* nest = (uint16*)mxGetData(mxNest);

    const mxArray *mxOffset = prhs[4];
    if (int(mxGetM(mxOffset)) != 1 || !mxIsInt16(mxOffset))
        mexErrMsgIdAndTxt(cStrErr, "5th parameter (tOffset) must be a matrix 1 x N of int16.");
    if (int(mxGetN(mxOffset)) != n)
        mexErrMsgIdAndTxt(cStrErr, "5th parameter (tOffset: 1 x N) must be have the same N as the 1st parameter.");
    const int16* tOffsets = (int16*)mxGetData(mxOffset);

    const mxArray *mxFlags = prhs[5];
    const int nFlags = int(mxGetN(mxFlags));
    if (int(mxGetM(mxFlags)) != 1 || !mxIsUint8(mxFlags))
        mexErrMsgIdAndTxt(cStrErr, "5th parameter (flags) must be a matrix 1 x n of uint8.");
    const uint8* flags = (uint8*)mxGetData(mxFlags);

    const mxArray *mxTimestamps = prhs[6];
    const int nTimestamps = int(mxGetN(mxTimestamps));
    if (int(mxGetM(mxTimestamps)) != 1 || !mxIsUint32(mxTimestamps))
        mexErrMsgIdAndTxt(cStrErr, "6th parameter (timestamp) must be a matrix 1 x n of uint32.");
    const uint32* timestamps = (uint32*)mxGetData(mxTimestamps);

    const mxArray* mxRegs = prhs[7];
    Regs regs;
    regs.imgVsize = mxField<int>(mxRegs, "imgVsize", cStrErr);
    regs.imgHsize = mxField<int>(mxRegs, "imgHsize", cStrErr);
    regs.sampleRate = mxField<int>(mxRegs, "sampleRate", cStrErr);
    regs.codeLength = mxField<int>(mxRegs, "codeLength", cStrErr);
    regs.cmaMaxSamples = mxField<int>(mxRegs, "cmaMaxSamples", cStrErr);
    regs.invalidateDiffTxRx = mxField<bool>(mxRegs, "invalidateDiffTxRx", cStrErr);
    regs.rangeFinder = mxField<bool>(mxRegs, "rangeFinder", cStrErr);
    regs.discardLateChuncks = mxField<bool>(mxRegs, "discardLateChuncks", cStrErr);
    
    // create output matrix
    mwSize cmaSize[3];
    cmaSize[0] = regs.sampleRate * regs.codeLength;
    cmaSize[1] = regs.imgVsize;
    cmaSize[2] = regs.imgHsize;

    plhs[0] = mxCreateNumericArray(3, cmaSize, mxUINT8_CLASS, mxREAL); // accumulator
    plhs[1] = mxCreateNumericArray(3, cmaSize, mxUINT8_CLASS, mxREAL); // counter

    Image3D<uint8> cmaA((uint8*)mxGetData(plhs[0]), cmaSize[1], cmaSize[2], cmaSize[0]);
    Image3D<uint8> cmaC((uint8*)mxGetData(plhs[1]), cmaSize[1], cmaSize[2], cmaSize[0]);

    const int M = regs.imgVsize;
    const int N = regs.imgHsize;

    plhs[2] = mxCreateNumericMatrix(M, N, mxUINT32_CLASS, mxREAL);
    Image<uint32> outIR((uint32*)mxGetData(plhs[2]), M, N);

    plhs[3] = mxCreateNumericMatrix(M, N, mxUINT16_CLASS, mxREAL);
    Image<uint16> outIRC((uint16*)mxGetData(plhs[3]), M, N);

    plhs[4] = mxCreateNumericMatrix(M, N, mxUINT16_CLASS, mxREAL);
    Image<uint16> outIRmin((uint16*)mxGetData(plhs[4]), M, N);

    plhs[5] = mxCreateNumericMatrix(M, N, mxUINT16_CLASS, mxREAL);
    Image<uint16> outIRmax((uint16*)mxGetData(plhs[5]), M, N);

    plhs[6] = mxCreateNumericMatrix(M, N, mxUINT16_CLASS, mxREAL);
    Image<uint16> outNest((uint16*)mxGetData(plhs[6]), M, N);

    plhs[7] = mxCreateNumericMatrix(M, N, mxUINT8_CLASS, mxREAL);
    Image<uint8> outFlags((uint8*)mxGetData(plhs[7]), M, N);

    Point* outXY = new Point[M * N * 2];

    Stats stats;
    MexStruct mxStats;
    plhs[9] = mxStats.mxStruct();
    stats.timestamp.set(mxStats.add<uint32>("timestamps", M, N), M, N);
    stats.xLate.set(mxStats.add<uint16>("xLate", M, N), M, N);
    stats.nThrownChunks.set(mxStats.add<uint16>("nThrownChunks", M, N), M, N);

    const int iOutXY = buildCMAs(chunks, IR, nest, xy, tOffsets, flags, timestamps, n,
        cmaA, cmaC, outIR, outIRC, outIRmin, outIRmax, outNest, outFlags, outXY, regs, stats);

    plhs[8] = mxCreateNumericMatrix(2, iOutXY, mxINT16_CLASS, mxREAL);
    Point* mxOutXY = (Point*)mxGetData(plhs[8]);

    for (int i = 0; i != iOutXY; ++i)
        mxOutXY[i] = outXY[i];

    delete outXY;
}
