function collectMaxRangeFrames()
% Once the camera is positioned targeting the 10% target this script will
% collect 100 frames for each configuration.
% It will save the frames sturct array in a mat file in a destination at X
% drive.

% Configurations (for 64 and 52 code):
% 1. Default.
% 2. Half horizontal resolution plus upscale X.
% 3. Half vertical resolution plus upscale Y.
% 4. Tx rate of 0.5/0.25 GHz using multi focal.
% 5. Tx rate of 0.5/0.25 GHz using multi focal with LPF disabled.
% 6. Tx rate of 0.5/0.25 using repetitions of code 26 and barker.



savedir = 'X:\Data\IvCam2\maxRange\testRecord5';
savedir = '\\ger\ec\proj\ha\RSG\SA_3DCam\TMund\maxRange\testRecord5';
N = 50;

for codeLen = [52,64]
    clear hw
    waitfor(msgbox('Please disconnect and reconnect the unit. Press ok when done.')); 
    hw = openHWInterface();
    if codeLen == 64
         setCodeWithRepetitions( hw,codeLen, 1);
    end
    frame = hw.getFrame(10);
    fn = fullfile(savedir,['scene_frame_',num2str(codeLen),'.mat']);
    save(fn,'frame');

    % default
    [fn,fn_ir_dc] = getFnames(savedir,'default',codeLen);
    frames = collectFrames(hw,N);
    tabplot; imagesc(frames(1).z/8);title(fn)
    setAltIr(hw,0);setConfAsDC(hw);
    frames_ir_dc = collectFrames(hw,N);
    save(fn,'frames');
    save(fn_ir_dc,'frames_ir_dc');
    setAltIr(hw,1); hw.shadowUpdate;
    
    % tx_rate_500M_MF
    [fn,fn_ir_dc] = getFnames(savedir,'tx_rate_500M_MF',codeLen);
    factor = 2; setTxRateMF( hw, factor, 1 );
    frames = collectFrames(hw,N);
    tabplot; imagesc(frames(1).z/8);title(fn)
    setAltIr(hw,0);setConfAsDC(hw);
    frames_ir_dc = collectFrames(hw,N);
    save(fn,'frames');
    save(fn_ir_dc,'frames_ir_dc');
    setAltIr(hw,1); hw.shadowUpdate;
    
    % tx_rate_250M_MF
    [fn,fn_ir_dc] = getFnames(savedir,'tx_rate_250M_MF',codeLen);
    factor = 4; setTxRateMF( hw, factor, 1 );
    frames = collectFrames(hw,N);
    tabplot; imagesc(frames(1).z/8);title(fn)
    setAltIr(hw,0);setConfAsDC(hw);
    frames_ir_dc = collectFrames(hw,N);
    save(fn,'frames');
    save(fn_ir_dc,'frames_ir_dc');
    setAltIr(hw,1); hw.shadowUpdate;
    
    clear hw
    waitfor(msgbox('Please disconnect and reconnect the unit. Press ok when done.')); 
    hw = openHWInterface();
    
    
    % tx_rate_500M
    [fn,fn_ir_dc] = getFnames(savedir,'tx_rate_500M',codeLen);
    factor = 2; 
    setCodeWithRepetitions( hw,codeLen/factor, factor);
    frames = collectFrames(hw,N);
    tabplot; imagesc(frames(1).z/8);title(fn)
    setAltIr(hw,0);setConfAsDC(hw);
    frames_ir_dc = collectFrames(hw,N);
    save(fn,'frames');
    save(fn_ir_dc,'frames_ir_dc');
    setAltIr(hw,1); hw.shadowUpdate;
    

    % tx_rate_250M
    [fn,fn_ir_dc] = getFnames(savedir,'tx_rate_250M',codeLen);
    factor = 4;
    setCodeWithRepetitions( hw,codeLen/factor, factor);
    frames = collectFrames(hw,N);
    tabplot; imagesc(frames(1).z/8);title(fn)
    setAltIr(hw,0);setConfAsDC(hw);
    frames_ir_dc = collectFrames(hw,N);
    save(fn,'frames');
    save(fn_ir_dc,'frames_ir_dc');
    setAltIr(hw,1); hw.shadowUpdate;
    
    
    clear hw
    waitfor(msgbox('Please disconnect and reconnect the unit. Press ok when done.')); 
    hw = openHWInterface();
    
    % halfResX
    [fn,fn_ir_dc] = getFnames(savedir,'halfResX',codeLen);
    setHalfRes( hw,1 );
    if codeLen == 64
         setCodeWithRepetitions( hw,codeLen, 1);
    end
    hw.setReg('sphericalEn',1);% Since half res is in spherical, we want them all to use it.
    hw.setReg('DESTaltIrEn',1);
    hw.setReg('JFILinvBypass',1);
    hw.shadowUpdate();  
    pause(0.1);
    frames = collectFrames(hw,N);
    tabplot; imagesc(frames(1).z/8);title(fn)
    setAltIr(hw,0);setConfAsDC(hw);
    frames_ir_dc = collectFrames(hw,N);
    save(fn,'frames');
    save(fn_ir_dc,'frames_ir_dc');
    setAltIr(hw,1); hw.shadowUpdate;
    
    
    
    % halfResX code 26 repeat 2
    [fn,fn_ir_dc] = getFnames(savedir,'halfResX_tx_rate_500',codeLen);
    setCodeWithRepetitions( hw,codeLen/2, 2);
    hw.setReg('sphericalEn',1);% Since half res is in spherical, we want them all to use it.
    hw.setReg('DESTaltIrEn',1);
    hw.setReg('JFILinvBypass',1);
    hw.shadowUpdate();  
    pause(0.1);
    frames = collectFrames(hw,N);
    tabplot; imagesc(frames(1).z/8);title(fn)
    setAltIr(hw,0);setConfAsDC(hw);
    frames_ir_dc = collectFrames(hw,N);
    save(fn,'frames');
    save(fn_ir_dc,'frames_ir_dc');
    setAltIr(hw,1); hw.shadowUpdate;
    
    % halfResX code 13 repeat 4
    [fn,fn_ir_dc] = getFnames(savedir,'halfResX_tx_rate_250',codeLen);
    setCodeWithRepetitions( hw,codeLen/4, 4);
    hw.setReg('sphericalEn',1);% Since half res is in spherical, we want them all to use it.
    hw.setReg('DESTaltIrEn',1);
    hw.setReg('JFILinvBypass',1);
    hw.shadowUpdate();  
    pause(0.1);
    frames = collectFrames(hw,N);
    tabplot; imagesc(frames(1).z/8);title(fn)
    setAltIr(hw,0);setConfAsDC(hw);
    frames_ir_dc = collectFrames(hw,N);
    save(fn,'frames');
    save(fn_ir_dc,'frames_ir_dc');
    setAltIr(hw,1); hw.shadowUpdate;
    
    
    clear hw
    waitfor(msgbox('Please disconnect and reconnect the unit. Press ok when done.')); 
    hw = openHWInterface();
    
    % halfResY
    [fn,fn_ir_dc] = getFnames(savedir,'halfResY',codeLen);
    setHalfRes( hw,0 );
    if codeLen == 64
         setCodeWithRepetitions( hw,codeLen, 1);
    end
    hw.setReg('sphericalEn',1);% Since half res is in spherical, we want them all to use it.
    hw.setReg('DESTaltIrEn',1);
    hw.setReg('JFILinvBypass',1);
    hw.shadowUpdate();  
    pause(0.1);
    frames = collectFrames(hw,N);
    tabplot; imagesc(frames(1).z/8)
    setAltIr(hw,0);setConfAsDC(hw);
    frames_ir_dc = collectFrames(hw,N);
    save(fn,'frames');
    save(fn_ir_dc,'frames_ir_dc');
    setAltIr(hw,1); hw.shadowUpdate;
    
    
    % halfResY code 26 repeat 2
    [fn,fn_ir_dc] = getFnames(savedir,'halfResY_tx_rate_500',codeLen);
    setCodeWithRepetitions( hw,codeLen/2, 2);
    hw.setReg('sphericalEn',1);% Since half res is in spherical, we want them all to use it.
    hw.setReg('DESTaltIrEn',1);
    hw.setReg('JFILinvBypass',1);
    hw.shadowUpdate();  
    pause(0.1);
    frames = collectFrames(hw,N);
    tabplot; imagesc(frames(1).z/8);title(fn);
    setAltIr(hw,0);setConfAsDC(hw);
    frames_ir_dc = collectFrames(hw,N);
    save(fn,'frames');
    save(fn_ir_dc,'frames_ir_dc');
    setAltIr(hw,1); hw.shadowUpdate;
    
    
    % halfResY code 13 repeat 4
    [fn,fn_ir_dc] = getFnames(savedir,'halfResY_tx_rate_250',codeLen);
    setCodeWithRepetitions( hw,codeLen/4, 4);
    hw.setReg('sphericalEn',1);% Since half res is in spherical, we want them all to use it.
    hw.setReg('DESTaltIrEn',1);
    hw.setReg('JFILinvBypass',1);
    hw.shadowUpdate();  
    pause(0.1);
    frames = collectFrames(hw,N);
    tabplot; imagesc(frames(1).z/8); title(fn);
    setAltIr(hw,0);setConfAsDC(hw);
    frames_ir_dc = collectFrames(hw,N);
    save(fn,'frames');
    save(fn_ir_dc,'frames_ir_dc');
    setAltIr(hw,1); hw.shadowUpdate;
    
    
    clear hw

end
end
function setInitScript(hw,initScript)
    hw.runPresetScript('maReset');
    pause(0.1);
    hw.runScript(initScript);
    pause(0.1);
    hw.runPresetScript('maRestart');
    pause(0.1);
    hw.runPresetScript('maReset');
    hw.runPresetScript('maRestart');
    hw.shadowUpdate();

end
function hw = openHWInterface()
hw = HWinterface;
hw.getFrame(10); % Activate and let it warm up 
hw.setReg('sphericalEn',1);% Since half res is in spherical, we want them all to use it.
hw.setReg('DESTaltIrEn',1);
hw.setReg('JFILinvBypass',1);
hw.shadowUpdate();

pause(0.1);
end
function setAltIr(hw,altIrEn)
hw.setReg('DESTaltIrEn',altIrEn);
end
function setConfAsDC(hw)
hw.setConfidenceAs('dc');
end
function frames = collectFrames(hw,N)
    pause(0.30);
    for i = 1:N
       frames(i) = hw.getFrame(); 
    end
end
    
function [fn,fn_ir_dc] = getFnames(savedir,prefix,codeLen)
    fn = [prefix,'_',num2str(codeLen)];
    fn = fullfile(savedir,[fn,'.mat']);
    fn_ir_dc = ['ir_dc_',prefix,'_',num2str(codeLen)];
    fn_ir_dc = fullfile(savedir,[fn_ir_dc,'.mat']);
    
end
