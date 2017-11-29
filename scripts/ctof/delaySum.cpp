#include "mex.h"
#include <cmath>

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	const float* data = static_cast<const float*>(mxGetData(prhs[0]));
	const float* delays = static_cast<const float*>(mxGetData(prhs[1]));
	const float* attenuation = static_cast<const float*>(mxGetData(prhs[2]));
    
    
    int datalen = int(mxGetNumberOfElements(prhs[0]));
    int ndelays = int(mxGetNumberOfElements(prhs[1]));

	plhs[0] = mxCreateDoubleMatrix(1, datalen,  mxREAL);
	float* out = static_cast<float*>(mxGetData(plhs[0]));

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