#include <stdint.h>
#include <algorithm>//std::max
#include <iostream>//std::cout
//#include <vector> //debug only


bool bitget(uint32_t v, int n)
{
	bool b = (v >> n)&uint32_t(1);
	return b;
}


//-----8<-----8<-----8<-----8<-----8<-----8<-----8<-----8<-----8<-----8<-----8<-----8<-----
float algo_convertDealyFromGain(float p)
{
	float tau=  0.016056 *p - 4.743036;
	return tau;
}
//-----8<-----8<-----8<-----8<-----8<-----8<-----8<-----8<-----8<-----8<-----8<-----8<-----


void genPWRlut(uint32_t* data,size_t n,float* outputLUT)
{
	static const int lutSize = 65;
	float yfov = 56;
	float mirrorFreq = 20e3;
	float ibias = 3;
	
	uint8_t modulationRef = 63;
	static const float pi = std::acos(0.0f)*2 ;
	static const float deg2rad = pi / 180.0;
	float PA_CLK = 125e6;

	float yfovRADdiv2 = yfov * deg2rad/2;
	
	float dt = 1 / PA_CLK;
	
	int16_t gainV = 0;
	
	float gainT = 0;
	
	float g2i = (float(modulationRef) / 63 * 150 + 150) / 255.0f;
	
	

	size_t binIndex = 0;

	//std::vector<int16_t> dbgV;
	//std::vector<float> dbgT;
	//std::vector<float> dbgB;


	auto index2time = [&]() {return (acos(-atan((binIndex / float(lutSize-1) * 2 - 1)*std::tan(yfovRADdiv2)) / yfovRADdiv2)) / (2 * pi*mirrorFreq); };//ATAN
	//auto index2time = [&]() {return (acos(-(float(binIndex) / 64.0 * 2 - 1))) / (2 * pi*mirrorFreq); };//LINEAR
	
	

    for(size_t i=0;i!=n;++i)
    {
		
		gainT += float((data[i] >> 4)&uint32_t(255))*dt;
		gainV += int16_t(bitget(data[i], 1) * 2 - 1);
		gainV = std::max(int16_t(0), gainV);
		++j;

		if (bitget(data[i], 0))
		{
			gainT += float((data[i] >> 12)&uint32_t(255))*dt;
			gainV += int16_t(bitget(data[i], 2) * 2 - 1);
			gainV = std::max(int16_t(0), gainV);
			++j;
		}

		float binTime = (acos(-atan((binIndex / 64.0 * 2 - 1)*std::tan(yfovRAD / 2)) * 2 / yfovRAD)) / (2 * pi*mirrorFreq);
		if (binTime < gainT)
		{
			
			float iout = (float(gainV) / 255 * (float(modulationRef) / 63 * 150 + 150) + ibias);
			outputLUT[binIndex] = algo_convertDealyFromGain(iout);
			++binIndex;
			binTime = index2time();
		}

		//dbgB.push_back(binTime);
		//dbgV.push_back(gainV);
		//dbgT.push_back(gainT);


		gainT += tB;
		gainV = std::max(int(0), gainV + vB);




	

    }

	if (binIndex != lutSize)
		std::cout << "error! did not fill all LUT values" << std::endl;

	//for (int i = 0; i != dbgV.size(); ++i)
	//{
	//	std::cout << dbgT[i] << " " << dbgV[i] << " " <<dbgB[i] << std::endl;
	//}
}