#include "../mex/auGeneral.h"
#include <cstring>

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  
    const uint16* p = (const uint16*)mxGetData(prhs[0]);
    const uint16* ninv = (const uint16*)mxGetData(prhs[1]);

    const int m = int(mxGetM(prhs[0]));
    const int n = int(mxGetN(prhs[0]));

    if (mxGetM(prhs[1])!=1 || mxGetN(prhs[1])!=n)
        mexErrMsgIdAndTxt("circSort:input","bad input");
	mwSize d[2];
	d[0] = m;
	d[1] = n;
    plhs[0]= mxCreateNumericArray(2, d, mxUINT16_CLASS, mxREAL);
    uint16* out = ( uint16*)mxGetData(plhs[0]);

	uint16* p_ = new uint16[m * 2];
    
    for(int i=0;i!=n;++i)
    {
        std::memcpy(p_     ,p+i*m  ,m*2);
        std::memcpy(p_+m   ,p+i*m  ,m*2);
        std::memcpy(out+i*m,p_+ninv[i]%m,m*2); //c[i]%m so we won't get overflow
    }
	delete[] p_;


}

