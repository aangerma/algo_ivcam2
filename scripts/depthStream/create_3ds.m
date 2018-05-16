fldr = 'd:\temp\ipdevCaptures2\';
d=io.readZIC(fldr);
fid = fopen(sprintf('%s/stream.3ds',fldr),'w');
c=[];
c(end+1)=fwrite(fid,'3ds');
c(end+1)=fwrite(fid,uint32(length(d)),'uint32');%#frames
c(end+1)=fwrite(fid,uint16(30),'uint8');%fps
c(end+1)=fwrite(fid,uint16(size(d(1).z,2)),'uint8');%width
c(end+1)=fwrite(fid,uint16(size(d(1).z,1)),'uint8');%height
c(end+1)=fwrite(fid,uint8(2),'uint8');%number of streams (max 16)
c(end+1)=fwrite(fid,uint8(2),'uint8');% #1 steam Bpp
c(end+1)=fwrite(fid,uint8(1),'uint8');% #2 steam Bpp
c(end+1)=fwrite(fid,single(1/8),'uint32');% #1 steam scale
c(end+1)=fwrite(fid,single(1)  ,'uint32');% #2 steam scale

c(end+1)=fwrite(fid,uint8(2),'uint8');% #1 steam type 0:X 1:Y 2:Z 3:R 4:G 5:B 6:IR 7:conf
c(end+1)=fwrite(fid,uint8(6),'uint8');% #2 steam type 0:X 1:Y 2:Z 3:R 4:G 5:B 6:IR 7:conf


