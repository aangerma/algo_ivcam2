function num_data = getNumericData(data_str,varargin)
% DESCRIPTION:
%	 getNumericData extracts numeric data from cell array 
%
% INPUTS:
%	 data_cell 	- input cellarray
%
% OUTPUTS:
%	 num_data 	- output numeric data
%
% METADATA:
%	 MATLAB version: 9.5.0.1033004 (R2018b) Update 2
%	 OS: Microsoft Windows 10 Enterprise Version 10.0 (Build 16299)
%	 created by: omriberm
%	 DATE: 04-Dec-2019
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

data_cell           = strsplit(data_str,{':',' ',',',char(176),'Â','C',newline,'\r'});
info_numeric_idx    = find(cellfun(@(S) ~isnan(str2double(S)),data_cell));

if nargin>1
    N = varargin{:};
else
    N=1;
end

num_data            = str2double(data_cell(info_numeric_idx(end-(N-1):end)));

