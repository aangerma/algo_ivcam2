% General variables:
num_frames_per_test = 100;
storeResPath = 'X:\Users\mkiperwa\AFE\experiment';

%% init hw
if ~exist('hw','var')
    hw = HWinterface();
    hw.getFrame(10);%need to start streaming
    pause(5);
end
%% main
alignFrame = Calibration.aux.CBTools.showImageRequestDialog(hw,1,[],sprintf('move camera desired location'));
figure(1);
imagesc(alignFrame.i)
maximizeFig(1);
title('Mark Target');
h = drawpolygon;
rect_coords = h.get.Position;
K = hw.getIntrinsics();
save([storeResPath '\K.mat'],'K');
msk = double(poly2mask(h.Position(:,1), h.Position(:,2),size(alignFrame.i,1),size(alignFrame.i,2)));
imshowpair(alignFrame.i,msk);
frames = hw.getFrame(num_frames_per_test,false);
save([storeResPath '\im_reg.mat'], 'frames', 'msk', 'rect_coords');

r = Calibration.RegState(hw);
r.add('JFILinvBypass',1 );
r.set();
% pause();
frames = hw.getFrame(num_frames_per_test,false);
save([storeResPath '\im_reg_invBypass.mat'], 'frames', 'msk', 'rect_coords');

hw.cmd('MWD a003022c a0030230 1');
hw.cmd('MWD a003004c a0030050 0');
hw.shadowUpdate();
% pause();
frames = hw.getFrame(num_frames_per_test,false);
save([storeResPath '\im_CMP_invBypass.mat'], 'frames', 'msk', 'rect_coords');



hw.setReg('DESTaltIrEn',1);
hw.setConfidenceAs('dc');

r = Calibration.RegState(hw);
r.add('RASTbiltBypass',1 );
r.add('JFILinvBypass',1 );
r.add('JFILgrad1bypass',true);
r.add('JFILgrad2bypass',true);
r.add('DESTaltIRDiv', uint32(hex2dec('307')));
r.add('JFILbypass$',true);
r.set();

%Return to default
hw.cmd('MWD a003022c a0030230 0'); % Cmp_RateSel
hw.cmd('MWD a003004c a0030050 3'); % CmpPeak
hw.shadowUpdate();
% pause();
frames = hw.getFrame(num_frames_per_test,false);
save([storeResPath '\im_alter_default.mat'], 'frames', 'msk', 'rect_coords');

% hw.shutDownLaser();
% hw.openLaser()
%%
% Cmp_RateSel - Changes with TX Rate: Rate selection for fast path:
% 2’b00 – 1Gbps
% 2’b01 – 500Mbps
% 2’b10 – 250Mbps
% 2'b11 - Reserved
% LPF 2 – poles
% (controlled by):
% CmpRateSel<1:0>=00, CmpPeak <1:0>=11
% CmpRateSel<1:0>=01, CmpPeak <1:0>=00
% CmpRateSel<1:0>=10, CmpPeak <1:0>=00
hw.cmd('MWD a003022c a0030230 1');
hw.shadowUpdate();
disp(hw.cmd('MRD a003022c a0030230'));

hw.cmd('MWD a003004c a0030050 0');
hw.shadowUpdate();
disp(hw.cmd('MRD a003004c a0030050')); % CmpPeak
% pause();
frames = hw.getFrame(num_frames_per_test,false);
save([storeResPath '\im_alter_CMP.mat'], 'frames', 'msk', 'rect_coords');
%{
% Default
hw.cmd('MWD a003022c a0030230 0'); % Cmp_RateSel
hw.cmd('MWD a003004c a0030050 3'); % CmpPeak
hw.shadowUpdate();
%}

%{
%%
disp(hw.cmd('MRD a0030108 a003010c'));% BistLevel
hw.cmd('MWD a0030108 a003010c 1000'); % ??
hw.shadowUpdate();
%%
% Comparator #n offset cancellation control
% Default = 0 (HEX)  each
% 0 (HEX) – 0 mV
% monotonic increase, may not be linear (step=0.25mV)
% 7F (HEX) – 28 mV (typ)

disp(hw.cmd('MRD a0030024 a0030028'));% CmpOffn
disp(hw.cmd('MRD a0030028 a003002c'));% CmpOffn
disp(hw.cmd('MRD a003002c a0030030'));% CmpOffn
disp(hw.cmd('MRD a0030030 a0030034'));% CmpOffn
disp(hw.cmd('MRD a0030034 a0030038'));% CmpOffn
disp(hw.cmd('MRD a0030038 a003003c'));% CmpOffn
disp(hw.cmd('MRD a003003c a0030040'));% CmpOffn
disp(hw.cmd('MRD a0030040 a0030044'));% CmpOffn

hw.cmd('MWD a0030024 a0030028 0');% CmpOffn
hw.cmd('MWD a0030028 a003002c 0');% CmpOffn
hw.cmd('MWD a003002c a0030030 0');% CmpOffn
hw.cmd('MWD a0030030 a0030034 0');% CmpOffn
hw.cmd('MWD a0030034 a0030038 0');% CmpOffn
hw.cmd('MWD a0030038 a003003c 0');% CmpOffn
hw.cmd('MWD a003003c a0030040 0');% CmpOffn
hw.cmd('MWD a0030040 a0030044 0');% CmpOffn
hw.shadowUpdate();

hw.cmd('MWD a0030024 a0030028 1061F');% CmpOffn
hw.cmd('MWD a0030028 a003002c 1061F');% CmpOffn
hw.cmd('MWD a003002c a0030030 1061F');% CmpOffn
hw.cmd('MWD a0030030 a0030034 1061F');% CmpOffn
hw.cmd('MWD a0030034 a0030038 1061F');% CmpOffn
hw.cmd('MWD a0030038 a003003c 1061F');% CmpOffn
hw.cmd('MWD a003003c a0030040 1061F');% CmpOffn
hw.cmd('MWD a0030040 a0030044 1061F');% CmpOffn
hw.shadowUpdate();

%{
% Default
hw.cmd('MWD a0030024 a0030028 B00');% CmpOffn
hw.cmd('MWD a0030028 a003002c B00');% CmpOffn
hw.cmd('MWD a003002c a0030030 0');% CmpOffn
hw.cmd('MWD a0030030 a0030034 1C06');% CmpOffn
hw.cmd('MWD a0030034 a0030038 B00');% CmpOffn
hw.cmd('MWD a0030038 a003003c 5');% CmpOffn
hw.cmd('MWD a003003c a0030040 1C01');% CmpOffn
hw.cmd('MWD a0030040 a0030044 0');% CmpOffn
hw.shadowUpdate();

%}
%%
% Pre-amplifier offset cancellation control
% Default: ampoffp<4:0> = 0 (HEX)
% Default: ampoffn<4:0> = 0 (HEX)
% 0 (HEX) – 0 mV
% linear monotonic increase (step=0.35mV)
% 1F (HEX) – 11 mV (typ)

disp(hw.cmd('MRD a0030168 a003016c'));% CmpPreAmpOffp
disp(hw.cmd('MRD a003016c a0030170'));% CmpPreAmpOffn

%}