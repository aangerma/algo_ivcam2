#include "mex.h"   //Matlab env
#include <cstdint>
#include <future>  //std::async
#include <vector>


void dec2bin_range(int nbits,int i0, int i1, const uint64_t* v, unsigned short* mxout)
{
	for (int i = i0; i != i1; ++i)
	{
		for (uint8_t j = 0; j != nbits; ++j)
		{
			mxout[nbits - j - 1 + i*nbits] = v[i] & (uint64_t(1) << j) ? '1' : '0';
		}

	}
}


void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	unsigned int nvals = int(mxGetNumberOfElements(prhs[0]));
	mxClassID c =  mxGetClassID(prhs[0]);
	int csize;
	switch(c)
	{
        case mxLOGICAL_CLASS,mxCHAR_CLASS,mxINT8_CLASS ,mxUINT8_CLASS :    csize=8;   break;
        case mxINT16_CLASS,mxUINT16_CLASS:    csize=16;   break;
        case mxSINGLE_CLASS,mxINT32_CLASS,mxUINT32_CLASS:    csize=32;   break;
        case mxDOUBLE_CLASS,mxINT64_CLASS,mxUINT64_CLASS:    csize=64;   break;
        default: mexErrMsgTxt("Unknown input type");
	}
	int n = nvals*csize;
	if(n%64!=0)
		mexErrMsgTxt("number of input bytes should divide by 8");

	const uint64_t* v = static_cast<const uint64_t*>(mxGetData(prhs[0]));

	
	unsigned int nbits = nrhs == 2 ? int(*mxGetPr(prhs[1])) : 16;
	plhs[0] = mxCreateNumericMatrix(nbits, nvals, mxCHAR_CLASS, mxREAL);
	unsigned short* mxout = static_cast<unsigned short*>(mxGetData(plhs[0]));


	const int nWorkers = std::min(nvals, std::thread::hardware_concurrency());

	std::vector<std::future<void>> thrd(nWorkers);

	for (int w = 0; w != nWorkers; ++w)
	{
		const int i0 = nvals * w / nWorkers;
		const int i1 = nvals * (w + 1) / nWorkers;
		thrd[w] = std::async(std::launch::async, dec2bin_range, nbits, i0, i1, v, mxout);
	}
	for (int w = 0; w != nWorkers; ++w)
		thrd[w].get();

	//  for(int i=0;i!=nvals;++i)
	//  {
		  //for (uint8_t j = 0; j != nbits; ++j)
		  //{
		  //	mxout[nbits - j - 1 + i*nbits] =  v[i] & (uint64_t(1) << j) ? '1' : '0';
		  //}
	//          
	//  }

}



