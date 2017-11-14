function [metaData,errMsg] = sprivReadAsicFile(filename)
errMsg = 0;

% filename = 'tables\RegsFile_15b0_8_1.xlsx';
if ~exist(filename,'file')
    error('Missing ASIC file: %s',filename)
end
% define iff


% Read XLS/CSV file
%     [~,~,allData] = xlsread(filename);
[allData] = FirmwareBase.sprivReadCSV(filename);

% Headers cell
metaData.headers = strtrim(allData(1,:));
metaData.data = allData(2:end,:);


% allData = cellfun(@(x) space_trim(x), allData,'UniformOutput',false);


end
