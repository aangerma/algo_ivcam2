#define N_BITS 20
#define N_MNTS 12
#define N_EXPT 7



#include "fpN.h"
typedef cynw_cm_float<N_EXPT, N_MNTS, CYNW_NATIVE_ACCURACY, CYNW_NEAREST, 1> FP20;
//typedef cynw_cm_float<N_EXPT, N_MNTS> FP20;












void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{

	if (nrhs < 2)
		mexErrMsgTxt("1");
	if (mxGetClassID(prhs[0]) != mxCHAR_CLASS)
		mexErrMsgTxt("first input sould be op string");
	char buff[256];
	mxGetString(prhs[0], buff, 256);
	if (strcmp(buff, "to")==0)
		switch_toSingle<FP20>(nlhs, plhs, nrhs, prhs);
	else if (strcmp(buff, "from")==0)
		switch_toFPN<FP20>(nlhs, plhs, nrhs, prhs);
	else if (strcmp(buff, "dot") == 0)
		switch_dot<FP20>(nlhs, plhs, nrhs, prhs);
    else if (strcmp(buff, "mul") == 0)
        switch_mul<FP20>(nlhs, plhs, nrhs, prhs);
	else if (strcmp(buff, "plus") == 0)
		switch_plus<FP20>(nlhs, plhs, nrhs, prhs);
	else if (strcmp(buff, "min") == 0)
		switch_min<FP20>(nlhs, plhs, nrhs, prhs);
	else if (strcmp(buff, "max") == 0)
		switch_max<FP20>(nlhs, plhs, nrhs, prhs);

    else
		mexErrMsgTxt("unknonwn op code");


	

}

