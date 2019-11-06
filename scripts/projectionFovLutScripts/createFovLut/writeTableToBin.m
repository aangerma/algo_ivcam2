function []=writeTableToBin(vshFull, path)
%% remove zeros from vector
% remove each 4's line
shrinkedV=vshFull; shrinkedV(4:4:end,:)=[];

%% file size
fileSize=4080 ;%bytes
dec=uint32(hex2dec(shrinkedV));
dec8=typecast(dec,'uint8');
% remove 0 at the end
byteNum=12240;
dec8=dec8(1:byteNum);
%%
lutName={'Lut1','Lut2','Lut3'};
for i=1:3
    fname=[path,'\',lutName{i},'.bin'];
    writeAllBytes(dec8((i-1)*fileSize+1:i*fileSize),fname);
end
end