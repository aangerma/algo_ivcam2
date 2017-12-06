function ivsArr = readFrames(varargin)
inputDir = varargin{1};

p = inputParser;
addOptional(p,'numFrames',2^31-1);
addOptional(p,'verbose',false);

parse(p,varargin{2:end});
p = p.Results;

logger=Logger(p.verbose);

if(isnumeric(inputDir))
    s = ArrayStream(inputDir);
else
    s = BinaryStream(inputDir);
end

ivsArr = [];
fhs=[];


for i=1:p.numFrames
    logger.print('Reading frame %d...',i);
    [ivs,frameHeader] = readOneFrame(s);
    if(isempty(ivs))
        break;
    end
    logger.print('done\n');
    ivsArr = [ivsArr; ivs];
    fhs=[fhs;frameHeader];
end

end



function [ivs,frameHeader] = readOneFrame(s)

[columns,frameHeader] = getFrameData(s);
if(isempty(columns))
    ivs=[];
else
    ivs.xy = [columns.xy];
    ivs.slow = [columns.slow];
    ivs.fast = [columns.fast];
    ivs.flags = [columns.flags];
end



end







function frameHeader = getFrameHeader(s)
frameHeader=[];
FRAME_HEADER_SZ_BYTES = 32;


[rawFH,ok]=s.get(FRAME_HEADER_SZ_BYTES-1);
rawFH=[0;rawFH];
if(~ok),return;end
while(true)
    [b,ok]=s.get(1);
    if(~ok),return;end
    rawFH=[rawFH(2:end);b];
    
    
    frameHeader.RawFormat = bitand(rawFH(1),uint8(15));
    frameHeader.locationFormat = bitshift(rawFH(1),-4);
    frameHeader.info = typecast(rawFH(2:3),'uint16');
    frameHeader.numOfColumns = typecast(rawFH(4:5),'uint16');
    frameHeader.frameCounter = typecast(rawFH(6:7),'uint16');
    frameHeader.MIPIDispatcherPointer = rawFH(8);
    frameHeader.timestamp=typecast(rawFH(9:12),'uint32');
    frameHeader.reserved=rawFH(13:32);
    
    if(all(frameHeader.info~=[16  17]))
        continue;
    end
    if(frameHeader.RawFormat~=3)
        continue;
    end
    if(frameHeader.numOfColumns==0 || frameHeader.numOfColumns>10e3)
        continue;
    end
    if(all(frameHeader.MIPIDispatcherPointer ~=[1 2 3 4]))
        continue;
    end
    if(any(frameHeader.reserved ~=0))
        continue;
    end
    break;
end






end


function colHeader = getHeader(s)
colHeader=[];
COLUMN_HEADER_SZ_BYTES = 32;


[rawCH,ok] = s.get(COLUMN_HEADER_SZ_BYTES-1);
rawCH=[0;rawCH];
if(~ok),return;end
OFFSET=1;
while(true)
    [b,ok]=s.get(1);
    if(~ok),return;end
    rawCH = [rawCH(2:end);b];
    
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
    
    
    colHeader.numPackets=typecast(rawCH(1+(0:1)),'uint16');
    colHeader.sizeOfPacket=rawCH(1+2);
    
    colHeader.horizontalLocation=int16(bitshift(typecast(rawCH(1+(3:6)),'int32'),-2)); %we get 14b but should get 12b
    colHeader.verticalLocation=int16(bitshift(typecast(rawCH(1+(7:10)),'int32'),-2));
    
    colHeader.txSyncDelay=typecast(rawCH(1+(11:12)),'uint16'); %in fast samples count
    colHeader.columnLength=typecast(rawCH(1+(13:14)),'uint16');
    colHeader.info=rawCH(1+15);
    colHeader.scanDir=bitand(colHeader.info,uint8(1));
    colHeader.data=rawCH(1+(16:24));
    colHeader.timestamp=bitand(bitshift(typecast([rawCH(1+(25:29));0;0;0],'uint64'),-4),uint64(2^32-1))*4;%*4 for it to be in fast samples count
    colHeader.vSyncDelay=bitand(bitshift(typecast([rawCH(1+(29:31));0;],'uint32'),-4),uint32(2^20-1))*4;%*4 for it to be in fast samples count
    colHeader.reserved=rawCH(1+(30:31));
    
    if(colHeader.sizeOfPacket~=36)
        continue;
    end
    if(colHeader.columnLength==0)
        continue;
    end
    break;
    
    
end


end





function colData = getScanline(s)
colData.header = getHeader(s);
colSz = double(colData.header.numPackets)*double(colData.header.sizeOfPacket);
[rawCol,ok] = s.get(colSz);
if(~ok),  colData=[];   return;end



%column packets- fast & slow
rawColMat = reshape(rawCol,double(colData.header.sizeOfPacket),[]);

slow=rawColMat(1:3,:);
slow = typecast(vec([slow;zeros(1,size(slow,2))]),'uint32');
slow=vec([bitand(slow,uint32(2^12-1)) bitshift(slow,-12)]');
if(round(double(colData.header.txSyncDelay)/64)>length(slow))
    error('txSyncDelay(%d) is bigger than data length(%d),cannot padd data.',round(double(colData.header.txSyncDelay)/64),length(slow));
end
fast=rawColMat(4:35,:);
fast = uint82bin(fast);



%column packets- location
locOffset=rawColMat(36,:);
colData.projectionFlag = bitget(locOffset,1);

hlocIndex=bitand(bitshift(locOffset,-1),uint8(3));

% assert(all(hlocIndex~=2),'Hloc index equal to 3');

hlocLUT = int16([0 1 0 -1]);
offsetH = hlocLUT(hlocIndex+1);
offsetH = cumsum(offsetH);

offsetV = -int16(bitshift(locOffset,-3))*(int16(colData.header.scanDir)*2-1);%scanDir: 1== down, 0==up
offsetV = cumsum(offsetV);

x = (colData.header.horizontalLocation+offsetH);
y = (colData.header.verticalLocation+offsetV);

%% aSync sim
y = y-int16(2048);
x = x-int16(2048);



slow=uint16(min(2^12-1,interp1((0:length(slow)-1)*2,double(slow),0:length(slow)*2-1,'linear','extrap')));
assert(length(slow)==length(fast)/64,'length(slow)~=length(fast)/64');

xy=int16(interp1((0:length(y)-1)*4,double([x;y]'),0:length(y)*4-1,'linear','extrap'))';

% padding due to txSyncDelay
txDelay_slowShift = round(double(colData.header.txSyncDelay)/64);
txDelay_fastShift = double(colData.header.txSyncDelay);
fast = [false(txDelay_fastShift,1);fast(1:end-txDelay_fastShift)];
slow = [zeros(1,txDelay_slowShift) slow(1:end-txDelay_slowShift)];
xy   = [ones(2,txDelay_slowShift,'int16').*xy(:,1)   xy(:,1:end-txDelay_slowShift)];


tx_code_start = [uint8(1); zeros(length(slow)-1,1,'uint8')];

scan_dir = colData.header.scanDir*ones(length(slow),1,'uint8');
ld_on = vec(repmat(uint8(colData.projectionFlag),4,1));

scan_dir=1-scan_dir; %?????????????????????????????????????????????????????????????????????????????????????




%% column struct
colData.slow = slow;
colData.fast = fast';
colData.xy = xy;

ld_on_bit = 1; %starting from 1...
tx_code_start_bit = 2;
scan_dir_bit = 3;
colData.flags =vec(...
    bitshift(ld_on         ,ld_on_bit-1)+...
    bitshift(tx_code_start ,tx_code_start_bit-1)+...
    bitshift(scan_dir      ,scan_dir_bit-1))';

end




function [columns,frameHeader] = getFrameData(s)

columns=[];
frameHeader = getFrameHeader(s);
%% columns
for i=1:frameHeader.numOfColumns
    ns=getScanline(s);
    if(isempty(ns)),columns=[];return; end
        
    columns =[columns ns];
end
%% padding
for i=1:frameHeader.numOfColumns-1
    nFast = columns(i+1).header.timestamp-columns(i).header.timestamp;
    assert(mod(nFast,64)==0,'Time between timestamps does not divide in 64');
    nSlow = nFast/64;
    columns(i).fast=[columns(i).fast false(1,nFast)]; %#ok<*AGROW>
    columns(i).slow=[columns(i).slow zeros(1,nSlow)];
    columns(i).flags=[columns(i).flags zeros(1,nSlow)];
    columns(i).xy=[columns(i).xy columns(i).xy(:,end).*ones(2,nSlow,'int16')];
end

if(0)
    %%
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
    
    
    t=(0:length([columns.slow])-1)/8e9;
    xy = [columns.xy];
    
    figure(3673);clf;
    plot(t,xy(1,:),'*');
    title('x')
    
    figure(39673);clf;
    plot(t,xy(2,:),'*');
    title('y')
    
    
end

%% data check
ch = [columns.header];
anoimalyChk = @(x) any(min(x)<mean(x)-5*std(x));
if(anoimalyChk(double([ch.vSyncDelay])))
    error('readRawframe error: bad  vSyncDelay data in file %s',fn);
end
if(anoimalyChk(double([ch.txSyncDelay])))
    error('readRawframe error: bad  txSyncDelay data in file %s',fn);
end
if(anoimalyChk(diff(double([ch.timestamp]))))
    error('readRawframe error: bad  timestamp data in file %s',fn);
end

end


function bi = uint82bin(i)
i = vec(i);

bi = bitand(i,uint8(2.^(7:-1:0)))./uint8(2.^(7:-1:0)) == 1;

bi = vec(fliplr(bi)');
end



