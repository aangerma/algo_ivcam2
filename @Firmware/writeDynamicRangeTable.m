function [] = writeDynamicRangeTable(obj,fname, presetsPath)
%%
current_dir = mfilename('fullpath');
ix = strfind(current_dir, '\');
if (~exist('presetsPath','var'))
    pathLR = fullfile(current_dir(1:ix(end-1)), '\+Calibration\+presets\+defaultValues\longRangePreset.csv');
    pathSR = fullfile(current_dir(1:ix(end-1)), '\+Calibration\+presets\+defaultValues\shortRangePreset.csv');
else
    pathLR=strcat( presetsPath,'\longRangePreset.csv');
    pathSR=strcat( presetsPath,'\shortRangePreset.csv');
end
longRangePreset=readtable(pathLR);
shortRangePreset=readtable(pathSR);

%definitions
TableSize = 120*2;
resrevedLength = 29;

%%
%initialize the stream
arr = zeros(1,TableSize,'uint8');
s = Stream(arr);

for i=1:size(longRangePreset,1)
    type=longRangePreset.type{i};
    value=longRangePreset.value(i);
    
    s.setNext(value,type);
end

for i=1:resrevedLength
    s.setNext(0,'uint8');
end

for i=1:size(shortRangePreset,1)
    type=shortRangePreset.type{i};
    value=shortRangePreset.value(i);
    
    s.setNext(value,type);
end

DynamicRangeTable = s.flush();


fileID = fopen(fname,'w');
fwrite(fileID,DynamicRangeTable','uint8');
fclose(fileID);
end

