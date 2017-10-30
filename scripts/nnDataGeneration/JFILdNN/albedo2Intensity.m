function [intensity] = albedo2Intensity(regs,zImg,aImg)
zImg = zImg*8;
[fw,p] = getInputRegs(regs,'zimg',zImg,'aimg',aImg);
[regs,luts] = fw.get();
[vImg,rImg] = genVerts(zImg,regs);
dist = sqrt(sum(vImg.^2,3));
intensity = aImg./(dist.^2*1e-6) * (2^12-1);
intensity = uint16(min(2^12-1,max(0,intensity)));

end

function [v,r]=genVerts(zUINT16,regs)


[sinx,cosx,~,~,sinw,cosw,~]=Pipe.DEST.getTrigo(size(zUINT16),regs);
 
    


% [nyi,nxi]=ndgrid((1:h)/h*2-1,(1:w)/w*2-1);
% 
% phi   = atand(tand(regs.FRMW.xfov/2).*nxi);
% theta = atand(tand(regs.FRMW.yfov/2).*nyi);
z = double(zUINT16)/bitshift(1,regs.GNRL.zMaxSubMMExp);
z(zUINT16==0)=nan;

r = z./(cosx.*cosw);
x = z.*sinx./cosx;
y = z.*sinw./(cosw.*cosx);

v = cat(3,x,y,z);
end

function [fw,p] =getInputRegs(varargin)
isflag = @(x) or(isnumeric(x),islogical(x));
isimg = @(x) ismatrix(x) && min(x(:))>=0;

inputData=varargin{1};

if(ischar(inputData) && exist(inputData,'file')~=0)
    defOutDir=fileparts(inputData);
else
    defOutDir = tempdir;
end
p = inputParser;
addOptional(p,'outputDir',defOutDir);
addOptional(p,'verbose',false,isflag);
addOptional(p,'zImg',[],isimg);
addOptional(p,'aImg',[],isimg);
addOptional(p,'runPipe',false,isflag);
addOptional(p,'regHandle','throw',@ischar);

parse(p,varargin{2:end});
p = p.Results;



p.configOutputFilename = fullfile(p.outputDir,filesep,'config.csv');



fw = Firmware();
fw.setRegHandle(p.regHandle);
if(isstruct(inputData)) %regs struct
    configOutputFilename = fullfile(p.outputDir,'config.csv');
    fw.setRegs(inputData,configOutputFilename);
elseif(~isempty(strfind(inputData,'.csv'))) %config.csv
    if(~exist(inputData,'file'))
        error('COuld not find file %s',inputData);
    end
    if(~strcmpi(inputData,p.configOutputFilename))
        copyfile(inputData,p.configOutputFilename,'f')
    end
    fw.setRegs(p.configOutputFilename);
    
    
    
elseif(ischar(inputData))
    switch(inputData)
        case 'wall'
            patgenregs.EPTG.zImageType = uint8(1);
            patgenregs.EPTG.irImageType = uint8(1);
            patgenregs.EPTG.irImageType = uint8(1);
            patgenregs.EPTG.minZ = single(1000);
            patgenregs.EPTG.maxZ = single(1000);
            patgenregs.FRMW.xres = uint16(320);
            patgenregs.FRMW.yres = uint16(240);
            patgenregs.EPTG.frameRate = single(60);
            patgenregs.EPTG.noiseLevel=single(0);
            patgenregs.EPTG.sampleJitter=single(0);
            patgenregs.EPTG.calibVariationsP=single(0);
            patgenregs.DEST.hbaseline=false;
            patgenregs.DEST.baseline=single(30);
            
        case 'debug'
            patgenregs.EPTG.maxZ = single(1500);
            patgenregs.EPTG.zImageType = uint8(2);
            patgenregs.EPTG.irImageType = uint8(1);
            patgenregs.EPTG.noiseLevel = single(0.01);
            patgenregs.FRMW.xres=uint16(64);
            patgenregs.FRMW.yres=uint16(64);
            patgenregs.JFIL.dnnBypass=true;
            patgenregs.EPTG.frameRate=single(600);
            
            [patgenregs.FRMW.txCode, patgenregs.GNRL.codeLength] = Utils.bin2uint32( Codes.propCode(16,1) );
        case 'checkerboard'
            patgenregs.EPTG.zImageType = uint8(1);
            patgenregs.EPTG.irImageType = uint8(2);
            patgenregs.EPTG.noiseLevel = single(0.01);
            patgenregs.EPTG.frameRate = single(60);
        case 'largeFOV'
            patgenregs.EPTG.zImageType = uint8(1);
            patgenregs.EPTG.irImageType = uint8(2);
            patgenregs.DIGG.undistBypass = false;
            patgenregs.EPTG.frameRate = single(60);
        case 'randomA'
            patgenregs.EPTG.zImageType = uint8(2);
            patgenregs.EPTG.irImageType = uint8(3);
            patgenregs.EPTG.frameRate = single(60);
        case 'randomB'
            patgenregs.EPTG.zImageType = uint8(5);
            patgenregs.EPTG.irImageType = uint8(1);
            patgenregs.EPTG.frameRate = single(60);
        case 'helloworld'
            patgenregs.EPTG.zImageType = uint8(3);
            patgenregs.EPTG.irImageType = uint8(1);
            patgenregs.EPTG.frameRate = single(60);
        case 'rangefinder'
            
            patgenregs.GNRL.rangeFinder= true;
            patgenregs.FRMW.xres=uint16(2);
            patgenregs.FRMW.yres=uint16(1);
            patgenregs.RAST.biltBypass=true;
            patgenregs.CBUF.bypass=true;
            [patgenregs.FRMW.txCode, patgenregs.GNRL.codeLength] = Utils.bin2uint32( Codes.propCode(128,1) );
        case 'ironly'
            
            [patgenregs.FRMW.txCode, patgenregs.GNRL.codeLength] = Utils.bin2uint32( [1 0 1 0 1 0 1 0] );
            patgenregs.DCOR.bypass=true;
            patgenregs.DEST.bypass=true;
            patgenregs.JFIL.edge1bypassMode = uint8(1);
            patgenregs.JFIL.edge3bypassMode = uint8(1);
            patgenregs.JFIL.edge4bypassMode = uint8(1);
            patgenregs.JFIL.dnnBypass = true;
            patgenregs.DIGG.notchBypass = true;
        case 'multifocal'
            
            patgenregs.EPTG.zImageType = uint8(2);
            patgenregs.EPTG.irImageType = uint8(3);
            patgenregs.EPTG.multiFocalROI=int32([-600 -400 1000 1000]);
            patgenregs.EPTG.frameRate=single(60);
        otherwise
            error('Unknonw patgen input');
            
    end
    fw.setRegs(patgenregs,p.configOutputFilename);
    
else
    error('Unknonw input');
end



end
