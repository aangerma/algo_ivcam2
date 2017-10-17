#include <stdio.h>

#include "../+Pipe/mex/auGeneral.h"

const char* cStrErr = "toHex:nrhs";

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

const char toHex[17] = "0123456789ABCDEF";

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    if (nlhs != 1)
        mexErrMsgIdAndTxt(cStrErr, "1 output is required.");

    if (nrhs != 4 && nrhs != 3 && nrhs != 2) // check for proper number of arguments
        mexErrMsgIdAndTxt(cStrErr, "2 or 3 input parameters are required:\n"
            "  (1) A: matrix M x N or K x M x N,\n"
            "  (2) nNibbles: scalar\n"
            "  or\n"
            "  (1) A: matrix M x N or K x M x N of uint8,\n"
            "  (2) XY: matrix 2 x n of int16,\n"
            "  (3) nNibbles: scalar\n"
            "  or\n"
            "  (1) A: matrix K x M x N (not of uint8),\n"
            "  (2) XY: matrix 2 x n of int16,\n"
            "  (3) nNibbles per element: scalar\n"
            "  (4) nElements: scalar\n"
        );

    uint8* zeros = 0;

    if (nrhs >= 3) {

        const mxArray* mxNN = prhs[2];
        if (!mxIsNumeric(mxNN))
            mexErrMsgIdAndTxt(cStrErr, "3rd parameter (number of nibbles) should be a scalar");
        const int nN = int(mxGetScalar(mxNN));

        const mxArray *mxXY = prhs[1];
        if (int(mxGetM(mxXY)) == 2 && mxIsInt16(mxXY)) {
            const Point* xy = (Point*)mxGetData(mxXY);
            const int nXY = int(mxGetN(mxXY));

            const mxArray *mxA = prhs[0];
            mwSize nDimA = mxGetNumberOfDimensions(mxA);
            const mwSize* dimCma = mxGetDimensions(mxA);
            if (!(nDimA == 2 || nDimA == 3))
                mexErrMsgIdAndTxt(cStrErr, "1st parameter must be a matrix K x M x N");

            if (!(nDimA != 3 || mxIsUint8(mxA) || nrhs == 4))
                mexErrMsgIdAndTxt(cStrErr, "1st parameter must be a matrix K x M x N of uint8 or specify the 4th ");

            const int elemSize = mxClassSize(mxA);
            const int elemNum = (nDimA < 3) ? 1 : int(dimCma[0]); // the number of input elements
            const int objSize = elemNum * elemSize;

            int K = 0; // the number of bytes per element
            int nE = 0; // the number of elements to output
            int Q = 0; // the number of input elements

            if (nrhs == 4) {
                K = elemSize;
                Q = elemNum;
                const mxArray* mxNE = prhs[3];
                if (!mxIsNumeric(mxNE))
                    mexErrMsgIdAndTxt(cStrErr, "4th parameter (number of elements) should be a scalar");
                nE = int(mxGetScalar(mxNE));
            }
            else if (nDimA < 3) {
                Q = 1;
                K = elemSize;
                nE = 1;
            }
            else { // nDimA == 3
                if (mxIsUint8(mxA)) {
                    Q = 1;
                    K = objSize;
                    nE = 1;
                }
                else {
                    Q = elemNum;
                    K = elemSize;
                    nE = elemNum;
                }
            }

            CHECK(ValidObjSize, K*Q == objSize);

            const int M = (nDimA < 3) ? int(dimCma[0]) : int(dimCma[1]);
            const int N = (nDimA < 3) ? int(dimCma[1]) : int(dimCma[2]);

            Image3D<uint8> cma((uint8*)mxGetData(mxA), M, N, objSize);

            // create output matrix
            plhs[0] = mxCreateNumericMatrix(nN*nE, nXY, mxINT8_CLASS, mxREAL);
            Image<char> outHex((char*)mxGetData(plhs[0]), nN*nE, nXY);

            zeros = new uint8[objSize];
            for (int k = 0; k != objSize; ++k)
                zeros[k] = 0;

            for (int i = 0; i != nXY; ++i) {
                Point p = xy[i];
                const uint8* c = (p.x() < 0 || p.y() < 0) ? zeros : cma(p.y(), p.x());

                for (int q = 0; q != Q; ++q) {
                    int j = nN*nE - nN*q - 1; // hex counter
                    for (int k = 0; k != K; ++k) {
                        uint8 v = c[k];

                        outHex(j, i) = toHex[v & 0xF];
                        --j; if (j < 0) break;

                        outHex(j, i) = toHex[v >> 4];
                        --j; if (j < 0) break;
                    }
                    c += K;

                    for (; j >= 0; --j) // complete the required nibble count for element
                        outHex(j, i) = toHex[0];
                }

                // complete the rest of nibbles
                for (int j = nN*(nE - Q) - 1; j >= 0; --j)
                    outHex(j, i) = toHex[0];
            }
        }
        else if (int(mxGetM(mxXY)) == 1 || int(mxGetN(mxXY)) == 1) {
            const int n = int(mxGetN(mxXY)) * int(mxGetM(mxXY));

            int32* ind = 0;
            int32* allocatedIndices = 0;
            if (mxIsInt32(mxXY))
                ind = (int32*)mxGetData(mxXY);
            else if (mxIsDouble(mxXY)) {
                allocatedIndices = new int32[n];
                const double* dInd = (double*)mxGetData(mxXY);
                for (int i = 0; i != n; ++i)
                    ind[i] = int32(dInd[i]);
                ind = allocatedIndices;
            }
            else
                mexErrMsgIdAndTxt(cStrErr, "2nd parameter (XY) must be a vector of double or int32");

            const mxArray *mxA = prhs[0];
            mwSize nDimA = mxGetNumberOfDimensions(mxA);
            const mwSize* dimCma = mxGetDimensions(mxA);
            if (!(nDimA == 2 || nDimA == 1))
                mexErrMsgIdAndTxt(cStrErr, "1st parameter must be a matrix M x N");

            const int K = mxClassSize(mxA);
            const uint8* A = (uint8*)mxGetData(mxA);

            zeros = new uint8[K];
            for (int k = 0; k != K; ++k)
                zeros[k] = 0;

            // create output matrix
            plhs[0] = mxCreateNumericMatrix(nN, n, mxINT8_CLASS, mxREAL);
            Image<char> outHex((char*)mxGetData(plhs[0]), nN, n);

            for (size_t i = 0; i != n; ++i) {
                const int index = ind[i];
                const uint8* c = (index < 0) ? zeros : &A[index*K];

                int j = nN - 1; // hex counter
                for (int k = 0; k != K; ++k) {
                    uint8 v = c[k];

                    outHex(j, i) = toHex[v & 0xF];
                    --j; if (j < 0) break;

                    outHex(j, i) = toHex[v >> 4];
                    --j; if (j < 0) break;
                }

                for (; j >= 0; --j)
                    outHex(j, i) = toHex[0];
            }
            
            delete allocatedIndices;
        }
        else
            mexErrMsgIdAndTxt(cStrErr, "2nd parameter (XY) must be either a matrix 2 x n of int16 or a vector of double or int32");

    }
    else if (nrhs == 2) {
        const mxArray *mxA = prhs[0];
        mwSize nDimA = mxGetNumberOfDimensions(mxA);
        const mwSize* dimCma = mxGetDimensions(mxA);
        if (!(nDimA == 2 || nDimA == 1))
            mexErrMsgIdAndTxt(cStrErr, "1st parameter must be a matrix M x N");

        const int K = mxClassSize(mxA);
        const int M = mxGetM(mxA);
        const int N = mxGetN(mxA);
        const size_t n = M * N;

        const uint8* A = (uint8*)mxGetData(mxA);

        const mxArray* mxNN = prhs[1];
        if (!mxIsNumeric(mxNN))
            mexErrMsgIdAndTxt(cStrErr, "2nd parameter (number of nibbles) should be a scalar");
        const int nN = int(mxGetScalar(mxNN));

        // create output matrix
        plhs[0] = mxCreateNumericMatrix(nN, n, mxINT8_CLASS, mxREAL);
        Image<char> outHex((char*)mxGetData(plhs[0]), nN, n);

        for (size_t i = 0; i != n; ++i) {
            const uint8* c = &A[i*K];

            int j = nN - 1; // hex counter
            for (int k = 0; k != K; ++k) {
                uint8 v = c[k];

                outHex(j, i) = toHex[v & 0xF];
                --j; if (j < 0) break;

                outHex(j, i) = toHex[v >> 4];
                --j; if (j < 0) break;
            }

            for (; j >= 0; --j)
                outHex(j, i) = toHex[0];
        }
    }

    delete zeros;
}
