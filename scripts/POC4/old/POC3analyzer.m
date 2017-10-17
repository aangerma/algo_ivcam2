function POC3analyzer(scopeFile)
scopeFile = 'D:\ohad\data\lidar\EXP\20170406_POC3\ScopeData.h5';
mirrorFlavor='B';

[t0_,dt_,angx_,angy_]=Extract_LOS_POC3_v1_0(scopeFile,mirrorFlavor);

[~,dt,TIA_P]=io.POC.readScopeHDF5data(scopeFile,1);%Vsync=Vsync;
tend=length(TIA_P)*dt;
fs=1/dt;

adcFreq=125e6;
dt2=1/adcFreq;

[b,a]=butter(2,4e6/fs*2,'high');
TIA_P_FILT=FiltFiltM(b,a,TIA_P);

TIA_P_FILT = abs(TIA_P_FILT);
[b,a]=butter(2,adcFreq*.4/fs*2,'low');
TIA_P_FILT=FiltFiltM(b,a,TIA_P_FILT);

tinANG=t0_+(0:length(angx_)-1)*dt_;
tout=t0_:dt2:tend-dt2;
angx = interp1(tinANG,angx_,tout);
angy = interp1(tinANG,angy_,tout);
slowOut=interp1(0:dt:tend-dt,TIA_P_FILT,tout);



%%
nbm=@(x) (x-min(x(:)))/(max(x(:))-min(x(:)));
slowOutD=circshift(slowOut,82);
sz=[480 640]*2;
angxQ=uint16(nbm(angx)*(sz(2)-1));
angyQ=uint16(nbm(angy)*(sz(1)-1));
ind = sub2ind(sz,angyQ+1,angxQ+1);
pixout=accumarray(ind',slowOutD',[prod(sz),1],@mean);
pixout=reshape(pixout,sz);
pixout=imdilate(pixout,ones(2));
pixout(pixout==0)=nan;

imagescNAN(pixout);
axis image
%%

ivs.xy=[angxQ;angyQ];
ivs.fast=zeros(1,length(angxQ)*64,'logical');


end


function [t0,dt,SA_LOS_Filt,FA_LOS_Filt]=Extract_LOS_POC3_v1_0(Fn,Flavor)
% Extract LOS  POC3
% V.1.0
% Date: 4/4/17

% Channel 1: TIA_P
% Channel 2: SA_FBS
% Channel 3: PA_FBS
% Channel 4: FA_FBS
% Digital 0: Hsync
% Digital 1: Vsync

% LOS_Filt - LOS & Sync Data
% LOS_Raw - Raw Data no filtered
% LOS_Cut - Chunked frames 
% LOS_SingleFrame - arrange FrameNum data in chunks of Vsync

%  [LOS_Cut,LOS_Raw,LOS_Filt]=Extract_LOS('Poc4_RealData_06.h5')

% Fn          - Filename (H5 format)
% FrameNum    - choose frame number to be cut
% Flavor      - 'A' or 'B'


% Updates
% 4/4/17
% Cutted frames are limited to 1000 Vsyncs due to previuos sync. method
% Changed to include all frame
% 9/1/17
% schmitt triggering added to LOS_Cut Vsync
% 10/1/17
% Filters changed (order & runtime)
% 20/1/17
% Porcino flavor B compatabilty
% Filters mod. (SA PZR's)
% 22/1/17
% Cut frames with respect to recorded Hsyncs ! (and not peak detector)
% 2/2/17
% Remove internal path (addpath)
% Comment out Freq Calc.

DEC_FACT=100;
tic

%% MEMS info

% PZR1_SF_S=144.64;        %SA Direction PZR1 SF [optDeg/V]
% PZR2_SF_S=189.15;        %SA Direction PZR2 SF [optDeg/V]

% PZR1_SF_P=PZR1_SF_S/10;  %PA Direction PZR1 SF [optDeg/V]
% PZR2_SF_P=-PZR2_SF_S/10; %PA Direction PZR2 SF [optDeg/V]
PZR3_SF=16.7;            %FA Direction PZR3 SF [optDeg/V]

% OVERRIDE !Opt. FOV To Be Investigated !
% Post Calc. using fast harmnic reduction

HFOV=49.18; % Opt
% VFOV=44.6; % Opt

%% Scope Config. & Readout
% Chan1: VSync
% Chan2: PZR1 (SA)
% Chan3: PZR2 (PA)
% Chan4: PZR3 (FA)
% D0: HSync
% 1st Hsync on Rise of HSync (D0) / T=0


% Normalize Sync, Fix. Polarities, Remove Sensors Offset

[~,dt_ ,PZR1]=io.POC.readScopeHDF5data(Fn,2);PZR1=PZR1*-1;PZR1=PZR1-mean(PZR1);
[~,~ ,PZR2]=io.POC.readScopeHDF5data(Fn,3);PZR2=PZR2*-1;PZR2=PZR2-mean(PZR2);
[~,~ ,PZR3]=io.POC.readScopeHDF5data(Fn,4);PZR3=PZR3*1;PZR3=PZR3-mean(PZR3);

PZR1=PZR1(1:DEC_FACT:end);
PZR2=PZR2(1:DEC_FACT:end);
PZR3=PZR3(1:DEC_FACT:end);
dt = dt_*DEC_FACT;

% [~,~,HsyncT]=readScopeHDF5data(Fn,5);HsyncT1=HsyncT(1,:)*10e6/24.414;HsyncT1=HsyncT1';
% [t0_Vsync,dt_Vsync,VsyncT]=readScopeHDF5data(Fn,5);VsyncT1=VsyncT(2,:)*10e6/24.414;VsyncT1=Vsync';

% timeT1=[0:dt_Vsync:(length(HsyncT1)-1)*dt_Vsync]';


% Hsync = interp1(HsyncT1,timeT1,time);

if strcmp(Flavor,'B')
PZR1=-1*PZR1;
PZR2=-1*PZR2;
end

% Filter design
fBW=30e3;
fBW2=0.5e3;
d1 = designfilt('lowpassiir','FilterOrder',2,'HalfPowerFrequency',fBW,'SampleRate',1/dt,'DesignMethod','butter');
d2 = designfilt('lowpassiir','FilterOrder',2,'HalfPowerFrequency',fBW2,'SampleRate',1/dt,'DesignMethod','butter');

[b1,a1]=tf(d1);
[b2,a2]=tf(d2);

PZR2_Filt2 = FiltFiltM(b2,a2,PZR2);
PZR1_Filt2 = FiltFiltM(b2,a2,PZR1);
PZR1_SF_S=HFOV/(max(PZR1_Filt2)-min(PZR1_Filt2));
PZR2_SF_S=HFOV/(max(PZR2_Filt2)-min(PZR2_Filt2));
%approx. pitch
PZR1_SF_P=PZR1_SF_S/10; %PA Direction PZR1 SF [optDeg/V]
PZR2_SF_P=-PZR2_SF_S/10; %PA Direction PZR2 SF [optDeg/V]

SA_LOS=(PZR1*PZR1_SF_S+PZR2*PZR2_SF_S)/2;
PA_Angle=(PZR2*PZR2_SF_P+PZR1*PZR1_SF_P)/2;
FA_LOS=PA_Angle+PZR3*PZR3_SF;


% SA_PZR12=PZR1+PZR2;

% Sync. to first Hsync
% indS=find(Hsync>0.5,1,'first');





% LOS_Raw.Hsync=Hsync(indS:end)';
% LOS_Raw.Vsync=Vsync(indS:end);

% figure,
% plot(LOS_Raw.Time,LOS_Raw.SA)
%% Filtering... 
% disp('filtering...')
disp('Filt. FA')
FA_LOS_Filt = FiltFiltM(b1,a1,FA_LOS);
FA_LOS_Filt=FA_LOS_Filt-(max(FA_LOS_Filt)+min(FA_LOS_Filt))/2;
disp('Filt. SA')
SA_LOS_Filt = FiltFiltM(b2,a2,SA_LOS);
SA_LOS_Filt=SA_LOS_Filt-(max(SA_LOS_Filt)+min(SA_LOS_Filt))/2;

% PZR1_Filt=FiltFiltM(b1,a1,PZR1(indS:end));
% PZR2_Filt=FiltFiltM(b1,a1,PZR2(indS:end));


[~,ind1]=max(SA_LOS_Filt);
[~,ind0]=min(SA_LOS_Filt(1:ind1));
SA_LOS_Filt=SA_LOS_Filt(ind0:ind1);
FA_LOS_Filt=FA_LOS_Filt(ind0:ind1);
t0=dt*(ind0-1);


%{
    figure,
    subplot(311)
    plot(LOS_Raw.Time,[PZR1(indS:end) PZR2(indS:end)])
    hold on,plot(LOS_Raw.Time,[PZR1_Filt PZR2_Filt],'LineWidth',2)
    subplot(312)
    plot(LOS_Raw.Time,(PZR1_SF_S+PZR2_SF_S)/2*[PZR1_Filt+PZR2_Filt]/2,'LineWidth',0.5)
    subplot(313)
    plot(LOS_Raw.Time,[(PZR1_Filt_SF+PZR2_Filt_SF)/2])
    
%}
% SA_PZR12_Filt=FiltFiltM(b1,a1,SA_PZR12(indS:end));


% LOS_Filt.Time=LOS_Raw.Time;
% LOS_Filt.SA=SA_LOS_Filt;
% LOS_Filt.FA=FA_LOS_Filt;
% %% UPSAMPLE
% LOS_Filt.Time=(0:N-1)*dt_;
% LOS_Filt.SA=interp1(LOS_Raw.Time,SA_LOS_Filt,LOS_Filt.Time);
% LOS_Filt.FA=interp1(LOS_Raw.Time,FA_LOS_Filt,LOS_Filt.Time);
end