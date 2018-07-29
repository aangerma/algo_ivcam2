#include <stdint.h>
#include <algorithm>//std::max
#include <iostream>//std::cout


//#define VERBOSE_OUT
#ifdef VERBOSE_OUT
#include <vector> //debug only
#include <tuple>
typedef std::tuple<uint16_t, int16_t, float, uint16_t> Dh;
#include <fstream>
#endif





//-----8<-----8<-----8<-----8<-----8<-----8<-----8<-----8<-----8<-----8<-----8<-----8<-----
float algo_convertDealyFromGain(float i)
{
	float tau = (0.016754f*i - 3.5f);
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
	uint16_t t[2];
	int16_t v[2];

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

uint16_t countNticks(uint32_t* vGainTbl, uint16_t vGainTblSz)
{
	int16_t gainV = 0;
	uint16_t gainT = 0;

	for (uint16_t i = 0; i != vGainTblSz; ++i)
	{

		Dpt dpt = parseVgainTableValue(vGainTbl[i]);

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
    float pixMarginTprcnt;
    float pixMarginBprcnt;
	uint8_t laser_BIAS;
	uint8_t laser_MODULATION_REF;
};
void genPWRlut(uint32_t* vGainTbl, uint16_t vGainTblSz, Params p, float* outputLUT)
{
	static const int lutSize = 65;




	static const float pi = std::acos(0.0f) * 2;
	static const float deg2rad = pi / 180.0f;


	float yfovRADdiv2 = p.yfov * deg2rad / 2;
	float tanyfovRADdiv2 = std::tan(yfovRADdiv2);


	int16_t gainV = 0;
	uint16_t gainT = 0;





	uint16_t binIndex = 0;
#ifdef VERBOSE_OUT
	std::vector<Dh> dbg;
#endif


	uint16_t n = countNticks(vGainTbl, vGainTblSz) * 2;//number of ticks in a full cycle



	//auto index2time = [&]() {return (acos(-(float(binIndex) / 64.0 * 2 - 1))) / (2 * pi*mirrorFreq); };//LINEAR



	for (uint16_t i = 0; i != vGainTblSz; ++i)
	{

		Dpt dpt = parseVgainTableValue(vGainTbl[i]);


		for (int z = 0; z != 2; ++z)
		{
			uint16_t binTic;
			float iout = float(gainV)/ 255.0f  * (float(p.laser_MODULATION_REF) / 63 + 1)*150.0f  + float(p.laser_BIAS)*60.0f / 255.0f;
			while (binIndex != lutSize)
			{

				float binIndex01 = float(binIndex) / float(lutSize - 1);
				binIndex01 = (binIndex01 + p.pixMarginTprcnt )/(1 + p.pixMarginTprcnt+ p.pixMarginBprcnt);
				//float binIndex01 = float(binIndex) /  float(lutSize - 1);
                binIndex01 = std::min(1.0f,std::max(0.0f,binIndex01));
				binTic = uint16_t((acos(-atan((binIndex01 * 2 - 1)*tanyfovRADdiv2) / yfovRADdiv2))*n / (2 * pi) + 0.5f);
				if (binTic < gainT)
				{
					std::cout << "error! did not fill LUT value at " << binIndex << std::endl;
					++binIndex;
					continue;
				}
				if (binTic > gainT + dpt.t[z])
					break;
#ifdef VERBOSE_OUT
				dbg.push_back(std::make_tuple(0, 0, binTic, iout));
#endif
				
                outputLUT[binIndex] = algo_convertDealyFromGain(iout);
				++binIndex;

			}
			if (binIndex == lutSize)
				break;
#ifdef VERBOSE_OUT
			dbg.push_back(std::make_tuple(gainT, iout, 0, 0));
#endif

			gainT += dpt.t[z];
			gainV += dpt.v[z];


		}


		if (gainV < 0)
			break;



	}


	for (int i = 0; i != lutSize - 1; ++i)
		outputLUT[i] = (outputLUT[i] + outputLUT[i + 1]) / 2;

	for (int i = 0; i != lutSize; ++i)
		outputLUT[i] /= 1024.0;


	if (binIndex != lutSize)
		std::cout << "error! did not fill all LUT values" << std::endl;
#ifdef VERBOSE_OUT
	{
		std::ofstream f("lutdata.txt");
		for (int i = 0; i != dbg.size(); ++i)
		{
			f << std::get<0>(dbg[i]) << " " << std::get<1>(dbg[i]) << " " << std::get<2>(dbg[i]) << " " << std::get<3>(dbg[i]) << " " << std::endl;
		}
		f.close();
	}

#endif



}