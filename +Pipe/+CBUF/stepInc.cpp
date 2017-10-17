

#include "mex.h"
#include <algorithm>
#include <cmath>
typedef unsigned long ulong;
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    const mxArray*& dataP= prhs[0];
    double* dt = reinterpret_cast<double*>(mxGetData(prhs[1]));
    double* yi = reinterpret_cast<double*>(mxGetData(dataP));
	ulong n = mxGetNumberOfElements(dataP);
	plhs[0] = mxCreateNumericArray_730(mxGetNumberOfDimensions_730(dataP), mxGetDimensions_730(dataP), mxDOUBLE_CLASS, mxREAL);
  	double* yo = mxGetPr(plhs[0]);
    yo[0]=yi[0];
    for(int i=1;i!=n;++i)
    {
        double d = yi[i]-yo[i-1];
        d = std::max(std::min(d,dt[i]),-dt[i]);
            
         yo[i]=yo[i-1]+d;
        
        
    }
       
}