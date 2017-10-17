function [columns,frameHeader]=readRawframe(fn,sampledTemplateSize)
if(~exist('sampledTemplateSize','var'))
    sampledTemplateSize=64;%used to calc fake location;
end
fid = fopen(fn,'r');
raw = uint8(fread(fid,'uint8'));
fclose(fid);

%%
%%
frameHeader.rawFormat = bitand(raw(1),uint8(15));
frameHeader.locationFormat = bitshift(raw(1),-4);
frameHeader.info = typecast(raw(2:3),'uint16');
frameHeader.numOfColumns = typecast(raw(4:5),'uint16');
frameHeader.frameCounter = typecast(raw(6:7),'uint16');
frameHeader.MIPIDispatcherPointer = raw(8);
frameHeader.timestamp=typecast(raw(9:12),'uint32');
frameHeader.reserved=raw(13:32);
columns=struct();
%%
cnt = 33;
for i=1:frameHeader.numOfColumns
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
    columns(i).number_of_packet=typecast(raw(cnt+(0:1)),'uint16');
    columns(i).sizeOfPacket=raw(cnt+2);
    columns(i).horizontalLocation=typecast(raw(cnt+(3:6)),'uint32');
    columns(i).verticalLocation=typecast(raw(cnt+(7:10)),'uint32');
    columns(i).txSyncDelay=typecast(raw(cnt+(11:12)),'uint16');
    columns(i).columnLength=typecast(raw(cnt+(13:14)),'uint16');
    columns(i).info=raw(cnt+15);
    columns(i).data=raw(cnt+(16:24));
    columns(i).timestamp=bitand(bitshift(typecast([raw(cnt+(25:29));0;0;0],'uint64'),-4),uint64(2^32-1))*4;
    columns(i).vSyncDelay=bitand(bitshift(typecast([raw(cnt+(29:31));0;],'uint32'),-4),uint32(2^20-1))*4;
    columns(i).reserved=raw(cnt+(30:31));
    cnt =cnt+32;
    if(double(columns(i).columnLength)==0)
        error('readRawframe error: bad columnLength data in file %s',fn);
    end
    if(double(columns(i).sizeOfPacket)~=36)
        error('readRawframe error: bad  sizeOfPacket data in file %s',fn);

    end
    len = double(columns(i).number_of_packet)*double(columns(i).sizeOfPacket);
    colraw = raw(cnt+ (0:len-1));
    colraw = reshape(colraw,double(columns(i).sizeOfPacket),[]);
    slow=colraw(1:3,:);
    slow = typecast(vec([slow;zeros(1,size(slow,2))]),'uint32');
    slow=vec([bitand(slow,uint32(2^12-1)) bitshift(slow,-12)]');
     slow = 2^12-1-slow;
    slow=min(2^12-1,uint16(interp1(0:length(slow)-1,double(slow),0:0.5:length(slow)-0.5,'linear','extrap'))');
    
    fast=colraw(4:35,:);
    fast = vec((fliplr(dec2bin(fast)))')=='1';
    
    columns(i).slow = slow;
    columns(i).fast = fast;
    
    %fake location
    x = ones(1,length(slow),'int16')*int16(i-1)*4;
    y = int16(floor((0:length(slow)-1)/(sampledTemplateSize/64)));
    if(mod(i,2))
        y=fliplr(y);
    end
    columns(i).xy = [x;y];
    
    assert(length(slow)==length(fast)/64);
    
 
    

    
    
    cnt = cnt+double(columns(i).columnLength)*32;
    if(i~=1)
        deltaTxSyncDelay = columns(i).timestamp-uint64(columns(i).txSyncDelay) -(columns(i-1).timestamp-uint64(columns(i-1).txSyncDelay));
    assert(rem(deltaTxSyncDelay,64)==0,'deltaTxSyncDelay should divide by 64(got %d)',mod(deltaTxSyncDelay,64));
    end
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
        nFastBits=length(columns(i).fast)+uint64(columns(i  ).vSyncDelay)+64-mod(uint64(columns(i  ).vSyncDelay),64);
    else
        %         nFastBits = columns(i+1).timestamp*4-uint64(columns(i+1).txSyncDelay) -(columns(i  ).timestamp*4-uint64(columns(i  ).txSyncDelay));
        nFastBits = columns(i+1).timestamp-uint64(columns(i+1).vSyncDelay) -...
            (columns(i  ).timestamp-uint64(columns(i  ).vSyncDelay));
    end
    if(nFastBits==0)
        break;
    end
    assert(rem(nFastBits,64)==0)
    nSlowBits     =nFastBits/64;
    
    %      nFastBitsPre = columns(i  ).txSyncDelay;
    nFastBitsPre = columns(i  ).vSyncDelay;
    nFastBitsPost = nFastBits-uint64(nFastBitsPre)-length(columns(i).fast);
    columns(i).fast = [false(nFastBitsPre,1);columns(i).fast;false(nFastBitsPost,1)];
    
    
    
    
    %      nSlowBitsPre = round(double(columns(i  ).txSyncDelay)/64);
    nSlowBitsPre = round(double(columns(i  ).vSyncDelay)/64);
    nSlowBitpost = nSlowBits-nSlowBitsPre-length(columns(i).slow);
    
    ld_on =[zeros(nSlowBitsPre,1,'uint8');ones(length(columns(i).slow),1,'uint8');zeros(nSlowBitpost,1,'uint8')];
    
    columns(i).slow = [zeros(nSlowBitsPre,1,'uint16');columns(i).slow;zeros(nSlowBitpost,1,'uint16')];
    
    tx_code_start = zeros(nSlowBits,1,'uint8');
    txStartLoc = (double(columns(i).vSyncDelay)-double(columns(i).txSyncDelay))/64+1;
    tx_code_start(txStartLoc)=true;
    scan_dir = ones(nSlowBits,1,'uint8')*bitget(columns(i).info,1);
    %scan_dir=0 --> scan up
    xyPre  = int16([double(columns(i).xy(1,1  ));double(columns(i).xy(2,1  ))+(double(scan_dir(1))*2-1)]);
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

% fast = cellfun(@(x) x' ,{columns.fast},'uni',0);
% slow = cellfun(@(x) x' ,{columns.slow},'uni',0);
% flags = cellfun(@(x) x' ,{columns.flags},'uni',0);
% xy    = cellfun(@(x) x ,{columns.xy},'uni',0);
% ivs.fast=[fast{:}];
% ivs.slow=[slow{:}];
% ivs.flags=[flags{:}];
% ivs.xy=[xy{:}];
% vsync = [columns.verticalLocation];
end