function [status] = Iv2CaptureLoopFGTimeStamp(dname,T, codeFlag, left, top)
    
    if ~exist('T','var')
        T = 1;
    end
    
    if ~exist('codeFlag','var')
        codeFlag = 2;
    end
    
    if ~exist('left','var')
        left = 0;
    end
    
    if ~exist('top','var')
        top = 0;
    end
    
    if ischar(codeFlag) || isstring(codeFlag)
        codeFlag = str2double(codeFlag);
    end
    
    if ischar(T) || isstring(T)
        T = str2double(T);
    end
    
    if ischar(left) || isstring(left)
        left = str2double(left);
    end
    
    if ischar(top) || isstring(top)
        top = str2double(top);
    end
    
    %prepare the folder
    mkdirSafe(dname);
    base_name = 'FG_TimeStamp_';
    
    %prepare the camera
    hw = HWinterface();
    hw.cmd('dirtybitbypass');
    hw.runScript('ldOn.txt');
    pause(1);
    
    warning off;
    if codeFlag >0
        
        %change code
        fullCode = zeros(128,1);
        codeLen = 64;
        switch codeFlag
            case 1 %64x1
                code_64 =  vec(repmat(Codes.propCode(64,1),1,2)');
                fullCode(1:length(code_64)) = code_64;
            case 2 %32x2
                code_32x2 =  vec(repmat(Codes.propCode(32,1),1,2)');
                fullCode(1:length(code_32x2)) = code_32x2;
            case 3 %16x4
                code_16x4 =  vec(repmat(Codes.propCode(16,1),1,4)');
                fullCode(1:length(code_16x4)) = code_16x4;
            otherwise
                error('unknown code flag');
        end
        code2Use = uint32(bin2dec(reshape(num2str(fullCode)',32,4)'))';
        
        %change actual code. due to bug in hw.setRegs can't use it for code
        baseAddress = 2231762944;
        for i=0:3
            hw.writeAddr(uint32(baseAddress+i*4),code2Use(i+1));%EXTLauxPItxCode
        end
        hw.writeAddr(uint32(2684682680),uint32(codeLen));% EXTLauxPItxCodeLength
        hw.cmd('mwd a00d01ec a00d01f0 00000111 // EXTLauxShadowUpdateFrame');
        pause(0.1);
        
    end
    
    res = [720 1280];
    pos.left = left;
    pos.top = top;
    
    % initiate and "warm up" the unit so setReg and
    % runScript commands take effect
    hw.FG_getFrame(100,res,pos);
    fprintf('starting...\n');
    
    prevTs = now;
    while (true)
        frame = hw.FG_getFrame(1,res,pos);
        ts_curr = now;
        fn = fullfile(dname,strcat(base_name, datestr(ts_curr,'dd-mm-yyyy HH-MM-SS-FFF'),'.bin'));
        fid = fopen(fn,'w');
        fwrite(fid,frame.fg,'uint8');
        fclose(fid);
        %delta = etime(datevec(datenum(ts_curr)),datevec(datenum(prevTs)));
        pause(T-0.05);
        prevTs = ts_curr;
    end
end

