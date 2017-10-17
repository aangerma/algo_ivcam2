#include "mex.h"
#include <array>
#include <vector>
#include <stdint.h>




class Container
{
	std::vector<uint64_t> _cma;

	double _x;
	double _y;
	double _i;
	int _d;
public:
	Container(size_t n) :_cma(n, 0), _d(0), _x(0), _y(0), _i(0) {};
	void add2cma(const uint64_t* beg, int offset, size_t len)
	{
		for (int i = 0; i != len; ++i)
		{
			int ind = (offset + i) % _cma.size();
			_cma[ind] = beg[i];

		}
	}
	void add2xyi(int16_t x, int16_t y, uint16_t i)
	{
		_x += x;
		_y += y;
		_i += i;
		++_d;
	}
	void dump(uint8_t* cma, double* xy, double* i)const
	{
		xy[0] = _x / _d;
		xy[1] = _y / _d;
		*i = _i / _d;
		for (int i = 0; i != _cma.size(); ++i)
		{
			for (int j = 0; j != 64; ++j)
				cma[i * 64 + j] = static_cast<uint8_t>((_cma[i] >> j) & 1);
		}
	}

};
const char* cStrErr = "ivsCodechunker:nrhs";
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	if (nrhs != 2)
		mexErrMsgIdAndTxt(cStrErr, "exactly 2 inputs");
	uint16_t* slow = static_cast<uint16_t*>(mxGetData(mxGetField(prhs[0], 0, "slow")));
	uint8_t*  fast = static_cast<uint8_t*>(mxGetData(mxGetField(prhs[0], 0, "fast")));
	uint8_t*  flags = static_cast<uint8_t*>(mxGetData(mxGetField(prhs[0], 0, "flags")));
	int16_t*  xy = static_cast<int16_t*>(mxGetData(mxGetField(prhs[0], 0, "xy")));

	size_t n = mxGetNumberOfElements(mxGetField(prhs[0], 0, "slow"));
	size_t nPackets = int(*mxGetPr(prhs[1]));
	n -= n%nPackets;

	std::vector<uint64_t> fast64(n, 0);
	for (int i = 0; i != n; ++i)
	{

		for (int j = 0; j != 64; ++j)
		{
			fast64[i] += static_cast<uint64_t>(*(fast + i * 64 + j)) << j;
		}
	}
	const uint64_t* fast64p = &fast64[0];



	int offset = 0;
	size_t nData = n / nPackets;
	std::vector<Container> data(nData, Container(nPackets));
	for (int i = 0; i != n; ++i)
	{
		const bool codeStart = (flags[i] >> 1 & uint8_t(1));
		if (offset == nPackets || codeStart)
			offset = 0;

		size_t cindx = i / nPackets;
		data[cindx].add2cma(fast64p + i, offset, nPackets);
		data[cindx].add2xyi(xy[2 * i], xy[2 * i + 1], slow[i]);
		++offset;

	}

	plhs[0] = mxCreateNumericMatrix(nPackets * 64, nData, mxUINT8_CLASS, mxREAL);
	plhs[1] = mxCreateDoubleMatrix(2, nData, mxREAL);
	plhs[2] = mxCreateDoubleMatrix(1, nData, mxREAL);
	uint8_t* outcma = static_cast<uint8_t*>(mxGetData(plhs[0]));
	double* outxy = mxGetPr(plhs[1]);
	double* outi = mxGetPr(plhs[2]);
	for (int i = 0; i != nData; ++i)
		data[i].dump(outcma + i*nPackets * 64, outxy + i * 2, outi + i);



}