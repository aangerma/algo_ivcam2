#define N_BITS 32
#define N_MNTS 23
#define N_EXPT 8

#include "fpN.h"
#include      "recip/cynw_cm_float_rcp_E8_M23.h"
#include "sqrt_recip/cynw_cm_float_rsq_E8_M23.h"
typedef cynw_cm_float<N_EXPT, N_MNTS, CYNW_NATIVE_ACCURACY, CYNW_NEAREST, 1> FP32;




void switch_invFP32(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	const mxArray*& dataA = prhs[1];



	size_t n = mxGetNumberOfElements(dataA);
	std::vector<FP32> v = mxarr2fpN<FP32>(dataA);
	FP32 a;
	
	std::vector<FP32> o(n);
	for (int i = 0; i != n; ++i)
	{
		sc_uint< 32 > outraw;
		cynw_cm_float_rcp_E8_M23(v[i].sign, v[i].exp, v[i].man, outraw);
		o[i].raw_bits(outraw);
	}
	
	setOut(o, mxGetNumberOfDimensions_730(dataA), mxGetDimensions_730(dataA), plhs, mxIsSingle(dataA));
}

void switch_invsqrtFP32(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	const mxArray*& dataA = prhs[1];



	size_t n = mxGetNumberOfElements(dataA);
	std::vector<FP32> v = mxarr2fpN<FP32>(dataA);
	FP32 a;
	
	std::vector<FP32> o(n);
	for (int i = 0; i != n; ++i)
	{
		sc_uint< 32 > outraw;
		cynw_cm_float_rsq_E8_M23(v[i].sign, v[i].exp, v[i].man, outraw);
		o[i].raw_bits(outraw);
	}
	
	setOut(o, mxGetNumberOfDimensions_730(dataA), mxGetDimensions_730(dataA), plhs, mxIsSingle(dataA));
}
void switch_sqrtFP32(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	const mxArray*& dataA = prhs[1];



	size_t n = mxGetNumberOfElements(dataA);
	std::vector<FP32> v = mxarr2fpN<FP32>(dataA);

	
	std::vector<FP32> o(n);
	for (int i = 0; i != n; ++i)
	{
		sc_uint< 32 > outraw;
		cynw_cm_float_rsq_E8_M23(v[i].sign, v[i].exp, v[i].man, outraw);
		o[i].raw_bits(outraw);
        cynw_cm_float_rcp_E8_M23(o[i].sign, o[i].exp, o[i].man, outraw);
        o[i].raw_bits(outraw);
		
	}
	
	setOut(o, mxGetNumberOfDimensions_730(dataA), mxGetDimensions_730(dataA), plhs, mxIsSingle(dataA));
}







void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{


	if (nrhs < 2)
		mexErrMsgTxt("1");
	if (mxGetClassID(prhs[0]) != mxCHAR_CLASS)
		mexErrMsgTxt("first input sould be op string");
	char buff[256];
	mxGetString(prhs[0], buff, 256);
	if (strcmp(buff, "to")==0)
		switch_toSingle<FP32>(nlhs, plhs, nrhs, prhs);
	else if (strcmp(buff, "from")==0)
		switch_toFPN<FP32>(nlhs, plhs, nrhs, prhs);
	else if (strcmp(buff, "dot") == 0)
		switch_dot<FP32>(nlhs, plhs, nrhs, prhs);
    else if (strcmp(buff, "mul") == 0)
        switch_mul<FP32>(nlhs, plhs, nrhs, prhs);
	else if (strcmp(buff, "plus") == 0)
		switch_plus<FP32>(nlhs, plhs, nrhs, prhs);
	else if (strcmp(buff, "min") == 0)
		switch_min<FP32>(nlhs, plhs, nrhs, prhs);
	else if (strcmp(buff, "max") == 0)
		switch_max<FP32>(nlhs, plhs, nrhs, prhs);
	else if (strcmp(buff, "inv") == 0)
		switch_invFP32(nlhs, plhs, nrhs, prhs);
	else if (strcmp(buff, "invsqrt") == 0)
		switch_invsqrtFP32(nlhs, plhs, nrhs, prhs);
    	else if (strcmp(buff, "sqrt") == 0)
		switch_sqrtFP32(nlhs, plhs, nrhs, prhs);
    else
		mexErrMsgTxt("unknonwn op code");


	

}

