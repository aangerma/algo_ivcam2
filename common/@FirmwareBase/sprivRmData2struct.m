function regs = sprivRmData2struct(valStruct)
regs = struct;


%extract block ID
%
% uids = cellfun(@(x) regexp(x,'(?<blkID>[\d]+)\.(?<regID>[\d]+)\.(?<subID>[\d]+)','names'),{valStruct.uniqueID});
% uids = arrayfun(@(x) bitshift(uint32(str2double(x.blkID)),20)+bitshift(uint32(str2double(x.regID)),10)+bitshift(uint32(str2double(x.subID)),0),uids);
%
% uuids = unique(bitshift(bitshift(uids,-10),10));

names = cell(size(valStruct));
for i=1:length(valStruct)
    names{i} = [valStruct(i).algoBlock valStruct(i).algoName];
end
uniq_names = unique(names);

for i=1:length(uniq_names)
    indices = find(strcmp(uniq_names{i},names) == 1);
    val=FirmwareBase.sprivRegstruct2val(valStruct(indices));
    
    
    regName = valStruct(indices(1)).algoName;
    regBlck = valStruct(indices(1)).algoBlock;
    
    regs.(regBlck).(regName)=val;
    
end


end

