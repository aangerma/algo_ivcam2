function [ivsFilename, GTivsFilename] = setModeRegs(modeName,scene,outputDir)

    switch modeName
        case 'HD30' %1
            regs.GNRL.imgHsize = uint16(1280);
            regs.GNRL.imgVsize = uint16(720);
            regs.JFIL.upscalexyBypass = true; % no upsampling
            % regs.JFIL.upscalex1y0 =
            regs.EPTG.frameRate = single(30);
            regs.GNRL.codeLength = uint8(26);
            k = false(1,128);
            k(1:regs.GNRL.codeLength) = Codes.propCode(regs.GNRL.codeLength,1);
            regs.FRMW.txCode = sum(bsxfun(@times,reshape(uint32(k),32,4),uint32(2.^(0:31)')),'native');               
            regs.MTLB.txSymbolLength = single(1/1);
            regs.GNRL.sampleRate = uint8(16);


        case 'HD45' %2
            regs.GNRL.imgHsize = uint16(1280);
            regs.GNRL.imgVsize = uint16(720);
            regs.JFIL.upscalexyBypass = true; % no upsampling
            % regs.JFIL.upscalex1y0 =            
            regs.EPTG.frameRate = single(45);
            regs.GNRL.codeLength = uint8(26);
            k = false(1,128);
            k(1:regs.GNRL.codeLength) = Codes.propCode(regs.GNRL.codeLength,1);
            regs.FRMW.txCode = sum(bsxfun(@times,reshape(uint32(k),32,4),uint32(2.^(0:31)')),'native');   
            regs.MTLB.txSymbolLength = single(1/1);
            regs.GNRL.sampleRate = uint8(16);
            
        case 'HD5' %3
            regs.GNRL.imgHsize = uint16(1280);
            regs.GNRL.imgVsize = uint16(720);
            regs.JFIL.upscalexyBypass = true; % no upsampling
            % regs.JFIL.upscalex1y0 =            
            regs.EPTG.frameRate = single(5);
            regs.GNRL.codeLength = uint8(16);
            k = false(1,128);
            k(1:regs.GNRL.codeLength) = Codes.propCode(regs.GNRL.codeLength,1);
            regs.FRMW.txCode = sum(bsxfun(@times,reshape(uint32(k),32,4),uint32(2.^(0:31)')),'native');   
            regs.MTLB.txSymbolLength = single(1/1);
            regs.GNRL.sampleRate = uint8(16);
            
        case 'HHD45' %4
            regs.GNRL.imgHsize = uint16(640);
            regs.GNRL.imgVsize = uint16(720);
            regs.JFIL.upscalexyBypass = false; % no upsampling
            regs.JFIL.upscalex1y0 = true;            
            regs.EPTG.frameRate = single(45);
            regs.GNRL.codeLength = uint8(26);
            k = false(1,128);
            k(1:regs.GNRL.codeLength) = Codes.propCode(regs.GNRL.codeLength,1);
            regs.FRMW.txCode = sum(bsxfun(@times,reshape(uint32(k),32,4),uint32(2.^(0:31)')),'native');   
            regs.MTLB.txSymbolLength = single(1/1);
            regs.GNRL.sampleRate = uint8(16);            
            
        case 'SXVGA30' %5
            regs.GNRL.imgHsize = uint16(1280);
            regs.GNRL.imgVsize = uint16(960);
            regs.JFIL.upscalexyBypass = true; % no upsampling
%             regs.JFIL.upscalex1y0 = true;           
            regs.EPTG.frameRate = single(30);
            regs.GNRL.codeLength = uint8(26);
            k = false(1,128);
            k(1:regs.GNRL.codeLength) = Codes.propCode(regs.GNRL.codeLength,1);
            regs.FRMW.txCode = sum(bsxfun(@times,reshape(uint32(k),32,4),uint32(2.^(0:31)')),'native');   
            regs.MTLB.txSymbolLength = single(1/1);
            regs.GNRL.sampleRate = uint8(16);
            
        case 'SXVGA30F' %6
            regs.GNRL.imgHsize = uint16(1280);
            regs.GNRL.imgVsize = uint16(960);
            regs.JFIL.upscalexyBypass = true; % no upsampling
%             regs.JFIL.upscalex1y0 = true;           
            regs.EPTG.frameRate = single(30);
            regs.GNRL.codeLength = uint8(8);
            k = false(1,128);
            k(1:regs.GNRL.codeLength) = Codes.propCode(regs.GNRL.codeLength,1);
            regs.FRMW.txCode = sum(bsxfun(@times,reshape(uint32(k),32,4),uint32(2.^(0:31)')),'native');   
            regs.MTLB.txSymbolLength = single(1/1);
            regs.GNRL.sampleRate = uint8(16);   
            % This is a short range mode, chaneg the default min and max z
            % from 500-1000mm to 550-750mm.
            regs.EPTG.minZ = single(550); % [mm]
            regs.EPTG.maxZ = single(750); % [mm]
                     
        case 'VGA60' %7
            regs.GNRL.imgHsize = uint16(640);
            regs.GNRL.imgVsize = uint16(480);
            regs.JFIL.upscalexyBypass = true; % no upsampling
%             regs.JFIL.upscalex1y0 = true;           
            regs.EPTG.frameRate = single(60);
            regs.GNRL.codeLength = uint8(52);
            k = false(1,128);
            k(1:regs.GNRL.codeLength) = Codes.propCode(regs.GNRL.codeLength,1);
            regs.FRMW.txCode = sum(bsxfun(@times,reshape(uint32(k),32,4),uint32(2.^(0:31)')),'native');   
            regs.MTLB.txSymbolLength = single(1/1); 
            regs.GNRL.sampleRate = uint8(16);
            
        case 'HVGA100' %8
            regs.GNRL.imgHsize = uint16(320);
            regs.GNRL.imgVsize = uint16(480);
            regs.JFIL.upscalexyBypass = false; % no upsampling
            regs.JFIL.upscalex1y0 = true;           
            regs.EPTG.frameRate = single(100);
            regs.GNRL.codeLength = uint8(52);
            k = false(1,128);
            k(1:regs.GNRL.codeLength) = Codes.propCode(regs.GNRL.codeLength,1);
            regs.FRMW.txCode = sum(bsxfun(@times,reshape(uint32(k),32,4),uint32(2.^(0:31)')),'native');   
            regs.MTLB.txSymbolLength = single(1/1);
            regs.GNRL.sampleRate = uint8(16);
       
        case 'VGA30' %9
            regs.GNRL.imgHsize = uint16(640);
            regs.GNRL.imgVsize = uint16(480);
            regs.JFIL.upscalexyBypass = true; % no upsampling
%             regs.JFIL.upscalex1y0 = true;           
            regs.EPTG.frameRate = single(30);
            regs.GNRL.codeLength = uint8(52);
            k = false(1,128);
            k(1:regs.GNRL.codeLength) = Codes.propCode(regs.GNRL.codeLength,1);
            regs.FRMW.txCode = sum(bsxfun(@times,reshape(uint32(k),32,4),uint32(2.^(0:31)')),'native');   
            regs.MTLB.txSymbolLength = single(1/1);
            regs.GNRL.sampleRate = uint8(16);
            
        case 'VGA15' %10
            regs.GNRL.imgHsize = uint16(640);
            regs.GNRL.imgVsize = uint16(480);
            regs.JFIL.upscalexyBypass = true; % no upsampling
%             regs.JFIL.upscalex1y0 = true;           
            regs.EPTG.frameRate = single(15);
            regs.GNRL.codeLength = uint8(62);
            k = false(1,128);
            k(1:regs.GNRL.codeLength) = Codes.propCode(regs.GNRL.codeLength,1);
            regs.FRMW.txCode = sum(bsxfun(@times,reshape(uint32(k),32,4),uint32(2.^(0:31)')),'native');   
            regs.MTLB.txSymbolLength = single(1/1);
            regs.GNRL.sampleRate = uint8(8);
            
        case 'VGA5' %11
            regs.GNRL.imgHsize = uint16(640);
            regs.GNRL.imgVsize = uint16(480);
            regs.JFIL.upscalexyBypass = true; % no upsampling
%             regs.JFIL.upscalex1y0 = true;           
            regs.EPTG.frameRate = single(5);
            regs.GNRL.codeLength = uint8(70);
            k = false(1,128);
            k(1:regs.GNRL.codeLength) = Codes.propCode(regs.GNRL.codeLength,1);
            regs.FRMW.txCode = sum(bsxfun(@times,reshape(uint32(k),32,4),uint32(2.^(0:31)')),'native');   
            regs.MTLB.txSymbolLength = single(1/1);
            regs.GNRL.sampleRate = uint8(4);
            
        case 'QVGA120' %12
            regs.GNRL.imgHsize = uint16(320);
            regs.GNRL.imgVsize = uint16(240);
            regs.JFIL.upscalexyBypass = true; % no upsampling
%             regs.JFIL.upscalex1y0 = true;           
            regs.EPTG.frameRate = single(120);
            regs.GNRL.codeLength = uint8(64);
            k = false(1,128);
            k(1:regs.GNRL.codeLength) = Codes.propCode(regs.GNRL.codeLength,1);
            regs.FRMW.txCode = sum(bsxfun(@times,reshape(uint32(k),32,4),uint32(2.^(0:31)')),'native');   
            regs.MTLB.txSymbolLength = single(1/1);
            regs.GNRL.sampleRate = uint8(8);
            
        case 'QVGA60' %13
            regs.GNRL.imgHsize = uint16(320);
            regs.GNRL.imgVsize = uint16(240);
            regs.JFIL.upscalexyBypass = true; % no upsampling
%             regs.JFIL.upscalex1y0 = true;           
            regs.EPTG.frameRate = single(60);
            regs.GNRL.codeLength = uint8(64);
            k = false(1,128);
            k(1:regs.GNRL.codeLength) = Codes.propCode(regs.GNRL.codeLength,1);
            regs.FRMW.txCode = sum(bsxfun(@times,reshape(uint32(k),32,4),uint32(2.^(0:31)')),'native');   
            regs.MTLB.txSymbolLength = single(1/1);
            regs.GNRL.sampleRate = uint8(16);
            
        case 'QVGA30' %14
            regs.GNRL.imgHsize = uint16(320);
            regs.GNRL.imgVsize = uint16(240);
            regs.JFIL.upscalexyBypass = true; % no upsampling
%             regs.JFIL.upscalex1y0 = true;           
            regs.EPTG.frameRate = single(30);
            regs.GNRL.codeLength = uint8(90);
            k = false(1,128);
            k(1:regs.GNRL.codeLength) = Codes.propCode(regs.GNRL.codeLength,1);
            regs.FRMW.txCode = sum(bsxfun(@times,reshape(uint32(k),32,4),uint32(2.^(0:31)')),'native');   
            regs.MTLB.txSymbolLength = single(1/1);
            regs.GNRL.sampleRate = uint8(8);
            
        case 'QVGA15' %15
            regs.GNRL.imgHsize = uint16(320);
            regs.GNRL.imgVsize = uint16(240);
            regs.JFIL.upscalexyBypass = true; % no upsampling
%             regs.JFIL.upscalex1y0 = true;           
            regs.EPTG.frameRate = single(15);
            regs.GNRL.codeLength = uint8(104);
            k = false(1,128);
            k(1:regs.GNRL.codeLength) = Codes.propCode(regs.GNRL.codeLength,1);
            regs.FRMW.txCode = sum(bsxfun(@times,reshape(uint32(k),32,4),uint32(2.^(0:31)')),'native');   
            regs.MTLB.txSymbolLength = single(1/1);
            regs.GNRL.sampleRate = uint8(8);
            
        case 'QVGA5' %16
            regs.GNRL.imgHsize = uint16(320);
            regs.GNRL.imgVsize = uint16(240);
            regs.JFIL.upscalexyBypass = true; % no upsampling
%             regs.JFIL.upscalex1y0 = true;           
            regs.EPTG.frameRate = single(5);
            regs.GNRL.codeLength = uint8(106); % was 104
            k = false(1,128);
            k(1:regs.GNRL.codeLength) = Codes.propCode(regs.GNRL.codeLength,1);
            regs.FRMW.txCode = sum(bsxfun(@times,reshape(uint32(k),32,4),uint32(2.^(0:31)')),'native');   
            regs.MTLB.txSymbolLength = single(1/1);
            regs.GNRL.sampleRate = uint8(8);
            
        case 'QVGA30S.5_8' %17
            regs.GNRL.imgHsize = uint16(320);
            regs.GNRL.imgVsize = uint16(240);
            regs.JFIL.upscalexyBypass = true; % no upsampling
%             regs.JFIL.upscalex1y0 = true;           
            regs.EPTG.frameRate = single(30);
            regs.GNRL.codeLength = uint8(52);
            k = false(1,128);
            k(1:regs.GNRL.codeLength) = Codes.propCode(regs.GNRL.codeLength,1);
            regs.FRMW.txCode = sum(bsxfun(@times,reshape(uint32(k),32,4),uint32(2.^(0:31)')),'native');   
            regs.MTLB.txSymbolLength = single(1/0.5);
            regs.GNRL.sampleRate = uint8(16);
            
        case 'QVGA5S.5_8' %18
            regs.GNRL.imgHsize = uint16(320);
            regs.GNRL.imgVsize = uint16(240);
            regs.JFIL.upscalexyBypass = true; % no upsampling
%             regs.JFIL.upscalex1y0 = true;           
            regs.EPTG.frameRate = single(5);
            regs.GNRL.codeLength = uint8(52);
            k = false(1,128);
            k(1:regs.GNRL.codeLength) = Codes.propCode(regs.GNRL.codeLength,1);
            regs.FRMW.txCode = sum(bsxfun(@times,reshape(uint32(k),32,4),uint32(2.^(0:31)')),'native');   
            regs.MTLB.txSymbolLength = single(1/0.5);
            regs.GNRL.sampleRate = uint8(16);
            
        case 'QVGA30S.5_4' %19
            regs.GNRL.imgHsize = uint16(320);
            regs.GNRL.imgVsize = uint16(240);
            regs.JFIL.upscalexyBypass = true; % no upsampling
%              regs.JFIL.upscalex1y0 = true;           
            regs.EPTG.frameRate = single(30);
            regs.GNRL.codeLength = uint8(106); % was 104
            k = false(1,128);
            k(1:regs.GNRL.codeLength) = Codes.propCode(regs.GNRL.codeLength,1);
            regs.FRMW.txCode = sum(bsxfun(@times,reshape(uint32(k),32,4),uint32(2.^(0:31)')),'native');   
            regs.MTLB.txSymbolLength = single(1/0.5);
            regs.GNRL.sampleRate = uint8(8);
            
        case 'QVGA5S.5_4' %20
            regs.GNRL.imgHsize = uint16(320);
            regs.GNRL.imgVsize = uint16(240);
            regs.JFIL.upscalexyBypass = true; % no upsampling
%             regs.JFIL.upscalex1y0 = true;           
            regs.EPTG.frameRate = single(5);
            regs.GNRL.codeLength = uint8(106); % was 104
            k = false(1,128);
            k(1:regs.GNRL.codeLength) = Codes.propCode(regs.GNRL.codeLength,1);
            regs.FRMW.txCode = sum(bsxfun(@times,reshape(uint32(k),32,4),uint32(2.^(0:31)')),'native');   
            regs.MTLB.txSymbolLength = single(1/0.5);
            regs.GNRL.sampleRate = uint8(8);
            
        case 'QVGA30S.25_4_26' %21
            regs.GNRL.imgHsize = uint16(320);
            regs.GNRL.imgVsize = uint16(240);
            regs.JFIL.upscalexyBypass = true; % no upsampling
%             regs.JFIL.upscalex1y0 = true;           
            regs.EPTG.frameRate = single(30);
            regs.GNRL.codeLength = uint8(26);
            k = false(1,128);
            k(1:regs.GNRL.codeLength) = Codes.propCode(regs.GNRL.codeLength,1);
            regs.FRMW.txCode = sum(bsxfun(@times,reshape(uint32(k),32,4),uint32(2.^(0:31)')),'native');   
            regs.MTLB.txSymbolLength = single(1/0.25);
            regs.GNRL.sampleRate = uint8(16);
            
        case 'QVGA5S.25_4_26' %22
            regs.GNRL.imgHsize = uint16(320);
            regs.GNRL.imgVsize = uint16(240);
            regs.JFIL.upscalexyBypass = true; % no upsampling
%             regs.JFIL.upscalex1y0 = true;           
            regs.EPTG.frameRate = single(5);
            regs.GNRL.codeLength = uint8(26);
            k = false(1,128);
            k(1:regs.GNRL.codeLength) = Codes.propCode(regs.GNRL.codeLength,1);
            regs.FRMW.txCode = sum(bsxfun(@times,reshape(uint32(k),32,4),uint32(2.^(0:31)')),'native');   
            regs.MTLB.txSymbolLength = single(1/0.25);
            regs.GNRL.sampleRate = uint8(16);
            
        case 'QVGA30S.25_4_52' %23
            regs.GNRL.imgHsize = uint16(320);
            regs.GNRL.imgVsize = uint16(240);
            regs.JFIL.upscalexyBypass = true; % no upsampling
%             regs.JFIL.upscalex1y0 = true;           
            regs.EPTG.frameRate = single(30);
            regs.GNRL.codeLength = uint8(52);
            k = false(1,128);
            k(1:regs.GNRL.codeLength) = Codes.propCode(regs.GNRL.codeLength,1);
            regs.FRMW.txCode = sum(bsxfun(@times,reshape(uint32(k),32,4),uint32(2.^(0:31)')),'native');   
            regs.MTLB.txSymbolLength = single(1/0.25);
            regs.GNRL.sampleRate = uint8(16);
            
        case 'QVGA5S.25_4_52' %24
            regs.GNRL.imgHsize = uint16(320);
            regs.GNRL.imgVsize = uint16(240);
            regs.JFIL.upscalexyBypass = true; % no upsampling
%             regs.JFIL.upscalex1y0 = true;           
            regs.EPTG.frameRate = single(5);
            regs.GNRL.codeLength = uint8(52);
            k = false(1,128);
            k(1:regs.GNRL.codeLength) = Codes.propCode(regs.GNRL.codeLength,1);
            regs.FRMW.txCode = sum(bsxfun(@times,reshape(uint32(k),32,4),uint32(2.^(0:31)')),'native');   
            regs.MTLB.txSymbolLength = single(1/0.25);
            regs.GNRL.sampleRate = uint8(16);
            
        case 'QVGA30S.5_8_64' %25
            regs.GNRL.imgHsize = uint16(320);
            regs.GNRL.imgVsize = uint16(240);
            regs.JFIL.upscalexyBypass = true; % no upsampling
%             regs.JFIL.upscalex1y0 = true;           
            regs.EPTG.frameRate = single(30);
            regs.GNRL.codeLength = uint8(64);
            k = false(1,128);
            k(1:regs.GNRL.codeLength) = Codes.propCode(regs.GNRL.codeLength,1);
            regs.FRMW.txCode = sum(bsxfun(@times,reshape(uint32(k),32,4),uint32(2.^(0:31)')),'native');   
            regs.MTLB.txSymbolLength = single(1/0.5);
            regs.GNRL.sampleRate = uint8(16);
            
        case 'QVGA5S.5_4_104' %26
            regs.GNRL.imgHsize = uint16(320);
            regs.GNRL.imgVsize = uint16(240);
            regs.JFIL.upscalexyBypass = true; % no upsampling
%             regs.JFIL.upscalex1y0 = true;           
            regs.EPTG.frameRate = single(5);
            regs.GNRL.codeLength = uint8(104);
            k = false(1,128);
            k(1:regs.GNRL.codeLength) = Codes.propCode(regs.GNRL.codeLength,1);
            regs.FRMW.txCode = sum(bsxfun(@times,reshape(uint32(k),32,4),uint32(2.^(0:31)')),'native');   
            regs.MTLB.txSymbolLength = single(1/0.5);
            regs.GNRL.sampleRate = uint8(8);
            
        case 'QVGA30S.5_4_104' %27
            regs.GNRL.imgHsize = uint16(320);
            regs.GNRL.imgVsize = uint16(240);
            regs.JFIL.upscalexyBypass = true; % no upsampling
%             regs.JFIL.upscalex1y0 = true;           
            regs.EPTG.frameRate = single(30);
            regs.GNRL.codeLength = uint8(104);
            k = false(1,128);
            k(1:regs.GNRL.codeLength) = Codes.propCode(regs.GNRL.codeLength,1);
            regs.FRMW.txCode = sum(bsxfun(@times,reshape(uint32(k),32,4),uint32(2.^(0:31)')),'native');   
            regs.MTLB.txSymbolLength = single(1/0.5);
            regs.GNRL.sampleRate = uint8(8);
            
        case 'QVGA5S.5_4_128' %28
            regs.GNRL.imgHsize = uint16(320);
            regs.GNRL.imgVsize = uint16(240);
            regs.JFIL.upscalexyBypass = true; % no upsampling
%             regs.JFIL.upscalex1y0 = true;           
            regs.EPTG.frameRate = single(5);
            regs.GNRL.codeLength = uint8(128);
            k = false(1,128);
            k(1:regs.GNRL.codeLength) = Codes.propCode(regs.GNRL.codeLength,1);
            regs.FRMW.txCode = sum(bsxfun(@times,reshape(uint32(k),32,4),uint32(2.^(0:31)')),'native');   
            regs.MTLB.txSymbolLength = single(1/0.5);
            regs.GNRL.sampleRate = uint8(8);
            
        case 'QVGA30S.25_4_44' %29
            regs.GNRL.imgHsize = uint16(320);
            regs.GNRL.imgVsize = uint16(240);
            regs.JFIL.upscalexyBypass = true; % no upsampling
%             regs.JFIL.upscalex1y0 = true;           
            regs.EPTG.frameRate = single(30);
            regs.GNRL.codeLength = uint8(44);
            k = false(1,128);
            k(1:regs.GNRL.codeLength) = Codes.propCode(regs.GNRL.codeLength,1);
            regs.FRMW.txCode = sum(bsxfun(@times,reshape(uint32(k),32,4),uint32(2.^(0:31)')),'native');   
            regs.MTLB.txSymbolLength = single(1/0.25);
            regs.GNRL.sampleRate = uint8(16);
            
        case 'QVGA5S.25_4_64' %30
            regs.GNRL.imgHsize = uint16(320);
            regs.GNRL.imgVsize = uint16(240);
            regs.JFIL.upscalexyBypass = true; % no upsampling
%             regs.JFIL.upscalex1y0 = true;           
            regs.EPTG.frameRate = single(5);
            regs.GNRL.codeLength = uint8(64);
            k = false(1,128);
            k(1:regs.GNRL.codeLength) = Codes.propCode(regs.GNRL.codeLength,1);
            regs.FRMW.txCode = sum(bsxfun(@times,reshape(uint32(k),32,4),uint32(2.^(0:31)')),'native');   
            regs.MTLB.txSymbolLength = single(1/0.25);
            regs.GNRL.sampleRate = uint8(16);
                    
        otherwise
            error('Not a valid mode!');

    end
    
    % Scene params
    regs.EPTG.noiseLevel = single(1.5);
    switch scene
        case 'Wall'
            regs.EPTG.zImageType = uint8(1);
            regs.EPTG.irImageType = uint8(1); 
        case 'randomCubes'
            regs.EPTG.zImageType = uint8(2);
            regs.EPTG.irImageType = uint8(3);            
        otherwise
            error('Invalid mode!');
    end

    % Groundtruth scene params
    GTregs = regs;
    GTregs.EPTG.noiseLevel = single(0.1);
    switch scene
        case 'Wall'
            GTregs.EPTG.zImageType = uint8(1); 
            GTregs.EPTG.irImageType = uint8(1);
        case 'randomCubes'
            GTregs.EPTG.zImageType = uint8(2);
            GTregs.EPTG.irImageType = uint8(3); 
        otherwise
            error('Invalid mode!');
    end        
    GTregs.JFIL.bypass = true;
    
    nMaxSamples = single(7000000); % 1600000000
    regs.EPTG.nMaxSamples = nMaxSamples;
    GTregs.EPTG.nMaxSamples = nMaxSamples;
    
    % Generate scenes
    mkdir(outputDir,sprintf('%s-%s',scene,modeName));
    mkdir(outputDir,sprintf('GT-%s-%s',scene,modeName));
    [ivsFilename,~]=Pipe.patternGenerator(regs,'outputdir',fullfile(outputDir,sprintf('%s-%s',scene,modeName)));
    [GTivsFilename,~]=Pipe.patternGenerator(GTregs,'outputdir',fullfile(outputDir,sprintf('GT-%s-%s',scene,modeName)));

end



