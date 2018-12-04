function collectMaxRangeFrames(initScript)
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
% 6. Tx rate of 0.5/0.25 using repetitions in the actual code.
% 7. Tx rate of 0.5/0.25 using repetitions in the actual code with LPF disabled.

savedir = 'X:\Data\IvCam2\maxRange\testRecordsLatestFixed';
N = 100;
hw = HWinterface;
hw.getFrame(10); % Activate and let it warm up 
hw.setReg('sphericalEn',1);% Since half res is in spherical, we want them all to use it.
hw.shadowUpdate;
pause(0.1);
frameI = hw.getFrame(30).i;
fn = fullfile(savedir,['IR','.mat']);
save(fn,'frameI');

for codeLen = [52,64]
    % default
    hw = openHWInterface(codeLen);
    fn = ['default','_',num2str(codeLen)];
    fn = fullfile(savedir,[fn,'.mat']);
    frames = collectFrames(hw,N);
    save(fn,'frames');
    clear hw

    % tx_rate_500M_MF_LPF_enabled
    hw = openHWInterface(codeLen);
    fn = ['tx_rate_500M_MF_LPF_enabled','_',num2str(codeLen)];
    fn = fullfile(savedir,[fn,'.mat']);
    factor = 2; LPFEn = 1; setTxRateMF( hw, factor, LPFEn );
    frames = collectFrames(hw,N);
    save(fn,'frames');
    clear hw
    % tx_rate_500M_MF_LPF_disabled
    hw = openHWInterface(codeLen);
    fn = ['tx_rate_500M_MF_LPF_disabled','_',num2str(codeLen)];
    fn = fullfile(savedir,[fn,'.mat']);
    factor = 2; LPFEn = 0; setTxRateMF( hw, factor, LPFEn );
    frames = collectFrames(hw,N);
    save(fn,'frames');
    clear hw
    % tx_rate_250M_MF_LPF_enabled
    hw = openHWInterface(codeLen);
    fn = ['tx_rate_250M_MF_LPF_enabled','_',num2str(codeLen)];
    fn = fullfile(savedir,[fn,'.mat']);
    factor = 4; LPFEn = 1; setTxRateMF( hw, factor, LPFEn );
    frames = collectFrames(hw,N);
    save(fn,'frames');
    clear hw
    % tx_rate_250M_MF_LPF_disabled
    hw = openHWInterface(codeLen);
    fn = ['tx_rate_250M_MF_LPF_disabled','_',num2str(codeLen)];
    fn = fullfile(savedir,[fn,'.mat']);
    factor = 4; LPFEn = 0; setTxRateMF( hw, factor, LPFEn );
    frames = collectFrames(hw,N);
    save(fn,'frames');
    clear hw

    % tx_rate_500M_LPF_enabled
    hw = openHWInterface(codeLen);
    fn = ['tx_rate_500M_LPF_enabled','_',num2str(codeLen)];
    fn = fullfile(savedir,[fn,'.mat']);
    factor = 2; LPFEn = 1; 
    AFE_LPF_Cmd = strcat('mwd a003006c a0030070',[' ',dec2hex(LPFEn)],' // Enable LPF in the AFE');
    hw.cmd(AFE_LPF_Cmd);
    setCodeWithRepetitions( hw,codeLen, factor);
    frames = collectFrames(hw,N);
    save(fn,'frames');
    clear hw
    % tx_rate_500M_LPF_disabled
    hw = openHWInterface(codeLen);
    fn = ['tx_rate_500M_LPF_disabled','_',num2str(codeLen)];
    fn = fullfile(savedir,[fn,'.mat']);
    factor = 2; LPFEn = 0; 
    AFE_LPF_Cmd = strcat('mwd a003006c a0030070',[' ',dec2hex(LPFEn)],' // Enable LPF in the AFE');
    hw.cmd(AFE_LPF_Cmd);
    setCodeWithRepetitions( hw,codeLen, factor);
    frames = collectFrames(hw,N);
    save(fn,'frames');
    clear hw
    % tx_rate_250M_LPF_enabled
    hw = openHWInterface(codeLen);
    fn = ['tx_rate_250M_LPF_enabled','_',num2str(codeLen)];
    fn = fullfile(savedir,[fn,'.mat']);
    factor = 4; LPFEn = 1; 
    AFE_LPF_Cmd = strcat('mwd a003006c a0030070',[' ',dec2hex(LPFEn)],' // Enable LPF in the AFE');
    hw.cmd(AFE_LPF_Cmd);
    setCodeWithRepetitions( hw,codeLen, factor);
    frames = collectFrames(hw,N);
    save(fn,'frames');
    clear hw
    % tx_rate_250M_LPF_disabled
    hw = openHWInterface(codeLen);
    fn = ['tx_rate_250M_LPF_disabled','_',num2str(codeLen)];
    fn = fullfile(savedir,[fn,'.mat']);
    factor = 4; LPFEn = 0; 
    AFE_LPF_Cmd = strcat('mwd a003006c a0030070',[' ',dec2hex(LPFEn)],' // Enable LPF in the AFE');
    hw.cmd(AFE_LPF_Cmd);
    setCodeWithRepetitions( hw,codeLen, factor);
    frames = collectFrames(hw,N);
    save(fn,'frames');
    clear hw

    % halfResX
    hw = openHWInterface(codeLen);
    fn = ['halfResX','_',num2str(codeLen)];
    fn = fullfile(savedir,[fn,'.mat']);
    setHalfRes( hw,1 );
    frames = collectFrames(hw,N);
    save(fn,'frames');
    clear hw

    % halfResY
    hw = openHWInterface(codeLen);
    fn = ['halfResX','_',num2str(codeLen)];
    fn = fullfile(savedir,[fn,'.mat']);
    setHalfRes( hw,1 );
    frames = collectFrames(hw,N);
    save(fn,'frames');
    clear hw

end
end
function hw = openHWInterface(codeLen)
hw = HWinterface;
hw.getFrame(10); % Activate and let it warm up 
hw.setReg('sphericalEn',1);% Since half res is in spherical, we want them all to use it.
hw.setReg('DESTaltIrEn',1);
hw.setCode(Codes.codeRegs(codeLen,4),0);

end
function frames = collectFrames(hw,N)
    pause(0.30);
    for i = 1:N
       frames(i) = hw.getFrame(); 
    end
end