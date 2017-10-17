#include "mex.h"
#include <inttypes.h>
#include <math.h>       /* fmod */
#include <future>  //std::async

void threadFun(int i0,int i1,const float* v,int32_t* out)
{
    for(int i=i0;i!=i1;++i)
    {
        float x = v[i];
        float xm2=fmod(x,2);
        out[i]=int32_t(round(x-(xm2==0.5)*0.5+(xm2==1.5)*0.5));
    }
}


void mexFunction(int nlhs,  mxArray* plhs[], int nrhs, const mxArray* prhs[])
{
    float* v = (float*)mxGetData(prhs[0]);
    const size_t n = mxGetNumberOfElements(prhs[0]);
    size_t ndims = mxGetNumberOfDimensions_730(prhs[0]);
    const size_t* dims = mxGetDimensions_730(prhs[0]);
    plhs[0]=mxCreateNumericArray_730(ndims, dims, mxINT32_CLASS, mxREAL);
    int32_t* out = (int32_t*)mxGetData(plhs[0]);
    
    
    const int nWorkers = std::thread::hardware_concurrency();
    std::vector<std::future<void>> thrd(nWorkers);
    
     for (int w = 0; w != nWorkers; ++w)
    {
        const int i0 = n * w / nWorkers;
        const int i1 = n * (w + 1) / nWorkers;

        thrd[w] = std::async(std::launch::async, threadFun, i0, i1, v, out);
    }

    for (int w = 0; w != nWorkers; ++w)
        thrd[w].get();
    /*
    for(int i=0;i!=n;++i)
    {
        float x = v[i];
        float xm2=fmod(x,2);
        out[i]=int32_t(round(x-(xm2==0.5)*0.5+(xm2==1.5)*0.5));
    }
     */
    
}