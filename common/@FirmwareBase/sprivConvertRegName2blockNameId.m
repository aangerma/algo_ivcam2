function [b,aname,sb]=sprivConvertRegName2blockNameId (blkDataName)
sb = nan;
if(length(blkDataName)<5)
    error('name too short(%s)',blkDataName);
end
b = blkDataName(1:4);
[bi,ei]=regexp(blkDataName,'_(?<num>[\d]+)');
if(~isempty(bi) && ei==length(blkDataName))
    sb = str2double(blkDataName(bi+1:ei));
    aname = blkDataName(5:bi-1);
else
    aname = blkDataName(5:end);
end

if(~isequal(upper(b),b))
    error('Error in register "%s": first 4 letters should represent the algo block in UPPER CASE.',aname);
end
 if(aname(1)~=lower(aname(1)))
     error('First letter after block name should be lowercase(%s)',aname);
 end

end