#include "mex.h"
#include <cmath>
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	double* data = mxGetPr(prhs[0]);
	double* delays = mxGetPr(prhs[1]);
	double* attenuation = mxGetPr(prhs[2]);
    
    
    int datalen = int(mxGetNumberOfElements(prhs[0]));
    int ndelays = int(mxGetNumberOfElements(prhs[1]));

	plhs[0] = mxCreateDoubleMatrix(1, datalen,  mxREAL);
	double* out = mxGetPr(plhs[0]);

    for (int i = 0; i != ndelays; ++i)
	{
        if(std::isinf(delays[i]))
            continue;
        
		int d = int(delays[i]);
		for (int j = 0; j != datalen-d; ++j)
		{
			out[j + d] += data[j]*attenuation[i];
		}
	}

}