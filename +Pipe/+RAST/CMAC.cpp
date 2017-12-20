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

int buildCMAs(const Input& in, Output& out, Point* outXY, const Regs& regs, Stats& stats)
{
    const int N = in.chunks.height();

    const int w = regs.imgHsize;
    const int h = regs.imgVsize;

    const int sz[2] = { w, h };

    const int cSizeCmaBank = sz[1];
    int16* cmaBank = new int16[cSizeCmaBank];
    for (int i = 0; i != cSizeCmaBank; ++i)
        cmaBank[i] = -1;

    FIFO<int16, 11> pxInOrder;

    const int cLenTemplate = out.cmaA.depth();

    int iOutXY = 0;

    uint32 lastTimestamp = (N == 0) ? 0 : in.timestamp[N - 1];

    for (int i = 0; i != N; ++i) {
        const uint8 flags = in.flags[i];
        if (flags == cPixelFlagsEOFMask) {
            lastTimestamp = (i == 0) ? 0 : in.timestamp[i-1];
            break;
        }

        const uint8* chunk = &in.chunks.data()[i << cChunkExp];
        const uint16 ir = in.ir[i];
        const Point& p = in.xy[i];
        const int tOffset = in.offset[i];

        const int16 y = p.y();

        if (cmaBank[y] != -1 && p.x() > cmaBank[y]) {
            // out pixel
            Point pOut;
            pOut.y() = y;
            pOut.x() = cmaBank[y];
            outXY[iOutXY] = pOut;
            ++iOutXY;
            out.timestamp(pOut.y(), pOut.x()) = in.timestamp[i];
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
            out.nest(y, cmaBank[y]) = in.nest[i]; // always overwrite:  align to ASIC - remove in the next version
            continue;
        }

        const int16 x = cmaBank[y];

        // aggregate
        for (int k = 0; k != cChunkSize; ++k) {
            int j = k + tOffset;
            if (j >= cLenTemplate)
                j -= cLenTemplate;

            if (out.cmaC(y, x, j) == regs.cmaMaxSamples)
                continue;
            out.cmaA(y, x, j) += chunk[k];
            out.cmaC(y, x, j) += 1;
        }

        if (out.nest(y, x) == 0) { // initialize a pixel
            out.flags(y, x) = flags;
            out.irMin(y, x) = ir;
            out.irMax(y, x) = ir;
        }
        else if (regs.invalidateDiffTxRx && (pixelFlagsTxRxMode(out.flags(y, x)) != pixelFlagsTxRxMode(flags)))
            out.flags(y, x) |= cPixelFlagsTxRxMask;

        out.irMin(y, x) = min(ir, out.irMin(y, x));
        out.irMax(y, x) = max(ir, out.irMax(y, x));
        
        out.nest(y, x) = in.nest[i]; // always overwrite

        if (ir != 0 && out.irC(y, x) < 65535) { // counter is 16 bit
            out.irA(y, x) += ir;
            out.irC(y, x) += 1;
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
        out.timestamp(pOut.y(), pOut.x()) = lastTimestamp;
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

    const int M = regs.imgVsize;
    const int N = regs.imgHsize;
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
