function [ addresses2save, values2save ] = getScanDirectionValues( hw )
addresses2save  = {'85001400 85001410';...
    '85000000 85000010';...
    'a0050074 a0050078';...
    'a0050090 a0050094';...
    'a005007c a0050080'};

for i = 1:numel(addresses2save)
    cmdStr = sprintf('mrd %s',addresses2save{i});
    values2save{i} = valueStringFromCmd(hw.cmd( cmdStr ));
end

end

function valueString = valueStringFromCmd(ansString)
valueString = strsplit(ansString,'=>');
valueString = valueString{2};
end
