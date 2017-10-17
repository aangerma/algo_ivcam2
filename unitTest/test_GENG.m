clear 
fw = Firmware();

regs.FRMW.projectionYshear =single(0);
regs.DIGG.undistBypass=false;
regs.FRMW.laserangleH = single(0);
regs.FRMW.laserangleV = single(0);
regs.FRMW.marginT=int16(0);
regs.FRMW.marginB=int16(0);
regs.FRMW.marginL=int16(0);
regs.FRMW.marginR=int16(0);

regs.FRMW.xR2L=false;


regs.FRMW.xres = uint16(640);
regs.FRMW.yres = uint16(480);

fw.setRegs(regs,'struct');
[regs,luts] = fw.get();

%%
SIM_dt = 128*1e-9;%nsec;
SIM_FPS = 60;
SIM_fastMirrorFreq=20e3;
SIM_t = (0:SIM_dt:1/SIM_FPS)';
angy =  -(regs.FRMW.yfov/2)/2*cos(2*pi*SIM_t*SIM_fastMirrorFreq); %fast
angx  =  atand(tand(regs.FRMW.xfov/2) * (2 * SIM_FPS * SIM_t-1))/2; %slow – tan
angy  = angy+angx*regs.FRMW.projectionYshear;



%12bit signed
 angxQ = int16(angx/(regs.FRMW.xfov/2*.5)*(2^11-1));
 angyQ = int16(angy/(regs.FRMW.yfov/2*.5)*(2^11-1));
%%

[xy,frame_startend] = Pipe.DIGG.GENG([angxQ,angyQ]',vec(gradient(angy)>0)',regs,luts,Logger(),[]);
frame_startend = [find(frame_startend,1,'first') find(frame_startend,1,'last')];
xy(1,:)=double(xy(1,:))/4;
 ldon = xy(1,:)>0 & xy(1,:)<=regs.FRMW.xres & xy(2,:)>0 & xy(2,:)<=regs.FRMW.yres;
 plot(xy(1,:),xy(2,:),'.-',xy(1,ldon),xy(2,ldon),'.');
 hold on;
 plot(xy(1,frame_startend),xy(2,frame_startend),'g.','markersize',30);
 hold off
view(0,-90);
camroll(atand(regs.FRMW.projectionYshear))
axis equal;
% legend('MEMS FOV','Projected FOV','frame start/end');