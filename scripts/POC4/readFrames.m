function colsOut = readFrames(inputDir)

colsOut = cell(0);

filesStruct.fns = sort(dirRecursive(inputDir,'Frame_*.bin'));

fDir = cellfun(@(x) dir(x), filesStruct.fns);
filesStruct.fSz = [fDir.bytes];
filesStruct.ptr = 0;
filesStruct.fileNum = 1;
filesStruct.fid = fopen(filesStruct.fns{filesStruct.fileNum},'r');

try
    while true
        [frameHeader,filesStruct] = getFrameHeader(filesStruct);
        [columns,filesStruct] = readOneFrame(filesStruct,frameHeader);
        colsOut = [colsOut; {columns}];
    end
catch e
    1
end


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

[raw,filesStruct] = getConcatData(filesStruct,FRAME_HEADER_SZ_BYTES);

if(raw(1) == 0)%frame header first byte ~= 0
    [raw,filesStruct] = zeroPadCropping(raw,filesStruct,FRAME_HEADER_SZ_BYTES);
end


% fprintf('end getFrameHeader : ptr is %d, fileNum is %d\n',filesStruct.ptr,filesStruct.fileNum)


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

function [raw,filesStruct] = zeroPadCropping(raw,filesStruct,dataSz)
%discard zero padding at the end of each col

ind = find(raw~=0,1);
while(isempty(ind))
    [raw,filesStruct] = getConcatData(filesStruct,dataSz);
    ind = find(raw~=0,1);
end
[rawTmp,filesStruct] = getConcatData(filesStruct,ind-1);
raw(1:ind-1) = [];
raw = [raw;rawTmp];


end


function [colHeader,filesStruct] = getColumnHeader(filesStruct,numCol)

COLUMN_HEADER_SZ_BYTES = 32;

[rawBefore,filesStruct] = getConcatData(filesStruct,COLUMN_HEADER_SZ_BYTES);

if(rawBefore(1) == 0)%column header first byte ~= 0
    [raw,filesStruct] = zeroPadCropping(rawBefore,filesStruct,COLUMN_HEADER_SZ_BYTES);
else
    raw = rawBefore;
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

colHeader.horizontalLocation=int14saturation(typecast(raw(OFFSET+(3:6)),'int32'));
colHeader.verticalLocation=int14saturation(typecast(raw(OFFSET+(7:10)),'int32'));

colHeader.txSyncDelay=typecast(raw(OFFSET+(11:12)),'uint16');
colHeader.columnLength=typecast(raw(OFFSET+(13:14)),'uint16');
colHeader.info=raw(OFFSET+15);
colHeader.scanDir=bitand(colHeader.info,uint8(1));
colHeader.data=raw(OFFSET+(16:24));
colHeader.timestamp=bitand(bitshift(typecast([raw(OFFSET+(25:29));0;0;0],'uint64'),-4),uint64(2^32-1))*4;
colHeader.vSyncDelay=bitand(bitshift(typecast([raw(OFFSET+(29:31));0;],'uint32'),-4),uint32(2^20-1))*4;
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


%column packets- data
rawColMat = reshape(rawCol,double(colHeader.sizeOfPacket),[]);

slow=rawColMat(1:3,:);
slow = typecast(vec([slow;zeros(1,size(slow,2))]),'uint32');
slow=vec([bitand(slow,uint32(2^12-1)) bitshift(slow,-12)]');
slow = 2^12-1-slow;
slow=min(2^12-1,uint16(interp1(0:length(slow)-1,double(slow),0:0.5:length(slow)-0.5,'linear','extrap'))');

fast=rawColMat(4:35,:);


% fast = vec((fliplr(dec2bin(fast)))')=='1';
fast = uint82bin(fast);


colData.slow = slow;
colData.fast = fast;

assert(length(slow)==length(fast)/64);

%column packets- location
locOffset=rawColMat(36,:);
colData.projectionFlag = logical(bitand(locOffset,uint8(1)));

offsetHperPacket = double(bitshift(bitand(locOffset,uint8(6)),-1));
offsetH = int16(cumsum(offsetHperPacket));

offsetVperPacket = ((double(colHeader.scanDir)*2-1)*-1) *double(bitshift(bitand(locOffset,uint8(2^8-1-7)),-3));
offsetV = int16(cumsum(offsetVperPacket));

x = int14saturation(colHeader.horizontalLocation+offsetH*4);
y = int14saturation(colHeader.verticalLocation+offsetV*4);
colData.xy = [x; y];

end




function [columns,filesStruct] = readOneFrame(filesStruct,frameHeader)

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
    figure(363);clf;
    xy = [columns.xy];
    plot(xy(1,:),xy(2,:),'*');
  title('xy')
    
    
        figure(3673);clf;
    xy = [columns.xy];
    plot(xy(1,:),'*');
    title('x')
    
            figure(39673);clf;
    xy = [columns.xy];
    plot(xy(2,:),'*');
    title('y')
    
%     figure(253243);clf;
%         hloc = [columns.verticalLocation];
%     plot(hloc,'*');
%    
%         figure(2538243);clf;
%         hloc = [columns.horizontalLocation];
%     plot(hloc);
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

%% vector concatination

for i=1:length(columns)
    %move vSyncDelay so it should be a divison of 64
    vsyncOffset = mod(double(columns(i).vSyncDelay)-double(columns(i).txSyncDelay),64);
    vsyncOffset(vsyncOffset>31)=-64+vsyncOffset(vsyncOffset>31);
    columns(i).vSyncDelay = columns(i).vSyncDelay - vsyncOffset;
end

for i=1:length(columns)
    if(i==length(columns))
        %          nFastBits=length(columns(i).fast)+uint64(columns(i  ).txSyncDelay)+64-mod(uint64(columns(i  ).txSyncDelay),64);
        nFastBits=length(columns(i).fast)+uint64(columns(i).vSyncDelay)+64-mod(uint64(columns(i).vSyncDelay),64);
    else
        %         nFastBits = columns(i+1).timestamp*4-uint64(columns(i+1).txSyncDelay) -(columns(i  ).timestamp*4-uint64(columns(i  ).txSyncDelay));
        nFastBits = columns(i+1).timestamp-uint64(columns(i+1).vSyncDelay) -...
           (columns(i).timestamp-uint64(columns(i).vSyncDelay));
    end
    if(nFastBits==0)
        break;
    end
    assert(rem(nFastBits,64)==0)
    nSlowBits     =nFastBits/64;
    
    %      nFastBitsPre = columns(i  ).txSyncDelay;
    nFastBitsPre = columns(i).vSyncDelay;
    nFastBitsPost = nFastBits-uint64(nFastBitsPre)-length(columns(i).fast);
    columns(i).fast = [false(nFastBitsPre,1);columns(i).fast;false(nFastBitsPost,1)];
    
    
    
    
    %      nSlowBitsPre = round(double(columns(i  ).txSyncDelay)/64);
    nSlowBitsPre = round(double(columns(i).vSyncDelay)/64);
    nSlowBitpost = nSlowBits-nSlowBitsPre-length(columns(i).slow);
    
    ld_on =[zeros(nSlowBitsPre,1,'uint8');ones(length(columns(i).slow),1,'uint8');zeros(nSlowBitpost,1,'uint8')];
    
    columns(i).slow = [zeros(nSlowBitsPre,1,'uint16');columns(i).slow;zeros(nSlowBitpost,1,'uint16')];
    
    tx_code_start = zeros(nSlowBits,1,'uint8');
    txStartLoc = (double(columns(i).vSyncDelay)-double(columns(i).txSyncDelay))/64+1;
    tx_code_start(txStartLoc)=true;
    scan_dir = columns(i).scanDir;
    %scan_dir=0 --> scan up
    xyPre  = int16([double(columns(i).xy(1,1));double(columns(i).xy(2,1))+(double(scan_dir(1))*2-1)]);
    xyPost = int16([double(columns(i).xy(1,end));double(columns(i).xy(2,end))-(double(scan_dir(1))*2-1)]);
    columns(i).xy = [xyPre(:,ones(1,nSlowBitsPre)) columns(i).xy xyPost(:,ones(1,nSlowBitpost))];
    
    %flags
    ld_on_bit = 1; %starting from 1...
    tx_code_start_bit = 2;
    scan_dir_bit = 3;
    
    columns(i).flags = bitshift(ld_on        ,ld_on_bit-1)+...
        bitshift(tx_code_start,tx_code_start_bit-1)+...
        bitshift(scan_dir     ,scan_dir_bit-1);
end
for i=1:length(columns)
    columns(i).fast=columns(i).fast';
    columns(i).slow=columns(i).slow';
    columns(i).flags=columns(i).flags';
end

flag_scan_dir=bitget([columns.flags],scan_dir_bit);
if(length(unique(flag_scan_dir))==1)
    for i=1:length(columns)
        
        columns(i).flags=bitset([columns(i).flags],scan_dir_bit,mod(i,2));
    end
end

end

function x = int14saturation(x)

% x(x>2^11-1) = 2^11-1;
% x(x<-2^11) = -2^11;
x(x>2^14-1) = 2^14-1;
x(x<0) = 0;
x = int16(x);
end

function bi = uint82bin(i)

% i = uint8(i);
i = vec(i);

bi = bitand(i,uint8(2.^(7:-1:0)))./uint8(2.^(7:-1:0)) == 1;

bi = vec(fliplr(bi)');
end



