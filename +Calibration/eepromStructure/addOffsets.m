[NUM,TXT,RAW] = xlsread('eepromStructure.csv', 'eepromStructure', 'B:D');
TXT = TXT(2:end,:);
offset = zeros(length(NUM),1);
for k = 2:length(NUM)
    switch TXT{k-1,2}
        case {'single', 'uint32', 'int32'}
            offset(k) = offset(k-1) + 4*NUM(k-1);
        case {'uint16', 'int16'}
            offset(k) = offset(k-1) + 2*NUM(k-1);
        case {'uint8', 'int8', 'logical'}
            offset(k) = offset(k-1) + 1*NUM(k-1);
        case {'uint12'}
            offset(k) = offset(k-1) + 1.5*NUM(k-1);
    end
end
for k = 1:length(NUM)
    TXT{k,3} = sprintf('%d', round(offset(k)));
end
xlswrite('eepromStructureWithOffsets.xls', TXT, 'eepromStructureWithOffsets', 'B1');