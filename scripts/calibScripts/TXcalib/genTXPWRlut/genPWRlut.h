#include <stdint.h>
#include <algorithm>//std::max
#include <iostream>//std::cout


#define VERBOSE_OUT
#ifdef VERBOSE_OUT
#include <vector> //debug only
#include <fstream>
#endif





//-----8<-----8<-----8<-----8<-----8<-----8<-----8<-----8<-----8<-----8<-----8<-----8<-----
float algo_convertDealyFromGain(float p)
{
	float tau = -0.000312f*p*p + 0.018293f*p - 5.566810f;
	return tau;
}
//-----8<-----8<-----8<-----8<-----8<-----8<-----8<-----8<-----8<-----8<-----8<-----8<-----

bool bitget(uint32_t v, int n)
{
	bool b = (v >> n)&uint32_t(1);
	return b;
}


struct Dpt
{
	int16_t v[2];
	size_t t[2];
};

Dpt parseVgainTableValue(uint32_t binv)
{
	Dpt dpt;
	if (bitget(binv, 0) == 0)
	{
		dpt.t[0] = ((binv >> 4)&uint32_t(65535));
		dpt.v[0] = int16_t(bitget(binv, 2) * 2 - 1);
		dpt.t[1] = 0;
		dpt.v[1] = 0;
	}
	else
	{
		dpt.t[0] = ((binv >> 4)&uint32_t(255));
		dpt.v[0] = int16_t(bitget(binv, 1) * 2 - 1);
		dpt.t[1] = ((binv >> 12)&uint32_t(255));
		dpt.v[1] = int16_t(bitget(binv, 2) * 2 - 1);


	}
	return dpt;
}

size_t countNticks(uint32_t* vGainTbl, size_t vGainTblSz)
{
	int16_t gainV = 0;
	size_t gainT = 0;

	for (size_t i = 0; i != vGainTblSz; ++i)
	{

		Dpt dpt=parseVgainTableValue(vGainTbl[i]);

		gainT += dpt.t[0];
		gainV += dpt.v[0];
		if (gainV < 0)
			break;
		gainT += dpt.t[1];
		gainV += dpt.v[1];
		if (gainV < 0)
			break;
	}
	return gainT;
}
struct Params
{
	float yfov;
	uint8_t ibias;
	uint8_t modulationRef;
};
void genPWRlut(uint32_t* vGainTbl, size_t vGainTblSz, Params p, float* outputLUT)
{
	static const int lutSize = 65;




	static const float pi = std::acos(0.0f) * 2;
	static const float deg2rad = pi / 180.0f;


	float yfovRADdiv2 = p.yfov * deg2rad / 2;

	

	int16_t gainV = 0;
	size_t gainT = 0;

	float g2i = (float(p.modulationRef) / 63 * 150 + 150) / 255.0f;



	size_t binIndex = 0;
#ifdef VERBOSE_OUT
	std::vector<int16_t> dbgV;
	std::vector<float> dbgT;
	std::vector<size_t> dbgB;
#endif


	size_t n = countNticks(vGainTbl, vGainTblSz) * 2;//number of ticks in a full cycle



	auto index2time = [&]() {return size_t((acos(-atan((binIndex / float(lutSize - 1) * 2 - 1)*std::tan(yfovRADdiv2)) / yfovRADdiv2))*n / (2 * pi)+0.5f); };//ATAN
	//auto index2time = [&]() {return (acos(-(float(binIndex) / 64.0 * 2 - 1))) / (2 * pi*mirrorFreq); };//LINEAR



	for (size_t i = 0; i != vGainTblSz; ++i)
	{
		
		Dpt dpt = parseVgainTableValue(vGainTbl[i]);


		for (int z = 0; z != 2; ++z)
		{
			size_t binTic;
			while (binIndex != lutSize )
			{
				binTic = index2time();
				if (binTic < gainT)
				{
					++binIndex;
					continue;
				}
				if (binTic > gainT + dpt.t[z])
					break;

				float iout = (float(gainV)  * g2i + float(p.ibias));
				outputLUT[binIndex] = algo_convertDealyFromGain(iout);
				++binIndex;
				
			}
			if (binIndex == lutSize)
				break;
#ifdef VERBOSE_OUT
			dbgB.push_back(binTic);
			dbgV.push_back(gainV);
			dbgT.push_back(gainT);
#endif

			gainT += dpt.t[z];
			gainV += dpt.v[z];


		}


		if (gainV < 0)
			break;



	}

	if (binIndex != lutSize)
		std::cout << "error! did not fill all LUT values" << std::endl;
#ifdef VERBOSE_OUT
	std::ofstream f("lutdata.txt");
	for (int i = 0; i != dbgV.size(); ++i)
	{
		f << dbgT[i] << " " << dbgV[i] << " " << dbgB[i] << std::endl;
	}
	f.close();
#endif

	for (int i = 0; i != lutSize; ++i)
		outputLUT[i] /= 1024.0;
	
}