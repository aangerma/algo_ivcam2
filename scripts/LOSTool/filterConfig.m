function filterConfig()

FA_FracPl_SF='mrd fffe1100 fffe1108'; % 20
FA_MirrorDiv=readRegHWM('mrd fffe10fc fffe1100' %45380
MC_Data.FA.PhaseLoop.ClOutB4Red 'mrd fffe2d88 fffe2d8c';%2.364801;
%MC_Data.FA.PhaseLoop.ClOutB4Red = 2.364801;
%FA_MirrorDiv = 45380;
%FA_FracPl_SF = 20;




960e6./(FA_MirrorDiv-int32(FA_FracPl_SF*MC_Data.FA.PhaseLoop.ClOutB4Red));



basePhase01=0.57;
fs=120e6;%Hz
lpfFreq=50e3;%Hz
mirrorFreq = 21000;%Hz



baseDelay=1.418104467029072e-06;%fixed per configuration/asic card (no fitlers, demo board)
mirrorBasedDelay01=0.5;
basePhase01=mirrorBasedDelay01+baseDelay*mirrorFreq;



[b,a]=butter(2,lpfFreq/fs*2);

h0=freqz(b,a,[mirrorFreq*2*pi/fs 2*pi]);h0=h0(1);

gain = 1./abs(h0);
delayVal = -angle(h0)/(mirrorFreq*2*pi);%seconds

% gain = interp1(ff,angle(h),mirrorFreq)/fs;


%VALIDATION
t=0:1/fs:0.001;
y=sin(2*pi*mirrorFreq*t);
y_=interp1(t-delayVal,filter(b,a,y),t)*gain;

ind=round(fs/mirrorFreq):length(t)-round(delayVal*fs);

plot(t(ind),y(ind),'.-',t(ind),y_(ind),'.-')

delay01 = delayVal*mirrorFreq+basePhase01;

addr(1).num0=(4294869132);
addr(1).num1=(4294869140);
addr(1).num2=(4294869148);
addr(1).den0=(4294869156);
addr(1).den1=(4294869164);
addr(1).K   =(4294869180);
addr(1).en  =(4294869188);

addr(2).num0=(4294869196);
addr(2).num1=(4294869204);
addr(2).num2=(4294869212);
addr(2).den0=(4294869220);
addr(2).den1=(4294869228);
addr(2).K   =(4294869244);
addr(2).en  =(4294869252);


genmwdD=@(addr,val,comment)sprintf('mwd %08x %08x %s //(%g) %s',addr,addr+8,vec(fliplr(reshape(dec2hexFast(typecast(val,'uint64')),8,2)))',val,comment);
genmwdS=@(addr,val,comment)sprintf('mwd %08x %08x %08x //(%g) %s',addr,addr+4,typecast(single(val),'uint32'),val,comment);
 b(1)=typecast(hex2uint64('3EBCB1B536CFFFF7'),'double');
 b(2)=typecast(hex2uint64('3ECCB1B536CFFFF7'),'double');
 b(3)=typecast(hex2uint64('3EBCB1B536CFFFF7'),'double');
 a(2)=typecast(hex2uint64('BFFFF0D5C10AE7D8'),'double');
 a(3)=typecast(hex2uint64('3FEFE1B9DAF06B2C'),'double');
 

filtNum=1;
txt={};
txt{end+1}=genmwdS(4294840588   ,basePhase01,'set  base delay');
txt{end+1}=genmwdD(addr(filtNum).en   ,uint64(1),'turn off');
txt{end+1}=genmwdD(addr(filtNum).num0, b(1),'num0');
txt{end+1}=genmwdD(addr(filtNum).num1, b(2),'num1');
txt{end+1}=genmwdD(addr(filtNum).num2, b(3),'num2');
txt{end+1}=genmwdD(addr(filtNum).den0, a(2),'den0');
txt{end+1}=genmwdD(addr(filtNum).den1, a(3),'den1');
txt{end+1}=genmwdD(addr(filtNum).K   , gain,'K');
txt{end+1}=genmwdS(4294840588   ,delay01,'set delay');
txt{end+1}=genmwdD(addr(filtNum).en   ,uint64(0),'turn on');


fprintf(cell2str(txt,newline));
fprintf(newline);





end


%{
RegsAlg_Prefilt_FA_pBO_Filt1_Num_0SetA_0_31	RegsAlg_Prefilt_FA_pBO_Filt1_Num_0SetA_0_31	0xfffe8000	0x8c
RegsAlg_Prefilt_FA_pBO_Filt1_Num_0SetA_32_63	RegsAlg_Prefilt_FA_pBO_Filt1_Num_0SetA_32_63	0xfffe8000	0x90
RegsAlg_Prefilt_FA_pBO_Filt1_Num_1SetA_0_31	RegsAlg_Prefilt_FA_pBO_Filt1_Num_1SetA_0_31	0xfffe8000	0x94
RegsAlg_Prefilt_FA_pBO_Filt1_Num_1SetA_32_63	RegsAlg_Prefilt_FA_pBO_Filt1_Num_1SetA_32_63	0xfffe8000	0x98
RegsAlg_Prefilt_FA_pBO_Filt1_Num_2SetA_0_31	RegsAlg_Prefilt_FA_pBO_Filt1_Num_2SetA_0_31	0xfffe8000	0x9c
RegsAlg_Prefilt_FA_pBO_Filt1_Num_2SetA_32_63	RegsAlg_Prefilt_FA_pBO_Filt1_Num_2SetA_32_63	0xfffe8000	0xa0
RegsAlg_Prefilt_FA_pBO_Filt1_Den_0SetA_0_31	RegsAlg_Prefilt_FA_pBO_Filt1_Den_0SetA_0_31	0xfffe8000	0xa4
RegsAlg_Prefilt_FA_pBO_Filt1_Den_0SetA_32_63	RegsAlg_Prefilt_FA_pBO_Filt1_Den_0SetA_32_63	0xfffe8000	0xa8
RegsAlg_Prefilt_FA_pBO_Filt1_Den_1SetA_0_31	RegsAlg_Prefilt_FA_pBO_Filt1_Den_1SetA_0_31	0xfffe8000	0xac
RegsAlg_Prefilt_FA_pBO_Filt1_Den_1SetA_32_63	RegsAlg_Prefilt_FA_pBO_Filt1_Den_1SetA_32_63	0xfffe8000	0xb0
RegsAlg_Prefilt_FA_pBO_Filt1_LimSetA_0_31	RegsAlg_Prefilt_FA_pBO_Filt1_LimSetA_0_31	0xfffe8000	0xb4
RegsAlg_Prefilt_FA_pBO_Filt1_LimSetA_32_63	RegsAlg_Prefilt_FA_pBO_Filt1_LimSetA_32_63	0xfffe8000	0xb8
RegsAlg_Prefilt_FA_pBO_Filt1_KSetA_0_31	RegsAlg_Prefilt_FA_pBO_Filt1_KSetA_0_31	0xfffe8000	0xbc
RegsAlg_Prefilt_FA_pBO_Filt1_KSetA_32_63	RegsAlg_Prefilt_FA_pBO_Filt1_KSetA_32_63	0xfffe8000	0xc0
RegsAlg_Prefilt_FA_pBO_Filt1_DYFlagSetA_0_31	RegsAlg_Prefilt_FA_pBO_Filt1_DYFlagSetA_0_31	0xfffe8000	0xc4
RegsAlg_Prefilt_FA_pBO_Filt1_DYFlagSetA_32_63	RegsAlg_Prefilt_FA_pBO_Filt1_DYFlagSetA_32_63	0xfffe8000	0xc8
RegsAlg_Prefilt_FA_pBO_Filt2_Num_0SetA_0_31	RegsAlg_Prefilt_FA_pBO_Filt2_Num_0SetA_0_31	0xfffe8000	0xcc
RegsAlg_Prefilt_FA_pBO_Filt2_Num_0SetA_32_63	RegsAlg_Prefilt_FA_pBO_Filt2_Num_0SetA_32_63	0xfffe8000	0xd0
RegsAlg_Prefilt_FA_pBO_Filt2_Num_1SetA_0_31	RegsAlg_Prefilt_FA_pBO_Filt2_Num_1SetA_0_31	0xfffe8000	0xd4
RegsAlg_Prefilt_FA_pBO_Filt2_Num_1SetA_32_63	RegsAlg_Prefilt_FA_pBO_Filt2_Num_1SetA_32_63	0xfffe8000	0xd8
RegsAlg_Prefilt_FA_pBO_Filt2_Num_2SetA_0_31	RegsAlg_Prefilt_FA_pBO_Filt2_Num_2SetA_0_31	0xfffe8000	0xdc
RegsAlg_Prefilt_FA_pBO_Filt2_Num_2SetA_32_63	RegsAlg_Prefilt_FA_pBO_Filt2_Num_2SetA_32_63	0xfffe8000	0xe0
RegsAlg_Prefilt_FA_pBO_Filt2_Den_0SetA_0_31	RegsAlg_Prefilt_FA_pBO_Filt2_Den_0SetA_0_31	0xfffe8000	0xe4
RegsAlg_Prefilt_FA_pBO_Filt2_Den_0SetA_32_63	RegsAlg_Prefilt_FA_pBO_Filt2_Den_0SetA_32_63	0xfffe8000	0xe8
RegsAlg_Prefilt_FA_pBO_Filt2_Den_1SetA_0_31	RegsAlg_Prefilt_FA_pBO_Filt2_Den_1SetA_0_31	0xfffe8000	0xec
RegsAlg_Prefilt_FA_pBO_Filt2_Den_1SetA_32_63	RegsAlg_Prefilt_FA_pBO_Filt2_Den_1SetA_32_63	0xfffe8000	0xf0
RegsAlg_Prefilt_FA_pBO_Filt2_LimSetA_0_31	RegsAlg_Prefilt_FA_pBO_Filt2_LimSetA_0_31	0xfffe8000	0xf4
RegsAlg_Prefilt_FA_pBO_Filt2_LimSetA_32_63	RegsAlg_Prefilt_FA_pBO_Filt2_LimSetA_32_63	0xfffe8000	0xf8
RegsAlg_Prefilt_FA_pBO_Filt2_KSetA_0_31	RegsAlg_Prefilt_FA_pBO_Filt2_KSetA_0_31	0xfffe8000	0xfc
RegsAlg_Prefilt_FA_pBO_Filt2_KSetA_32_63	RegsAlg_Prefilt_FA_pBO_Filt2_KSetA_32_63	0xfffe8000	0x100
RegsAlg_Prefilt_FA_pBO_Filt2_DYFlagSetA_0_31	RegsAlg_Prefilt_FA_pBO_Filt2_DYFlagSetA_0_31	0xfffe8000	0x104
RegsAlg_Prefilt_FA_pBO_Filt2_DYFlagSetA_32_63	RegsAlg_Prefilt_FA_pBO_Filt2_DYFlagSetA_32_63	0xfffe8000	0x108

%}