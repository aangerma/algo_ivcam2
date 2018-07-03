%%
clear;
r = @(vmid,vpret) (rand*2-1)*vpret+vmid;
regs.FRMW.projectionYshear=single(0);
regs.FRMW.xres=uint16(640);
regs.FRMW.yres=uint16(480);
regs.DEST.baseline=single(30);


regs.FRMW.xfov=r(72,0);
regs.FRMW.yfov=r(56,0);
regs.FRMW.laserangleH=r(1,0);
regs.FRMW.laserangleV=r(-0.5,0);
tau=r(10,0);

targetVector=[1;0;1]*400;

v={};
%%
targetVector=normc([rand(2,1);5])*400;
for i=1:30
    %%
rng(i);
regs.FRMW.xfov=r(72,5);
regs.FRMW.yfov=r(56,5);
regs.FRMW.laserangleH=r(0,0.1);
regs.FRMW.laserangleV=r(0,0.1);
tau=r(0,50);
thO = [tau regs.FRMW.xfov regs.FRMW.yfov regs.FRMW.laserangleH regs.FRMW.laserangleV]';
 

% targetVector=[0;0;1]*400;
[im,rxy,k]=genImgs(regs,targetVector,tau);
imagesc(im);axis image;drawnow;
[thX,v{i}]=calibrateDFZ(rxy);


% 
% fprintf('-----------------------\n');
% fprintf('% 7.3f ',thO);fprintf('\n');
 fprintf('% 7.3f ',thX-thO);fprintf('\n');
% fprintf('% 6.1f%% ',abs(thX-thO)./abs(thO)*100);fprintf('\n');
end

%%
N=30;
im={};rxy={};
for i=1:N
%%
targetVector = 500*normc([randn(2,1)*0.5;1]);
[im{i},rxy{i},k]=genImgs(regs,targetVector );
imagesc(im{i});axis image
% imwrite(im{i},sprintf('%04d.png',i));
drawnow;
end


%%

regs.FRMW.xfov=55+rand*20;
regs.FRMW.yfov=45+rand*20;
regs.FRMW.laserangleH=(rand*2-1)*5;
regs.FRMW.laserangleV=(rand*2-1)*5;


[im,rxy,k]=genImgs(regs,targetVector,tau);


thX=calibrateDFZ(rxy);


fprintf('-----------------------\n');
fprintf('% 7.3f ',thO);fprintf('\n');
fprintf('% 7.3f ',thX);fprintf('\n');
fprintf('% 6.1f%% ',abs(thX-thO)./abs(thO)*100);fprintf('\n');