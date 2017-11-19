function ivsArr = readFrames(inputDir,outputDir,numFrames)

if(nargin==1)
    outputDir = fullfile(inputDir,'out');
    mkdirSafe(outputDir);
end
 ivsArr = cell(0);

filesStruct.fns = sort(dirRecursive(inputDir,'Frame_*.bin'));

fDir = cellfun(@(x) dir(x), filesStruct.fns);
filesStruct.fSz = [fDir.bytes];
filesStruct.ptr = 0;
filesStruct.fileNum = 1;
filesStruct.fid = fopen(filesStruct.fns{filesStruct.fileNum},'r');
filesStruct.currFrameNum = 0;
if(nargin<3)
%     try
        while true
            [filesStruct,ivs] = readOneFrame(filesStruct,outputDir);
             ivsArr = [ivsArr; {ivs}];
        end
%     catch
%     end
else
    for i=1:numFrames
        [filesStruct, ivs] = readOneFrame(filesStruct,outputDir);
         ivsArr = [ivsArr; {ivs}];
    end
end

end



function [filesStruct,ivs] = readOneFrame(filesStruct,outputDir)
% try
    filesStruct.currFrameNum = filesStruct.currFrameNum+1;
    [frameHeader,filesStruct] = getFrameHeader(filesStruct);
    [columns,filesStruct] = getFrameData(filesStruct,frameHeader);
% catch e
%     throw(e);
% end

%%
     for i=1:length(columns)

        if(mod(i,2)==0)
 
            columns(i).xy(2,:) = -columns(i).xy(2,:);

        end
     end
  %%  
     ivs.xy = [columns.xy];
ivs.slow = [columns.slow];
ivs.fast = [columns.fast];
 ivs.flags = [columns.flags];

 
io.writeIVS( fullfile(outputDir,sprintf('record_%02d.ivs',filesStruct.currFrameNum)),ivs);

end



function [data,filesStruct] = getConcatData(filesStruct,numBytes2read)

if(filesStruct.ptr == filesStruct.fSz(filesStruct.fileNum)) %the previous file has ended
    filesStruct.fileNum = filesStruct.fileNum+1;
    fclose(filesStruct.fid);
    filesStruct.fid = fopen(filesStruct.fns{filesStruct.fileNum},'r');
    filesStruct.ptr = 0;
end


fseek(filesStruct.fid,filesStruct.ptr,'bof');
[data,numBytesRead] = fread( filesStruct.fid,numBytes2read,'*uint8');

if(numBytesRead<numBytes2read) %data is in several seperate files
    filesStruct.fileNum = filesStruct.fileNum+1;
    fclose(filesStruct.fid);
    filesStruct.fid = fopen(filesStruct.fns{filesStruct.fileNum},'r');
    filesStruct.ptr = 0;
    
    [dataTemp,filesStruct] = getConcatData(filesStruct,numBytes2read-numBytesRead);
    data = [data; dataTemp];
else
    filesStruct.ptr = filesStruct.ptr+numBytesRead;
end
end




function [frameHeader,filesStruct] = getFrameHeader(filesStruct)

FRAME_HEADER_SZ_BYTES = 32;
FH_FIRST_BYTE = 35;%RAW_FORMAT_DEF = 3,LOCATION_FORMAT_DEF = 2; 2*2^4+3;
% FH_SECOND_BYTE = 16;%just because...... NOTE: IF SCANNED LEFT TO RIGHT THEN WE HAVE A PROBLEM!!!!


[raw,filesStruct] = getConcatData(filesStruct,FRAME_HEADER_SZ_BYTES);

if(raw(1) ~= FH_FIRST_BYTE)
    ind = find(raw==FH_FIRST_BYTE,1);
    while(isempty(ind) || floor((filesStruct.ptr +ind -1)/16)~=(filesStruct.ptr +ind -1)/16) %FH should always start with good ptr 
        [raw,filesStruct] = getConcatData(filesStruct,FRAME_HEADER_SZ_BYTES);
        ind = find(raw==FH_FIRST_BYTE,1);
    end
    [rawTmp,filesStruct] = getConcatData(filesStruct,ind-1);
    raw(1:ind-1) = [];
    raw = [raw;rawTmp];
end




frameHeader.RawFormat = bitand(raw(1),uint8(15));
frameHeader.locationFormat = bitshift(raw(1),-4);
frameHeader.info = typecast(raw(2:3),'uint16');
frameHeader.numOfColumns = typecast(raw(4:5),'uint16');
frameHeader.frameCounter = typecast(raw(6:7),'uint16');
frameHeader.MIPIDispatcherPointer = raw(8);
frameHeader.timestamp=typecast(raw(9:12),'uint32');
frameHeader.reserved=raw(13:32);

if(frameHeader.RawFormat ~= 3)
    error('frameHeader.RawFormat ~= 3')
end
end


function [colHeader,filesStruct] = getColumnHeader(filesStruct,numCol)

COLUMN_HEADER_SZ_BYTES = 32;

[raw,filesStruct] = getConcatData(filesStruct,COLUMN_HEADER_SZ_BYTES);
if(raw(1) == 0)%after each col could be some zero padding
    ind = find(raw~=0,1);
    while(isempty(ind))
        [raw,filesStruct] = getConcatData(filesStruct,COLUMN_HEADER_SZ_BYTES);
        ind = find(raw~=0,1);
    end
    [rawTmp,filesStruct] = getConcatData(filesStruct,ind-1);
    raw(1:ind-1) = [];
    raw = [raw;rawTmp];
end

%     struct colHeader
% {
%    UINT16               numPackets; //bytes 0 1
%    byte            sizeOfPacket;   //bytes 2
%    UINT32               horizontalLocation; //bytes 3-6
%    UINT32               verticalLocation; //bytes 7-10
%    UINT16               txSyncDelay; //bytes 11 12
%    UINT16               columnLength;  //bytes 13 14
%    Info            info; //byte 15
%    byte            data[9]; //byte 16-24
%    byte            timestamp[5]; //byte 25-29
%    byte            reserved[2]; //byte 30-31
%    // 204- 235
%
%    /*Info               info;
%    FreqCompensation freqCompensation;
%    LocCorrection    locCorrection;
%    UINT32               horizontalTimeFromHsync;
%    UINT32               verticalTimeFromHsync : 20;*/
% };
OFFSET = 1;

colHeader.numPackets=typecast(raw(OFFSET+(0:1)),'uint16');
colHeader.sizeOfPacket=raw(OFFSET+2);

colHeader.horizontalLocation=int16(bitshift(typecast(raw(OFFSET+(3:6)),'int32'),-2)); %we get 14b but should get 12b
colHeader.verticalLocation=int16(bitshift(typecast(raw(OFFSET+(7:10)),'int32'),-2));

colHeader.txSyncDelay=typecast(raw(OFFSET+(11:12)),'uint16'); %in fast samples count
colHeader.columnLength=typecast(raw(OFFSET+(13:14)),'uint16');
colHeader.info=raw(OFFSET+15);
colHeader.scanDir=bitand(colHeader.info,uint8(1));
colHeader.data=raw(OFFSET+(16:24));
colHeader.timestamp=bitand(bitshift(typecast([raw(OFFSET+(25:29));0;0;0],'uint64'),-4),uint64(2^32-1))*4;%*4 for it to be in fast samples count
colHeader.vSyncDelay=bitand(bitshift(typecast([raw(OFFSET+(29:31));0;],'uint32'),-4),uint32(2^20-1))*4;%*4 for it to be in fast samples count
colHeader.reserved=raw(OFFSET+(30:31));
colHeader.numCol = numCol;

if(double(colHeader.columnLength)==0)
    error('readRawframe error: bad columnLength data in file %s',filesStruct.fns{filesStruct.fileNum});
end
if(double(colHeader.sizeOfPacket)~=36)
    error('readRawframe error: bad  sizeOfPacket data in file %s',filesStruct.fns{filesStruct.fileNum});
end
end





function [colData,filesStruct] = getColumn(filesStruct,colSz,colHeader)

[rawCol,filesStruct] = getConcatData(filesStruct,colSz);


%column packets- fast & slow
rawColMat = reshape(rawCol,double(colHeader.sizeOfPacket),[]);

slow=rawColMat(1:3,:);
slow = typecast(vec([slow;zeros(1,size(slow,2))]),'uint32');
slow=vec([bitand(slow,uint32(2^12-1)) bitshift(slow,-12)]');

fast=rawColMat(4:35,:);
fast = uint82bin(fast);



%column packets- location
locOffset=rawColMat(36,:);
colData.projectionFlag = bitget(locOffset,1);

hlocIndex=bitand(bitshift(locOffset,-1),uint8(3))+1;
hlocLUT = int16([0 1 -2 -1]);%2s complement
offsetH = hlocLUT(hlocIndex);
offsetH = cumsum(offsetH);

offsetV = -int16(bitshift(locOffset,-3))*(int16(colHeader.scanDir)*2-1);%scanDir: 1== down, 0==up
offsetV = cumsum(offsetV);

x = (colHeader.horizontalLocation*ones(size(offsetH),'int16'));%+offsetH);
y = (colHeader.verticalLocation+offsetV);

%% aSync sim
y = y-int16(2048);

slow=min(2^12-1,uint16(interp1(0:length(slow)-1,double(slow),0:0.5:length(slow)-0.5,'linear','extrap'))');
assert(length(slow)==length(fast)/64,'length(slow)~=length(fast)/64');

x = min(2^12-1,int16(interp1(0:length(x)-1,double(x),0:0.25:length(x)-0.25,'linear','extrap')));
y = min(2^12-1,int16(interp1(0:length(y)-1,double(y),0:0.25:length(y)-0.25,'linear','extrap')));

numPackets2pad = double(colHeader.txSyncDelay)/64;
assert(floor(numPackets2pad)==numPackets2pad,'floor(numPackets2pad)~=numPackets2pad');

tx_code_start = [uint8(1); zeros(numPackets2pad,1,'uint8'); zeros(length(slow)-1,1,'uint8')];
slow = [zeros(numPackets2pad,1,'uint16'); slow];
scan_dir = colHeader.scanDir*ones(length(slow),1,'uint8');
ld_on =[ zeros(numPackets2pad,1,'uint8');  vec(repmat(uint8(colData.projectionFlag),4,1))];
x = [zeros(1,numPackets2pad,'int16') x];
y = [zeros(1,numPackets2pad,'int16') y];
fast = [false(numPackets2pad*64,1); fast];






%% column struct
colData.slow = slow';
colData.fast = fast';
colData.xy = [x; y];

ld_on_bit = 1; %starting from 1...
tx_code_start_bit = 2;
scan_dir_bit = 3;
colData.flags =vec(...
    bitshift(ld_on         ,ld_on_bit-1)+...
    bitshift(tx_code_start ,tx_code_start_bit-1)+...
    bitshift(scan_dir      ,scan_dir_bit-1))';
colData.ts=uint64(0:length(slow)-1)*64+colHeader.timestamp;
end




function [columns,filesStruct] = getFrameData(filesStruct,frameHeader)

columns=struct();

%% columns
for i=1:frameHeader.numOfColumns
    
    [colHeader,filesStruct] = getColumnHeader(filesStruct,i);
    [colData,filesStruct] = getColumn(filesStruct,double(colHeader.numPackets)*double(colHeader.sizeOfPacket),colHeader);
    
    if(i~=1)
        deltaTxSyncDelay = colHeader.timestamp-uint64(colHeader.txSyncDelay) -(columns(i-1).timestamp-uint64(columns(i-1).txSyncDelay));
         assert(rem(deltaTxSyncDelay,64)==0,'deltaTxSyncDelay should divide by 64(got %d)',mod(deltaTxSyncDelay,64));
    end
    
    fnames = fieldnames(colHeader);
    for j=1:length(fnames)
        columns(i).(fnames{j}) = colHeader.(fnames{j});
    end
    fnames = fieldnames(colData);
    for j=1:length(fnames)
        columns(i).(fnames{j}) = colData.(fnames{j});
    end
end

if(0)
    %% plot xy output
    figure(364);clf;hold on;
    for i=1:length(columns)
        pat = '*b';
        if(mod(i,2)==0)
            pat = '*r';
            plot(columns(i).xy(1,:),-columns(i).xy(2,:),pat)
        else
            plot(columns(i).xy(1,:),columns(i).xy(2,:),pat)
        end
    end
    title('xy- y in y direction is now with minus sign')
    legend('scanDir up','scanDir down')
    
    
    
    
    figure(36764);clf;hold on;
    for i=1:length(columns)
        pat = '*b';
        if(mod(i,2)==0)
            pat = '*r';
            plot(columns(i).xy(1,:),columns(i).xy(2,:),pat)
        else
            plot(columns(i).xy(1,:),columns(i).xy(2,:),pat)
        end
    end
    title('xy')
    legend('scanDir up','scanDir down')
    
    
    t=double([columns.ts])/8e9;
    xy = [columns.xy];
    
    figure(3673);clf;
    plot(t,xy(1,:),'*');
    title('x')
    
    figure(39673);clf;
    plot(t,xy(2,:),'*');
    title('y')
    
        figure(253243);clf;
            hloc = [columns.verticalLocation];
        plot(hloc,'*');
    
            figure(2538243);clf;
            hloc = [columns.horizontalLocation];
        plot(hloc);
end

%% data check
anoimalyChk = @(x) any(min(x)<mean(x)-5*std(x));
if(anoimalyChk(double([columns.vSyncDelay])))
    error('readRawframe error: bad  vSyncDelay data in file %s',fn);
end
if(anoimalyChk(double([columns.txSyncDelay])))
    error('readRawframe error: bad  txSyncDelay data in file %s',fn);
end
if(anoimalyChk(diff(double([columns.timestamp]))))
    error('readRawframe error: bad  timestamp data in file %s',fn);
end

end

% % % function x = int14saturation(x)
% % % 
% % % % x(x>2^11-1) = 2^11-1;
% % % % x(x<-2^11) = -2^11;
% % % x(x>2^14-1) = 2^14-1;
% % % x(x<0) = 0;
% % % x = int16(x);
% % % end

function bi = uint82bin(i)
i = vec(i);

bi = bitand(i,uint8(2.^(7:-1:0)))./uint8(2.^(7:-1:0)) == 1;

bi = vec(fliplr(bi)');
end



