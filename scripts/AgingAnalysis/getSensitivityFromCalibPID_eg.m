% DESCRIPTION:
%    Example for how to call getSensitivityFromCalibPID.
% METADATA:
%	 MATLAB version: 9.5.0.1033004 (R2018b) Update 2
%	 OS: Microsoft Windows 10 Enterprise Version 10.0 (Build 17763)
%	 created by: omriberm
%	 DATE: 09-Mar-2020
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc;
path = "\\143.185.124.250\Tester-data\IDC Data\IVCAM\L515\Calibration\BIG PBS\HENG-3212\F9440745\log.txt";
[SensOL,SensCL] = getSensitivityFromCalibPID(path);

FA_OL_mean     = mean(SensOL(:,1));FA_OL_std    = std(SensOL(:,1));
SA_CL_mean     = mean(SensCL(:,2));SA_CL_std    = std(SensCL(:,2));

