#include "mex.h"
#include <cmath>

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	const double* data = static_cast<const double*>(mxGetData(prhs[0]));
	const double* delays = static_cast<const double*>(mxGetData(prhs[1]));
	const double* attenuation = static_cast<const double*>(mxGetData(prhs[2]));
    
    
    int datalen = int(mxGetNumberOfElements(prhs[0]));
    int ndelays = int(mxGetNumberOfElements(prhs[1]));

	plhs[0] = mxCreateDoubleMatrix(1, datalen,  mxREAL);
	double* out = static_cast<double*>(mxGetData(plhs[0]));

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