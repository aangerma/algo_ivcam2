%% Firmare class 
%{
Manages the current state of the registers.  
%} 

fw = Firmware; % Registers state is asic default (as described in Pipe\tables\.*frmw)

initFW = fullfile(fileparts(pwd),'+Calibration','initScript'); % Folder with csv files with reg names and values
fw = Pipe.loadFirmware(initFW);% Load from a specific folder

fw.disp('baseline'); % Displays regs whos names fit the expression and their values.
[regs,luts] = fw.get();  regs = fw.get(); % Set the values of autogened regs and get a reg/lut struct.
fw.disp('baseline'); % Displays regs whos names fit the expression and their values.


mwdFileName = [tempname '.txt']; 
fw.genMWDcmd('baseline', mwdFileName); % Creates a script with mwd commands 

newRegs.DEST.baseline = single(20); % Set a single reg to a new value
fw.setRegs(newRegs,''); % Sets the reg to the new value in the fw object.
fw.disp('baseline'); % Displays regs whos names fit the expression and their values.
regs = fw.get(); % Runs the auto gen and gives an updated reg struct.
fw.disp('baseline'); % Displays regs whos names fit the expression and their values.


%% HWInterface
%{
Interface with the demoboard. 
%}
hw = HWinterface();
frame = hw.getFrame(); % Grab a frame (with z,i and c)  
pause(1); % wait for a second so the unit will warm up (open full fov, activate laser)
figure,tabplot; subplot(131), imagesc(frame.z/8); title('z'); subplot(132), imagesc(frame.c);title('c');subplot(133), imagesc(frame.i);title('i');
frame = hw.getFrame(30); % Grab 30 frames and average them (with z,i and c)  
tabplot; subplot(131), imagesc(frame.z/8); title('z'); subplot(132), imagesc(frame.c);title('c');subplot(133), imagesc(frame.i);title('i');

%% Update configuration
%{
Three methods to update registers:
1. By command or script - recommended when there are many registers to
update. 
2. By RegState -  recommended when there are few registers to update.
3. registerUpdateGUI - Great when you want to play with registers during streaming. 
%}

% 1. By command or script.
spRegs.DIGG.sphericalEn = 1; % Set a single reg to a new value
fw.setRegs(spRegs,''); % Sets the reg to the new value in the fw object.
regs = fw.get(); % Runs the auto gen and gives an updated reg struct.
fw.genMWDcmd('sphericalEn',mwdFileName) % Show the commands relevant for spherical mode
% hw.cmd('mwd a0020bf8 a0020bfc 00000001 // DIGGsphericalEn')% Send a command. Set spherical enable to 'on' 
hw.runScript(mwdFileName); % Run multiple lines of commands via text
% file.
hw.shadowUpdate(); % Apply the change. Some registers needs shadow update.

frame = hw.getFrame(); % Grab a frame (with z,i and c)  
tabplot; subplot(131), imagesc(frame.z/8); title('z'); subplot(132), imagesc(frame.c);title('c');subplot(133), imagesc(frame.i);title('i');

% 2. By RegState
r=Calibration.RegState(hw); % create the object
r.add('sphericalEn'        ,0 ); % Return spherical enable to false.
% r.add('JFILinvConfThr',uint8(0));
r.set();% Apply the new values (includes shadow update)
frame = hw.getFrame(); 
tabplot; subplot(131), imagesc(frame.z/8); title('z'); subplot(132), imagesc(frame.c);title('c');subplot(133), imagesc(frame.i);title('i');
r.reset();% Return regs to previous values. (sphericalEn is now 1)

% 3. By registerUpdateGUI.m
registerUpdateGUI; % A nice tool to control registers. Can be used with HWInterface or ipdev. Found under: lgo_ivcam2\scripts\registerUpdateGUI.m