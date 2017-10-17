#pragma once

typedef struct POC4Pipeline POC4Pipeline;


extern "C"
{
	enum SourceMode
	{
		FullFlowWithHardware,
		OnlyGPLABFrames,
		SplittedFrames,
		SplittedFramesSimulation,
		Simulation,
		RecordForExerciser
	};
	enum class RecordedMode
	{
		OverrideDiractory,
		ApendDiractory,
		None
	};

	enum class RecordedFormat
	{
		Text,
		Binary,
		None
	};

	enum GPLabType
	{
		USB,
		PCIExpress
	};

	void GetRevision(int* major, int* minor, int* fixNumber, int* buildID);

	POC4Pipeline* CreatePipeline(SourceMode mode, GPLabType type, RecordedMode recordedMode, RecordedFormat recordedFormat, const int numOfBytes, const bool withAutoSkew, const char* directoryName, const  char* recordDirectoryName, const int captureTimeout);


	void StartPipeline(POC4Pipeline* pipeline);
	void StopPipeline(POC4Pipeline* pipeline);
	bool GetFrame(POC4Pipeline* pipeline);
	bool GetFragmant(POC4Pipeline* pipeline, int port);

	const unsigned int GetFrameSize(POC4Pipeline* pipeline);
	const void* GetFrameData(POC4Pipeline* pipeline);

	const unsigned int GetFragmantSize(POC4Pipeline* pipeline, int port);
	const void* GetFragmantData(POC4Pipeline* pipeline, int port);

	bool HadError(POC4Pipeline* pipeline);
	const void* GetError(POC4Pipeline* pipeline);

	void ReleasePipeline(POC4Pipeline* pipeline);

	int GetNumOfPorts(POC4Pipeline* pipeline);
	bool GetSourceStatistics(POC4Pipeline* pipeline, int index, int *ID, int* framesCounter, double* FPS);


	bool GetFragmentForViewer(POC4Pipeline* pipeline, int index);
	const unsigned int GetFragmentForViewerSize(POC4Pipeline* pipeline, int index);
	const void* GetFragmentForViewerData(POC4Pipeline* pipeline, int index);

}