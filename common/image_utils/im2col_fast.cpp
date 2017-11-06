/**************************************************************************
*
* File name: im2colstep.c
*
* Ron Rubinstein
* Computer Science Department
* Technion, Haifa 32000 Israel
* ronrubin@cs
*
* Last Updated: 31.8.2009
*
*************************************************************************/


#include "mex.h"
#include <string.h>


/* Input Arguments */

//#define X_IN     prhs[0]
//#define SZ_IN  prhs[1]
//#define S_IN   prhs[2]


inline
int mxClassSize(mxClassID classID)
{
    switch (classID) {
    case mxCHAR_CLASS:
    case mxINT8_CLASS:
    case mxUINT8_CLASS:
        return 1;

    case mxINT16_CLASS:
    case mxUINT16_CLASS:
        return 2;

    case mxSINGLE_CLASS:
    case mxINT32_CLASS:
    case mxUINT32_CLASS:
        return 4;

    case mxINT64_CLASS:
    case mxUINT64_CLASS:
    case mxDOUBLE_CLASS:
        return 8;

    default:
        return 0;
    }
}

void mexFunction(int nlhs, mxArray *plhs[],
	int nrhs, const mxArray*prhs[])

{
	/* Check for proper number of arguments */
    if (nrhs != 2)
		mexErrMsgTxt("Invalid number of input arguments.");
	else if (nlhs > 1)
		mexErrMsgTxt("Too many output arguments.");


	/* Check the the input dimensions */

    const mxArray* X_IN = prhs[0];
	const int ndims = mxGetNumberOfDimensions(X_IN);

    if (!mxIsNumeric(X_IN) || mxIsComplex(X_IN) || ndims>3)
		mexErrMsgTxt("X should be an image.");

    const mxArray* SZ_IN = prhs[1];
    if (!mxIsDouble(SZ_IN) || mxIsComplex(SZ_IN) || mxGetNumberOfDimensions(SZ_IN) > 2 || mxGetM(SZ_IN)*mxGetN(SZ_IN) != ndims) 
		mexErrMsgTxt("Invalid block size.");

	/* Get parameters */
	const double* s = mxGetPr(SZ_IN);
    int sz[2] = { int(s[0]), int(s[1]) };
    if (s[0]<1 || s[1]<1)
		mexErrMsgTxt("Invalid block size.");

    int n[2];
	n[0] = (mxGetDimensions(X_IN))[0];
	n[1] = (mxGetDimensions(X_IN))[1];

	if (n[0]<sz[0] || n[1]<sz[1])
		mexErrMsgTxt("Block size too large.");

    const mxClassID classID = mxGetClassID(X_IN);

	/* Create a matrix for the return argument */
    plhs[0] = mxCreateNumericMatrix(sz[0] * sz[1], ((n[0] - sz[0]) + 1)*((n[1] - sz[1]) + 1), classID, mxREAL);
    char* b = (char*)mxGetData(plhs[0]);

    const char* x = (char*)mxGetData(X_IN);

    const int classSize = mxClassSize(classID);
    const int blockSize = sz[0] * classSize;
    if (blockSize == 0)
        mexErrMsgTxt("Invalid matrix class.");

	int blocknum = 0;
    /* iterate over all blocks */
    for (int j = 0; j <= n[1] - sz[1]; ++j) {
        for (int i = 0; i <= n[0] - sz[0]; ++i) {
            // copy single block
            for (int k = 0; k < sz[1]; ++k) {
                memcpy(b + (blocknum*sz[0] * sz[1] + k*sz[0])*classSize, x + ((j + k)*n[0] + i)*classSize, blockSize);
            }
            blocknum++;
        }
    }
}

