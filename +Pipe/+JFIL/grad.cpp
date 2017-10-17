#include "../mex/auGeneral.h"

const char* cStrErr = "NEST:nrhs";

inline int min(int a1, int a2)
{
	return (a1 > a2) ? a2 : a1;
}

inline int max(int a1, int a2)
{
	return (a1 > a2) ? a1 : a2;
}


//----------------------------------------------
// MEX FUNCTION
//----------------------------------------------

//
// gradient_filter - gradient filter
// ------------------------------
//
// Wg = gradient_filter(R,Wc,Thresholds)
//
// Input:
// ------
//  R - input depth image(uint16)
//  Wc - Confidence weight (uint16)
//  Mode - 0-B0, 1-C0
//  Mask - For C0 mode, defines which test to perform
//  Thresholds - thresholds for the gradient [dx,dy,diag,spike,dxc,dyr] (uint16)
//
// Output:
// -------
//  Wg - Gradient weights, 0 or 1. (uint16)
//


void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    if (nrhs != 4) // check for proper number of arguments
        mexErrMsgIdAndTxt(cStrErr, "3 input parameters are required:\n"
            "  (1) Img: matrix m x n of uint16,\n"
            "  (2) ValidMask: matrix 1 x n of uint8,\n"
            "  (3) Regs: struct of registers\n"
        );


    // input image
    const mxArray *mxImg = prhs[0];
    if (!mxIsUint16(mxImg))
        mexErrMsgIdAndTxt(cStrErr, "1st parameter (Depth image) must be a uint16 matrix");
    const uint16* image = (const uint16*) mxGetPr(mxImg);
    const int m = (int)mxGetM(mxImg);
    const int n = (int)mxGetN(mxImg);

    const mxArray *mxWc = prhs[1];
    if (int(mxGetM(mxWc)) != m || int(mxGetN(mxWc)) != n ||
        !(mxIsUint8(mxWc) || mxIsLogical(mxWc)))
        mexErrMsgIdAndTxt(cStrErr, "2nd parameter (Wc) must be a uint8 or ogical matrix of the same as the 1st image.");
    const uint8* Wc = (const uint8*)mxGetPr(mxWc);

    const mxArray *mxMask = prhs[2];
    if (!mxIsNumeric(mxMask)|| !mxIsUint16(mxMask))
        mexErrMsgIdAndTxt(cStrErr, "3rd parameter (Mask) must be a uint16 scalar.");
    const uint16 mask = *(const uint16*) mxGetPr(mxMask);

    const mxArray *mxThr = prhs[3];
    if (int(mxGetM(mxThr)) != 10  || int(mxGetN(mxThr)) != m*n || !mxIsUint16(mxThr))
        mexErrMsgIdAndTxt(cStrErr, "4th parameter (thresholds) must be a uint16 matrix of size 10");
    const uint16* imgThr = (const uint16*) mxGetPr(mxThr);
    
    //output allocation
    plhs[0] = mxCreateNumericMatrix(m, n, mxUINT8_CLASS, mxREAL);
    uint8* output  = (uint8*)mxGetData(plhs[0]);
    
    const int Dmax = (1 << 16) - 1;

	//main functunality
    for (int j=0; j<n; j++)
    {
        for (int i=0; i<m; i++)
        {
			int x0 = image[j*m + i];
            unsigned short w0 = Wc[j*m + i];

            const uint16* thr = &imgThr[(j*m + i) * 10];

            output[j*m +i] = 0;
            
			if (w0) //if the main pixel is legal (Wc = 1)
			{
                int d[9];
                uint8 W[9];

                //take the 3x3 surrounding window Wc 
				W[0] = Wc[max(0,j-1)*m + max(i-1,0)];
				W[1] = Wc[max(0,j-1)*m + i];
				W[2] = Wc[max(0,j-1)*m + min(i+1,m-1)];
            
				W[3] = Wc[j*m + max(i-1,0)];
				W[4] = Wc[j*m + i];
				W[5] = Wc[j*m + min(i+1,m-1)];
            
				W[6] = Wc[min(n-1,j+1)*m + max(i-1,0)];
				W[7] = Wc[min(n-1,j+1)*m + i];
				W[8] = Wc[min(n-1,j+1)*m + min(i+1,m-1)];

				//take the 3x3 (neighbours pixel - main pixel)*Wc of neighbour
				d[0] = image[max(0,j-1)*m + max(i-1,0)];
				d[1] = image[max(0,j-1)*m + i];
				d[2] = image[max(0,j-1)*m + min(i+1,m-1)];
            
				d[3] = image[j*m + max(i-1,0)];
				d[4] = image[j*m + i];
				d[5] = image[j*m + min(i+1,m-1)];
            
				d[6] = image[min(n-1,j+1)*m + max(i-1,0)];
				d[7] = image[min(n-1,j+1)*m + i];
				d[8] = image[min(n-1,j+1)*m + min(i+1,m-1)];
				
                const int D0 = abs(d[0] - x0);
                const int D1 = abs(d[1] - x0);
                const int D2 = abs(d[2] - x0);
                const int D3 = abs(d[3] - x0);
                const int D5 = abs(d[5] - x0);
                const int D6 = abs(d[6] - x0);
                const int D7 = abs(d[7] - x0);
                const int D8 = abs(d[8] - x0);

				//calculate gradient and normalize
                if (mask & ((uint16)1<<0)) // ave dx
                {
                    if ((D3*W[3] + D5*W[5]) > int(thr[0])*(W[3] + W[5]))
                        output[j*m+i] = 1;
                }

                if (mask & ((uint16)1 << 1)) // ave dy
                {
                    if ((D1*W[1] + D7*W[7]) > int(thr[1])*(W[1] + W[7]))
                        output[j*m + i] = 1;
                }

                if (mask & ((uint16)1 << 2)) // ave diag
                {
                    if (((D0*W[0] + D8*W[8]) > int(thr[2])*(W[0] + W[8])) ||
                        ((D2*W[2] + D6*W[6]) > int(thr[2])*(W[2] + W[6])))
                        output[j*m + i] = 1;
                }

                if (mask & ((uint16)1 << 3)) // min dx
                {
                    if ((Dmax - max((Dmax - D3)*W[3], (Dmax - D5)*W[5]))*(W[3] | W[5]) > thr[3])
                        output[j*m + i] = 1;
                }

                if (mask & ((uint16)1 << 4)) // min dy
                {
                   if ((Dmax - max((Dmax - D1)*W[1], (Dmax - D7)*W[7]))*(W[1] | W[7]) > thr[4])
 
                        output[j*m + i] = 1;
                }

                if (mask & ((uint16)1 << 5)) // min diag
                {
                    if ((Dmax - max(max((Dmax - D0)*W[0], (Dmax - D2)*W[2]),max((Dmax - D6)*W[6], (Dmax - D8)*W[8])))*(W[0] | W[2] | W[6] | W[8]) > thr[5])
    
	
	                    output[j*m + i] = 1;
                }

                if (mask & ((uint16)1 << 6)) // max dx
                {
                    if (max(D3*W[3], D5*W[5]) > thr[6])
                        output[j*m + i] = 1;
                }

                if (mask & ((uint16)1 << 7)) // max dy
                {
                    if (max(D1*W[1], D7*W[7]) > thr[7])
                        output[j*m + i] = 1;
                }

                if (mask & ((uint16)1 << 8)) // max diag
                {
                    if (max(max(D0*W[0], D2*W[2]),
                        max(D6*W[6], D8*W[8])) > thr[8])
                        output[j*m + i] = 1;
                }

                if (mask & ((uint16)1 << 9)) // spike
                {
                    int sxwc = -d[4], swc = -W[4]; // Not counting central pixel
                    for (int k=0; k<9; k++)
                    {
                        sxwc += d[k]*W[k];
                        swc += W[k];
                    }

                    int spike  = abs(sxwc - swc*x0);
                    if (spike > swc*thr[9])
                        output[j*m+i] = 1;
                }
			}
        }
    }
}