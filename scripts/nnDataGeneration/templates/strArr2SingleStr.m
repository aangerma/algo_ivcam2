function singleStruct = strArr2SingleStr(structArr)
singleStruct = struct;
for fi = fields(structArr)'
    singleStruct.(fi{1}) = [structArr(:).(fi{1})];
end

end