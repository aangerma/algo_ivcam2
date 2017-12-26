function [ allBlocks ] = privLoadRegisters(obj)
 lutsBlockID='100';
%Load register definition file and defualt values file.
% regsters with no defintion should be ONLY of block MTLB or FRMW (recieves defintion of single)
% register with both defintion and defaults are merged
% register with only definition get default initilization value
rMetaDataFilename = [obj.m_tablesFolder filesep 'regsDefinitions.frmw'];

%parse data
metaData = [];
if(~isempty(rMetaDataFilename))
    metaData = FirmwareBase.sprivReadAsicFile(rMetaDataFilename);
end

evltxt=sprintf('metaData.headers{%d},metaData.data(:,%d),',[1:length(metaData.headers);1:length(metaData.headers)]);
evltxt=sprintf('struct(%s)',evltxt(1:end-1));
obj.m_registers=eval(evltxt);



%% Build registers from defenition file
for i=1:size(metaData.data,1)
    
    [obj.m_registers(i).algoBlock,obj.m_registers(i).algoName,obj.m_registers(i).subReg]=FirmwareBase.sprivConvertRegName2blockNameId(obj.m_registers(i).regName);
    [obj.m_registers(i).base,obj.m_registers(i).value]=obj.sprivGetBaseVal(obj.m_registers(i).defaultValue);
    
    obj.m_registers(i).arraySize = str2double(obj.m_registers(i).arraySize);
    obj.m_registers(i).autogen = ~isempty(obj.m_registers(i).autogen)*-1; %autogen but not set ==-1, when set change it to 1
    obj.m_registers(i).updated=false;
    obj.m_registers(i).address=uint64(str2double(obj.m_registers(i).address));
    obj.m_registers(i).rangeStruct = parseRange(obj.m_registers(i));
    
    obj.m_registers(i).typeID = typeToClassID(obj.m_registers(i).type);
    obj.m_registers(i).functionallity=cleanComments(obj.m_registers(i).functionallity);
    if(~isempty(obj.m_registers(i).range) && obj.m_registers(i).autogen)
        error('autogen register should not recieve range(%s)',obj.m_registers(i).regName);
    end

    if(isempty(obj.m_registers(i).range) && ~obj.m_registers(i).autogen)
        error(' register should recieve range(%s)',obj.m_registers(i).regName);
    end
    

    if(strcmp(obj.m_registers(i).type,'single') && obj.m_registers(i).base~='f' && obj.m_registers(i).base~='h')
        error('floating point registers should be initilized with floating point data(%s)',obj.m_registers(i).regName);
    end
    
    if(~strcmp(obj.m_registers(i).type,'single') && obj.m_registers(i).base=='f')
        error('Cannot set float value to a non float register(%s)',obj.m_registers(i).regName);
    end
    if(obj.sprivSizeof( obj.m_registers(i).type)*obj.m_registers(i).arraySize>32)
        error('Bad register defenition - size is larger than 32(%s x %d) (%s)',obj.m_registers(i).type,obj.m_registers(i).arraySize,obj.m_registers(i).regName);
    end
%      if(strcmp(obj.m_registers(i).type,'logical') && obj.m_registers(i).base~='b')
%         error('Binary type registers should have default value in binary format to disable data abiguity (%s)',obj.m_registers(i).regName);
%     end
%     
end

%% UID check
if(length(unique({obj.m_registers.uniqueID}))~=length({obj.m_registers.uniqueID}))
    uuids = unique({obj.m_registers.uniqueID});
    nApprences = cellfun(@(x) nnz(strcmp({obj.m_registers.uniqueID},x)),uuids);
    error('Unique ID %s appears more than once in defenition file',uuids{find(nApprences~=1,1)});
end
%% name check
if(length(unique({obj.m_registers.regName}))~=length({obj.m_registers.regName}))
    uregNames = unique({obj.m_registers.regName});
    nApprences = cellfun(@(x) nnz(strcmp({obj.m_registers.regName},x)),uregNames);
    error('regname %s appears more than once in defenition file',uregNames{find(nApprences~=1,1)});
end
 blocks = unique({obj.m_registers.algoBlock});
 first3 = @(x) x(1:3);
 blockUID = cellfun(@(x) unique(cellfun(@(x) first3(x),{obj.m_registers(strcmpi(({obj.m_registers.algoBlock}),x)).uniqueID},'uni',false)),blocks,'uni',false);
 

 blockUID = cellfun(@(x) x(~strcmp(x,lutsBlockID)),blockUID,'uni',0);
 blockUIDlen=cellfun(@(x) length(x)~=1,blockUID);
 if(any(blockUIDlen))
     error('Each block must have the first 3 numbers in the unique ID as unique(%s - %s)',blocks{find(blockUIDlen,1)},cell2str(blockUID{blockUIDlen}));
 end



allBlocks = unique({obj.m_registers.algoBlock});

end


function id               = typeToClassID(tin)
typeList = FirmwareBase.typeList;


%special cast handling
switch(tin)
    case {'uint2','uint4'}
        tout = 'uint8';
    case {'int10'}
        tout='int16';
    case {'uint12'}
        tout='uint16';
    otherwise
        tout=tin;
end

id=find(strcmp(typeList,tout));
if(isempty(id))
    error('Unknonwn type %s',tin);
end

end


function rangeStruct=parseRange(s)
% check range. looks like:     {a;b;[c:d];[e:f];g}

rangeTxt = s.range;




if(isempty(rangeTxt)) %if empty range then all input is ok
    rangeStruct=[];
    return
end

%check: in {x}


% check: if float 0 -> 0.0
if(strcmp(s.type,'single'))
    res = regexp( [' ' rangeTxt ' '],'[^\d\./](?<n>\d+)[^\d\.]','names');
    if(~isempty(res))
        error(['in float type - register range should always be in form x.y (in reg ' s.regName ')']);
    end
end

rangeStruct=struct('fromTo',[],'scalar',[]);
%search with precentage
[is,ie,~,~,~,fromTo]=regexp(rangeTxt,'\[(?<val0>[-\.\d]+):(?<val1>[-+\.\d+]+)\]:/(?<p>[\d]+)');
rangeTxt=removeIndices(rangeTxt,is,ie);
[is,ie,~,~,~,scalar] =regexp(rangeTxt,'[{]*(?<val>[\d\.+-]+):/(?<p>[\d]+)[;}]{1}');
rangeTxt=removeIndices(rangeTxt,is,ie);
for i=1:length(fromTo)
    indx = length(rangeStruct.fromTo)+1;
    rangeStruct.fromTo(indx).val0=single(str2double(fromTo(i).val0));
    rangeStruct.fromTo(indx).val1=single(str2double(fromTo(i).val1));
    rangeStruct.fromTo(indx).p=single(str2double(fromTo(i).p));
end
for i=1:length(scalar)
    indx = length(rangeStruct.scalar)+1;
    rangeStruct.scalar(indx).val = single(str2double(scalar(i).val));
    rangeStruct.scalar(indx).p = single(str2double(scalar(i).p));
end
%search without precentage
[is,ie,~,~,~,fromTo]=regexp(rangeTxt,'\[(?<val0>[-\.\d]+):(?<val1>[-+\.\d+]+)\]');
rangeTxt=removeIndices(rangeTxt,is,ie);

[is,ie,~,~,~,scalar] =regexp(rangeTxt,'[{]*(?<val>[\d\.+-]+)[;}]*');%#ok
ip=100/(length(fromTo)+length(scalar));
% rangeTxt=removeIndices(rangeTxt,is,ie);
for i=1:length(fromTo)
    indx = length(rangeStruct.fromTo)+1;
    rangeStruct.fromTo(indx).val0=single(str2double(fromTo(i).val0));
    rangeStruct.fromTo(indx).val1=single(str2double(fromTo(i).val1));
    rangeStruct.fromTo(indx).p=single(ip);
end
for i=1:length(scalar)
    indx = length(rangeStruct.scalar)+1;
    rangeStruct.scalar(indx).val = single(str2double(scalar(i).val));
     rangeStruct.scalar(indx).p = single(ip);
end

psum=0;
if~isempty([rangeStruct.fromTo])
    psum=psum+sum([rangeStruct.fromTo.p]);
end
if~isempty([rangeStruct.scalar])
    psum=psum+sum([rangeStruct.scalar.p]);
end


assert(psum==100,sprintf('sum of range precentage should be 100,current sum=%d (%s)',psum,[s.algoBlock s.algoName]));


end


function strout = cleanComments(strin)
strout = strrep(strin,',',' ');
strout = strrep(strout,'%',' ');
end

function txtout = removeIndices(txtin,ib,ie)
n= false(1,length(txtin));
for i=1:length(ib)
    n(ib(i):ie(i))=true;
end
txtout=txtin;
txtout(n)=[];
end
