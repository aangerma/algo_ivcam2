#include "mex.h"
#include <string>
#include <stdint.h>
#include "../poc4.h"
#include <chrono>
#include <thread>
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{


	if (!mxIsChar(prhs[0]))
		mexErrMsgTxt("First argument should be string identidier");
	
	char buff[1024];
	mxGetString(prhs[0], buff, 1024);
	if (strcmp(buff, "new") == 0)
	{
		SourceMode sourceMode = SourceMode(int(*mxGetPr(prhs[1])));
		GPLabType  gpLabType = GPLabType(int(*mxGetPr(prhs[2])));
		bool doAutoSkew = int(*mxGetPr(prhs[3])) == 1;
		int codeLength = int(*mxGetPr(prhs[4]));

		mxGetString(prhs[5], buff, 1024);
		std::string directoryName(buff);
		mxGetString(prhs[6], buff, 1024);
		std::string recordDirectoryName(buff);
		int codeLengthByte = codeLength / 8;
		int captureTimeOut = 1000;
		POC4Pipeline* p = CreatePipeline(sourceMode, gpLabType, RecordedMode::OverrideDiractory,RecordedFormat::Binary, codeLengthByte,doAutoSkew, directoryName.c_str(), recordDirectoryName.c_str(), captureTimeOut);
		if (HadError(p))
			mexErrMsgTxt((const char*)GetError(p));
		uint64_t p64 = reinterpret_cast<uint64_t>(p);
		plhs[0]=mxCreateNumericMatrix(1, 1, mxUINT64_CLASS, mxREAL);
		*(uint64_t*)mxGetData(plhs[0]) = p64;
		return;
	}
	uint64_t p64 = *(uint64_t*)(mxGetData(prhs[1]));
	POC4Pipeline* p = reinterpret_cast<POC4Pipeline*>(p64);
	if (strcmp(buff, "delete") == 0)
	{
		ReleasePipeline(p);
		if (HadError(p))
			mexErrMsgTxt((const char*)GetError(p));
		return;
	}
	if (strcmp(buff, "start") == 0)
	{
		StartPipeline(p);
		//if (HadError(p))
		//	mexErrMsgTxt((const char*)GetError(p));
		return;
	}
	if (strcmp(buff, "stop") == 0)
	{
		StopPipeline(p);
		//if (HadError(p))
		//	mexErrMsgTxt((const char*)GetError(p));
		return;
	}
	if (strcmp(buff, "getFrame") == 0)
	{
		int maxCouter = 1000;
		int i = 0;
		for (; i != maxCouter && !GetFrame(p); ++i);

		if (i == maxCouter)
			mexErrMsgTxt("reached max getFrame counter");

		uint8_t * datap = (uint8_t*)GetFrameData(p);
		if (datap == nullptr)
			mexErrMsgTxt("bad pointer");
		unsigned int sz = GetFrameSize(p);
		plhs[0] = mxCreateNumericMatrix(sz, 1, mxUINT8_CLASS, mxREAL);
		uint8_t* datapOut = (uint8_t*)mxGetData(plhs[0]);
		memcpy(datapOut, datap, sz);
		return;

	}
    if (strcmp(buff, "getFragment") == 0)
	{
        int port = 0;
		int maxCouter = 1000;
		int i = 0;
		for (; i != maxCouter && !GetFragmant(p,port); ++i);

		if (i == maxCouter)
			mexErrMsgTxt("reached max getFrame counter");

		uint8_t * datap = (uint8_t*)GetFragmantData(p,port);
		if (datap == nullptr)
			mexErrMsgTxt("bad pointer");
		unsigned int sz = GetFragmantSize(p,port);
		plhs[0] = mxCreateNumericMatrix(sz, 1, mxUINT8_CLASS, mxREAL);
		uint8_t* datapOut = (uint8_t*)mxGetData(plhs[0]);
		memcpy(datapOut, datap, sz);
		return;

	}





}