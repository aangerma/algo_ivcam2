#include <stdio.h>

#include "../mex/auGeneral.h"
#include "../mex/pipeDefinitions.h"

const char* cStrErr = "NEST:nrhs";

struct Regs {
    int NestNumOfSamplesExp;
    int NestLdOnDelay;
};

void computeNest(const uint16* IR, const uint8* flags, int n, uint16* nest, const Regs& regs)
{
    const int nSamples = 1 << regs.NestNumOfSamplesExp;
    
    uint16 nestOut = 0;
    uint32 irAcc = 0;
    uint16 counter = 0;

    int delayCount = 0;
    bool prevLdOn = true;

    for (int i = 0; i != n; ++i) {
        // output first: delay of one chunk is not important
        nest[i] = max(uint16(1), nestOut);

        const bool LdOn = ((flags[i] & cFlagsLdOnMask) != 0);
        const bool LdOnFall = !LdOn && prevLdOn;
        prevLdOn = LdOn;

        if (LdOn)
            continue;

        if (LdOnFall)
            delayCount = regs.NestLdOnDelay;

        if (delayCount != 0)
            --delayCount;
        else {
            irAcc += IR[i];
            ++counter;

            if (counter == nSamples) {
                nestOut = uint16(irAcc >> regs.NestNumOfSamplesExp);
                irAcc = 0;
                counter = 0;
            }
        }
    }
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    if (nrhs != 3) // check for proper number of arguments
        mexErrMsgIdAndTxt(cStrErr, "3 input parameters are required:\n"
            "  (1) IR: matrix 1 x n of logical or uint16,\n"
            "  (2) flags: matrix 1 x n of uint8,\n"
            "  (3) Regs: struct of registers\n"
        );

    if (nlhs != 1)
        mexErrMsgIdAndTxt(cStrErr, "1 [NEST] output is required\n");

    const mxArray *mxIR = prhs[0];
    const int nIR = int(mxGetN(mxIR));
    if (int(mxGetM(mxIR)) != 1 || !mxIsUint16(mxIR))
        mexErrMsgIdAndTxt(cStrErr, "1st parameter (IR) must be a matrix 1 x n of uint16.");
    const uint16* IR = (uint16*)mxGetData(mxIR);

    const mxArray *mxFlags = prhs[1];
    const int nFlags = int(mxGetN(mxFlags));
    if (int(mxGetM(mxFlags)) != 1 || !mxIsUint8(mxFlags))
        mexErrMsgIdAndTxt(cStrErr, "2nd parameter (flags) must be a matrix 1 x n of uint8.");
    const uint8* flags = (uint8*)mxGetData(mxFlags);

    const mxArray* mxRegs = prhs[2];
    Regs regs;
    regs.NestNumOfSamplesExp = mxField<int>(mxRegs, "NestNumOfSamplesExp", cStrErr);
    regs.NestLdOnDelay = mxField<int>(mxRegs, "NestLdOnDelay", cStrErr);
    
    // create output matrices
    plhs[0] = mxCreateNumericMatrix(1, nIR, mxUINT16_CLASS, mxREAL); // chunks
    uint16* outNest = (uint16*)mxGetData(plhs[0]);

    computeNest(IR, flags, nIR, outNest, regs);
}
