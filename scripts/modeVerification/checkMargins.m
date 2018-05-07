regs.FRMW.xres = uint16(640);
regs.FRMW.yres = uint16(480);

regs.FRMW.marginL = int16(0);
regs.FRMW.marginR = int16(0);
regs.FRMW.gaurdBandH = single(0.0);
regs.FRMW.gaurdBandV = single(0.0500);

regs.FRMW.laserangleH = hex2single('3EB51CC0'); % 0.2852
regs.FRMW.laserangleV = hex2single('3F8B1F85'); % 0.9344 

regs.FRMW.xfov = hex2single('423C0915'); % 50.5519
regs.FRMW.yfov = hex2single('422000C5'); % 42.4060
%regs.FRMW.xfov = single(72);
%regs.FRMW.yfov = single(56);

regs.JFIL.upscalexyBypass = true; % no upsampling
regs.EPTG.frameRate = single(60);
regs.GNRL.codeLength = uint8(64);
k = false(1,128);
k(1:regs.GNRL.codeLength) = Codes.propCode(regs.GNRL.codeLength,1);
regs.FRMW.txCode = sum(bsxfun(@times,reshape(uint32(k),32,4),uint32(2.^(0:31)')),'native');
regs.MTLB.txSymbolLength = single(1/1);
regs.GNRL.sampleRate = uint8(8);

% 'Wall'
regs.EPTG.zImageType = uint8(1);
regs.EPTG.irImageType = uint8(1);

regs.EPTG.noiseLevel = single(1.1);

outputDir = 'D:\Data\Ivcam2\margins';

nMaxSamples = uint32(1600000000);
regs.EPTG.nMaxSamples = nMaxSamples;
    
mkdir(outputDir);
[ivsFilename,~]=Pipe.patternGenerator(regs,'outputdir',outputDir);