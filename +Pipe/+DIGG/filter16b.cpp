#include <mex.h>
#include <stdint.h>
#include <inttypes.h>
#include <vector>
#include <algorithm>



inline	int numel(const mxArray* arr)
{
	return int(mxGetN(arr))*int(mxGetM(arr));
}




uint16_t saturate12(int64_t v)
{
	static const int64_t maxval12b = (1 << 12) - 1;
	return uint16_t(std::min(std::max(int64_t(0), v),maxval12b));
}





void mexFunction(int nlhs,  mxArray* plhs[], int nrhs, const mxArray* prhs[])
{
    // input validation
    if(nrhs != 4) {
        mexErrMsgIdAndTxt("MyProg:ConvertString",
                "4 inputs required.");
    }
    if(nlhs != 1) {
        mexErrMsgIdAndTxt("MyProg:ConvertString",
                "One output required.");
    }
    if( !mxIsInt16(prhs[0]))
    {
        mexErrMsgIdAndTxt("MyProg:ConvertString",
                "Input 1 - 'a' must be int16.");
    }
    if( !mxIsInt16(prhs[1]))
    {
        mexErrMsgIdAndTxt("MyProg:ConvertString",
                "Input 2 - 'b' must be int16.");
    }
    if( !mxIsUint16(prhs[2]))
    {
        mexErrMsgIdAndTxt("MyProg:ConvertString",
                "Input 3 - 'vslow' must be uint16.");
    }
    if( !mxIsUint8(prhs[3]))
    {
        mexErrMsgIdAndTxt("MyProg:ConvertString",
                "Input 4 - 'fpShiftBits' must be uint8.");
    }
    
    
    
    // prhs (input):
    //1. numaretor coeffs (b1,b2,b3) of notch filter (3 vals of int64)
    //2. denumaretor coeffs (a2,a3) of notch filter (2 vals of int64)
    //3. slow channel (array of uint 16 - actually uint12...)
    //4. fixedPointScaleFactor (single var - int)
    uint16_t* datain = (uint16_t*)mxGetData(prhs[2]);
    int n = numel(prhs[2]);
    int16_t* a = (int16_t*)mxGetData(prhs[1]);
    int na = numel(prhs[1]);
	int16_t* b = (int16_t*)mxGetData(prhs[0]);
    int nb = numel(prhs[0]);
	uint8_t fixedPointScaleFactor = *(uint8_t*)mxGetData(prhs[3]);
    
    //plhs (output):
    plhs[0]=mxCreateNumericMatrix(n,1,mxUINT16_CLASS,mxREAL);
    uint16_t* out = (uint16_t*)mxGetData(plhs[0]);
    
    
   	uint64_t round_const = 1<<(fixedPointScaleFactor-1); //2^(fixedPointScaleFactor/2)  for rounding of the output y each loop
   
   
    
    //main calc
    for(int i=0 ; i!=n ; ++i)
    {  
        out[i] = 0;
		int64_t out_tmp=0;
        
		for (int j = 0; j != nb; ++j)
        {
			if(i-j<0) // zero pad the input
                break;
            out_tmp += int64_t(datain[i-j]) * int64_t(b[j]);
        }

		for (int j = 0; j != na; ++j)
        {
            if(i-j<0) // zero pad the input
                continue;
			out_tmp -= int64_t(out[i-j]) * int64_t(a[j]);
        }

		out_tmp += round_const;
		out_tmp >>= fixedPointScaleFactor;

		out[i] = saturate12(out_tmp);
    }  
    
}

