#include "mex.h"   //Matlab env
#include <cstdint> //types
#include <future>  //std::async
#include <vector>

template <class T>
        void dec2bin_thread(uint8_t nbits,int i0, int i1, const T* v, unsigned short* mxout)
{
    for (int i = i0; i != i1; ++i)
    {
        for (uint8_t j = 0; j != nbits; ++j)
        {
            mxout[nbits - j - 1 + i*nbits] = v[i] & (T(1) << j) ? '1' : '0';
        }
    }
}



template <class T>
        void threadRun(unsigned int nvals, uint8_t nbits, const T* v, unsigned short* mxout)
{
    const int nWorkers = std::min(nvals, std::thread::hardware_concurrency());
    std::vector<std::future<void>> thrd(nWorkers);
    for (int w = 0; w != nWorkers; ++w)
    {
        const int i0 = nvals * w / nWorkers;
        const int i1 = nvals * (w + 1) / nWorkers;
        thrd[w] = std::async(std::launch::async, dec2bin_thread<T>, nbits, i0, i1, v, mxout);
    }
    for (int w = 0; w != nWorkers; ++w)
    {
        thrd[w].get();
    }
}



void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    unsigned int nvals = int(mxGetNumberOfElements(prhs[0]));
    mxClassID c =  mxGetClassID(prhs[0]);

    switch(c)
    {
        case mxCHAR_CLASS: case mxINT8_CLASS: case mxUINT8_CLASS:
        {
            uint8_t nbits = (nrhs == 2) ? uint8_t(*mxGetPr(prhs[1])) : 8;
            
            const uint8_t* v = static_cast<const uint8_t*>(mxGetData(prhs[0]));
            plhs[0] = mxCreateNumericMatrix(nbits, nvals, mxCHAR_CLASS, mxREAL);
            unsigned short* mxout = static_cast<unsigned short*>(mxGetData(plhs[0]));
            threadRun<uint8_t>(nvals, nbits, v, mxout);
            break;
        }
        case mxINT16_CLASS: case mxUINT16_CLASS:
        {
            uint8_t nbits = (nrhs == 2) ? uint8_t(*mxGetPr(prhs[1])) : 16;
            const uint16_t* v = static_cast<const uint16_t*>(mxGetData(prhs[0]));
            plhs[0] = mxCreateNumericMatrix(nbits, nvals, mxCHAR_CLASS, mxREAL);
            unsigned short* mxout = static_cast<unsigned short*>(mxGetData(plhs[0]));
            threadRun<uint16_t>(nvals, nbits, v, mxout);
            break;
        }
        case mxSINGLE_CLASS: case mxINT32_CLASS: case mxUINT32_CLASS:
        {
            uint8_t nbits = (nrhs == 2) ? uint8_t(*mxGetPr(prhs[1])) : 32;
            const uint32_t* v = static_cast<const uint32_t*>(mxGetData(prhs[0]));
            plhs[0] = mxCreateNumericMatrix(nbits, nvals, mxCHAR_CLASS, mxREAL);
            unsigned short* mxout = static_cast<unsigned short*>(mxGetData(plhs[0]));
            threadRun<uint32_t>(nvals, nbits, v, mxout);
            break;
        }
        case mxDOUBLE_CLASS: case mxINT64_CLASS: case mxUINT64_CLASS:
        {
            uint8_t nbits = (nrhs == 2) ? uint8_t(*mxGetPr(prhs[1])) : 64;
            const uint64_t* v = static_cast<const uint64_t*>(mxGetData(prhs[0]));
            plhs[0] = mxCreateNumericMatrix(nbits, nvals, mxCHAR_CLASS, mxREAL);
            unsigned short* mxout = static_cast<unsigned short*>(mxGetData(plhs[0]));
            threadRun<uint64_t>(nvals, nbits, v, mxout);
            break;
        }
        default: mexErrMsgTxt("Unknown input type");
    }
    
    
}


