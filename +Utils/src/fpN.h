#pragma once

#include "systemc.h"            	// SystemC definitions
#include "cynw_cm_float.h"
#include "mex.h"   //Matlab env
//#include <thread>
#include <vector>
#include <algorithm>

template<class FPN>
std::vector<FPN> mxarr2fpN(const mxArray* data)
{
	const size_t n = mxGetNumberOfElements(data);
	std::vector<FPN> v(n);
	if (mxGetClassID(data) == mxUINT32_CLASS)
	{

		const uint32_t* raw = static_cast<const uint32_t*>(mxGetData(data));
		for (int i = 0; i != n; ++i)
			v[i].raw_bits(sc_uint<N_BITS>(raw[i]));
	}
	else if (mxGetClassID(data) == mxSINGLE_CLASS)
	{
		float* raw = static_cast<float*>(mxGetData(data));
		for (int i = 0; i != n; ++i)
			v[i] = FPN(raw[i]);
	}
	else
		mexErrMsgTxt("Input type should be UINT32/SINGLE");
	return v;

}

template<class FPN>
void setOut(const std::vector<FPN>& o, size_t ndims, const size_t* dims, mxArray* plhs[], bool isSingle)
{
	size_t n = 1;
	for (int i = 0; i != ndims; ++i)
		n *= dims[i];

	if (isSingle)
	{
		plhs[0] = mxCreateNumericArray_730(ndims, dims, mxSINGLE_CLASS, mxREAL);
		float* outp = static_cast<float*>(mxGetData(plhs[0]));
		for (int i = 0; i != n; ++i)
			outp[i] = o[i].to_float();
	}
	else {
		plhs[0] = mxCreateNumericArray_730(ndims, dims, mxUINT32_CLASS, mxREAL);
		uint32_t* outp = static_cast<uint32_t*>(mxGetData(plhs[0]));
		for (int i = 0; i != n; ++i)
			outp[i] = uint32_t(o[i].to_rawBits().to_uint64());
	}

}
template<class FPN>
void setOut(const std::vector<FPN>& o, int r, int c, mxArray* plhs[], bool isSingle)
{
	size_t ndims = 2;
	size_t dims[] = { size_t(r),size_t(c) };
	setOut(o, ndims, dims, plhs, isSingle);
	//int n = r*c;
	//if (isSingle)//output type same as input
	//{
	//	plhs[0] = mxCreateNumericMatrix(r, c, mxSINGLE_CLASS, mxREAL);
	//	float* outp = static_cast<float*>(mxGetData(plhs[0]));
	//	for (int i = 0; i != n; ++i)
	//		outp[i] = o[i].to_float();
	//}
	//else {
	//	plhs[0] = mxCreateNumericMatrix(r, c, mxUINT32_CLASS, mxREAL);
	//	uint32_t* outp = static_cast<uint32_t*>(mxGetData(plhs[0]));
	//	for (int i = 0; i != n; ++i)
	//		outp[i] = uint32_t(o[i].to_rawBits().to_uint64());
	//}

}

template<class FPN>
void calc_dot(const FPN* a, const FPN* b, FPN* o, int ca, int sx, int cb, int i0, int i1)
{

	for (int i = i0; i != i1; ++i)
	{
		int x = i / ca;
		int y = i % ca;
		for (int j = 0; j != sx; ++j)
			o[i] += a[y*sx + j] * b[x*sx + j];
	}

}


template<class FPN>
void switch_dot(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	const mxArray*& dataA = prhs[1];
	const mxArray*& dataB = prhs[2];

	//First input should be transpoesed
	size_t rA = mxGetM(dataA);
	size_t cA = mxGetN(dataA);

	size_t rB = mxGetM(dataB);
	size_t cB = mxGetN(dataB);
	if (rA != rB)
		mexErrMsgTxt("Matrix dimentions must agree(first input is transposed)");

	int n = cA*cB;
	std::vector<FPN> a = mxarr2fpN<FPN>(dataA);
	std::vector<FPN> b = mxarr2fpN<FPN>(dataB);
	std::vector<FPN> o(n, 0);
	calc_dot(&a[0], &b[0], &o[0], cA, rA, cB, 0, n);

	//const int nWorkers = std::min(unsigned int(n), std::thread::hardware_concurrency());
	//std::vector<std::future<void>> thrd(nWorkers);


	//for (int w = 0; w != nWorkers; ++w)
	//{
	//	const int i0 = n * w / nWorkers;
	//	const int i1 = n * (w + 1) / nWorkers;

	//	thrd[w] = std::async(std::launch::async, calc_dot, &a[0], &b[0], &o[0], rA, cA, cB, i0, i1);
	//}

	//for (int w = 0; w != nWorkers; ++w)
	//	thrd[w].get();

	setOut(o, cA, cB, plhs, mxIsSingle(prhs[1]));




}

template<class FPN>
void switch_plus(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	const mxArray*& dataA = prhs[1];
	const mxArray*& dataB = prhs[2];


	size_t r = mxGetM(dataA);
	size_t c = mxGetN(dataA);

	size_t rB = mxGetM(dataB);
	size_t cB = mxGetN(dataB);
	int n = r*c;
	std::vector<FPN> a = mxarr2fpN<FPN>(dataA);
	std::vector<FPN> b = mxarr2fpN<FPN>(dataB);
	std::vector<FPN> o(n);

	if (r == rB && cB == 1)
	{

		for (int i = 0; i != r*c; ++i)
			o[i] = (a[i] + b[i%r]);

	}
	else if (r == rB && c == cB)
	{
		for (int i = 0; i != r*c; ++i)
			o[i] = (a[i] + b[i]);

	}
	else
		mexErrMsgTxt("Matrix dimentions must agree");

	setOut(o, r, c, plhs, mxIsSingle(prhs[1]));




}


template<class FPN>
void switch_mul(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	const mxArray*& dataA = prhs[1];
	const mxArray*& dataB = prhs[2];


	size_t r = mxGetM(dataA);
	size_t c = mxGetN(dataA);

	size_t rB = mxGetM(dataB);
	size_t cB = mxGetN(dataB);
	if (r != rB || c != cB)
		mexErrMsgTxt("Matrix dimentions must agree");

	int n = r*c;
	std::vector<FPN> a = mxarr2fpN<FPN>(dataA);
	std::vector<FPN> b = mxarr2fpN<FPN>(dataB);
	std::vector<FPN> o(n);
	for (int i = 0; i != n; ++i)
		o[i] = (a[i] * b[i]);

	setOut(o, r, c, plhs, mxIsSingle(prhs[1]));



}

template<class FPN>
void switch_max(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	const mxArray*& dataA = prhs[1];
	const mxArray*& dataB = prhs[2];


	size_t n = mxGetNumberOfElements(dataA);
	std::vector<FPN> v = mxarr2fpN<FPN>(dataA);

	FPN mv = FPN(*static_cast<float*>(mxGetData(dataB)));
	std::vector<FPN> o(n);
	for (int i = 0; i != n; ++i)
		o[i] = std::max(v[i], mv);


	setOut(o, mxGetNumberOfDimensions_730(dataA), mxGetDimensions_730(dataA), plhs, mxIsSingle(dataA));



}

template<class FPN>
void switch_min(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	const mxArray*& dataA = prhs[1];
	const mxArray*& dataB = prhs[2];


	size_t n = mxGetNumberOfElements(dataA);
	std::vector<FPN> v = mxarr2fpN<FPN>(dataA);

	FPN mv = FPN(*static_cast<float*>(mxGetData(dataB)));
	std::vector<FPN> o(n);
	for (int i = 0; i != n; ++i)
		o[i] = std::min(v[i], mv);

	setOut(o, mxGetNumberOfDimensions_730(dataA), mxGetDimensions_730(dataA), plhs, mxIsSingle(dataA));



}




template<class FPN>
void switch_toFPN(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	const mxArray*& dataP = prhs[1];

	if (!mxIsSingle(dataP))
		mexErrMsgTxt("Input data should be single");

	std::vector<FPN> o = mxarr2fpN<FPN>(dataP);

	setOut(o, mxGetNumberOfDimensions_730(dataP), mxGetDimensions_730(dataP), plhs, false);

	//plhs[0] = mxCreateNumericArray_730(mxGetNumberOfDimensions_730(dataP), mxGetDimensions_730(dataP), mxUINT32_CLASS, mxREAL);

	//uint32_t* outp = static_cast<uint32_t*>(mxGetData(plhs[0]));

	//for (int i = 0; i != v.size(); ++i)

	//	outp[i] = uint32_t(v[i].to_rawBits().to_uint64());







}

template<class FPN>
void switch_toSingle(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	const mxArray*& dataP = prhs[1];
	if (!mxIsUint32(dataP))
		mexErrMsgTxt("Input data should be uint32");



	//const int nWorkers = std::min(n, std::thread::hardware_concurrency());
	//std::vector<std::future<void>> thrd(nWorkers);
	//for (int w = 0; w != nWorkers; ++w)
	//{
	//	const int i0 = n * w / nWorkers;
	//	const int i1 = n * (w + 1) / nWorkers;
	//	thrd[w] = std::async(std::launch::async, thrd_toSingle, v, i0, i1, outp);
	//}
	//for (int w = 0; w != nWorkers; ++w)
	//	thrd[w].get();



	std::vector<FPN> o = mxarr2fpN<FPN>(prhs[1]);

	setOut(o, mxGetNumberOfDimensions_730(dataP), mxGetDimensions_730(dataP), plhs, true);

	//plhs[0] = mxCreateNumericArray_730(mxGetNumberOfDimensions_730(dataP), mxGetDimensions_730(dataP), mxSINGLE_CLASS, mxREAL);
	//float* outp = static_cast<float*>(mxGetData(plhs[0]));
	//for (int i = 0; i != v.size(); ++i)
	//	outp[i] = v[i].to_float();


}


