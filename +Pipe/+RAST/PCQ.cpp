#include <stdio.h>

#include "../mex/auGeneral.h"

#include <string.h>

const char* cStrErr = "PCQ:nrhs";

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


struct Regs {
    int imgHsize;
    int imgVsize;

    int sampleRate;
    int codeLength;

    int chunkExp;
    int extraResExp;

    int skipOnTxModeChange;

    int chunkRate = 1;

    bool sideLobeDir;
    bool rangeFinder;
    bool irDiscardsidelobes;
};

struct Stats {
    int maxPixelFifoSize = 0;
    int maxChunkFifoSize = 0;
    int minPixelMainLobe = 1 << 24;
    int maxPixelMainLobe = 0;
    double maxPixelSideLobe = 0;
    bool pixelSideLobeExceeded = false;
    bool consecutiveChunksFail = false;
    uint32 nConsecutiveChunksFails = 0;
    uint32 idConsecutiveChunksFail = 0;
    Point pConsecutiveChunksFail = 0;
};

const int cChunkExp = 6;
const int cChunkSize = 1 << cChunkExp;

struct Chunk {
    uint8 samples[cChunkSize];
    Point xy;
    uint16 ir;
    int16 nest;
    int16 tOffset = 0; // offset within template
    uint8 flags = 255;
    uint8 used = 0;
    uint32 timestamp = 0;
    uint32 id;
    bool codeStart;
};

struct PxInfo {
    int idxExtStart = 0;
    int idxExtEnd = 0;
    int idxStart = 0;
    int idxEnd = 0;
    uint16 nest;
    uint8 flags = 0;
    Point xy;
};

struct OutCounters {
    int nChunks = 0;
    int nChunkQuads = 0;
    int nPxInfos = 0;

    int maxChunks = 0;
    int maxChunkQuads = 0;
    int maxPxInfos = 0;
};

struct ValidFlag {
    ValidFlag() { valid[0] = valid[1] = valid[2]= valid[3] = 0; }
    bool valid[4]; // = { 0, 0, 0, 0 };
};

struct QuadInd {
    QuadInd() { index[0] = index[1] = index[2] = index[3] = -1; }
    int32 index[4];
};

struct FlowData {
    ValidFlag* valids = 0;
    PxInfo* pxInfos = 0;
    QuadInd* quadIndices = 0;
    int16* pxTotalChunks = 0;
    int16* pxMainChunks = 0;

    ~FlowData() {
        delete valids;
        delete pxInfos;
        delete quadIndices;
        delete pxTotalChunks;
        delete pxMainChunks;
    }
};

template <class T, int Size>
class Buffer {
public:
    Buffer() : m_pushIndex(0)  {
        size_t nBytes = sizeof(T)* Size;
        memset(m_buf, 0, nBytes);
    }

    int push() {
        const int index = m_pushIndex;
        ++m_pushIndex;
        if (m_pushIndex == Size)
            m_pushIndex = 0;
        return index;
    }

    T& get(int index) {
        CHECK(ValidBufferIndex, 0 <= index && index < Size);
        return m_buf[index];
    }
    const T& get(int index) const {
        CHECK(ValidBufferIndex, 0 <= index && index < Size);
        return m_buf[index];
    }

    T& operator[](int i) { return get(i); }
    const T& operator[](int i) const { return get(i); }

    int getNextPushIndex() const { return m_pushIndex; }
    static int next(int i) { return i == Size - 1 ? 0 : i + 1; }

    static bool between(int iStart, int i, int iEnd) {
        if (iStart < iEnd)
            return iStart <= i && i < iEnd;
        else
            return iStart <= i || i < iEnd; // eq to !(iEnd <= i && i < iStart);
    }

    static int mod(int i) {
        if (i < 0)
            return i + Size;
        else if (i >= Size)
            return i - Size;
        else
            return i;
    }

private:
    T m_buf[Size];
    int m_pushIndex;
};

inline
void copyChunk(const uint8* src, uint8* dst)
{
    for (int i = 0; i != cChunkSize; ++i)
        dst[i] = src[i];
}

void pixelate(const uint8* S, const Point* xy, const uint16* IR, const uint16* nest, const uint8* flags, int nChunks,
    OutCounters& outCounters, Chunk* outChunks, const FlowData& flowData, const Regs& regs, Stats& stats)
{
    typedef Buffer<Chunk, 320> ChunkFifo;
    ChunkFifo chunkFifo;

    typedef FIFO<PxInfo, 5> PxFifo; // up to 32 pixels - 30 in ASIC 
    PxFifo pxFifo;

    bool eof = false;

    const int cChunkSize = 1 << regs.chunkExp;

    // [1] input to the chunk-pixel fifos
    const int cLenCodeData = regs.sampleRate * regs.codeLength;
    const int cCodeChunks = ((cLenCodeData - 1) >> regs.chunkExp) + 1;
    const int cMaxPxChunks = 32;

    //XY xy(xySource, regs.xyT * regs.SampleRate);
    Point p0 = Point(-16384, -2048); //xy[0];
    Point pLast = p0;
    Point pPrev = p0;

    //int16 yCurr = p0.y();

    int16 tOffset = 0;
    bool codeStartReceived = false;

    int idxFirstChunk = -1;
    int lenCurrPxCode = -1;
    int nCurrPxChunks = -1;

    uint16 currNest = 0;

    bool prevRoi = false;
    bool prevInRoi = false;
    bool toEmptyPxFifo = false;

    // [2] the chunk-pixel fifos to the scanline fifo
    PxInfo pxCurr; // empty pixel when (idxStart == idxEnd)
    
    int iClock = 0; // used to align input chunk rate, regs.symbolRate == 1 is no delays
    for (int i = 0; true; ++i) { // index of input chunks 

       /////////////////////////////////////////////
       // [1] Writer
       // get 4 chunks from the chunk-pixel buffer and add to the scanline fifo

       const bool doneCurrent = (pxCurr.idxExtStart == pxCurr.idxExtEnd);

       if (eof && doneCurrent && pxFifo.empty())
           break; // stop processing chunks

       const int txMode = pxFifo.empty() ? 0 : pixelFlagsTxRxMode(pxFifo.getPopValue().flags);

       if (doneCurrent && !pxFifo.empty() && (eof || toEmptyPxFifo || regs.rangeFinder || pxFifo.size() > 2 * (1 + txMode))) {
           pxCurr = pxFifo.pop();
       }

       for (int k = 0; k != 4; ++k) {
           // pop when chunks of at least two pixels are available
           if (pxCurr.idxExtStart == pxCurr.idxExtEnd)
               break; // nothing to write for the pixel

           // write one chunk to scanline
           const int idxChunk = pxCurr.idxExtStart;
           pxCurr.idxExtStart = ChunkFifo::next(pxCurr.idxExtStart);

           Chunk ch = chunkFifo[idxChunk];
           ++chunkFifo[idxChunk].used; // stat only

           //if (pixelFlagsTxRxMode(pxCurr.flags) == ch.flags)
           {
               const bool consChunk = (pxCurr.idxExtStart == pxCurr.idxExtEnd || ch.id + 1 == chunkFifo[pxCurr.idxExtStart].id);
               //CHECK(ConsecutiveChunk, consChunk);
               if (!consChunk) {
                   if (!stats.consecutiveChunksFail) {
                       stats.pConsecutiveChunksFail = pxCurr.xy;
                       stats.idConsecutiveChunksFail = ch.id;
                   }
                   stats.consecutiveChunksFail = true;
                   stats.nConsecutiveChunksFails++;
               }

               if (k != 0) { // align to ASIC
                   int16 outChunkOffset = outChunks[outCounters.nChunks-1].tOffset;
                   outChunkOffset += cChunkSize;
                   if (outChunkOffset >= cLenCodeData)
                       outChunkOffset -= cLenCodeData;
                   ch.tOffset = outChunkOffset;
               }

               //CHECK(CloseChunk, abs(ch.xy.x() - pxCurr.xy.x()) <= 2 && abs(ch.xy.y() - pxCurr.xy.y()) <= 2 * (1 + txMode));
               ch.xy = pxCurr.xy;
               ch.nest = pxCurr.nest;
               ch.timestamp = i * regs.chunkRate + iClock;

               if (regs.irDiscardsidelobes && !ChunkFifo::between(pxCurr.idxStart, idxChunk, pxCurr.idxEnd))
                   ch.ir = 0; // don't use ir outisde the main lobe

               if (outCounters.nChunks == outCounters.maxChunks)
                   mexErrMsgIdAndTxt(cStrErr, "The maximal number of output chunks exceeded.\n"
                       "Possible cause: sidelobes are too large.\n"
                       "Bad configuration: Large vertical resolution together with large code length");

               outChunks[outCounters.nChunks] = ch;
               outChunks[outCounters.nChunks].flags = pxCurr.flags;

               if (outCounters.nChunkQuads == outCounters.maxChunkQuads)
                   mexErrMsgIdAndTxt(cStrErr, "The maximal number of output quads exceeded.\nPossible cause: sidelobes are too large.");

               flowData.valids[outCounters.nChunkQuads].valid[k] = true;
               flowData.quadIndices[outCounters.nChunkQuads].index[k] = outCounters.nChunks;

               ++outCounters.nChunks;
           }
       }

       if (flowData.valids[outCounters.nChunkQuads].valid[0] == true)
           ++outCounters.nChunkQuads;

       /////////////////////////////////////////////
       // [2] Analyzer
       // add chunk to the chunk-pixel fifos

       if (i >= nChunks) {
           if (!eof) {
               CHECK(PCQ_input_roi_eof_missing, false);
               eof = true;
           }
           continue;
       }

       ++iClock;
       if (iClock == regs.chunkRate)
           iClock = 0;
       else {
           --i; // do not process input chunk
           continue;
       }

       const bool codeStart = ((flags[i] & cFlagsCodeStartMask) != 0);
       const bool scanDir = ((flags[i] & cFlagsScanDirMask) != 0);
       const bool roi = ((flags[i] & cFlagsRoiMask) != 0);
       const uint8 txRxMode = flagsTxRxMode(flags[i]);

       if (roi != prevRoi) {
           if (!roi)
               eof = true;
       }
       if (eof && !prevRoi)
           continue; // all the chunks are ignored by Analyzer 

       currNest = nest[i];

       bool firstCodeStart = false;
       if (codeStart) {
           tOffset = 0;
           if (!codeStartReceived) {
               codeStartReceived = true;
               firstCodeStart = true;
           }
       }

       int16 chunkOffset = tOffset;
       if (codeStartReceived)
           tOffset += cChunkSize;
       if (tOffset >= cLenCodeData)
           tOffset -= cLenCodeData;

       if (eof) { // align to ASIC
           chunkOffset -= cChunkSize;
           if (chunkOffset < 0)
               chunkOffset += cLenCodeData;
       }
       
       if (!codeStartReceived ) //|| firstCodeStart)
           continue; // align to ASIC

       //const bool ldOn = ((flags[i] & cFlagsLdOnMask) != 0);
       Point pChunk = xy[i];
       const int16 cMaxSidelobeY = regs.rangeFinder ? 0 : 2 + 2 * txRxMode;
       const int16 cMaxSidelobeX = regs.rangeFinder ? 4 : 6 + 8 * txRxMode;
       const bool inRoi = (-cMaxSidelobeY <= pChunk.y() && pChunk.y() <= regs.imgVsize + cMaxSidelobeY &&
           -cMaxSidelobeX <= pChunk.x() && pChunk.x() <= regs.imgHsize*4 + cMaxSidelobeX);
       if (inRoi) {
           const int iPxChunk = chunkFifo.push();
           Chunk& chunk = chunkFifo.get(iPxChunk);

           copyChunk(&S[i << regs.chunkExp], &chunk.samples[0]); // copy fast
           chunk.ir = IR[i];
           chunk.xy.x() = (xy[i].x()+2)>>2; // for validation only
           chunk.xy.y() = xy[i].y(); // for validation only
           chunk.tOffset = chunkOffset; // chunk template offset
           chunk.used = 0;
           chunk.flags = txRxMode;
           chunk.id = i;
           chunk.codeStart = codeStart;

           const int16 x = pChunk.x();
           const int16 y = pChunk.y();

           if (prevInRoi == false) { // initialize on ld_on raise
               idxFirstChunk = iPxChunk;
               lenCurrPxCode = 0;
               nCurrPxChunks = 0;
           }

		

           lenCurrPxCode += cChunkSize;

		   //2017-06-26 OHAD FIX
		   //
		   if (regs.rangeFinder)
		   {
			   nCurrPxChunks = iPxChunk - idxFirstChunk;
			   if (nCurrPxChunks < 0)
				   nCurrPxChunks += 320;
			   
		   }
		   else
			nCurrPxChunks += 1;


		   
		   
		   //CHECK(CurrPxChunks, nCurrPxChunks <= cMaxPxChunks);
           if (y != pPrev.y() || (regs.rangeFinder && x != pPrev.x()) || nCurrPxChunks == cMaxPxChunks) { // new pixel
               Point pPixel;
               pPixel.x() = (p0.x() + pLast.x() + 4) >> (regs.extraResExp + 1);
               pPixel.y() = pPrev.y();

           
			   bool inImage = pPixel.x() >= 0 && pPixel.x() < regs.imgHsize && pPixel.y() >= 0 && pPixel.y() < regs.imgVsize &&    idxFirstChunk != iPxChunk;

		   
			   if (inImage) // no chunks yet (prevInRoi == true)
               {
                   PxInfo pxInfo;


                   pxInfo.idxStart = idxFirstChunk;
                   pxInfo.idxEnd = iPxChunk; // chunk iPxChunk belongs to the next pixel

                   pxInfo.xy = pPixel;
                   pxInfo.nest = currNest;
                   pxInfo.flags = (flags[i] >> 2) & 7; // copy scan_dir and tx_mode from the current chuck

                   const int nExtraChunks = regs.rangeFinder ? 0 : max(0, cCodeChunks - nCurrPxChunks);
                   const int smallSideLobe = nExtraChunks >> 1; // div by 2
                   const int bigSideLobe = nExtraChunks - smallSideLobe;
                   const bool dir = (regs.sideLobeDir ^ scanDir);
                   const int extraStart = dir ? bigSideLobe : smallSideLobe;
                   const int extraEnd = dir ? smallSideLobe : bigSideLobe;
                   pxInfo.idxExtStart = ChunkFifo::mod(pxInfo.idxStart - extraStart);
                   pxInfo.idxExtEnd = ChunkFifo::mod(pxInfo.idxEnd + extraEnd);

                   pxFifo.push(pxInfo);
                   REQUIRE(ASIC_PxFIFO_size_limit_is_30, pxFifo.size() <= 30);
                   toEmptyPxFifo = false;

                   if (outCounters.nPxInfos == outCounters.maxPxInfos)
                       mexErrMsgIdAndTxt(cStrErr, "The maximal number of pixel infos exceeded.");
                   flowData.pxInfos[outCounters.nPxInfos] = pxInfo;
                   flowData.pxMainChunks[outCounters.nPxInfos] = nCurrPxChunks;
                   flowData.pxTotalChunks[outCounters.nPxInfos] = nCurrPxChunks + nExtraChunks;
                   ++outCounters.nPxInfos;

                   stats.maxPixelFifoSize = max(stats.maxPixelFifoSize, pxFifo.size());
                   stats.maxPixelSideLobe = max(stats.maxPixelSideLobe, double(cLenCodeData - lenCurrPxCode) / double(lenCurrPxCode));
                   stats.minPixelMainLobe = min(stats.minPixelMainLobe, nCurrPxChunks);
                   stats.maxPixelMainLobe = max(stats.maxPixelMainLobe, nCurrPxChunks);
               }
               else
                   toEmptyPxFifo = true;

               idxFirstChunk = iPxChunk;


			   if (regs.rangeFinder && !inImage) {
				   const int16 firstOffset = chunkFifo[idxFirstChunk].tOffset;
				   const int16 posInQuad = (firstOffset & 0xFF) >> cChunkExp; // modulo 256, and divide by 64
				   const int16 chunksToMove = (4 - posInQuad) & 3; // modulo 4
				   idxFirstChunk += chunksToMove;
				   //if chunksToMove!=0 we are checking chunks that are not yet written to chunk fifo
				   // - check 4 back
					CHECK(RangeFinderFirstChunk, (chunkFifo[max(0,idxFirstChunk-4)].tOffset & 0xFF) == 0);

			   }


               p0 = pChunk;
               pPrev = Point(x, y);
               lenCurrPxCode = 0;
               nCurrPxChunks = 0;
           } // new pixel

           pLast = pChunk;

       } // ld_on

       if (!inRoi && prevInRoi) // fall
           toEmptyPxFifo = false;
       prevInRoi = inRoi;

       prevRoi = roi;

   }
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    Stats stats;

    if (nrhs != 6) // check for proper number of arguments
        mexErrMsgIdAndTxt(cStrErr, "6 input parameters are required:\n"
            "  (1) S: matrix 1 x N of logical or uint8,\n"
            "  (2) XY: matrix 2 x n of int16,\n"
            "  (3) IR: matrix 1 x n of uint16,\n"
            "  (4) NEST: matrix 1 x n of uint16,\n"
            "  (5) flags: matrix 1 x n of uint8,\n"
            "  (6) Regs: struct of registers\n"
        );

    if (nlhs != 7)
        mexErrMsgIdAndTxt(cStrErr, "5 (chunks, xy, IR, nest, offset, flags, timestamps, valids, stats) outputs are required\n");

    const mxArray *mxS = prhs[0];
    const int N = int(mxGetN(mxS));
    if (int(mxGetM(mxS)) != 1 || !(mxIsLogical(mxS) || mxIsUint8(mxS)))
        mexErrMsgIdAndTxt(cStrErr, "1st parameter (S) must be a matrix 1 x N of logical or uint8.");
    const uint8* S = (uint8*)mxGetData(mxS);

    const mxArray *mxXY = prhs[1];
    const int m = int(mxGetM(mxXY));
    const int nChunks = int(mxGetN(mxXY));
    if (int(mxGetM(mxXY)) != 2 || !mxIsInt16(mxXY))
        mexErrMsgIdAndTxt(cStrErr, "2nd parameter (XY) must be a matrix 2 x n of int16.");
    const Point* xy = (Point*)mxGetData(mxXY);

    const mxArray *mxIR = prhs[2];
    const int nIR = int(mxGetN(mxIR));
    if (int(mxGetM(mxIR)) != 1 || !mxIsUint16(mxIR))
        mexErrMsgIdAndTxt(cStrErr, "3rd parameter (IR) must be a matrix 1 x n of uint16.");
    const uint16* IR = (uint16*)mxGetData(mxIR);

    const mxArray *mxNest = prhs[3];
    const int nNest = int(mxGetN(mxNest));
    if (int(mxGetM(mxNest)) != 1 || !mxIsUint16(mxNest))
        mexErrMsgIdAndTxt(cStrErr, "4th parameter (NEST) must be a matrix 1 x n of uint16.");
    const uint16* nest = (uint16*)mxGetData(mxNest);

    const mxArray *mxFlags = prhs[4];
    const int nFlags = int(mxGetN(mxFlags));
    if (int(mxGetM(mxFlags)) != 1 || !mxIsUint8(mxFlags))
        mexErrMsgIdAndTxt(cStrErr, "5th parameter (flags) must be a matrix 1 x n of uint8.");
    const uint8* flags = (uint8*)mxGetData(mxFlags);

    if (nIR != nChunks || nNest != nChunks || nFlags != nChunks)
        mexErrMsgIdAndTxt(cStrErr, "3rd, 4th and 5th parameters (IR, NEST, flags) must be of the length of 2nd parameter (XY)");

    if (nChunks * 64 != N)
        mexErrMsgIdAndTxt(cStrErr, "The number of chunks based on the 2nd parameter (XY) and the size of the 1st parameter (fast) mismatch.");

    const mxArray* mxRegs = prhs[5];
    Regs regs;
    regs.imgVsize = mxField<int>(mxRegs, "imgVsize", cStrErr);
    regs.imgHsize = mxField<int>(mxRegs, "imgHsize", cStrErr);
    regs.sampleRate = mxField<int>(mxRegs, "sampleRate", cStrErr);
    regs.codeLength = mxField<int>(mxRegs, "codeLength", cStrErr);
    regs.chunkExp = mxField<int>(mxRegs, "chunkExp", cStrErr);
    regs.extraResExp = mxField<int>(mxRegs, "extraResExp", cStrErr);
    regs.sideLobeDir = mxField<bool>(mxRegs, "sideLobeDir", cStrErr);
    regs.rangeFinder = mxField<bool>(mxRegs, "rangeFinder", cStrErr);
    regs.skipOnTxModeChange = mxField<int>(mxRegs, "skipOnTxModeChange", cStrErr);
    regs.chunkRate = mxField<int>(mxRegs, "chunkRate", cStrErr);
    regs.irDiscardsidelobes = mxField<bool>(mxRegs, "irDiscardsidelobes", cStrErr);

    REQUIRE(ValidChunkRate, 0 < regs.chunkRate && regs.chunkRate <= 4);

    const int lenCodeData = regs.sampleRate * regs.codeLength;
    
    OutCounters outCounters;

    uint8 maxTxRx = 0;
    for (int i = 0; i != nFlags; ++i) {
        const uint8 txRxMode = flagsTxRxMode(flags[i]);
        maxTxRx = max(txRxMode, maxTxRx);
    }
    maxTxRx = min(maxTxRx, uint8(2)); // only 0, 1 and 2 are possible
    const int cTxRxFactors[3] = { 1, 2, 4 };
    const int cTxRxFactor = cTxRxFactors[maxTxRx];

    outCounters.maxChunks = (nChunks + 1) * 4 * cTxRxFactor; // 4 is for sidelobes, cTxRxFactor is for slowest multi-focal mode
    Chunk* chunks = new Chunk[outCounters.maxChunks];

    outCounters.maxChunkQuads = (nChunks + 1) * cTxRxFactor;
    outCounters.maxPxInfos = nChunks + 1;
    
    FlowData flowData;
    flowData.valids = new ValidFlag[outCounters.maxChunkQuads];
    flowData.quadIndices = new QuadInd[outCounters.maxChunkQuads];
    flowData.pxInfos = new PxInfo[outCounters.maxPxInfos];
    flowData.pxTotalChunks = new int16[outCounters.maxPxInfos];
    flowData.pxMainChunks = new int16[outCounters.maxPxInfos];

    pixelate(S, xy, IR, nest, flags, nChunks, outCounters, chunks, flowData, regs, stats);
    const int nOutChunks = outCounters.nChunks;
    const int nOutValidQuads = outCounters.nChunkQuads;
    const int nPxInfos = outCounters.nPxInfos;
    
    // create output matrices

    plhs[0] = mxCreateNumericMatrix(cChunkSize, nOutChunks, mxUINT8_CLASS, mxREAL);
    uint8* outFast = (uint8*)mxGetData(plhs[0]);

    plhs[1] = mxCreateNumericMatrix(2, nOutChunks, mxINT16_CLASS, mxREAL);
    Point* outXY = (Point*)mxGetData(plhs[1]);

    plhs[2] = mxCreateNumericMatrix(1, nOutChunks, mxUINT16_CLASS, mxREAL);
    uint16* outIR = (uint16*)mxGetData(plhs[2]);

    plhs[3] = mxCreateNumericMatrix(1, nOutChunks, mxUINT16_CLASS, mxREAL);
    uint16* outNest = (uint16*)mxGetData(plhs[3]);

    plhs[4] = mxCreateNumericMatrix(1, nOutChunks, mxINT16_CLASS, mxREAL);
    int16* outOffset = (int16*)mxGetData(plhs[4]);

    plhs[5] = mxCreateNumericMatrix(1, nOutChunks, mxUINT8_CLASS, mxREAL);
    uint8* outFlags = (uint8*)mxGetData(plhs[5]);

    MexStruct mxStats;
    plhs[6] = mxStats.mxStruct();
    mxStats.add("maxPixelFifoSize", stats.maxPixelFifoSize);
    mxStats.add("maxChunkFifoSize", stats.maxChunkFifoSize);
    mxStats.add("minPixelMainLobe", stats.minPixelMainLobe);
    mxStats.add("maxPixelMainLobe", stats.maxPixelMainLobe);
    mxStats.add("maxPixelSideLobe", stats.maxPixelSideLobe);
    mxStats.add("pixelSideLobeExceeded", stats.pixelSideLobeExceeded);
    mxStats.add("consecutiveChunksFail", stats.consecutiveChunksFail);
    mxStats.add("nConsecutiveChunksFails", stats.nConsecutiveChunksFails);
    mxStats.add("idConsecutiveChunksFail", stats.idConsecutiveChunksFail);
    int16* outPConsecutiveChunksFail = mxStats.add<int16>("pConsecutiveChunksFail", 1, 2);
    outPConsecutiveChunksFail[0] = stats.pConsecutiveChunksFail.x();
    outPConsecutiveChunksFail[1] = stats.pConsecutiveChunksFail.y();

    Image<int16> outPxInfos(mxStats.add<int16>("pxInfo", 8, nPxInfos), 8, nPxInfos);
    int16* outPxTotalChunks = mxStats.add<int16>("pxTotalChunks", 1, nPxInfos);
    int16* outPxMainChunks = mxStats.add<int16>("pxMainChunks", 1, nPxInfos);
    uint32* outIDs = mxStats.add<uint32>("ids", 1, nOutChunks);
    int32* outQIndices = mxStats.add<int32>("validIndices", 4, nOutValidQuads);
    ValidFlag* outValids = (ValidFlag*)mxStats.add<uint8>("valids", 4, nOutValidQuads);
    uint32* outTimestamp = mxStats.add<uint32>("timestamps", 1, nOutChunks);
        
    // copy to output

    for (int i = 0; i != nOutChunks; ++i) {
        copyChunk(&chunks[i].samples[0], &outFast[i*cChunkSize]);
        outXY[i] = chunks[i].xy;
        outIR[i] = chunks[i].ir;
        outNest[i] = chunks[i].nest;
        outOffset[i] = chunks[i].tOffset;
        outFlags[i] = chunks[i].flags;
        outTimestamp[i] = chunks[i].timestamp;
        outIDs[i] = chunks[i].id;
    }

    for (int i = 0; i != nOutValidQuads; ++i) {
        outValids[i] = flowData.valids[i];
        for (int k = 0; k != 4; ++k)
            outQIndices[i * 4 + k] = flowData.quadIndices[i].index[k];
    }

    for (int i = 0; i != nPxInfos; ++i) {
        const PxInfo& pxInfo = flowData.pxInfos[i];
        outPxInfos(0, i) = pxInfo.xy.x();
        outPxInfos(1, i) = pxInfo.xy.y();
        outPxInfos(2, i) = pxInfo.flags;
        outPxInfos(3, i) = pxInfo.nest;
        outPxInfos(4, i) = pxInfo.idxStart;
        outPxInfos(5, i) = (pxInfo.idxEnd-1<0) ? 0 : pxInfo.idxEnd - 1;
        outPxInfos(6, i) = pxInfo.idxExtStart;
        outPxInfos(7, i) = (pxInfo.idxExtEnd - 1<0) ? 0 : pxInfo.idxExtEnd - 1;

        outPxTotalChunks[i] = flowData.pxTotalChunks[i];
        outPxMainChunks[i] = flowData.pxMainChunks[i];
    }

    delete chunks;
}
