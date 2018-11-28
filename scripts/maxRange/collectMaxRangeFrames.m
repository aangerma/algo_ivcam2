function collectMaxRangeFrames(hw)
% Once the camera is positioned targeting the 10% target this script will
% collect 100 frames for each configuration.
% It will save the frames sturct array in a mat file in a destination at X
% drive.

% Configurations:
% 1. Default.
% 2. Half vertical resolution plus upscale.
% 3. Tx rate of 0.5/0.25 GHz using multi focal.
% 4. Tx rate of 0.5/0.25 GHz using multi focal with LPF disabled.
% 5. Tx rate of 0.5/0.25 using repetitions in the actual code.
% 6. Tx rate of 0.5/0.25 using repetitions in the actual code with LPF disabled.

hw.getFrame(60); % Activate and let it warm up for a minute.
hw.setReg('sphericalEn',1);% Since half res is in spherical, we want the mall to use it.
hw.shadowUpdate();
savedir = 'X:\Data\IvCam2\maxRange\testRecords';
N = 100;
% default
fn = 'default';
fn = fullfile(savedir,[fn,'.mat']);

frames = collectFrames(hw,N);
save(fn,'frames');

% tx_rate_500M_MF_LPF_enabled
fn = 'tx_rate_500M_MF_LPF_enabled';
fn = fullfile(savedir,[fn,'.mat']);
factor = 2; LPFEn = 1; setTxRateMF( hw, factor, LPFEn );
frames = collectFrames(hw,N);
save(fn,'frames');
% tx_rate_500M_MF_LPF_disabled
fn = 'tx_rate_500M_MF_LPF_disabled';
fn = fullfile(savedir,[fn,'.mat']);
factor = 2; LPFEn = 0; setTxRateMF( hw, factor, LPFEn );
frames = collectFrames(hw,N);
save(fn,'frames');
% tx_rate_250M_MF_LPF_enabled
fn = 'tx_rate_250M_MF_LPF_enabled';
fn = fullfile(savedir,[fn,'.mat']);
factor = 4; LPFEn = 1; setTxRateMF( hw, factor, LPFEn );
frames = collectFrames(hw,N);
save(fn,'frames');
% tx_rate_250M_MF_LPF_disabled
fn = 'tx_rate_250M_MF_LPF_disabled';
fn = fullfile(savedir,[fn,'.mat']);
factor = 4; LPFEn = 0; setTxRateMF( hw, factor, LPFEn );
frames = collectFrames(hw,N);
save(fn,'frames');

disableMF(hw);

% tx_rate_500M_LPF_enabled
fn = 'tx_rate_500M_LPF_enabled';
fn = fullfile(savedir,[fn,'.mat']);
factor = 2; LPFEn = 1; 
AFE_LPF_Cmd = strcat('mwd a003006c a0030070',[' ',dec2hex(LPFEn)],' // Enable LPF in the AFE');
hw.cmd(AFE_LPF_Cmd);
setCode52WithRepetitions( hw, factor);
frames = collectFrames(hw,N);
save(fn,'frames');
% tx_rate_500M_LPF_disabled
fn = 'tx_rate_500M_LPF_disabled';
fn = fullfile(savedir,[fn,'.mat']);
factor = 2; LPFEn = 0; 
AFE_LPF_Cmd = strcat('mwd a003006c a0030070',[' ',dec2hex(LPFEn)],' // Enable LPF in the AFE');
hw.cmd(AFE_LPF_Cmd);
setCode52WithRepetitions( hw, factor);
frames = collectFrames(hw,N);
save(fn,'frames');
% tx_rate_250M_LPF_enabled
fn = 'tx_rate_250M_LPF_enabled';
fn = fullfile(savedir,[fn,'.mat']);
factor = 4; LPFEn = 1; 
AFE_LPF_Cmd = strcat('mwd a003006c a0030070',[' ',dec2hex(LPFEn)],' // Enable LPF in the AFE');
hw.cmd(AFE_LPF_Cmd);
setCode52WithRepetitions( hw, factor);
frames = collectFrames(hw,N);
save(fn,'frames');
% tx_rate_250M_LPF_disabled
fn = 'tx_rate_250M_LPF_disabled';
fn = fullfile(savedir,[fn,'.mat']);
factor = 4; LPFEn = 0; 
AFE_LPF_Cmd = strcat('mwd a003006c a0030070',[' ',dec2hex(LPFEn)],' // Enable LPF in the AFE');
hw.cmd(AFE_LPF_Cmd);
setCode52WithRepetitions( hw, factor);
frames = collectFrames(hw,N);
save(fn,'frames');

% Restor default code
factor = 1; LPFEn = 1; 
AFE_LPF_Cmd = strcat('mwd a003006c a0030070',[' ',dec2hex(LPFEn)],' // Enable LPF in the AFE');
hw.cmd(AFE_LPF_Cmd);
setCode52WithRepetitions( hw, factor);

% halfRes
fn = 'halfRes';
fn = fullfile(savedir,[fn,'.mat']);
setHalfRes( hw );
frames = collectFrames(hw,N);
save(fn,'frames');
end

function frames = collectFrames(hw,N)
    pause(0.30);
    for i = 1:N
       frames(i) = hw.getFrame(); 
    end
end