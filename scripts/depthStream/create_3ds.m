% hw=HWinterface;
% d = hw.getFrame;
% k=reshape([typecast(hw.read('CBUFspare'),'single');1],3,3)';
% z2mm=uint8(2^double(hw.read('GNRLzMaxSubMMExp')));

z2mm=uint8(8);
d.z=ones(480,640,'uint16')*800 +uint16(0:639);
d.i=uint8(reshape(mod(0:640*480-1,256),640,480)');
k = single([320 0 320;0 240 240; 0 0 1]);
fid = fopen('stream.3ds','w');

header=zeros(1,1024,'uint8');
header(1:4)='.3ds';
header(5:8)=typecast(uint32(1),'uint8');
header(9:12)=typecast(single(z2mm),'uint8');

header(13:16)=typecast(uint16([size(d.i,2) size(d.i,1)]),'uint8');
header(17:52)=typecast(vec(k'),'uint8');
fwrite(fid,header,'uint8');
zidata=typecast(vec([vec(uint16(d.z)') vec(uint16(d.i)');]'),'uint8');
fwrite(fid,zidata,'uint8');
fclose(fid);
%
%  d=io.readZIC(fldr);
% 
% c=[];
% c(end+1)=fwrite(fid,'3ds');
% c(end+1)=fwrite(fid,uint32(length(d)),'uint32');%#frames
% c(end+1)=fwrite(fid,uint16(30),'uint8');%fps
% c(end+1)=fwrite(fid,uint16(size(d(1).z,2)),'uint8');%width
% c(end+1)=fwrite(fid,uint16(size(d(1).z,1)),'uint8');%height
% c(end+1)=fwrite(fid,uint8(2),'uint8');%number of streams (max 16)
% c(end+1)=fwrite(fid,uint8(2),'uint8');% #1 steam Bpp
% c(end+1)=fwrite(fid,uint8(1),'uint8');% #2 steam Bpp
% c(end+1)=fwrite(fid,single(1/8),'uint32');% #1 steam scale
% c(end+1)=fwrite(fid,single(1)  ,'uint32');% #2 steam scale
% 
% c(end+1)=fwrite(fid,uint8(2),'uint8');% #1 steam type 0:X 1:Y 2:Z 3:R 4:G 5:B 6:IR 7:conf
% c(end+1)=fwrite(fid,uint8(6),'uint8');% #2 steam type 0:X 1:Y 2:Z 3:R 4:G 5:B 6:IR 7:conf
% 
% 
