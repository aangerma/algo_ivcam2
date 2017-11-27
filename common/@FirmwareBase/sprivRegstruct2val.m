function valout=sprivRegstruct2val(s)
nvals = length(s);
% concat same subRegs values or find single reg value
if(nvals~=1)
    allsame = @(v) all(strcmp(v,v{1}));
    assert(all(s(1).typeID==[s.typeID]),sprintf('registers with same blockID and register ID should have the same type(%s)',s(1).regName));
    assert(allsame({s.algoName}),sprintf('registers with same blockID and register ID should have the same algoName(%s)',s(1).regName));
%     assert(all(s(1).arraySize==[s.arraySize]),sprintf('registers with same blockID and register ID should have the same arraySize(%s)',s(1).regName));
%     assert(allsame({s.range}),sprintf('registers with same blockID and register ID should have the same range(%s)',s(1).regName));
    
    
    
    
end
[~,ordr] = sort([s.subReg]);
%disp
s = s(ordr);

noutVals = sum([s.arraySize]);
valBIN = arrayfun(@(x) val2bin(s(x))',1:length(s),'uni',false);
valBIN = reshape([valBIN{:}],[],noutVals)';

if(s(1).type(1)=='i')
    %signed integer, pad left with left most bit
    nrep = FirmwareBase.sprivSizeof(FirmwareBase.typeList{s(1).typeID})-FirmwareBase.sprivSizeof(s(1).type);
    valBIN=[valBIN(:,ones(1,nrep)) valBIN];
end

valout = arrayfun(@(x) bin2valout(valBIN(x,:),s(1).typeID,s(1).regName),1:noutVals);

fieldValsIndex=[0 cumsum([s.arraySize])];
valoutC = arrayfun(@(i) valout(fieldValsIndex(i)+1:fieldValsIndex(i+1)),1:length(fieldValsIndex)-1,'uni',0);
for i=1:length(s)
    checkValidRange(s(i),valoutC{i});
end


end

function val = bin2valout(bins,tt,regName)

typeList = FirmwareBase.typeList;


% nbits = length(bins);

%special handling
% if(nbits==4)
%     nbits=8;
% elseif(nbits==12)
%     nbits=16;
% end

% uintTypes = [8 16 32 64];
% nbits = uintTypes(minind(abs(uintTypes-nbits)));
%  bin2dec_ = @(x) cast(bin2dec(x),sprintf('uint%d',nbits));
bin2dec_ = @(x) cast(bin2dec(x),FirmwareBase.typeUintList{tt});


if(tt==1)%logical type recieves different handling
    val = (bins-48)==1;
else
    val = typecast(bin2dec_(bins),typeList{tt});
end
% switch(tt)
%     case 'logical'
%         val = (bins-48)==1;
%    case 'uint4'
%         val = typecast(bin2dec_(bins),'uint8');
%     case 'uint8'
%         val = typecast(bin2dec_(bins),'uint8');
%     case 'int8'
%         val = typecast(bin2dec_(bins),'int8');
%     case 'uint16'
%         val = typecast(bin2dec_(bins),'uint16');
%     case 'int16'
%         val = typecast(bin2dec_(bins),'int16');
%     case 'uint32'
%         val = typecast(bin2dec_(bins),'uint32');
%     case 'int32'
%         val = typecast(bin2dec_(bins),'int32');
%     case 'single'
%         val = typecast(bin2dec_(bins),'single');
%     otherwise
%         error('unsopported numeric type for register %s',regName);
% end

if(length(val)~=1)
    error('Register value does not agree with register type (%s)',regName);
end
end
function bout = val2bin(s)
tt = s.type;
val = s.value;
n=FirmwareBase.sprivSizeof(tt);
nbits = n*s.arraySize;


switch(lower(s.base))
    case 'd'
        numval = str2double(val);
        if(rem(numval,1)~=0)
            error('decimal value should be non fraction numbers(%s)',s.regName);
        end
        if(numval<0)
            error('use d type for fixed unsigned and s for fixed signed(%s)',s.regName);
        end
        bout = dec2binFAST(uint64(numval),nbits);
    case 's'
        numval = str2double(val);
        if(rem(numval,1)~=0)
            error('decimal value should be non fraction numbers(%s)',s.regName);
        end
        if(numval<0)
            numval = numval+2^nbits;
        end
        bout = dec2binFAST(uint64(numval),nbits);
    case 'h'
        bout = dec2binFAST(uint64(hex2dec(val)),nbits);
    case 'b'
        bout = [ones(1,nbits-length(val))*'0' val];
    case 'f'
        bout = dec2binFAST(uint64(typecast(single(str2double(val)),'uint32')),32);
    otherwise
        error('Invalid base in register %s',s(1).regName);
end
if(length(bout)>nbits)
    error('Register value(%s) is too big for register type(%s) (%s)',[s.base s.value],s.type,s.regName);
end

bout=vec(fliplr(reshape(bout,n,[]))); %LITLLE ENDIAN

end






function checkValidRange(s,val)
% check range. looks like:     {a;b;[c:d];[e:f];g}
if(isempty(s.rangeStruct))
    return;
end


ok = false(numel(val),1);
for r=s.rangeStruct.fromTo
    ok(val>=r.val0 & val<=r.val1)=true;
    if(all(ok))
        return;
    end
end
if(isstruct(s.rangeStruct.scalar))
    ok = ok | any(abs(bsxfun(@minus,[s.rangeStruct.scalar.val],single(vec(val))))==0,2);
end
if(all(ok))
    return;
end
% for r=s.rangeStruct.singleVal
%     ok(val==r)=true;
%     if(all(ok))
%         return;
%     end
% end

error('Register value(%g) is not in range(%s) (%s)',val(find(~ok,1)),s.range,[s.algoBlock s.algoName]);


end
