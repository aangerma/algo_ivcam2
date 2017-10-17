#include "mex.h"
#include <algorithm>
#include <cmath>
typedef unsigned long ulong;
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    double* yi = reinterpret_cast<double*>(mxGetData(prhs[0]));
    double* dt = reinterpret_cast<double*>(mxGetData(prhs[1]));
	ulong n = mxGetNumberOfElements(prhs[0]);
	
    plhs[0] = mxCreateNumericMatrix(1, n, mxDOUBLE_CLASS, mxREAL);
	double* yo = mxGetPr(plhs[0]);

	ulong i1 = n;
	ulong i0 = 0;
	for (int i=i0; i != i1; ++i)
	{
		if (std::isnan(dt[i]) || std::isinf(dt[i]))
			continue;
		double dsti = i+dt[i];
		ulong dsti0 = ulong(std::floor(dsti));

		if (dsti0  > n - 2)
			continue;
		ulong dsti1 = dsti0+1;

		double w0 = dsti - dsti0;
		double w1 = 1 - w0;

		yo[dsti0] += w1*yi[i];
		yo[dsti1] += w0*yi[i];
	}
}