function [LOS_Cut,LOS_Raw,LOS_Filt]=Extract_LOS(Fn,~,Flavor)
% Extract LOS 
% V.8.1.1
% Date: 5/4/17

% LOS_Filt - LOS & Sync Data
% LOS_Raw - Raw Data no filtered
% LOS_Cut - Chunked frames 
% LOS_SingleFrame - arrange FrameNum data in chunks of Vsync

%  [LOS_Cut,LOS_Raw,LOS_Filt]=Extract_LOS('Poc4_RealData_06.h5')

% Fn          - Filename (H5 format)
% FrameNum    - choose frame number to be cut
% Flavor      - 'A' or 'B'

% Updates
% 9/1/17
% schmitt triggering added to LOS_Cut Vsync
% 10/1/17
% Filters changed (order & runtime)
% 20/1/17
% Porcino flavor B compatabilty
% Filters mod. (SA PZR's)
% 22/1/17
% Cut frames with respect to recorded Hsyncs ! (and not peak detector)

% tic
if nargin<1
   disp('File name not supplied...')
   return 
elseif nargin <2
% % % %     FrameNum=1;
    Flavor='A';
elseif nargin <3
    Flavor='A';
end
%% MEMS info

% % % % PZR1_SF_S=144.64;        %SA Direction PZR1 SF [optDeg/V]
% % % % PZR2_SF_S=189.15;        %SA Direction PZR2 SF [optDeg/V]

% % % % PZR1_SF_P=PZR1_SF_S/10;  %PA Direction PZR1 SF [optDeg/V]
% % % % PZR2_SF_P=-PZR2_SF_S/10; %PA Direction PZR2 SF [optDeg/V]
PZR3_SF=16.7;            %FA Direction PZR3 SF [optDeg/V]

% OVERRIDE !Opt. FOV To Be Investigated !
% Post Calc. using fast harmnic reduction

HFOV=49.18; % Opt
% % % % VFOV=44.6; % Opt

%% Scope Config. & Readout
% Chan1: VSync
% Chan2: PZR1 (SA)
% Chan3: PZR2 (PA)
% Chan4: PZR3 (FA)
% D0: HSync
% 1st Hsync on Rise of HSync (D0) / T=0



% Normalize Sync, Fix. Polarities, Remove Sensors Offset
[t0_Vsync,dt_Vsync,Vsync]=io.POC.readScopeHDF5data(Fn,1);Vsync=Vsync;
[t0_PZR1,dt_PZR1,PZR1]=io.POC.readScopeHDF5data(Fn,2);PZR1=PZR1*-1;PZR1=PZR1-mean(PZR1);
[t0_PZR2,dt_PZR2,PZR2]=io.POC.readScopeHDF5data(Fn,3);PZR2=PZR2*-1;PZR2=PZR2-mean(PZR2);
[t0_PZR3,dt_PZR3,PZR3]=io.POC.readScopeHDF5data(Fn,4);PZR3=PZR3*1;PZR3=PZR3-mean(PZR3);
[t0_HsyncT,dt_HsyncT,HsyncT]=io.POC.readScopeHDF5data(Fn,5);Hsync=HsyncT(1,:)*10e6/24.414;

time=(0:dt_Vsync:(length(Vsync)-1)*dt_Vsync)';

if strcmp(Flavor,'B')
PZR1=-1*PZR1;
PZR2=-1*PZR2;
end

%% LOS_Raw

% Filter design
fBW2=0.5e3;
d2 = designfilt('lowpassiir','FilterOrder',2,'HalfPowerFrequency',fBW2,'SampleRate',1/dt_PZR1,'DesignMethod','butter');
[b2,a2]=tf(d2);


% tic
% PZR2_FiltNew=FiltFiltM(b1,a1,(PZR2));
% toc
% tic
% PZR2_Filt2 = filtfilt(d22,PZR2);
% toc
% figure
% plot(PZR2_FiltNew-PZR2_Filt2)

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

% % % % SA_PZR12=PZR1+PZR2;

% Sync. to first Hsync
indS=find(Hsync>0.5,1,'first');

LOS_Raw.Time=time(indS:end)-time(indS);
LOS_Raw.SA=SA_LOS(indS:end);
LOS_Raw.PA=PA_Angle(indS:end);
LOS_Raw.FA=FA_LOS(indS:end);
LOS_Raw.Hsync=Hsync(indS:end)';
LOS_Raw.Vsync=Vsync(indS:end);

% % % % %% downsample
% % % % downSampleRatio = 10;
% % % % names = fieldnames(LOS_Raw);
% % % % for i=1:length(names)
% % % %     LOS_Raw.(names{i}) = LOS_Raw.(names{i})(1:downSampleRatio:end);
% % % % end
% % % % dt_PZR1 = dt_PZR1*downSampleRatio;
% % % % % dt_PZR2 = dt_PZR2*downSampleRatio;
% figure,
% plot(LOS_Raw.Time,LOS_Raw.SA)


%% Filtering

fBW=30e3;
fBW2=30e3;
d1 = designfilt('lowpassiir','FilterOrder',2,'HalfPowerFrequency',fBW,'SampleRate',1/dt_PZR1,'DesignMethod','butter');
d2 = designfilt('lowpassiir','FilterOrder',2,'HalfPowerFrequency',fBW2,'SampleRate',1/dt_PZR1,'DesignMethod','butter');

[b1,a1]=tf(d1);
[b2,a2]=tf(d2);


% disp('Filt. FA')
FA_LOS_Filt = FiltFiltM(b1,a1,LOS_Raw.FA);
FA_LOS_Filt=FA_LOS_Filt-(max(FA_LOS_Filt)+min(FA_LOS_Filt))/2;
% disp('Filt. SA')
SA_LOS_Filt = FiltFiltM(b2,a2,LOS_Raw.SA);
SA_LOS_Filt=SA_LOS_Filt-(max(SA_LOS_Filt)+min(SA_LOS_Filt))/2;



% %% notch filter
% 
% F=1/dt_PZR1;
% f0=39.29e3; Q=2*pi*f0/F; r=0.995; z=exp(1i*Q*[-1 1]'); p=r*z; [b,a]=zp2tf(z,p,r^2); [H,ff]=freqz(b,a,2^16,F); figure(300); plot(ff(1:end),abs(H(1:end))); grid
% 
% SA_LOS_Filt2 = filter(b,a,LOS_Raw.SA);
% SA_LOS_Filt= SA_LOS_Filt2;
% 
% figure;fftplot(SA_LOS_Filt,1/dt_PZR1);hold on;fftplot(LOS_Raw.SA,1/dt_PZR1);


% % % % PZR1_Filt=FiltFiltM(b1,a1,PZR1(indS:end));
% % % % PZR2_Filt=FiltFiltM(b1,a1,PZR2(indS:end));
% % % % 
% % % % PZR1_Filt_SF=PZR1_Filt*PZR1_SF_S;
% % % % PZR2_Filt_SF=PZR2_Filt*PZR2_SF_S;
% % % % 
% % % % if 0
% % % %     figure,
% % % %     subplot(311)
% % % %     plot(LOS_Raw.Time,[PZR1(indS:end) PZR2(indS:end)])
% % % %     hold on,plot(LOS_Raw.Time,[PZR1_Filt PZR2_Filt],'LineWidth',2)
% % % %     subplot(312)
% % % %     plot(LOS_Raw.Time,(PZR1_SF_S+PZR2_SF_S)/2*[PZR1_Filt+PZR2_Filt]/2,'LineWidth',0.5)
% % % %     subplot(313)
% % % %     plot(LOS_Raw.Time,[(PZR1_Filt_SF+PZR2_Filt_SF)/2])
% % % %     
% % % % end
% % % % SA_PZR12_Filt=FiltFiltM(b1,a1,SA_PZR12(indS:end));


LOS_Filt.Time=LOS_Raw.Time;
LOS_Filt.SA=SA_LOS_Filt;
LOS_Filt.FA=FA_LOS_Filt;
LOS_Filt.Hsync=LOS_Raw.Hsync;
% LOS_Filt.Vsync=LOS_Raw.Vsync;
LOS_Filt.Vsync = (SchmittTrig(LOS_Raw.Vsync,0.79,1.03,0))';


%% Plot
% % % % iS=1; %20e6;
% % % % iE=length(Vsync); %;50e6;
% % % % iD=10;

% % % % [sPV_U1,sPL_U1]=findpeaks(LOS_Filt.SA);
% % % % [sPV_L1,sPL_L1]=findpeaks(-LOS_Filt.SA);sPV_L1=-sPV_L1;
% % % % 
% % % % if sPL_U1(1)<sPL_L1(1)
% % % % sPL_L1=[1; sPL_L1]; % add the first man.
% % % % sPV_L1=[LOS_Filt.SA(1) ;sPV_L1];
% % % % end
% 11/1/17
% Clear Non real peaks due to filtering I.C !
% this fix doesnt check for short frames in between
% % % % Frames_Cr=mean(diff(sPL_U1))*0.95; % 95% allowed deviation
% % % % Frames_Ind=find(diff(sPL_U1)>Frames_Cr);
% % % % Frames_Ind2=[Frames_Ind;Frames_Ind(end)+1]; % add last point

% % % % sPL_U=sPL_U1(Frames_Ind2);
% % % % sPV_U=sPV_U1(Frames_Ind2);
% % % % sPL_L=sPL_L1(Frames_Ind2);
% % % % sPV_L=sPV_L1(Frames_Ind2);
% % % % 
% % % % 
% % % % fprintf('total %i frames \n',length(sPL_U))


% % % % iS=sPL_L(FrameNum);
% % % % iE=sPL_U(FrameNum);
% % % % 
% % % % if 0
% % % %    figure
% % % %    plot(LOS_Raw.Time,LOS_Filt.SA)
% % % %    hold on
% % % %    plot(LOS_Raw.Time(sPL_U),sPV_U,'ro')
% % % %    hold on
% % % %    plot(LOS_Raw.Time(sPL_L),sPV_L,'go')
% % % %     
% % % % end
% % % % NumOfFrames=min(length(sPL_L),length(sPL_U));
%% Freq Calc.
% % % % TH=0.5;
% [ind,t0,s0,t0close,s0close] = crossing1(LOS_Filt.Vsync,LOS_Raw.Time,TH);
% [FAind,FAt0,FAs0,FAt0close,FAs0close] = crossing1(LOS_Filt.FA,LOS_Raw.Time,0);
% [SAind,SAt0,SAs0,SAt0close,SAs0close] = crossing1(LOS_Filt.Hsync,LOS_Filt.Time,TH);

% 
% SA_Peak=SAt0(1:2:end)';
% SA_Cros=LOS_Filt.Time(sPL_U);
% tmp=(SA_Cros-SA_Peak)*1e6;
% fprintf('SA sync offset: %f [us] std %f [us] \n',mean(tmp),std(tmp))

%% Cut & Arrange frames without Return time
% Cut using Hsync

% FrInd=find(LOS_Filt.Hsync>0.5);


[SAind,SAt0,SAs0,SAt0close,SAs0close] = crossing1(LOS_Filt.Hsync,LOS_Filt.Time,0.5);

SAind_M=[1 SAind(2:2:length(SAind))]; % assume first rising isn't rec.
% % % % ofS=1; % ASIC Reg.
% ofD=1000; % ASIC Reg %v8.1 Change

% % % % tCut= mean(diff(x0Vsync_val))*ofD;
% % % % jj=1;

dHsync=diff(SAt0);
tCut=dHsync(2);
% fprintf('Scan Time %f ms \n',tCut*1e3) %v8.1 Change
% tCut= mean(diff(x0Vsync_val))*ofD; %v8.1 Change


LOS_Cut.Time = cell(length(SAind_M),1);
LOS_Cut.SA_LOS_Filt = cell(length(SAind_M),1);
LOS_Cut.FA_LOS_Filt = cell(length(SAind_M),1);
LOS_Cut.Hsync = cell(length(SAind_M),1);
LOS_Cut.Vsync = cell(length(SAind_M),1);
for jj=1:length(SAind_M)
%    F_V(jj)=find(x0Vsync_ind>SAind(jj),1);
   %     x0Vsync_t0_V(jj*1000-1000+1:jj*1000)=x0Vsync_val(F_V(jj)+ofS:F_V(jj)+1000+ofS-1);
    iS1=SAind_M(jj);
    iE1=find(LOS_Raw.Time>LOS_Raw.Time(iS1)+tCut,1);

    LOS_Cut.Time{jj}=LOS_Raw.Time(iS1:1:iE1);
    LOS_Cut.SA_LOS_Filt{jj}=LOS_Filt.SA(iS1:1:iE1);
% % % %     DataOut_SA_LOS{jj}=LOS_Raw.SA(iS1:1:iE1);

    LOS_Cut.FA_LOS_Filt{jj}=LOS_Filt.FA(iS1:1:iE1);
    LOS_Cut.Hsync{jj}=LOS_Filt.Hsync(iS1:1:iE1);
    LOS_Cut.Vsync{jj}=LOS_Filt.Vsync(iS1:1:iE1);
end


end