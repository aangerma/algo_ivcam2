%%
% % Pipe.patternGenerator('wall')
% Pipe.autopipe('C:\Users\weisstom\AppData\Local\Temp\patternGenerator.ivs')

%%
% hw = HWinterface;
% codeLength  = 64;
% sampleRate = 8;
% sampleSize = codeLength*sampleRate;
% tCode = vec(decimalToBinaryVector( hw.read('EXTLauxPItxCode_'))');
% tCode = double(vec(repmat(tCode(1:codeLength),[1,sampleRate])'));
% save('C:\sources\ivcam2_project\tCode.mat','tCode');
data_dir = 'C:\Users\weisstom\Desktop\ivcam\data32\val1';
files = dirFiles(data_dir,'*');
% load('C:\sources\ivcam2_project\tCode.mat','tCode'); %code 64
load('C:\sources\ivcam2_project\code32.mat','tCode'); %code 32
% load('C:\sources\ivcam2_project\code16.mat','tCode'); %code 16
load('C:\sources\ivcam2_project\codes.mat');
code_i=5;
files={strcat('C:\Users\weisstom\Desktop\ivcam\codes_data\450\',codes(code_i).name,'.mat')};

fcode=codes(code_i).tCode;
sample_dist=18.7314;
system_delay= 7394;
max_dist=sample_dist*length(fcode);

coarse_fine_loss=0;
fine_loss=0;
our_loss=0;
invalid_cf=0;
invalid_f=0;
invalid_our=0;
for i=1:length(files)
    temp=load(files{i});
    cma_=temp.fast(:,1:10000);
    dist=temp.dist(:,1:10000);
    dist=ones(1,10000)*473;

    %% coarse correlation
    ccode = reshape(fcode, 4, double(length(fcode))/4,1);
    ccode = permute(sum(uint32(ccode),1, 'native'),[2 1]);
    ccode = repmat(ccode,1,64);
    cma_dec = reshape(cma_, 4, double(length(fcode))/4, size(cma_,2));
    cma_dec = permute(sum(uint32(cma_dec),1, 'native'),[2 3 1]);

    cor_dec = Utils.correlator(uint16(cma_dec), uint8(flip(ccode)));
    [~, maxIndDec] = max(cor_dec);
    corrOffset = uint8(maxIndDec-1);
    corrOffset = permute(corrOffset,[2 1]);

    corrSegment = Utils.correlator(cma_, flip(fcode), uint32(zeros(10000,1)), uint16(corrOffset)*uint16(4), uint16(16));

    mxv=64;
    ker = @(sr) ([sr;mxv-2*sr;sr]);

    cor_seg_fil = corrSegment;
    cor_seg_fil=(pad_array(cor_seg_fil,4,0,'both'));
    cor_seg_fil = bitshift(convn(cor_seg_fil, ker(21), 'valid'),-6);
    cor_seg_fil = bitshift(convn(cor_seg_fil, ker(21), 'valid'),-6);
    cor_seg_fil = bitshift(convn(cor_seg_fil, ker(21), 'valid'),-6);
    cor_seg_fil = bitshift(convn(cor_seg_fil, ker(21), 'valid'),-6);
    cor_seg_fil = uint32(cor_seg_fil);

    corrOffset = uint16(corrOffset)*uint16(4); 
    corrOffset = uint16(mod(int32(corrOffset)-int32(16)  ,int32(length(fcode))));
    corrOffset = single(corrOffset) ;   
    [peak_index, peak_val ] = Pipe.DEST.detectPeaks(cor_seg_fil,corrOffset,1);

    roundTripDistance = peak_index .* sample_dist;
    % roundTripDistance_ = Pipe.DEST.rtdDelays(roundTripDistance,regs,pflow.iImgRAW,txmode);
    Distance_cf = mod(roundTripDistance-system_delay,max_dist)';
    coarse_fine_loss=coarse_fine_loss+mean(abs(Distance_cf-dist));
    invalid_cf = invalid_cf + mean(abs(Distance_cf-dist)>30);
end
coarse_fine_loss=coarse_fine_loss/length(files)
invalid_cf=invalid_cf/length(files)

%% plot corr
a=[dist; Distance_cf];
% plot(a(1,:),a(2,:),'+')
histogram(Distance_cf);
mean(Distance_cf)-473