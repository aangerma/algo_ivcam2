#include <stdio.h>

#include "../mex/auGeneral.h"

const char* cStrErr = "cmaFilter:nrhs";

struct Point {
    int16 x() const { return p[0]; }
    int16 y() const { return p[1]; }

    int16& x() { return p[0]; }
    int16& y() { return p[1]; }

    int16 p[2];

    int16 operator[] (int i) const { return p[i]; }
    int16& operator[] (int i) { return p[i]; }

    Point() {}
    Point(int a) { p[0] = p[1] = a; }
    Point(int _x, int _y) { p[0] = _x;  p[1] = _y; }
};

//const uint8 cSmoothWSTotalExp = 7;
//const uint8 cSmoothWSTotal = 1 << cSmoothWSTotalExp;

const uint8 cSmoothWTotalExp = 8;
const uint16 cSmoothWTotal = 1 << cSmoothWTotalExp;

struct Regs {

    int imgHsize;
    int imgVsize;

    uint8 biltAdapt;
    uint8 biltSharpnessS;
    uint8 biltSharpnessR;
    uint8 biltDiag;

    bool biltBypass;
    bool fastApprox;

    uint8 mmSide;
};

struct RowPtr {
    uint8 ptr[3];
};

struct Luts {

    // divCma: 7bit -> 8bit
    //const uint8* divCma = 0;

    // rastSpat: 6bit -> 4bit
    const uint8* biltSpat = 0;

    // AdaptR: 6bit -> 8bit
    const uint8* biltAdaptR = 0;

    // Sigmoid: 6bit -> 8bit
    const uint8* biltSigmoid = 0;
};

struct Stats {
    int nNonRefsPixels = 0;
    int maxPixelFifoSize = 0;
    int maxChunkFifoSize = 0;
    int minPixelMainLobe = 1 << 24;
    int n12NeighborMiss = 0;
    double maxPixelSideLobe = 0;
    bool pixelSideLobeExceeded = false;
};

struct WindowOut {
    Image<Point> xy;
    Image<uint16> ir;
    Image<uint16> irSort;
    Image<uint16> wr;
    Image<uint16> ws;
    Image<uint16> w;
    RowPtr* rowPtrs = 0;
};

template <class T>
inline
void swap(T& a, T& b)
{
    T tmp = a;
    a = b;
    b = tmp;
}

uint16 irMM(uint16* ir, int n, const Regs& regs)
{
    if (n == 1)
        return ir[0];
    else if (n == 2) {
        if (ir[0] > ir[1])
            swap(ir[0], ir[1]);
        return (ir[0] + ir[1]) / 2;
    }

    //std::sort(ir, ir + n);
    
    // sort
    for (int k = 0; k != n - 1; ++k) {
        for (int m = 0; m != n - k - 1; ++m) {
            if (ir[m] > ir[m + 1])
                swap(ir[m], ir[m + 1]);
        }
    }

    const int ic = n / 2; // center index

    const uint8 ws = regs.mmSide;
    const uint8 wc = 16 - 2 * ws;

    return (ir[ic] * wc + ir[ic - 1] * ws + ir[ic + 1] * ws) >> 4;
}

const int cCmaFifoSizeExp = 12; // up to 4092 pixel : real max 3 * max column size
typedef FIFO<int16, cCmaFifoSizeExp> CmaFifo;

typedef FIFO<Point, 2> CMARefs; // FIFOs of size 4 but max 3 should be used


void smooth(int16 y, int iRef, const CMARefs* cmaRefs, const uint8* rowPtrs,
    const Image3D<uint8>& cma, const Image<uint16>& IR, const Image<uint8>& flags,
    Image3D<uint8>& outCma, Image<uint16>& outIR, Image<uint8>& outFlags,
    Image<uint8>& pxSmoothType, const Regs& regs, const Luts& luts, Stats& stats,
    WindowOut& outWin, int iPxOut)
{
    const int K = cma.depth();

    const int sz[2] = { int(cma.height()), int(cma.width()) };

    const int cScanlineLength = sz[1];

    CHECK(ValidPixel, y != -1 && iRef < cmaRefs[y].size());

    const int16 x = cmaRefs[y][iRef].x();

    uint8* C = (uint8*)outCma(y, x);

    outFlags(y, x) = clearPixelFlagsEOF(flags(y, x));

    const uint8 txrxMode = pixelFlagsTxRxMode(flags(y, x));
    if (txrxMode == 3) {
        outIR(y, x) = IR(y, x);
        const uint8* c = (uint8*)cma(y, x);
        for (int k = 0; k != K; ++k)
            C[k] = c[k];
        return;
    }

    Point pn[9] = { -1,-1,-1,-1,-1,-1,-1,-1,-1 };
    // 0 1 2
    // 3 4 5
    // 6 7 8

    pn[4] = Point(x, y);

    //BREAK(Pixel, y == 300 && x == 300);

    uint16 pxDist = 0;

    // y row
    {
        const CMARefs& refs = cmaRefs[y];

        if (iRef > 0)
            pn[3] = refs[iRef - 1];

        if (iRef + 1 < refs.size()) // there is a pixel after
            pn[5] = refs[iRef + 1];
        else if (refs.size() == 3) // there is no pixel after
            pn[5] = refs[0]; // cyclically take the 1st pixel in FIFO (two pixels on the left)

        if (rowPtrs[y] == 0)
            swap(pn[3], pn[5]);
        outWin.rowPtrs[iPxOut].ptr[1] = rowPtrs[y];
    }

    // y - 1 row
    if (y != 0) {
        const CMARefs& refs = cmaRefs[y - 1];

        if (refs.size() == 3)
            pn[0] = refs[0];

        if (refs.size() > 1) {
            pn[1] = refs[refs.size() - 2];
            pxDist += abs(x - pn[1].x());
        }

        if (refs.size() > 0)
            pn[2] = refs[refs.size() - 1];

        if (rowPtrs[y-1] == 0)
            swap(pn[0], pn[2]);
        outWin.rowPtrs[iPxOut].ptr[0] = rowPtrs[y-1];
    }

    // y+1 row
    if (y != cScanlineLength - 1) {
        const CMARefs& refs = cmaRefs[y + 1];

        if (refs.size() == 3)
            pn[6] = refs[0];

        if (refs.size() > 1) {
            pn[7] = refs[refs.size() - 2];
            pxDist += abs(x - pn[7].x());
        }

        if (refs.size() > 0)
            pn[8] = refs[refs.size() - 1];

        if (rowPtrs[y + 1] == 0)
            swap(pn[6], pn[8]);
        outWin.rowPtrs[iPxOut].ptr[2] = rowPtrs[y + 1];
    }

    /////////////////////////////////
    // compute robust IR estimate

    uint8 count = 0;
    uint16 vIR[9] = { 0, 0, 0, 0, 0, 0, 0, 0, 0 };
    uint16 sortedIR[9] = { 0, 0, 0, 0, 0, 0, 0, 0, 0 };

    for (int j = 0; j != 9; ++j) {
        if (pn[j].x() == -1 || pixelFlagsTxRxMode(flags(pn[j].y(), pn[j].x())) != txrxMode) {
            pn[j] = Point(-1);
            continue;
        }
        vIR[count] = IR(pn[j].y(), pn[j].x());
        sortedIR[count] = vIR[count];
        ++count;
    }

    const uint16 mIR = irMM(sortedIR, count, regs);
    outIR(y, x) = regs.biltBypass ? IR(y, x) : mIR;

    pxSmoothType(y, x) = count;
    //pxSmoothType(y, x) = uint8(pxDist);

    /////////////////////////////////
    // compute weights

    const bool sAdaptive = ((regs.biltAdapt & 1) != 0);
    const bool rAdaptive = ((regs.biltAdapt & 2) != 0);

    const uint8 sSharpness = regs.biltSharpnessS; // 6bit:  0=min, 16=default, 64=max
    const uint8 rSharpness = regs.biltSharpnessR; // 6bit:  0=min, 16=default, 64=max

    // spatial weights
    const uint16 sIR = sAdaptive ? min((mIR >> 6), 63) : 16; // 12bit -> 6bit
    const uint8 wSide = luts.biltSpat[min((sIR * sSharpness) >> 4, 63)]; // biltSpat: 6bit -> 4bit

    const uint8 wDiag = (uint16(wSide) * regs.biltDiag) >> 4; // regs.biltDiag: 5bit, 0=min, 16=same as wSide, >16 do not use
    const uint8 wCentral = 255 - ((wSide + wDiag) << 2); // 128 - 4*wSide - 4*wDiag
    const uint8 ws[9] = { wDiag, wSide, wDiag, wSide, wCentral, wSide, wDiag, wSide, wDiag };

    // radiometric weights
    uint8 wr[9] = { 0, 0, 0,  0, 0, 0,  0, 0, 0 };
    for (int j = 0; j != 9; ++j) {
        if (pn[j].x() == -1)
            continue;

        const uint16 ir = IR(pn[j].y(), pn[j].x());
        const uint16 dIR = min(abs(int16(ir) - int16(mIR)), 1023); // 10bit

        // 10bit*8bit*6bit -> 8bit
        const uint16 rIR = rAdaptive ? min((mIR >> 6), 63) : 0; // 12bit -> 6bit
        const uint32 rd = (uint32(dIR)*luts.biltAdaptR[rIR] * rSharpness) >> (6 + 5);
        wr[j] = luts.biltSigmoid[min(rd, uint32(63))];
    }

    uint16 wOrg[9] = { 0, 0, 0,  0, 0, 0,  0, 0, 0 };

    // normalize weights
    uint32 wSum = 0;
    for (int j = 0; j != 9; ++j) {
        if (pn[j].x() == -1)
            continue;
        wOrg[j] = uint16(ws[j]) * uint16(wr[j]);
        wSum += wOrg[j];
    }

    float recip = 0;
    if (wSum == 0)
        recip = 0;
    else if (regs.fastApprox)
        recip = 1.0f / float(wSum);
    else {
        mxArray* mxInFp32[2];
        mxInFp32[0] = mxCreateString("inv");
        mxInFp32[1] = mxCreateNumericMatrix(1, 1, mxSINGLE_CLASS, mxREAL);
        *(float*)mxGetData(mxInFp32[1]) = float(wSum);
        mxArray* mxOutFp32[1];
        mexCallMATLAB(1, mxOutFp32, 2, mxInFp32, "Utils.fp32");
        recip = *(float*)mxGetData(mxOutFp32[0]);
    }

    const uint32 sFactor = uint32(float(1 << (cSmoothWTotalExp + 20)) * recip); // 8 bit weigths + 12 bit extra precision

    uint16 w[9] = { 0, 0, 0,  0, 0, 0,  0, 0, 0 };
    uint16 sum8 = 0;
    for (int j = 0; j != 9; ++j) {
        if (pn[j].x() == -1)
            continue;

        w[j] = uint16((uint64(wOrg[j]) * uint64(sFactor) + 0) >> 20); // no round
        if (j != 4) // without central pixel
            sum8 += w[j];
    }
    CHECK(ValidWeightSum, sum8 <= 256);
    w[4] = cSmoothWTotal - uint16(sum8);

    typedef const uint8* CmaType;
    CmaType cmas[9] = { 0, 0, 0,  0, 0, 0,  0, 0, 0 };
    for (int j = 0; j != 9; ++j) {
        if (pn[j].x() == -1)
            continue;
        Point p = pn[j];
        cmas[j] = cma(p.y(), p.x());
    }

    if (sum8 == 0 || regs.biltBypass) {
        CmaType cc = cmas[4];
        for (int k = 0; k != K; ++k)
            C[k] = cc[k];
    }
    else {
        for (int k = 0; k != K; ++k) {
            uint16 vTotal = 0;
            for (int j = 0; j != 9; ++j) {
                if (w[j] == 0)
                    continue;

                const uint16 v = uint16(cmas[j][k]);
                vTotal += v * w[j];
            }
            C[k] = uint8(vTotal >> cSmoothWTotalExp);
        }
    }

    // output windows
    for (int j = 0; j != 9; ++j) {
        outWin.xy(j, iPxOut) = pn[j];
        outWin.ir(j, iPxOut) = vIR[j];
        outWin.irSort(j, iPxOut) = sortedIR[j];
        outWin.wr(j, iPxOut) = wr[j];
        outWin.w(j, iPxOut) = w[j];
    }
    outWin.ws(0, iPxOut) = wCentral;
    outWin.ws(1, iPxOut) = wSide;
    outWin.ws(2, iPxOut) = wDiag;

    outWin.irSort(9, iPxOut) = mIR;
}

void smooth(const Image3D<uint8>& cma, const Image<uint16>& IR, const Image<uint8>& flags,
    const Image<uint32>& timestamps, const Point* xy, int nXY,
    Image3D<uint8>& outCma, Image<uint16>& outIR, Image<uint8>& outFlags, Image<uint32>& outTimestamps,
    Point* outXY, Image<uint8>& pxSmoothType, const Regs& regs, const Luts& luts, Stats& stats,
    WindowOut& outWin)
{
    const int K = cma.depth();

    const int sz[2] = { int(cma.height()), int(cma.width()) };

    const int cScanlineLength = sz[1];

    CMARefs* cmaRefs = new CMARefs[cScanlineLength];

    int* rowIndex = new int[cScanlineLength];
    uint8* rowCounters = new uint8[cScanlineLength];
    uint8* rowPtrs = new uint8[cScanlineLength];

    for (int i = 0; i != cScanlineLength; ++i) {
        rowIndex[i] = 0;
        rowCounters[i] = 2;
        rowPtrs[i] = 0;
    }

    CmaFifo cmaFifo;

    const int cMaxCmaFifoSize = min(1 << cCmaFifoSizeExp, 4 * cScanlineLength);
    const int cSmoothDelay = cMaxCmaFifoSize >> 1;
    int16 refCurrCma = -1;

    int nPxComputed = 0;
    const int cMaxPixelFails = 2 * cScanlineLength;
    int pxFails = cMaxPixelFails;

    uint32 lastTimestamp = 0;

    for (int i = 0; i != nXY; ++i) {

        Point p = xy[i];
        const int y = p.y();
        const uint32 timestamp = timestamps(p.y(), p.x());
        lastTimestamp = timestamp;

        // smooth a cma
        if (rowCounters[y] == 0) {
            const int iRef = cmaRefs[y].indexToOrder(rowIndex[y]);
            const int16 x = cmaRefs[y][iRef].x();

            smooth(y, iRef, cmaRefs, rowPtrs, cma, IR, flags, outCma, outIR, outFlags, pxSmoothType, regs, luts, stats,
                outWin, nPxComputed);

            rowIndex[y] = CMARefs::next(rowIndex[y]);
            outXY[nPxComputed] = Point(x, y);
            outTimestamps(y, x) = timestamp;
            ++nPxComputed;
        }

        // add pixel to FIFOs
        {
            if (cmaRefs[y].size() == 3) {
                // check if the removed pixel is not yet processed
                int iPop = cmaRefs[y].getPopIndex();
                if (iPop == rowIndex[y]) {
                    rowIndex[y] = CMARefs::next(iPop); // move to the next pixel
                    CHECK(InvalidRefPop, false); // should not happen - remove eventually
                }

                cmaRefs[y].pop();
            }
            cmaRefs[y].push(p);

            rowPtrs[y] = (rowPtrs[y] == 2) ? 0 : rowPtrs[y] + 1;

            if (rowCounters[y] != 0)
                --rowCounters[y];
        }
    }


    // flush the rest of pixels
    for (int y = 0; y != cScanlineLength; ++y) {
        while (cmaRefs[y].indexToOrder(rowIndex[y]) < cmaRefs[y].size()) {
            const int iRef = cmaRefs[y].indexToOrder(rowIndex[y]);
            const int16 x = cmaRefs[y][iRef].x();
            
            smooth(y, iRef, cmaRefs, rowPtrs, cma, IR, flags, outCma, outIR, outFlags, pxSmoothType, regs, luts, stats,
                outWin, nPxComputed);

            rowIndex[y] = CMARefs::next(rowIndex[y]);
            rowPtrs[y] = (rowPtrs[y] == 2) ? 0 : rowPtrs[y] + 1;
            outXY[nPxComputed] = Point(x, y);
            lastTimestamp += 5;
            outTimestamps(y, x) = lastTimestamp;
            ++nPxComputed;
        }
    }

    // [!!!] add dummy pixel with EOF directly to the flow

    //if (nPxComputed > 0) {
    //    Point pLast = outXY[nPxComputed - 1];
    //    outFlags(pLast.y(), pLast.x()) |= cPixelFlagsEOFMask;
    //}

    delete cmaRefs;
    delete rowIndex;
    delete rowCounters;
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    if (nrhs != 7) // check for proper number of arguments
        mexErrMsgIdAndTxt(cStrErr, "5 input parameters are required:\n"
            "  (1) cma: matrix K x M x N of uint8,\n"
            "  (2) IR: image M x N of uint16,\n"
            "  (3) flags: matrix M x N of uint8,\n"
            "  (4) XY: matrix 2 x n of int16,\n"
            "  (5) timestamps: matrix 1 x n of uint32,\n"
            "  (6) Regs: struct of registers\n"
            "  (7) Luts: struct of LUTs\n"
        );

    if (nlhs != 7)
        mexErrMsgIdAndTxt(cStrErr, "7 outputs are required.");

    const mxArray *mxCma = prhs[0];
    mwSize nDimCma = mxGetNumberOfDimensions(mxCma);
    const mwSize* dimCma = mxGetDimensions(mxCma);
    if (!(nDimCma == 1 || nDimCma == 2 || nDimCma == 3) || !mxIsUint8(mxCma))
        mexErrMsgIdAndTxt(cStrErr, "1st parameter (CMA) must be a matrix K x M x N of uint8");

    const int K = int(dimCma[0]);
    const int M = (nDimCma < 2) ? 1 : int(dimCma[1]);
    const int N = (nDimCma < 3) ? 1 : int(dimCma[2]);

    Image3D<uint8> cma((uint8*)mxGetData(mxCma), M, N, K);

    const mxArray *mxIR = prhs[1];
    if (int(mxGetM(mxIR)) != M || int(mxGetN(mxIR)) != N || !mxIsUint16(mxIR))
        mexErrMsgIdAndTxt(cStrErr, "2nd parameter (IR) must be a matrix M x N of uint16.");
    Image<uint16> IR((uint16*)mxGetData(mxIR), M, N);

    const mxArray *mxFlags = prhs[2];
    if (int(mxGetM(mxFlags)) != M || int(mxGetN(mxFlags)) != N || !mxIsUint8(mxFlags))
        mexErrMsgIdAndTxt(cStrErr, "3rd parameter (XY) must be a matrix 2 x n of int16.");
    Image<uint8> flags((uint8*)mxGetData(mxFlags), M, N);

    const mxArray *mxTimestamps = prhs[3];
    if (int(mxGetM(mxTimestamps)) != M || int(mxGetN(mxTimestamps)) != N || !mxIsUint32(mxTimestamps))
        mexErrMsgIdAndTxt(cStrErr, "4th parameter (timestamps) must be a matrix M x N of uint32.");
    Image<uint32> timestamps((uint32*)mxGetData(mxTimestamps), M, N);

    const mxArray *mxXY = prhs[4];
    if (int(mxGetM(mxXY)) != 2 || !mxIsInt16(mxXY))
        mexErrMsgIdAndTxt(cStrErr, "5th parameter (XY) must be a matrix 2 x n of int16.");
    const Point* xy = (Point*)mxGetData(mxXY);
    const int nXY = int(mxGetN(mxXY));

    Regs regs;
    const mxArray* mxRegs = prhs[5];
    regs.imgVsize = mxField<int>(mxRegs, "imgVsize", cStrErr);
    regs.imgHsize = mxField<int>(mxRegs, "imgHsize", cStrErr);

    regs.biltAdapt = mxField<uint8>(mxRegs, "biltAdapt", cStrErr);
    regs.biltSharpnessS = mxField<uint8>(mxRegs, "biltSharpnessS", cStrErr);
    regs.biltSharpnessR = mxField<uint8>(mxRegs, "biltSharpnessR", cStrErr);
    regs.biltDiag = mxField<uint8>(mxRegs, "biltDiag", cStrErr);
    regs.fastApprox = mxField<bool>(mxRegs, "fastApprox", cStrErr);
    regs.biltBypass = mxField<bool>(mxRegs, "biltBypass", cStrErr);
    regs.mmSide = mxField<uint8>(mxRegs, "mmSide", cStrErr);
    
    Luts luts;
    const mxArray* mxLuts = prhs[6];
    //luts.divCma = mxArrayField<uint8>(mxLuts, "divCma", 128, cStrErr);
    luts.biltSpat = mxArrayField<uint8>(mxLuts, "biltSpat", 64, cStrErr);
    luts.biltSigmoid = mxArrayField<uint8>(mxLuts, "biltSigmoid", 64, cStrErr);
    luts.biltAdaptR = mxArrayField<uint8>(mxLuts, "biltAdaptR", 64, cStrErr);

    if (M != regs.imgVsize || N != regs.imgHsize)
        mexErrMsgIdAndTxt(cStrErr, "Dimmenstions of CMA do not agree with ImgVsize and/or ImgHsize");

    // create output matrix
    plhs[0] = mxCreateNumericArray(nDimCma, dimCma, mxUINT8_CLASS, mxREAL); // accumulator
    Image3D<uint8> outCma((uint8*)mxGetData(plhs[0]), M, N, K);

    // create output IR
    plhs[1] = mxCreateNumericMatrix(M, N, mxUINT16_CLASS, mxREAL);
    Image<uint16> outIR((uint16*)mxGetData(plhs[1]), M, N);
    
    plhs[2] = mxCreateNumericMatrix(M, N, mxUINT8_CLASS, mxREAL);
    Image<uint8> outFlags((uint8*)mxGetData(plhs[2]), M, N);

    plhs[3] = mxCreateNumericMatrix(2, nXY, mxINT16_CLASS, mxREAL);
    Point* mxOutXY = (Point*)mxGetData(plhs[3]);

    // create smooth decision applied for every pixel
    plhs[4] = mxCreateNumericMatrix(M, N, mxUINT8_CLASS, mxREAL);
    Image<uint8> pxSmoothType((uint8*)mxGetData(plhs[4]), M, N);

    MexStruct mxsWin;
    plhs[6] = mxsWin.mxStruct();

    WindowOut winOut;
    winOut.xy.set((Point*)mxsWin.add<int16>("xy", 9 * 2, nXY), 9, nXY);
    winOut.ir.set(mxsWin.add<uint16>("ir", 9, nXY), 9, nXY);
    winOut.irSort.set(mxsWin.add<uint16>("irSort", 10, nXY), 10, nXY);
    winOut.wr.set(mxsWin.add<uint16>("wr", 9, nXY), 9, nXY);
    winOut.ws.set(mxsWin.add<uint16>("ws", 3, nXY), 3, nXY);
    winOut.w.set(mxsWin.add<uint16>("w", 9, nXY), 9, nXY);
    winOut.rowPtrs = (RowPtr*)mxsWin.add<uint8>("rowPtrs", 3, nXY);

    MexStruct mxStats;
    plhs[5] = mxStats.mxStruct();
    Image<uint32> outTimestamps(mxStats.add<uint32>("timestamps", M, N), M, N);

    Stats stats;
    smooth(cma, IR, flags, timestamps, xy, nXY, outCma, outIR, outFlags, outTimestamps, mxOutXY, pxSmoothType, regs, luts, stats, winOut);

    mxStats.add("nNonRefsPixels", stats.nNonRefsPixels);
    mxStats.add("maxChunkFifoSize", stats.maxChunkFifoSize);
    mxStats.add("minPixelMainLobe", stats.minPixelMainLobe);
    mxStats.add("maxPixelSideLobe", stats.maxPixelSideLobe);
    mxStats.add("pixelSideLobeExceeded", stats.pixelSideLobeExceeded);
    mxStats.add("n12NeighborMiss", stats.n12NeighborMiss);

}
