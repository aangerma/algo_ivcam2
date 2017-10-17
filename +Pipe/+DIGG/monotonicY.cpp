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
    if (nrhs != 2) // check for proper number of arguments
        mexErrMsgIdAndTxt(cStrErr, "2 input parameters are required:\n"
            "  (1) XY: matrix 2 x n of int16,\n"
            "  (2) scandir: 1xn of logical\n"
        );

    if (nlhs != 1)
        mexErrMsgIdAndTxt(cStrErr, "1 output is required.");

    const mxArray *mxXY = prhs[0];
    if (int(mxGetM(mxXY)) != 2 || !mxIsInt16(mxXY))
        mexErrMsgIdAndTxt(cStrErr, "1st parameter (XY) must be a matrix 2 x n of int16.");
    const Point* xy = (Point*)mxGetData(mxXY);
    const int nXY = int(mxGetN(mxXY));

    const mxArray *mxScandir = prhs[1];
    if (mxGetM(mxScandir)*mxGetN(mxScandir) != nXY || !mxIsLogical(mxScandir))
        mexErrMsgIdAndTxt(cStrErr, "2nd parameter (scandir must be a matrix 1 x n of logical.");
    const bool* scandir = (const bool*)mxGetData(mxScandir);

    // create output matrix
    plhs[0] = mxCreateNumericMatrix(2, nXY, mxINT16_CLASS, mxREAL);
    Point* outXY = (Point*)mxGetData(plhs[0]);

    for (int i = 0; i != nXY; ++i) {
        Point p = xy[i];
        outXY[i] = p;
        if (i == 0)
            continue;

        const int16 yPrev = outXY[i - 1].y();
        if (scandir[i]) {
            if (p.y() < yPrev)
                outXY[i].y() = yPrev;
        }
        else {
            if (p.y() > yPrev)
                outXY[i].y() = yPrev;
        }
    }
}
