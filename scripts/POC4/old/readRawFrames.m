function frames=readRawFrames(inputHandle,varargin)
p=inputParser;

p.addOptional('sampledTemplateSize',64,@(x) isnumeric(x));
p.addOptional('nframes',1e6,@(x) isnumeric(x));
p.addOptional('verbose',true,@(x) islogical(x));
p.parse(varargin{:});
args=p.Results;


if(isdir(inputHandle))
    ff = dirFiles([inputHandle filesep] ,'*.bin');
    raw = cellfun(@(x) readDataByte(x),ff,'uni',0);
    raw=vec([raw{:}]);
elseif(isnumeric(inputHandle))
    raw=fread(args.InputHandle,'uint8');
end

%%
fpA=1;


dataBlockSize=[];
for i=1:args.nframes
    [frames(i),fpB]=readFrame(raw,fpA,args.sampledTemplateSize);%#ok
    if(args.verbose)
        fprintf('%3d (timestamp %d #cols:%d)  %4.1f%%\n',i,frames(i).header.timestamp,frames(i).header.numOfColumns,round(fpB/length(raw)*1000)/10);
    end
    fpB = fpB+find(raw(fpB:end)~=0,1)-1;
    if(isempty(dataBlockSize))
        dataBlockSize=fpB-fpA;
    else
        if(fpB-fpA~=dataBlockSize)
            error('inconsistent data block size');
        end
    end
    
    if(fpB+dataBlockSize>length(raw))
        break;
    end
    fpA=fpB;
    
    i=i+1;
end
% fast = cellfun(@(x) x' ,{frame.columns.fast},'uni',0);
% slow = cellfun(@(x) x' ,{frame.columns.slow},'uni',0);
% flags = cellfun(@(x) x' ,{frame.columns.flags},'uni',0);
% xy    = cellfun(@(x) x ,{frame.columns.xy},'uni',0);
% ivs.fast=[fast{:}];
% ivs.slow=[slow{:}];
% ivs.flags=[flags{:}];
% ivs.xy=[xy{:}];
% vsync = [frame.columns.verticalLocation];
end

function [frame,fp]=readFrame(raw,fp,sampledTemplateSize)
%
frame.header.rawFormat = bitand(raw(fp+0),uint8(15));
frame.header.locationFormat = bitshift(raw(fp+0),-4);
frame.header.info = typecast(raw(fp+(1:2)),'uint16');
frame.header.numOfColumns = typecast(raw(fp+(3:4)),'uint16');
frame.header.frameCounter = typecast(raw(fp+(5:6)),'uint16');
frame.header.MIPIDispatcherPointer = raw(fp+7);
frame.header.timestamp=typecast(raw(fp+(8:11)),'uint32');
frame.header.reserved=raw(fp+(12:31));

%%
fp = fp+32;

for i=1:frame.header.numOfColumns
    [col,fp]=readColumn(raw,fp,i,sampledTemplateSize);
    frame.columns(i)=col;
    if(i~=1)
        deltaTxSyncDelay = frame.columns(i).timestamp-uint64(frame.columns(i).txSyncDelay) -(frame.columns(i-1).timestamp-uint64(frame.columns(i-1).txSyncDelay));
        assert(rem(deltaTxSyncDelay,64)==0,'deltaTxSyncDelay should divide by 64(got %d)',mod(deltaTxSyncDelay,64));
    end
end

%% vector concatination

for i=1:length(frame.columns)
    if(i==length(frame.columns))
        %          nFastBits=length(frame.columns(i).fast)+uint64(frame.columns(i  ).txSyncDelay)+64-mod(uint64(frame.columns(i  ).txSyncDelay),64);
        nFastBits=length(frame.columns(i).fast)+uint64(frame.columns(i  ).vSyncDelay)+64-mod(uint64(frame.columns(i  ).vSyncDelay),64);
    else
        %         nFastBits = frame.columns(i+1).timestamp*4-uint64(frame.columns(i+1).txSyncDelay) -(frame.columns(i  ).timestamp*4-uint64(frame.columns(i  ).txSyncDelay));
        nFastBits = frame.columns(i+1).timestamp-uint64(frame.columns(i+1).vSyncDelay) -...
            (frame.columns(i  ).timestamp-uint64(frame.columns(i  ).vSyncDelay));
    end
    assert(rem(nFastBits,64)==0)
    nSlowBits     =nFastBits/64;
    
    %      nFastBitsPre = frame.columns(i  ).txSyncDelay;
    nFastBitsPre = frame.columns(i  ).vSyncDelay;
    nFastBitsPost = nFastBits-uint64(nFastBitsPre)-length(frame.columns(i).fast);
    frame.columns(i).fast = [false(nFastBitsPre,1);frame.columns(i).fast;false(nFastBitsPost,1)];
    
    
    
    
    %      nSlowBitsPre = round(double(frame.columns(i  ).txSyncDelay)/64);
    nSlowBitsPre = round(double(frame.columns(i  ).vSyncDelay)/64);
    nSlowBitpost = nSlowBits-nSlowBitsPre-length(frame.columns(i).slow);
    
    ld_on =[zeros(nSlowBitsPre,1,'uint8');ones(length(frame.columns(i).slow),1,'uint8');zeros(nSlowBitpost,1,'uint8')];
    
    frame.columns(i).slow = [zeros(nSlowBitsPre,1,'uint16');frame.columns(i).slow;zeros(nSlowBitpost,1,'uint16')];
    
    tx_code_start = zeros(nSlowBits,1,'uint8');
    txStartLoc = (double(frame.columns(i).vSyncDelay)-double(frame.columns(i).txSyncDelay))/64+1;
    tx_code_start(txStartLoc)=true;
    sd = bitand(frame.columns(i).info,uint8(1));
    scan_dir = zeros(nSlowBits,1,'uint8')*sd;
    %scan_dir=0 --> scan up
    xyPre  = int16([double(frame.columns(i).xy(1,1  ));double(frame.columns(i).xy(2,1  ))+(double(sd)*2-1)]);
    xyPost = int16([double(frame.columns(i).xy(1,end));double(frame.columns(i).xy(2,end))-(double(sd)*2-1)]);
    frame.columns(i).xy = [xyPre(:,ones(1,nSlowBitsPre)) frame.columns(i).xy xyPost(:,ones(1,nSlowBitpost))];
    
    frame.columns(i).flags = bitshift(ld_on        ,0)+...
        bitshift(tx_code_start,1)+...
        bitshift(scan_dir     ,2);
end
for i=1:length(frame.columns)
    frame.columns(i).fast=frame.columns(i).fast';
    frame.columns(i).slow=frame.columns(i).slow';
    frame.columns(i).flags=frame.columns(i).flags';
end
flag_scan_dir=bitget([frame.columns.flags],4);
if(length(unique(flag_scan_dir))==1)
    for i=1:length(frame.columns)
        
        frame.columns(i).flags=bitset([frame.columns(i).flags],4,mod(i,2));
    end
end

end

function [col,fp]=readColumn(raw,fp,i,sampledTemplateSize)
%     struct ColumnHeader
% {
% 	UINT16		     number_of_packet; //bytes 0 1
% 	byte		     sizeOfPacket;	//bytes 2
% 	UINT32		     horizontalLocation; //bytes 3-6
% 	UINT32		     verticalLocation; //bytes 7-10
% 	UINT16		     txSyncDelay; //bytes 11 12
% 	UINT16		     columnLength;  //bytes 13 14
% 	Info			 info; //byte 15
% 	byte		     data[9]; //byte 16-24
% 	byte		     timestamp[5]; //byte 25-29
% 	byte		     reserved[2]; //byte 30-31
% 	// 204- 235
%
% 	/*Info		     info;
% 	FreqCompensation freqCompensation;
% 	LocCorrection    locCorrection;
% 	UINT32		     horizontalTimeFromHsync;
% 	UINT32		     verticalTimeFromHsync : 20;*/
% };
col.number_of_packet=typecast(raw(fp+(0:1)),'uint16');
col.sizeOfPacket=raw(fp+2);
col.horizontalLocation=typecast(raw(fp+(3:6)),'uint32');
col.verticalLocation=typecast(raw(fp+(7:10)),'uint32');
col.txSyncDelay=typecast(raw(fp+(11:12)),'uint16');
col.columnLength=typecast(raw(fp+(13:14)),'uint16');
col.info=raw(fp+15);
col.data=raw(fp+(16:24));
col.timestamp=bitand(bitshift(typecast([raw(fp+(25:29));0;0;0],'uint64'),-4),uint64(2^32-1))*4;
col.vSyncDelay=bitand(bitshift(typecast([raw(fp+(29:31));0;],'uint32'),-4),uint32(2^20-1))*4;
col.reserved=raw(fp+(30:31));
fp =fp+32;
if(double(col.columnLength)==0)
    error('bad file: column length==0');
end
if(double(col.sizeOfPacket)~=36)
    error('Bad column: col.sizeOfPacket==%d',col.sizeOfPacket);
    %         fp = fp+double(col.columnLength)*32;
    %         continue;
end
len = double(col.number_of_packet)*double(col.sizeOfPacket);
colraw = raw(fp+ (0:len-1));
colraw = reshape(colraw,double(col.sizeOfPacket),[]);
slow=colraw(1:3,:);
slow = typecast(vec([slow;zeros(1,size(slow,2))]),'uint32');
slow=vec([bitand(slow,uint32(2^12-1)) bitshift(slow,-12)]');
slow = 2^12-1-slow;
slow=min(2^12-1,uint16(interp1(0:length(slow)-1,double(slow),0:0.5:length(slow)-0.5,'linear','extrap'))');

fast=colraw(4:35,:);
fast = vec((fliplr(dec2bin(fast)))')=='1';

col.slow = slow;
col.fast = fast;

%fake location
x = ones(1,length(slow),'int16')*int16(i-1)*4;
y = int16(floor((0:length(slow)-1)/(sampledTemplateSize/64)));
col.xy = [x;y];

assert(length(slow)==length(fast)/64);

%move vSyncDelay so it should be a divison of 64
vsyncOffset = mod(double(col.vSyncDelay)-double(col.txSyncDelay),64);
vsyncOffset(vsyncOffset>31)=-64+vsyncOffset(vsyncOffset>31);
col.vsyncOffset=vsyncOffset;
col.vSyncDelay = col.vSyncDelay - vsyncOffset;





fp = fp+double(col.columnLength)*32;
end


function raw = readDataByte(fn)
fid = fopen(fn,'r');
raw = uint8(fread(fid,'uint8'));
fclose(fid);
end