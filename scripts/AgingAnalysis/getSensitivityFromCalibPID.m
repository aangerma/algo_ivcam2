function [SensOL,SensCL] = getSensitivityFromCalibPID(log_path)
% DESCRIPTION:
%	 getSensitivityFromCalibPID returns the sensitivity (Vcmd/FOV) based on measurements taken as part of the PID loop performed during MEMS Calibration
%
% INPUTS:
%	 log_path 	- the full-path of the log of the MEMS Calibration, including the PID loop's measurements
%
% OUTPUTS: (1st col is FA, 2nd col is SA)
%	 SensOL 	- the sensitivity inferred from the Open-Loop PID 
%	 SensCL 	- the sensitivity inferred from the Closed-Loop PID  
%
% METADATA:
%	 MATLAB version: 9.5.0.1033004 (R2018b) Update 2
%	 OS: Microsoft Windows 10 Enterprise Version 10.0 (Build 17763)
%	 created by: omriberm
%	 DATE: 09-Mar-2020
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
s = fileread(log_path);
[~,~,endIndex]          = regexp(s,'[^\n\r]+Finish calc fov phase','match');

FOV     = zeros(length(endIndex)-2,2);
VCMD    = FOV;
for i=1:length(endIndex)-1
    
    %%% Cropp specific iteration:
    block        = s(endIndex(i):endIndex(i+1));
    block_rows   = strsplit(block,'\n');
    
    %% Extract FOV,Vcmd:
    raw_vcmd        = block_rows(contains(block_rows,'Write value:'));
    raw_fov         = block_rows(contains(block_rows,'Calc FOV'));

    if isempty(raw_fov) || isempty(raw_vcmd) || length(raw_vcmd)~=2
        FOV(i,:)    = nan;
        VCMD(i,:)   = nan;
        continue;
    end
        
    
    VCMD(i,:)           = cellfun(@getNumericData,raw_vcmd);
    if any(contains(raw_vcmd{1},'RegsAlg_SAreg_Rcmd_NotchFilt1_K'))
        VCMD(i,:) = circshift(VCMD(i,:),1);
    end
    VCMD(i,2)           = VCMD(i,2)*31.5; %% SA Rcmd amplitude 
    
    FOV(i,:)            = getNumericData(raw_fov{:},2);
    FOV(i,:)            = circshift(FOV(i,:),1);
end

%% remove Nans:
is_nan = any(isnan(VCMD),2);
FOV(is_nan,:) = [];
VCMD(is_nan,:) = [];

%% Partition between OL and CL:

is_cl = VCMD(:,2)>10;

FOV_OL = FOV(~is_cl,:);
FOV_CL = FOV(is_cl,:);

VCMD_OL = VCMD(~is_cl,:);
VCMD_CL = VCMD(is_cl,:);

%% Sensitivity:
SensOL  = VCMD_OL./FOV_OL;
SensCL  = VCMD_CL./FOV_CL;