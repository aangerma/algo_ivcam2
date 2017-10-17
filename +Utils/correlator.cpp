//#include "mex.h"   //Matlab env
#include "../+Pipe/mex/auGeneral.h"
#include <vector>
#include <future>  //std::async
//#include <numeric> //std::inner_product

typedef unsigned char uint8;
typedef unsigned char byte;
typedef unsigned short uint16;
typedef unsigned int uint32;
typedef char int8;
typedef short int16;
typedef int int32;

// -------------------------------------------------------------------------------------------------------
// convert c type to mex enum type
// -------------------------------------------------------------------------------------------------------

/*
template<class T>
class mxType {
public:
    static mxClassID classID();
};

#define MX_TYPE(type, cid)  template<>\
class mxType<type> { public: static mxClassID classID() { return cid; } };

MX_TYPE(bool, mxLOGICAL_CLASS)
MX_TYPE(int8, mxINT8_CLASS)
MX_TYPE(uint8, mxUINT8_CLASS)
MX_TYPE(int16, mxINT16_CLASS)
MX_TYPE(uint16, mxUINT16_CLASS)
MX_TYPE(int32, mxINT32_CLASS)
MX_TYPE(uint32, mxUINT32_CLASS)
MX_TYPE(float, mxSINGLE_CLASS)
MX_TYPE(double, mxDOUBLE_CLASS)
*/

/*-------------------------------------------------------------------------------------------------------*/
//calc cyclic correlation between two vectors of type TX and TT
/*-------------------------------------------------------------------------------------------------------*/
template<class TX,class TT,class TOut>
void calcCorr(const TX* inX, const TT* inT, int K, TOut* out)
{
	/* correlation
	inX - input data
	inT - input template, double copy in memory (inT = [T T]
	K   - length of data/template/out 
	*/

    const TX* xEnd = inX + K;
    for (int i = 0; i != K; ++i)
    {
        const TT* t = inT + K - i;
        TOut res = 0;
        for (const TX* x = inX; x != xEnd; ++x, ++t)
            res += TOut(*x) * TOut(*t);
        out[i] = res;
        //out[i] = std::inner_product(inX, inX + K, inT + i, TOut(0));
    }
}

template<class TX, class TT, class TOut>
void calcCorrPeakOnly(const TX* inX, const TT* inT, int K, TOut* out, int peakCenter, int peakRange)
{
	/* correlationover range function
	inX - input data
	inT - input template, double copy in memory (inT = [T T]
	K   - data/template size
	out - out loc, size peakRange*2+1 
	peakCenter - index around it to preform the correlation (Imax in doc)
	peakRange - range of the correlation (R in doc, RegsFineCorRange)

	*/

    const int lenCorr = peakRange * 2 + 1;

    const TX* xEnd = inX + K;

    for (int c = 0; c != lenCorr; ++c) {
        int ct = peakCenter - peakRange + c;

        // make sure 0 <= ct < K, replace with bitmask when switching to power 3 codes 
        if (ct < 0) ct += K;
        else if (ct >= K) ct -= K;

        const TT* t = inT + K - ct;

        TOut res = 0;
        for (const TX* x = inX; x != xEnd; ++x, ++t)
            res += TOut(*x) * TOut(*t);
        out[c] = res;
    }
}

/*-------------------------------------------------------------------------------------------------------*/
//calc correlation of k1-k0 different vectors with single or multiple template(s)
/*-------------------------------------------------------------------------------------------------------*/
template<class TX, class TT, class TOut>
void calcCorrRange(const TX* inX, const TT* inT, int K, const uint32* inTindex, int nT,
    TOut* out, int i0, int i1, const uint16* peaks, int peakRange)
{
    const int lenCorr = peakRange * 2 + 1;
    for (int i = i0; i != i1; ++i) {
        CHECK(Valid_Template_index, inTindex == 0 || inTindex[i] < nT);
        const TT* T = (inTindex == 0) ? inT : inT + 2*K * int(inTindex[i]);

        if (peaks == 0)
            calcCorr(inX + i*K, T, K, out + i*K); //coarse correlation
        else
            calcCorrPeakOnly(inX + i*K, T, K, out + i*lenCorr, peaks[i], peakRange); //fine correlation
    }
//        calcCorr(inX+ k*ns, inT + (multiTemplate ? k*ns : 0), out + k*ns, ns);
}



/*-------------------------------------------------------------------------------------------------------*/
//calc correlation of K different vectors with single or multiple template(s)
/*-------------------------------------------------------------------------------------------------------*/

template<class TX, class TT, class TOut>
void correlation(const mxArray* mxX, const mxArray* mxT, const mxArray* mxTindex, mxClassID mxTypeOut,
    const uint16* peaks, int peakRange,
    mxArray*& mxOut)
{
    const TX* inX = (const TX*)mxGetData(mxX);
    const TT* inT = (const TT*)mxGetData(mxT);

    const uint32* inTindex = (mxTindex == 0) ? 0 : (const uint32*)mxGetData(mxTindex);

    mwSize nDimX = mxGetNumberOfDimensions(mxX);
    const mwSize* dimX = mxGetDimensions(mxX);
    const int nT = (1 == int(mxGetM(mxT))) ? 1 : int(mxGetN(mxT));
    
    mwSize dimCorr[3];
    for (mwSize i = 0; i != nDimX; ++i)
        dimCorr[i] = dimX[i];
    if (peaks != 0)
        dimCorr[0] = 1 + peakRange * 2;

    mxOut = mxCreateNumericArray(nDimX, dimCorr, mxTypeOut, mxREAL);
    TOut* out = (TOut*)mxGetData(mxOut);

    const int K = int(mxGetM(mxX));
    const int n = (nDimX == 2) ? dimX[1] : dimX[1] * dimX[2];

    const int nWorkers = std::thread::hardware_concurrency();
    std::vector<std::future<void>> thrd(nWorkers);

    TT* extT = new TT[2 * K * nT];
    for (int t = 0; t != nT; ++t) {
        const TT* sT = inT + K * t;
        TT* eT = extT + (2 * K * t);
        for (int i = 0; i != K; ++i)
            eT[i] = eT[i + K] = sT[i];
    }
#ifndef gfdsf


    for (int w = 0; w != nWorkers; ++w)
    {
        const int i0 = n * w / nWorkers;
        const int i1 = n * (w + 1) / nWorkers;

        thrd[w] = std::async(std::launch::async, calcCorrRange<TX, TT, TOut>, inX, extT, K, inTindex, nT, out, i0, i1, peaks, peakRange);
    }

    for (int w = 0; w != nWorkers; ++w)
        thrd[w].get();
#else
calcCorrRange<TX, TT, TOut>(inX, exT, k, inTindex, nT, out, 0, n, peaks, peakRange);
#endif // !_DEBUG
    delete extT;
}


#define corrTypeElseif(typeX, typeT, typeOut) \
else if (cidX == mxType<typeX>::classID() && cidT == mxType<typeT>::classID()) \
    correlation<typeX, typeT, typeOut>(mxX, mxT, mxTindex, mxType<typeOut>::classID(), \
    peaks, peakRange, plhs[0])

/*-------------------------------------------------------------------------------------------------------*/
//main mex function
/*-------------------------------------------------------------------------------------------------------*/
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    //input check
    if (nrhs != 2 && nrhs != 3 && nrhs != 5)
        mexErrMsgIdAndTxt(
        "correlator:nrhs", "2, 3 or 5 input  parameters are required:\n"
        "  (1) X (signal): matrix K x N or K x M x N of bool/uint8/uint16/double\n"
        "  (2) T (template): matrix K x 1 or 1 x K or K x NT of bool/uint8/int8/double\n"
        "     output size is K x N or K x M x N matrix where out[i,j] = SUM_k X[i,j]*T[(i+k)%%K]\n"
        "  [3] Tindex (template index) : matrix 1 x N or M x N of uint8\n"
        "  [4] PC (peak center) : matrix 1 x N or M x N of uint16\n"
        "  [5] PR (peak range) : scalar\n"
        );

    const mxArray* mxX = prhs[0];
    const mxArray* mxT = prhs[1];

    const int K = int(mxGetM(mxX));
    if (!(K == int(mxGetM(mxT)) || (1 == int(mxGetM(mxT)) && K == int(mxGetN(mxT)))))
        mexErrMsgIdAndTxt("correlator:nrhs", "The 2st (Template ) parameter length does not correpsond the 1st parameter size");

    const mwSize nDimX = mxGetNumberOfDimensions(mxX);
    const mwSize* dimX = mxGetDimensions(mxX);
    if (nDimX != 2 && nDimX != 3)
        mexErrMsgIdAndTxt("correlator:nrhs", "The 1st parameter length shold be either K x N or K x M x N");

    mxClassID cidX = mxGetClassID(mxX);
    mxClassID cidT = mxGetClassID(mxT);

    const mxArray* mxTindex = 0;
    if (nrhs >= 3) {
        mxTindex = prhs[2];
        if (nDimX == 3 && int(mxGetM(mxTindex)) != 0) {
            if (dimX[1] != int(mxGetM(mxTindex)) || dimX[2] != int(mxGetN(mxTindex)) || !mxIsUint32(mxTindex))
                mexErrMsgIdAndTxt("correlator:nrhs", "The 3rd parameter (TIndex) shold be either K x N or K x M x N of uint8");
        }
    }

    const uint16* peaks = 0;
    int peakRange = 0;

    if (nrhs == 5) {
        const mxArray *mxPeaks = prhs[3];
        mwSize nDimPeaks = mxGetNumberOfDimensions(mxPeaks);
        const mwSize* dimPeaks = mxGetDimensions(mxPeaks);
		mwSize dimX2 = nDimX==2? 1:dimX[2];
        if (nDimPeaks != 2 || !mxIsUint16(mxPeaks) ||
            !((dimPeaks[0] == 1 && dimX[1] == dimPeaks[1]) || (dimPeaks[0] == dimX[1] && dimPeaks[1] == dimX2)))
            mexErrMsgIdAndTxt("correlator:nrhs", "4th parameter (peak centers) must be a matrix 1 x N or M x N of uint16");
        peaks = (const uint16*)mxGetData(mxPeaks);

        const mxArray* mxPR = prhs[4];
        if (!mxIsNumeric(mxPR))
            mexErrMsgIdAndTxt("correlator:nrhs", "5th parameter (peak range) should be a scalar");
        peakRange = int(mxGetScalar(mxPR));
    }

    //run only on allowed types
    if (0) {} //tidy :-)
        corrTypeElseif(bool, bool, uint32);
        corrTypeElseif(uint8, bool, uint32);
        corrTypeElseif(uint16, bool, uint32);
        corrTypeElseif(uint8, int8, int32);
        corrTypeElseif(uint16, int8, int32);
        corrTypeElseif(uint8, uint8, uint32);
        corrTypeElseif(uint16, uint8, uint32);
        corrTypeElseif(bool, double, double);
        corrTypeElseif(double, bool, double);
        corrTypeElseif(double, int8, double);
        corrTypeElseif(uint8, double, double);
        corrTypeElseif(double, double, double);
    else
        mexErrMsgIdAndTxt("correlation:nrhs", "Illigal input type(s) 1st param type:%s, 2nd param type:%s", mxGetClassName(mxX), mxGetClassName(mxT));

}

