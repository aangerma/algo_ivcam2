%  clear
[t0,dt,vn_]=io.POC.readScopeHDF5data('D:\ohad\data\lidar\EXP\20150622_noise\000_fluorescent.h5',2);
[t0,dt,vs_]=io.POC.readScopeHDF5data('D:\ohad\data\lidar\EXP\20150614_RF\040_no_scan.h5',2);
 p = xml2structWrapper('D:\ohad\data\lidar\simulatorParams\params_1550POC.xml');

 
 nnn = 9e4+(1:3e5);
 vn = vn_(nnn);
 vs = vs_(nnn);
 
%  nnAV= 0e5+(1:130*1e4);
% tAV = (1:130)*dt;
% II = reshape(vs_(nnAV),130,[]);
% vsAV = mean(II,2);
% vsSTD = std(II,1,2);
GAMMA = 32e-6;



% t = (0:length(vn)-1)*dt;

%std(vn)/mean(abs(vn))==sqrt(pi/2)

%%
s0 = @(s,a) s;
s1 = @(s,a) sqrt(s.^2+GAMMA^2*a.^2);
u0 = @(s,a) -0.5*GAMMA*a;
u1 = @(s,a) 0.5*GAMMA*a;
meanFGD = @(s,u) s*sqrt(2/pi).*exp(-u.^2*0.5./s.^2)+u.*(1-2*phi(-u./s));
M1analytic = @(s,a) 0.5*meanFGD(s0(s,a),u0(s,a))+0.5*meanFGD(s1(s,a),u1(s,a));
%fsolve(@(x) M1analytic(sigN,x),0)




%% SLOW CHANNEL SIMULATION
 %%%
dtSlowChannel = 100e-9;
Tslw = round(dtSlowChannel/dt)*dt;
slowChanCutoff = 1/Tslw;%[ghz]
[b,a]=butter(1,slowChanCutoff/(0.5/dt),'low');

vnS = filter(b,a,abs(vn));
vsS = filter(b,a,abs(vs));
slowChanD = Tslw/dt;
vnS = vnS(slowChanD+1:slowChanD:end);
vsS = vsS(slowChanD+1:slowChanD:end);
tS = (0:length(vsS)-1)*Tslw;
sigN_eval = mean(vnS)*sqrt(pi/2);
a = arrayfun(@(x) mysolve(@(x) M1analytic(sigN_eval,x),x,0,1e6,1e-6),vsS);
PSNR_eval = a*GAMMA./sqrt(sigN_eval^2+GAMMA^2*a);
plot(1:length(PSNR_eval),PSNR_eval);

 

% 
%sigS=prctile(vnS,50)*sqrt(pi/2);




