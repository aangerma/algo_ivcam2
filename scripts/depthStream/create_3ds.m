clear all;
rng(1);
w=640;h=480;
k=[w/2 0 w/2; 0 h/2 h/2;0 0 1];
z2mm=uint8(8);
N=360;
fps = 30;%hz
fid = fopen('stream.3ds','w');
header=zeros(1,1024,'uint8');
header(1:4)='.3ds';
header(5:8)=typecast(uint32(1),'uint8');
header(9:12)=typecast(single(z2mm),'uint8');
header(13:16)=typecast(uint16([w h]),'uint8');
header(17:52)=typecast(vec(single(k)'),'uint8');
header(53:56)=typecast(single(fps),'uint8');

fwrite(fid,header,'uint8');
[verts_,tri]=icosphere(1);
a=rand(size(tri,1),1)*.3+.7;


for T=1:N

R=rotation_matrix(sin(T/120*2*pi)*pi/2,cos(T/360*2*pi)*pi/2,sin(T/180*2*pi).^2*pi/2);

verts=verts_*600;
verts=verts*R;
verts(:,3)=verts(:,3)+1000;
verts(:,1)=verts(:,1)+eps;

[v,u]=ndgrid(0:h-1,0:w-1);

r=normc(k^-1*[u(:) v(:) ones(numel(v),1)]');
[dd,i]=Simulator.aux.raytrace2d(tri,verts,a,r',zeros(3,1));
r=r.*dd(:,1)';
%
% trisurf(t,verts(:,1),verts(:,2),verts(:,3));
% hold on;plot3(r(1,:),r(2,:),r(3,:),'.');hold off;
% axis equal

dd(isinf(dd(:,1)),1)=0;
d.z=uint16(round(reshape(dd(:,1),h,w)))*uint16(z2mm);

d.i=uint8(round(255*reshape(i,h,w)));

zidata=typecast([vec(uint16(d.z)');vec(uint16(d.i)');],'uint8');
frameheader=uint8(0:255);
fwrite(fid,frameheader,'uint8');
fwrite(fid,zidata,'uint8');



subplot(121);imagesc(d.z);axis image;colorbar;subplot(122);imagesc(d.i);axis image
drawnow;
colormap gray;
end
fclose(fid);
%

return

%%
% hw=HWinterface;
% d = hw.getFrame;
% k=reshape([typecast(hw.read('CBUFspare'),'single');1],3,3)';
% z2mm=uint8(2^double(hw.read('GNRLzMaxSubMMExp')));

z2mm=uint8(8);
d.z=ones(480,640,'uint16')*800 +uint16(0:639);
d.i=uint8(reshape(mod(0:640*480-1,256),640,480)');
k = single([320 0 320;0 240 240; 0 0 1]);


%%

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
