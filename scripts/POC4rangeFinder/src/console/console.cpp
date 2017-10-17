#include "../poc4.h"
#include <stdint.h>
#include <string>
#include <iostream>
#include <ctime>
#include <chrono>
void main()
{

	char directoryName[] = "c:\\temp\\testData\\Frames\\";
	char recordDirectoryName[] = "c:\\temp\\Frames_rec_constant\\";

	


	std::cout << "Starting" << std::endl;
	SourceMode s(SourceMode::Simulation);
	GPLabType t(GPLabType::USB);
	bool doAS=false;
	int captureTimeOut = 5000;
	POC4Pipeline* p = CreatePipeline(s, t, RecordedMode::OverrideDiractory, RecordedFormat::Binary, 1024/8, doAS,directoryName, recordDirectoryName, captureTimeOut);
	if (HadError(p))
	{
		std::string str((const char*)GetError(p));
		std::cout << str << std::endl;
		return;
	}

	StartPipeline(p);
	if (HadError(p))
	{
		std::string str((const char*)GetError(p));
		std::cout << str << std::endl;
	}
	bool ok = false;
	auto start = std::chrono::steady_clock::now();
	while (true)
	{
		
		ok = GetFrame(p);
		
		if (ok)
		{
			auto end = std::chrono::steady_clock::now();

			uint8_t * datap = (uint8_t*)GetFrameData(p);

			uint64_t vfast = *reinterpret_cast<uint64_t*>(datap + 32);
			uint16_t vslow = *reinterpret_cast<uint16_t*>(datap + 32+8);
			std::cout << std::chrono::duration_cast<std::chrono::milliseconds>(end - start).count() << "msec" <<
				" fast" << vfast << " slow" << vslow << std::endl;

			start = std::chrono::steady_clock::now();



		}
		else
			std::cout << ".";
		if (HadError(p))
		{
			std::string str((const char*)GetError(p));
			std::cout << str << std::endl;
			continue;
		}
	}
	if (HadError(p))
	{
		std::string str((const char*)GetError(p));
		std::cout << str << std::endl;
	}

	StopPipeline(p);
	if (HadError(p))
	{
		std::string str((const char*)GetError(p));
		std::cout << str << std::endl;
	}
	ReleasePipeline(p);
	
	std::cout << "Done" << std::endl;
}