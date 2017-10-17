#include <stdio.h>

#include "../mex/auGeneral.h"

const char* cStrErr = "cmaNorm:nrhs";

struct Point {
    int16 x() const { return p[0]; }
    int16 y() const { return p[1]; }

    int16& x() { return p[0]; }
    int16& y() { return p[1]; }

    int16 p[2];

    int16 operator[] (int i) const { return p[i]; }
    int16& operator[] (int i) { return p[i]; }

    Point() {}
    Point(int a) { p[0] = p[1] = a; }
    Point(int _x, int _y) { p[0] = _x;  p[1] = _y; }
};

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    if (nrhs != 4) // check for proper number of arguments
        mexErrMsgIdAndTxt(cStrErr, "4 input parameters are required:\n"
            "  (1) CmaA: matrix K x M x N of uint8,\n"
            "  (2) CmaC: matrix K x M x N of uint8,\n"
            "  (3) XY: matrix 2 x n of int16,\n"
            "  (4) Luts: struct of LUTs\n"
        );

    if (nlhs != 1)
        mexErrMsgIdAndTxt(cStrErr, "1 output is required.");

    const mxArray *mxCmaA = prhs[0];
    mwSize nDimCmaA = mxGetNumberOfDimensions(mxCmaA);
    const mwSize* dimCmaA = mxGetDimensions(mxCmaA);
    if (!(nDimCmaA == 1 || nDimCmaA == 2 || nDimCmaA == 3) || !mxIsUint8(mxCmaA))
        mexErrMsgIdAndTxt(cStrErr, "1st parameter (CMA A) must be a matrix K x M x N of uint8");

    const int K = int(dimCmaA[0]);
    const int M = (nDimCmaA < 2) ? 1 : int(dimCmaA[1]);
    const int N = (nDimCmaA < 3) ? 1 : int(dimCmaA[2]);

    const mxArray *mxCmaC = prhs[1];
    mwSize nDimCmaC = mxGetNumberOfDimensions(mxCmaC);
    const mwSize* dimCmaC = mxGetDimensions(mxCmaC);
    if (!(nDimCmaC == 1 || nDimCmaC == 2 || nDimCmaC == 3) || !mxIsUint8(mxCmaC))
        mexErrMsgIdAndTxt(cStrErr, "2nd parameter (CMA C) must be a matrix K x M x N of uint8");

    if (K != int(dimCmaC[0]) || M != int((nDimCmaC < 2) ? 1 : int(dimCmaC[1])) || N != int((nDimCmaC < 3) ? 1 : int(dimCmaC[2])))
        mexErrMsgIdAndTxt(cStrErr, "Dimmenstions of  CmaA and CmaC must agree");

    Image3D<uint8> cmaA((uint8*)mxGetData(mxCmaA), M, N, K);
    Image3D<uint8> cmaC((uint8*)mxGetData(mxCmaC), M, N, K);

    const mxArray *mxXY = prhs[2];
    if (int(mxGetM(mxXY)) != 2 || !mxIsInt16(mxXY))
        mexErrMsgIdAndTxt(cStrErr, "3rd parameter (XY) must be a matrix 2 x n of int16.");
    const Point* xy = (Point*)mxGetData(mxXY);
    const int nXY = int(mxGetN(mxXY));

    const mxArray* mxLuts = prhs[3];
    // divCma: 7bit -> 8bit
    const uint8* divCma = mxArrayField<uint8>(mxLuts, "divCma", 32, cStrErr);

    // create output matrix
    plhs[0] = mxCreateNumericArray(nDimCmaA, dimCmaA, mxUINT8_CLASS, mxREAL); // accumulator
    Image3D<uint8> outCma((uint8*)mxGetData(plhs[0]), M, N, K);

    for (int i = 0; i != nXY; ++i) {
        Point p = xy[i];

        const uint8* a = cmaA(p.y(), p.x());
        const uint8* c = cmaC(p.y(), p.x());
        uint8* C = outCma(p.y(), p.x());

        for (int k = 0; k != K; ++k)
            C[k] = min(a[k] * divCma[c[k]], 127);
    }
}
